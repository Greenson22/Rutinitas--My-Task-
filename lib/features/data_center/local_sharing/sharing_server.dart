import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:archive/archive_io.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import '../../../core/services/storage_service.dart';

class SharingServer {
  final StorageService _storageService = StorageService();
  HttpServer? _serverEksternal;

  Future<String> _getLocalIpAddress() async {
    try {
      List<NetworkInterface> interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      for (var interface in interfaces) {
        for (var address in interface.addresses) {
          if (address.address.isNotEmpty) return address.address;
        }
      }
    } catch (e) {
      debugPrint("Gagal mendapatkan alamat IP: $e");
    }
    return "Tidak Diketahui";
  }

  void startServer({
    required BuildContext context,
    required String baseDir,
    required String Function(String prefix, String extension)
    getFormattedFileName,
    required VoidCallback onDataReceived,
  }) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Menyiapkan server komunikasi dua arah...'),
        backgroundColor: Colors.indigo,
      ),
    );

    try {
      String localIp = await _getLocalIpAddress();

      if (_serverEksternal != null) {
        await _serverEksternal!.close(force: true);
      }

      List<dynamic> clientActiveList = [];
      StateSetter? dialogState;

      var handler = webSocketHandler((dynamic webSocket, dynamic protocol) {
        final String clientId =
            "Client_${webSocket.hashCode.toString().substring(0, 4)}";

        clientActiveList.add(webSocket);
        if (dialogState != null) dialogState!(() {});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔌 [$clientId] Berhasil Terhubung ke Server!'),
            backgroundColor: Colors.green[800],
            duration: const Duration(seconds: 3),
          ),
        );

        Map<String, dynamic> openingMessage = {
          'tipe_pesan': 'koneksi_terkonfirmasi',
        };
        webSocket.sink.add(jsonEncode(openingMessage));

        webSocket.stream.listen(
          (pesanMasuk) async {
            try {
              Map<String, dynamic> dateReceived = jsonDecode(pesanMasuk);
              if (dateReceived['tipe_pesan'] == 'data_transfer') {
                String clientTasks = dateReceived['task_master'];
                String clientJurnal = dateReceived['jurnal_aktivitas'];
                String clientZipBase64 = dateReceived['checklist_zip'];
                String clientNotesZipBase64 = dateReceived['notes_zip'] ?? "";
                String clientPromptsZipBase64 =
                    dateReceived['prompts_zip'] ?? "";

                final Archive clientArchive = Archive();
                List<int> tasksBytes = utf8.encode(clientTasks);
                clientArchive.addFile(
                  ArchiveFile('my_tasks.json', tasksBytes.length, tasksBytes),
                );

                List<int> jurnalBytes = utf8.encode(clientJurnal);
                clientArchive.addFile(
                  ArchiveFile('time_log.json', jurnalBytes.length, jurnalBytes),
                );

                if (clientZipBase64.isNotEmpty) {
                  List<int> chkBytes = base64Decode(clientZipBase64);
                  Archive checklistArchive = ZipDecoder().decodeBytes(chkBytes);
                  for (ArchiveFile file in checklistArchive) {
                    if (file.isFile) {
                      clientArchive.addFile(
                        ArchiveFile(
                          'my_checklist/${file.name}',
                          file.content.length,
                          file.content,
                        ),
                      );
                    }
                  }
                }

                if (clientNotesZipBase64.isNotEmpty) {
                  List<int> notesBytes = base64Decode(clientNotesZipBase64);
                  Archive notesArchive = ZipDecoder().decodeBytes(notesBytes);
                  for (ArchiveFile file in notesArchive) {
                    if (file.isFile) {
                      clientArchive.addFile(
                        ArchiveFile(
                          'notes/${file.name}',
                          file.content.length,
                          file.content,
                        ),
                      );
                    }
                  }
                }

                if (clientPromptsZipBase64.isNotEmpty) {
                  List<int> promptsBytes = base64Decode(clientPromptsZipBase64);
                  Archive promptsArchive = ZipDecoder().decodeBytes(
                    promptsBytes,
                  );
                  for (ArchiveFile file in promptsArchive) {
                    if (file.isFile) {
                      clientArchive.addFile(
                        ArchiveFile(
                          'prompts/${file.name}',
                          file.content.length,
                          file.content,
                        ),
                      );
                    }
                  }
                }

                final List<int>? finalZipBytes = ZipEncoder().encode(
                  clientArchive,
                );
                if (finalZipBytes != null) {
                  String namaZipDinamis = getFormattedFileName(
                    'client_backup',
                    'zip',
                  );
                  File fileZipTarget = await _storageService.getBackupZipFile(
                    baseDir,
                    namaZipDinamis,
                  );
                  await fileZipTarget.writeAsBytes(finalZipBytes);

                  onDataReceived();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Sukses menerima data dari Client! Tersimpan: $namaZipDinamis',
                      ),
                      backgroundColor: Colors.teal,
                    ),
                  );
                }
              }
            } catch (err) {
              debugPrint("Server gagal memproses pesan: $err");
            }
          },
          onDone: () {
            clientActiveList.remove(webSocket);
            if (dialogState != null) dialogState!(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '❌ [$clientId] Koneksi Terputus atau Tiba-tiba Hilang.',
                ),
                backgroundColor: Colors.red[700],
                duration: const Duration(seconds: 4),
              ),
            );
          },
          onError: (error) {
            clientActiveList.remove(webSocket);
            if (dialogState != null) dialogState!(() {});
            debugPrint("Pipa jaringan error: $error");
          },
        );
      });

      _serverEksternal = await shelf_io.serve(
        handler,
        InternetAddress.anyIPv4,
        8090,
      );

      Future<void> sendDataToServer() async {
        if (clientActiveList.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Gagal! Belum ada perangkat penerima yang terhubung.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        String currentDir = await _storageService.getBaseDirSetting();
        File fileTasks = await _storageService.getTargetJsonFile(currentDir);
        String tasksContent = await fileTasks.exists()
            ? await fileTasks.readAsString()
            : "{}";

        File fileJurnal = await _storageService.getJurnalJsonFile(currentDir);
        String journalContent = await fileJurnal.exists()
            ? await fileJurnal.readAsString()
            : "[]";

        List<File> groupFiles = await _storageService.getAllChecklistGroups(
          currentDir,
        );
        final Archive archive = Archive();
        for (var file in groupFiles) {
          archive.addFile(
            ArchiveFile(
              file.path.split('/').last,
              file.lengthSync(),
              await file.readAsBytes(),
            ),
          );
        }
        final List<int>? zipBytes = ZipEncoder().encode(archive);
        String zipBase64Content = zipBytes != null
            ? base64Encode(zipBytes)
            : "";

        List<File> noteFiles = await _storageService.getAllNoteGroups(
          currentDir,
        );
        final Archive notesArchive = Archive();
        for (var file in noteFiles) {
          notesArchive.addFile(
            ArchiveFile(
              file.path.split('/').last,
              file.lengthSync(),
              await file.readAsBytes(),
            ),
          );
        }
        final List<int>? notesZipBytes = ZipEncoder().encode(notesArchive);
        String notesBase64Content = notesZipBytes != null
            ? base64Encode(notesZipBytes)
            : "";

        List<File> promptFiles = await _storageService.getAllPromptGroups(
          currentDir,
        );
        final Archive promptsArchive = Archive();
        for (var file in promptFiles) {
          promptsArchive.addFile(
            ArchiveFile(
              file.path.split('/').last,
              file.lengthSync(),
              await file.readAsBytes(),
            ),
          );
        }
        final List<int>? promptsZipBytes = ZipEncoder().encode(promptsArchive);
        String promptsBase64Content = promptsZipBytes != null
            ? base64Encode(promptsZipBytes)
            : "";

        Map<String, dynamic> sendBigPackage = {
          'tipe_pesan': 'data_transfer',
          'task_master': tasksContent,
          'jurnal_aktivitas': journalContent,
          'checklist_zip': zipBase64Content,
          'notes_zip': notesBase64Content,
          'prompts_zip': promptsBase64Content,
        };

        for (var socket in clientActiveList) {
          socket.sink.add(jsonEncode(sendBigPackage));
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Berhasil mengirim data ke ${clientActiveList.length} Client!',
            ),
            backgroundColor: Colors.teal,
          ),
        );
      }

      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setDialogState) {
            dialogState = setDialogState;
            bool adaClient = clientActiveList.isNotEmpty;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.wifi_tethering, color: Colors.indigo[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Server Sharing Aktif',
                    style: TextStyle(
                      color: Colors.indigo[900],
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.indigo.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Masukkan IP ini di perangkat Penerima:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          localIp,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo.shade900,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: adaClient
                          ? Colors.green.shade50
                          : Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: adaClient
                            ? Colors.green.shade200
                            : Colors.amber.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          adaClient
                              ? Icons.gpp_good_rounded
                              : Icons.hourglass_empty_rounded,
                          color: adaClient
                              ? Colors.green[800]
                              : Colors.amber[800],
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            adaClient
                                ? 'Client Terhubung Aktif'
                                : 'Menunggu Perangkat...',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: adaClient
                                  ? Colors.green[900]
                                  : Colors.amber[900],
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: adaClient
                                ? Colors.green[700]
                                : Colors.amber[700],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${clientActiveList.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    adaClient
                        ? 'Silakan tekan tombol di bawah jika Anda ingin mendistribusikan data lokal ke perangkat yang terhubung.'
                        : 'Server siap menerima koneksi pipa baru secara lokal dari aplikasi client.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: adaClient ? () => sendDataToServer() : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[700],
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[200],
                        disabledForegroundColor: Colors.grey[400],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.send_and_archive),
                      label: const Text(
                        'Kirim Data Ke Client',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    if (_serverEksternal != null) {
                      await _serverEksternal!.close(force: true);
                      _serverEksternal = null;
                    }
                    Navigator.pop(ctx);
                  },
                  child: const Text(
                    'Matikan Server',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ).then((_) {
        dialogState = null;
      });
    } catch (e) {
      debugPrint("Gagal menyiapkan server dua arah: $e");
    }
  }
}

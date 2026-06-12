import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:rutinitasku/features/data_center/backup/backup_tab.dart';
import 'package:rutinitasku/features/data_center/local_sharing/local_sharing_tab.dart';
import '../../core/services/storage_service.dart';
import '../../core/presentation/widgets/drawer_menu.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive_io.dart';

import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class DataCenterScreen extends StatefulWidget {
  const DataCenterScreen({super.key});

  @override
  State<DataCenterScreen> createState() => _DataCenterScreenState();
}

class _DataCenterScreenState extends State<DataCenterScreen> {
  final StorageService _storageService = StorageService();
  String _baseDir = 'Documents';
  HttpServer? _serverEksternal;

  List<File> _serverBackupFiles = [];
  bool _isLoading = false;

  // GlobalKey digunakan untuk memicu pembaruan daftar berkas lokal di dalam BackupTab
  // ketika aplikasi selesai mengunduh/menerima berkas dari server.
  final GlobalKey<BackupTabState> _backupTabKey = GlobalKey<BackupTabState>();

  @override
  void initState() {
    super.initState();
    _loadBaseDirectory();
  }

  void _loadBaseDirectory() async {
    String dir = await _storageService.getBaseDirSetting();
    if (mounted) {
      setState(() {
        _baseDir = dir;
      });
      _loadServerBackups();
    }
  }

  Future<void> _loadServerBackups() async {
    List<File> files = await _storageService.getAllServerBackupFiles(_baseDir);
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    setState(() {
      _serverBackupFiles = files;
    });
  }

  String _getFormattedFileName(String prefix, String extension) {
    final now = DateTime.now();
    const daftarHari = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    String namaHari = daftarHari[now.weekday - 1];
    String tanggal =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    String waktu =
        "${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}";
    return "${prefix}_${tanggal}_${namaHari}_$waktu.$extension";
  }

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

  // =========================================================================
  // LOGIKA SERVER SHARING (Tetap Di Screen karena Berinteraksi dengan Kedua Tab)
  // =========================================================================
  void _startServerSharing() async {
    setState(() {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Menyiapkan server komunikasi dua arah...'),
          backgroundColor: Colors.indigo,
        ),
      );
    });
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

        setState(() {
          clientActiveList.add(webSocket);
        });

        if (dialogState != null) {
          dialogState!(() {});
        }

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
                  String namaZipDinamis = _getFormattedFileName(
                    'client_backup',
                    'zip',
                  );
                  File fileZipTarget = await _storageService.getBackupZipFile(
                    _baseDir,
                    namaZipDinamis,
                  );
                  await fileZipTarget.writeAsBytes(finalZipBytes);

                  _loadBaseDirectory();
                  // Picu pembaruan daftar file cadangan lokal di tab sebelah jika sedang aktif
                  _backupTabKey.currentState?.refreshLocalBackups();

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
            setState(() {
              clientActiveList.remove(webSocket);
            });
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
            setState(() {
              clientActiveList.remove(webSocket);
            });
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
      if (!mounted) return;

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
        String JournalContent = await fileJurnal.exists()
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
          'jurnal_aktivitas': JournalContent,
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

  void _showConnectToServerDialog() async {
    List<String> ipHistory = await _storageService.getIpHistory();
    final ipController = TextEditingController(
      text: ipHistory.isNotEmpty ? ipHistory.first : '',
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Hubungkan ke Server'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: ipController,
                  decoration: const InputDecoration(
                    labelText: 'Alamat IP Server Pengirim',
                    hintText: 'Contoh: 192.168.1.5',
                  ),
                ),
                if (ipHistory.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'IP yang pernah digunakan:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 120,
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: ipHistory.length,
                      itemBuilder: (c, index) {
                        final savedIp = ipHistory[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: const Icon(Icons.history, size: 18),
                          title: Text(savedIp),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 18,
                            ),
                            onPressed: () async {
                              await _storageService.deleteIpFromHistory(
                                savedIp,
                              );
                              setDialogState(() {
                                ipHistory.remove(savedIp);
                                if (ipController.text == savedIp)
                                  ipController.clear();
                              });
                            },
                          ),
                          onTap: () =>
                              setDialogState(() => ipController.text = savedIp),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  String targetIp = ipController.text.trim();
                  if (targetIp.isNotEmpty) {
                    await _storageService.saveIpToHistory(targetIp);
                    if (!mounted) return;
                    Navigator.pop(ctx);
                    _receiveDateFromServerProcess(targetIp);
                  }
                },
                child: const Text('Hubungkan & Ambil'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _receiveDateFromServerProcess(String alamatIP) async {
    final urlWebSocket = 'ws://$alamatIP:8090';
    setState(() {
      _isLoading = true;
    });

    try {
      final channel = WebSocketChannel.connect(Uri.parse(urlWebSocket));
      bool isDialogOpened = false;
      bool isStillConnected = true;
      StateSetter? clientDialogState;

      Future<void> fungsiKirimDataClient() async {
        if (!isStillConnected) return;

        String currentDir = await _storageService.getBaseDirSetting();
        File fileTasks = await _storageService.getTargetJsonFile(currentDir);
        String kontenTasks = await fileTasks.exists()
            ? await fileTasks.readAsString()
            : "{}";

        File fileJurnal = await _storageService.getJurnalJsonFile(currentDir);
        String kontenJurnal = await fileJurnal.exists()
            ? await fileJurnal.readAsString()
            : "[]";

        List<File> hubFiles = await _storageService.getAllChecklistGroups(
          currentDir,
        );
        final Archive archive = Archive();
        for (var file in hubFiles) {
          archive.addFile(
            ArchiveFile(
              file.path.split('/').last,
              file.lengthSync(),
              await file.readAsBytes(),
            ),
          );
        }
        final List<int>? zipBytes = ZipEncoder().encode(archive);
        String kontenZipBase64 = zipBytes != null ? base64Encode(zipBytes) : "";

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
        String kontenNotesBase64 = notesZipBytes != null
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
        String kontenPromptsBase64 = promptsZipBytes != null
            ? base64Encode(promptsZipBytes)
            : "";

        Map<String, dynamic> paketBesarClient = {
          'tipe_pesan': 'data_transfer',
          'task_master': kontenTasks,
          'jurnal_aktivitas': kontenJurnal,
          'checklist_zip': kontenZipBase64,
          'notes_zip': kontenNotesBase64,
          'prompts_zip': kontenPromptsBase64,
        };

        channel.sink.add(jsonEncode(paketBesarClient));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data Anda sukses dikirimkan ke Server!'),
            backgroundColor: Colors.teal,
          ),
        );
      }

      channel.stream
          .timeout(
            const Duration(seconds: 45),
            onTimeout: (sink) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Batas waktu habis! Perangkat di $alamatIP tidak merespons.',
                    ),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
              channel.sink.close();
              sink.close();
            },
          )
          .listen(
            (pesanMasuk) async {
              if (_isLoading) {
                setState(() {
                  _isLoading = false;
                });
              }

              try {
                Map<String, dynamic> dataDiterima = jsonDecode(pesanMasuk);

                if (dataDiterima['tipe_pesan'] == 'koneksi_terkonfirmasi') {
                  debugPrint("Jabat tangan sukses. Pipa data penerima stabil.");
                }

                if (dataDiterima['tipe_pesan'] == 'data_transfer') {
                  String serverTasks = dataDiterima['task_master'];
                  String serverJurnal = dataDiterima['jurnal_aktivitas'];
                  String serverZipBase64 = dataDiterima['checklist_zip'];
                  String serverNotesZipBase64 = dataDiterima['notes_zip'] ?? "";
                  String serverPromptsZipBase64 =
                      dataDiterima['prompts_zip'] ?? "";

                  final Archive backupArchive = Archive();
                  List<int> tasksBytes = utf8.encode(serverTasks);
                  backupArchive.addFile(
                    ArchiveFile('my_tasks.json', tasksBytes.length, tasksBytes),
                  );

                  List<int> jurnalBytes = utf8.encode(serverJurnal);
                  backupArchive.addFile(
                    ArchiveFile(
                      'time_log.json',
                      jurnalBytes.length,
                      jurnalBytes,
                    ),
                  );

                  if (serverZipBase64.isNotEmpty) {
                    List<int> checklistZipBytes = base64Decode(serverZipBase64);
                    Archive checklistArchive = ZipDecoder().decodeBytes(
                      checklistZipBytes,
                    );
                    for (ArchiveFile file in checklistArchive) {
                      if (file.isFile) {
                        backupArchive.addFile(
                          ArchiveFile(
                            'my_checklist/${file.name}',
                            file.content.length,
                            file.content,
                          ),
                        );
                      }
                    }
                  }

                  if (serverNotesZipBase64.isNotEmpty) {
                    List<int> notesZipBytes = base64Decode(
                      serverNotesZipBase64,
                    );
                    Archive notesArchive = ZipDecoder().decodeBytes(
                      notesZipBytes,
                    );
                    for (ArchiveFile file in notesArchive) {
                      if (file.isFile) {
                        backupArchive.addFile(
                          ArchiveFile(
                            'notes/${file.name}',
                            file.content.length,
                            file.content,
                          ),
                        );
                      }
                    }
                  }

                  if (serverPromptsZipBase64.isNotEmpty) {
                    List<int> promptsZipBytes = base64Decode(
                      serverPromptsZipBase64,
                    );
                    Archive promptsArchive = ZipDecoder().decodeBytes(
                      promptsZipBytes,
                    );
                    for (ArchiveFile file in promptsArchive) {
                      if (file.isFile) {
                        backupArchive.addFile(
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
                    backupArchive,
                  );
                  if (finalZipBytes == null) return;

                  String namaZipDinamis = _getFormattedFileName(
                    'server_backup',
                    'zip',
                  );
                  File fileZipTarget = await _storageService.getBackupZipFile(
                    _baseDir,
                    namaZipDinamis,
                  );
                  await fileZipTarget.writeAsBytes(finalZipBytes);

                  _loadBaseDirectory();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Sukses menerima berkas dari Server! Disimpan: $namaZipDinamis',
                      ),
                      backgroundColor: Colors.teal,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                debugPrint("Client gagal memproses data: $e");
              }

              if (!isDialogOpened && mounted) {
                isDialogOpened = true;
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => StatefulBuilder(
                    builder: (context, setDialogState) {
                      clientDialogState = setDialogState;
                      return AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Row(
                          children: [
                            Icon(
                              isStillConnected
                                  ? Icons.cloud_done
                                  : Icons.cloud_off,
                              color: isStillConnected
                                  ? Colors.teal
                                  : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isStillConnected
                                  ? 'Terhubung ke Server'
                                  : 'Koneksi Terputus Terpaksa',
                            ),
                          ],
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isStillConnected
                                  ? 'Sukses tersambung dengan alamat IP: $alamatIP'
                                  : 'Pipa jaringan ke alamat server $alamatIP tiba-tiba terputus.',
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isStillConnected
                                    ? Colors.teal.shade50
                                    : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isStillConnected
                                      ? Colors.teal.shade200
                                      : Colors.red.shade200,
                                ),
                              ),
                              child: Text(
                                isStillConnected
                                    ? 'Anda bisa memantau proses penerimaan otomatis, atau mengirim balik data lokal HP ini ke Server.'
                                    : '⚠️ Hubungan terputus akibat server mati atau jaringan terganggu.',
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: isStillConnected
                                      ? Colors.black87
                                      : Colors.red[900],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: isStillConnected
                                    ? () => fungsiKirimDataClient()
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                  disabledBackgroundColor: Colors.grey[200],
                                ),
                                icon: const Icon(
                                  Icons.upload_file,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Kirim Data Saya Ke Server',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              channel.sink.close();
                              Navigator.pop(ctx);
                            },
                            child: Text(
                              isStillConnected
                                  ? 'Putuskan Koneksi'
                                  : 'Tutup Dialog',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ).then((_) {
                  isDialogOpened = false;
                  clientDialogState = null;
                });
              }
            },
            onDone: () {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
                isStillConnected = false;
                if (clientDialogState != null) clientDialogState!(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      '❌ Hubungan ke Server terputus secara tiba-tiba!',
                    ),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            onError: (err) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
                isStillConnected = false;
                if (clientDialogState != null) clientDialogState!(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Gagal terhubung! Jaringan ditolak perangkat $alamatIP.',
                    ),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
          );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terjadi kesalahan fatal jaringan.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // =========================================================================
  // LOGIKA OVERWRITE TOTAL SELURUH ISI ZIP (Masih dibutuhkan oleh kedua Tab)
  // =========================================================================
  void _importAllFromZip(File zipFile) async {
    try {
      List<int> bytes = await zipFile.readAsBytes();
      Archive archive = ZipDecoder().decodeBytes(bytes);

      String folderChecklist = await _storageService.getChecklistDirPath(
        _baseDir,
      );
      Directory checklistDir = Directory(folderChecklist);
      if (checklistDir.existsSync()) checklistDir.deleteSync(recursive: true);
      checklistDir.createSync(recursive: true);

      Directory notesDir = await _storageService.getNotesDir(_baseDir);
      if (notesDir.existsSync()) notesDir.deleteSync(recursive: true);
      notesDir.createSync(recursive: true);

      Directory promptsDir = await _storageService.getPromptDir(_baseDir);
      if (promptsDir.existsSync()) promptsDir.deleteSync(recursive: true);
      promptsDir.createSync(recursive: true);

      for (ArchiveFile file in archive) {
        if (file.isFile) {
          if (file.name == 'my_tasks.json') {
            File target = await _storageService.getTargetJsonFile(_baseDir);
            await target.writeAsBytes(file.content);
          } else if (file.name == 'time_log.json') {
            File target = await _storageService.getJurnalJsonFile(_baseDir);
            await target.writeAsBytes(file.content);
          } else if (file.name.startsWith('my_checklist/')) {
            String namaFileHub = file.name.split('/').last;
            if (namaFileHub.isNotEmpty) {
              await File(
                '$folderChecklist/$namaFileHub',
              ).writeAsBytes(file.content);
            }
          } else if (file.name.startsWith('notes/')) {
            String namaFileNote = file.name.split('/').last;
            if (namaFileNote.isNotEmpty) {
              await File(
                '${notesDir.path}/$namaFileNote',
              ).writeAsBytes(file.content);
            }
          } else if (file.name.startsWith('prompts/')) {
            String namaFilePrompt = file.name.split('/').last;
            if (namaFilePrompt.isNotEmpty) {
              await File(
                '${promptsDir.path}/$namaFilePrompt',
              ).writeAsBytes(file.content);
            }
          }
        }
      }

      _loadBaseDirectory();
      // Picu pembaruan daftar file cadangan lokal setelah sistem berhasil melakukan data restore total
      _backupTabKey.currentState?.refreshLocalBackups();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Restore Berhasil! Seluruh data disinkronkan dari "${zipFile.path.split('/').last}".',
          ),
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      debugPrint("Gagal mengimpor file ZIP global: $e");
    }
  }

  void _importZipLokal() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
      if (result != null && result.files.single.path != null) {
        File selectedZipFile = File(result.files.single.path!);

        if (!mounted) return;
        final bool confirm =
            await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange[800],
                    ),
                    const SizedBox(width: 8),
                    const Text('Import & Restore ZIP?'),
                  ],
                ),
                content: Text(
                  'Apakah Anda yakin ingin memulihkan data dari berkas luar "${selectedZipFile.path.split('/').last}"?\n\n*Peringatan: Seluruh data aktif aplikasi saat ini akan dihapus dan ditimpa.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text(
                      'Batal',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                    ),
                    child: const Text(
                      'Ya, Restore',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ) ??
            false;

        if (confirm) {
          _importAllFromZip(selectedZipFile);
        }
      }
    } catch (e) {
      debugPrint("Gagal mengimport file cadangan ZIP: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Data Center'),
          backgroundColor: Colors.indigo[700],
          bottom: const TabBar(
            indicatorColor: Colors.amberAccent,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(icon: Icon(Icons.backup_outlined), text: 'Backup'),
              Tab(icon: Icon(Icons.wifi_find_outlined), text: 'Local Sharing'),
            ],
          ),
        ),
        drawer: const DrawerMenu(isDataCenterActive: true),
        body: Stack(
          children: [
            TabBarView(
              children: [
                // TAB 1: Backup (Sekarang parameternya sangat ringkas & mandiri)
                BackupTab(
                  key: _backupTabKey,
                  onRestoreAllZip: (file) => _importAllFromZip(file),
                  onImportZip: () => _importZipLokal(),
                ),

                // TAB 2: Local Sharing (Tetap menangani fitur transfer jaringan P2P)
                LocalSharingTab(
                  onSendFile: () => _startServerSharing(),
                  onReceiveFile: () => _showConnectToServerDialog(),
                  serverBackupFiles: _serverBackupFiles,
                  onDeleteServerBackup: (file) async {
                    if (file.path == 'trigger_refresh_after_bulk_delete') {
                      await _loadServerBackups();
                      return;
                    }

                    final bool confirm =
                        await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Hapus Berkas Server?'),
                            content: Text(
                              'Apakah Anda yakin ingin menghapus berkas "${file.path.split('/').last}" ini secara permanen?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Batal'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Hapus'),
                              ),
                            ],
                          ),
                        ) ??
                        false;

                    if (confirm && await file.exists()) {
                      await file.delete();
                      await _loadServerBackups();
                    }
                  },
                  onRestoreAllZip: (file) => _importAllFromZip(file),
                ),
              ],
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.4),
                child: const Center(
                  child: Card(
                    elevation: 4,
                    shape: CircleBorder(),
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.indigo,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

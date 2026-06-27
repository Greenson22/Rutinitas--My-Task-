import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:archive/archive_io.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/services/storage_service.dart';
import 'doc_sync_helper.dart'; // Impor berkas bantu sinkronisasi dokumen cerdas

class SharingServer {
  final StorageService _storageService = StorageService();
  HttpServer? _serverEksternal;

  // VISUALISASI LOADING PROGRESS DIALOG MODERN & INDAH
  void _showTransferProgressDialog({
    required BuildContext context,
    required String title,
    required ValueNotifier<String> statusNotifier,
    required bool isSending,
    required Function(BuildContext) onReady,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        WidgetsBinding.instance.addPostFrameCallback((_) => onReady(dialogCtx));
        final accentColor = isSending ? Colors.teal : Colors.indigo;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 8.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 76,
                        height: 76,
                        child: CircularProgressIndicator(
                          strokeWidth: 5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            accentColor,
                          ),
                          backgroundColor: accentColor.withOpacity(0.1),
                        ),
                      ),
                      Icon(
                        isSending
                            ? Icons.swap_vertical_circle_outlined
                            : Icons.cloud_download_rounded,
                        size: 40,
                        color: accentColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[900],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<String>(
                  valueListenable: statusNotifier,
                  builder: (context, status, child) {
                    return Text(
                      status,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    );
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            accentColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isSending ? 'PROSES MENGIRIM...' : 'PROSES MENERIMA...',
                        style: TextStyle(
                          fontSize: 10,
                          color: accentColor,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
            // PENCEGAT UTAMA: Periksa jika aliran data merupakan bagian dari cermin dokumen cerdas
            bool handledByDocSync = await DocSyncHelper.handleDocSyncStream(
              pesanMasuk: pesanMasuk,
              socketSink: webSocket.sink,
              context: context,
              storageService: _storageService,
              showProgressDialog: (ctx, title, notif, isSend, onRdy) =>
                  _showTransferProgressDialog(
                    context: ctx,
                    title: title,
                    statusNotifier: notif,
                    isSending: isSend,
                    onReady: onRdy,
                  ),
            );
            if (handledByDocSync) return;

            BuildContext? progressCtx;
            final statusNotifier = ValueNotifier<String>(
              'Menginisialisasi penerimaan...',
            );

            try {
              Map<String, dynamic> dateReceived = jsonDecode(pesanMasuk);
              if (dateReceived['tipe_pesan'] == 'data_transfer') {
                if (context.mounted) {
                  _showTransferProgressDialog(
                    context: context,
                    title: 'Menerima Data Aplikasi',
                    statusNotifier: statusNotifier,
                    isSending: false,
                    onReady: (ctx) => progressCtx = ctx,
                  );
                }

                statusNotifier.value = 'Membaca paket enkripsi masuk...';
                String clientTasks = dateReceived['task_master'];
                String clientJurnal = dateReceived['jurnal_aktivitas'];
                String clientZipBase64 = dateReceived['checklist_zip'];
                String clientNotesZipBase64 = dateReceived['notes_zip'] ?? "";
                String clientPromptsZipBase64 =
                    dateReceived['prompts_zip'] ?? "";
                String clientDocsZipBase64 =
                    dateReceived['documents_zip'] ?? "";

                statusNotifier.value = 'Mengekstrak berkas inti data...';
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
                  statusNotifier.value = 'Memproses data modul Checklist...';
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
                  statusNotifier.value =
                      'Memproses berkas modul Catatan (Notes)...';
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
                  statusNotifier.value =
                      'Memproses berkas kecerdasan buatan AI...';
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

                if (clientDocsZipBase64.isNotEmpty) {
                  statusNotifier.value =
                      'Menyusun dokumen & struktur fisik media...';
                  List<int> docsBytes = base64Decode(clientDocsZipBase64);
                  Archive docsArchive = ZipDecoder().decodeBytes(docsBytes);
                  for (ArchiveFile file in docsArchive) {
                    if (file.isFile) {
                      clientArchive.addFile(
                        ArchiveFile(
                          file.name,
                          file.content.length,
                          file.content,
                        ),
                      );
                    }
                  }
                }

                statusNotifier.value =
                    'Menyusun paket berkas arsip final (.zip)...';
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

                  statusNotifier.value =
                      'Menulis cadangan ke penyimpanan internal...';
                  await fileZipTarget.writeAsBytes(finalZipBytes);

                  onDataReceived();

                  if (progressCtx != null && progressCtx!.mounted) {
                    Navigator.pop(progressCtx!);
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Sukses menerima data dari Client! Tersimpan: $namaZipDinamis',
                      ),
                      backgroundColor: Colors.teal,
                    ),
                  );
                } else {
                  if (progressCtx != null && progressCtx!.mounted) {
                    Navigator.pop(progressCtx!);
                  }
                }
              }
            } catch (err) {
              if (progressCtx != null && progressCtx!.mounted) {
                Navigator.pop(progressCtx!);
              }
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

        if (!context.mounted) return;
        final bool? includeDocuments = await showDialog<bool>(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: const [
                  Icon(Icons.share_rounded, color: Colors.teal),
                  SizedBox(width: 8),
                  Text('Kirim Data ke Client'),
                ],
              ),
              content: const Text(
                'Apakah Anda ingin menyertakan seluruh berkas fisik dari folder "My Documents" (PDF, Gambar, dll.) ke dalam paket transfer?\n\n*Catatan: Menyertakan dokumen dapat membuat proses transfer data membutuhkan waktu lebih lama.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                  ),
                  child: const Text(
                    'Tanpa Dokumen',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  child: const Text(
                    'Sertakan Dokumen',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );

        if (includeDocuments == null) return;

        BuildContext? progressCtx;
        final statusNotifier = ValueNotifier<String>(
          'Mempersiapkan pengiriman data...',
        );

        if (context.mounted) {
          _showTransferProgressDialog(
            context: context,
            title: 'Mengirim Data Ke Client',
            statusNotifier: statusNotifier,
            isSending: true,
            onReady: (ctx) => progressCtx = ctx,
          );
        }

        try {
          statusNotifier.value = 'Membaca berkas Task Master & Jurnal...';
          String currentDir = await _storageService.getBaseDirSetting();
          File fileTasks = await _storageService.getTargetJsonFile(currentDir);
          String tasksContent = await fileTasks.exists()
              ? await fileTasks.readAsString()
              : "{}";

          File fileJurnal = await _storageService.getJurnalJsonFile(currentDir);
          String journalContent = await fileJurnal.exists()
              ? await fileJurnal.readAsString()
              : "[]";

          statusNotifier.value = 'Mengompresi data Checklist (ZIP)...';
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

          statusNotifier.value = 'Mengompresi data Catatan/Notes...';
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

          statusNotifier.value = 'Mengompresi pustaka Prompt AI...';
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
          final List<int>? promptsZipBytes = ZipEncoder().encode(
            promptsArchive,
          );
          String promptsBase64Content = promptsZipBytes != null
              ? base64Encode(promptsZipBytes)
              : "";

          String documentsBase64Content = "";
          if (includeDocuments) {
            statusNotifier.value = 'Mengompresi berkas fisik media kustom...';
            final Directory documentsDir = Directory(
              '$currentDir/my_documents',
            );
            if (await documentsDir.exists()) {
              final Archive docArchive = Archive();
              final List<FileSystemEntity> entities = documentsDir.listSync(
                recursive: true,
              );
              for (var entity in entities) {
                if (entity is File) {
                  String relativePath = entity.path.substring(
                    documentsDir.parent.path.length + 1,
                  );
                  relativePath = relativePath.replaceAll('\\', '/');
                  final List<int> fileBytes = await entity.readAsBytes();
                  docArchive.addFile(
                    ArchiveFile(relativePath, fileBytes.length, fileBytes),
                  );
                }
              }
              final List<int>? docZipBytes = ZipEncoder().encode(docArchive);
              if (docZipBytes != null) {
                documentsBase64Content = base64Encode(docZipBytes);
              }
            }
          }

          statusNotifier.value =
              'Mengirimkan paket enkripsi data via nirkabel...';
          Map<String, dynamic> sendBigPackage = {
            'tipe_pesan': 'data_transfer',
            'task_master': tasksContent,
            'jurnal_aktivitas': journalContent,
            'checklist_zip': zipBase64Content,
            'notes_zip': notesBase64Content,
            'prompts_zip': promptsBase64Content,
            'documents_zip': documentsBase64Content,
          };

          for (var socket in clientActiveList) {
            socket.sink.add(jsonEncode(sendBigPackage));
          }

          if (progressCtx != null && progressCtx!.mounted) {
            Navigator.pop(progressCtx!);
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Berhasil mengirim data ke ${clientActiveList.length} Client!',
              ),
              backgroundColor: Colors.teal,
            ),
          );
        } catch (e) {
          if (progressCtx != null && progressCtx!.mounted) {
            Navigator.pop(progressCtx!);
          }
          debugPrint("Gagal mengirim data dari server: $e");
        }
      }

      // FUNGSI INTI BARU: Memicu Pembuatan Katalog Cermin dari Server menuju Client Terhubung
      Future<void> triggerDocumentMirrorToClients() async {
        if (clientActiveList.isEmpty) return;

        BuildContext? progressCtx;
        final statusNotifier = ValueNotifier<String>(
          'Memindai & membuat katalog berkas Server...',
        );

        if (context.mounted) {
          _showTransferProgressDialog(
            context: context,
            title: 'Sinkronisasi Cermin Dokumen',
            statusNotifier: statusNotifier,
            isSending: true,
            onReady: (ctx) => progressCtx = ctx,
          );
        }

        try {
          String currentDir = await _storageService.getBaseDirSetting();
          final manifest = await DocSyncHelper.createManifest(currentDir);

          Map<String, dynamic> initPayload = {
            'tipe_pesan': 'doc_sync_init',
            'manifest': manifest.map((m) => m.toJson()).toList(),
          };

          for (var socket in clientActiveList) {
            socket.sink.add(jsonEncode(initPayload));
          }

          if (progressCtx != null && progressCtx!.mounted) {
            Navigator.pop(progressCtx!);
          }
        } catch (e) {
          if (progressCtx != null && progressCtx!.mounted) {
            Navigator.pop(progressCtx!);
          }
          debugPrint("Gagal menginisialisasi cermin dokumen server: $e");
        }
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
                    'Server Sharing Active',
                    style: TextStyle(
                      color: Colors.indigo[900],
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Scan QR Code atau ketik IP di perangkat Penerima:',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.indigo.shade100),
                            ),
                            child: SizedBox(
                              width: 160.0,
                              height: 160.0,
                              child: QrImageView(
                                data: localIp,
                                version: QrVersions.auto,
                                size: 160.0,
                                gapless: false,
                                errorStateBuilder: (cxt, err) {
                                  return const Center(
                                    child: Text(
                                      'Gagal memuat QR Code',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            localIp,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo.shade900,
                              fontFamily: 'monospace',
                              letterSpacing: 0.5,
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
                          ? 'Silakan pilih metode pengiriman data lokal nirkabel ke perangkat client di bawah ini.'
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
                          'Kirim Full Backup Ke Client',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // TOMBOL AKSI BARU: Memicu One-Way Mirror Berbasis Katalog Dokumen
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: adaClient
                            ? () => triggerDocumentMirrorToClients()
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo[600],
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[200],
                          disabledForegroundColor: Colors.grey[400],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: const Icon(Icons.flip_camera_android_rounded),
                        label: const Text(
                          '🪞 Cermin Dokumen ke Client',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
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

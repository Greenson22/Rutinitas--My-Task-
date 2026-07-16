// lib/features/data_center/presentation/local_sharing/sharing_client.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:archive/archive_io.dart';
import 'package:rutinitasku/features/data_center/presentation/widgets/transfer_progress_dialog.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/services/storage_service.dart';
import 'doc_sync_helper.dart';

class SharingClient {
  final StorageService _storageService = StorageService();

  void _showTransferProgressDialog({
    required BuildContext context,
    required String title,
    required ValueNotifier<String> statusNotifier,
    required bool isSending,
    required Function(BuildContext) onReady,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      useRootNavigator: true,
      builder: (dialogCtx) {
        WidgetsBinding.instance.addPostFrameCallback((_) => onReady(dialogCtx));
        return TransferProgressDialog(
          title: title,
          statusNotifier: statusNotifier,
          isSending: isSending,
          subTitleProgress: isSending
              ? 'Proses Mengirim...'
              : 'Proses Menerima...',
          onClose: () => Navigator.of(dialogCtx, rootNavigator: true).pop(),
        );
      },
    );
  }

  void showConnectDialog({
    required BuildContext context,
    required String baseDir,
    required String Function(String prefix, String extension)
    getFormattedFileName,
    required Function(bool) onLoadingStatusChanged,
    required VoidCallback onDataReceived,
  }) async {
    List<String> ipHistory = await _storageService.getIpHistory();
    final ipController = TextEditingController(
      text: ipHistory.isNotEmpty ? ipHistory.first : '',
    );
    if (!context.mounted) return;

    final String? selectedIp = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Hubungkan ke Server'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ipController,
                        decoration: const InputDecoration(
                          labelText: 'Alamat IP Server Pengirim',
                          hintText: 'Contoh: 192.16 CONDITIONS.1.5',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Colors.indigo,
                      ),
                      tooltip: 'Scan QR / Barcode IP',
                      onPressed: () async {
                        final String? scannedIp = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const QRScannerScreen(),
                          ),
                        );
                        if (scannedIp != null && scannedIp.trim().isNotEmpty) {
                          setDialogState(
                            () => ipController.text = scannedIp.trim(),
                          );
                        }
                      },
                    ),
                  ],
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
                    if (ctx.mounted) Navigator.pop(ctx, targetIp);
                  }
                },
                child: const Text('Hubungkan & Ambil'),
              ),
            ],
          );
        },
      ),
    );

    if (selectedIp != null && selectedIp.isNotEmpty && context.mounted) {
      _receiveDataFromServerProcess(
        alamatIP: selectedIp,
        context: context,
        baseDir: baseDir,
        getFormattedFileName: getFormattedFileName,
        onLoadingStatusChanged: onLoadingStatusChanged,
        onDataReceived: onDataReceived,
      );
    }
  }

  void _receiveDataFromServerProcess({
    required String alamatIP,
    required BuildContext context,
    required String baseDir,
    required String Function(String prefix, String extension)
    getFormattedFileName,
    required Function(bool) onLoadingStatusChanged,
    required VoidCallback onDataReceived,
  }) async {
    final urlWebSocket = 'ws://$alamatIP:8090';
    onLoadingStatusChanged(true);
    try {
      final channel = WebSocketChannel.connect(Uri.parse(urlWebSocket));
      bool isDialogOpened = false;
      bool isStillConnected = true;
      StateSetter? clientDialogState;

      Future<void> fungsiKirimDataClient() async {
        if (!isStillConnected) return;
        if (!context.mounted) return;
        final bool? includeDocuments = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.share_rounded, color: Colors.teal),
                SizedBox(width: 8),
                Text('Kirim Data ke Server'),
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
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
          ),
        );
        if (includeDocuments == null) return;

        BuildContext? progressCtx;
        final statusNotifier = ValueNotifier<String>(
          'Mempersiapkan pengiriman data...',
        );
        if (context.mounted) {
          _showTransferProgressDialog(
            context: context,
            title: 'Mengirim Data Ke Server',
            statusNotifier: statusNotifier,
            isSending: true,
            onReady: (ctx) => progressCtx = ctx,
          );
        }
        try {
          statusNotifier.value = 'Membaca berkas Task Master...';
          String currentDir = await _storageService.getBaseDirSetting();
          File fileTasks = await _storageService.getTargetJsonFile(currentDir);
          String kontenTasks = await fileTasks.exists()
              ? await fileTasks.readAsString()
              : "{}";

          // Logika baru untuk mengompresi partisi multi-file dari folder jurnal_aktivitas di sisi Client
          statusNotifier.value = 'Mengompresi partisi berkas Jurnal (ZIP)...';
          final Directory jurnalDir = Directory('$currentDir/jurnal_aktivitas');
          final Archive jurnalArchive = Archive();
          if (await jurnalDir.exists()) {
            List<File> jurnalFiles = jurnalDir
                .listSync()
                .whereType<File>()
                .where((f) => f.path.endsWith('.json'))
                .toList();
            for (var file in jurnalFiles) {
              jurnalArchive.addFile(
                ArchiveFile(
                  file.path.split('/').last,
                  file.lengthSync(),
                  await file.readAsBytes(),
                ),
              );
            }
          }
          final List<int>? jrnZipBytes = ZipEncoder().encode(jurnalArchive);
          String kontenJurnalBase64 = jrnZipBytes != null
              ? base64Encode(jrnZipBytes)
              : "";

          statusNotifier.value = 'Mengompresi data Checklist (ZIP)...';
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
          String kontenZipBase64 = zipBytes != null
              ? base64Encode(zipBytes)
              : "";

          statusNotifier.value = 'Mengompresi catatan harian (Notes)...';
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

          statusNotifier.value = 'Mengompresi berkas generator AI...';
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
          String kontenPromptsBase64 = promptsZipBytes != null
              ? base64Encode(promptsZipBytes)
              : "";

          String kontenDocsBase64 = "";
          if (includeDocuments) {
            statusNotifier.value = 'Mengompresi berkas fisik Documents...';
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
                  String relativePath = entity.path
                      .substring(documentsDir.parent.path.length + 1)
                      .replaceAll('\\', '/');
                  final List<int> fileBytes = await entity.readAsBytes();
                  docArchive.addFile(
                    ArchiveFile(relativePath, fileBytes.length, fileBytes),
                  );
                }
              }
              final List<int>? docZipBytes = ZipEncoder().encode(docArchive);
              if (docZipBytes != null)
                kontenDocsBase64 = base64Encode(docZipBytes);
            }
          }

          statusNotifier.value =
              'Mengirim paket data ke pipa WebSocket Server...';
          Map<String, dynamic> paketBesarClient = {
            'tipe_pesan': 'data_transfer',
            'task_master': kontenTasks,
            'jurnal_aktivitas':
                kontenJurnalBase64, // Mengirimkan bundle arsip Base64 ZIP partisi jurnal
            'checklist_zip': kontenZipBase64,
            'notes_zip': kontenNotesBase64,
            'prompts_zip': kontenPromptsBase64,
            'documents_zip': kontenDocsBase64,
          };
          channel.sink.add(jsonEncode(paketBesarClient));

          if (progressCtx != null && progressCtx!.mounted) {
            Navigator.of(progressCtx!, rootNavigator: true).pop();
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data Anda sukses dikirimkan ke Server!'),
              backgroundColor: Colors.teal,
            ),
          );
        } catch (e) {
          if (progressCtx != null && progressCtx!.mounted) {
            Navigator.of(progressCtx!, rootNavigator: true).pop();
          }
          debugPrint("Gagal mengirim data dari client: $e");
        }
      }

      // Pemicu Cermin Dokumen Client ke Server
      Future<void> triggerDocumentMirrorToServer() async {
        if (!isStillConnected) return;
        final statusNotifier = ValueNotifier<String>(
          'Memindai & membuat katalog berkas Client...',
        );

        if (context.mounted) {
          DocSyncHelper.showSyncDialog(
            context: context,
            title: 'Sinkronisasi Cermin Dokumen',
            statusNotifier: statusNotifier,
            isSending: true,
          );
        }
        try {
          String currentDir = await _storageService.getBaseDirSetting();
          final manifest = await DocSyncHelper.createManifest(currentDir);
          Map<String, dynamic> initPayload = {
            'tipe_pesan': 'doc_sync_init',
            'manifest': manifest.map((m) => m.toJson()).toList(),
          };
          channel.sink.add(jsonEncode(initPayload));
        } catch (e) {
          DocSyncHelper.closeSyncDialog(context);
          debugPrint("Gagal menginisialisasi cermin dokumen client: $e");
        }
      }

      channel.stream
          .timeout(
            const Duration(seconds: 45),
            onTimeout: (sink) {
              onLoadingStatusChanged(false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Batas waktu habis! Perangkat di $alamatIP tidak merespons.',
                  ),
                  backgroundColor: Colors.redAccent,
                ),
              );
              channel.sink.close();
              sink.close();
            },
          )
          .listen(
            (pesanMasuk) async {
              bool handledByDocSync = await DocSyncHelper.handleDocSyncStream(
                pesanMasuk: pesanMasuk,
                socketSink: channel.sink,
                context: context,
                storageService: _storageService,
                onLoadingStatusChanged: onLoadingStatusChanged,
              );
              if (handledByDocSync) return;

              // PERBAIKAN: Hindari main parser JSON dari crash[cite: 6]
              if (pesanMasuk is! String) return;

              onLoadingStatusChanged(false);
              BuildContext? progressCtx;
              final statusNotifier = ValueNotifier<String>(
                'Menginisialisasi penerimaan...',
              );
              try {
                Map<String, dynamic> dataDiterima = jsonDecode(pesanMasuk);
                if (dataDiterima['tipe_pesan'] == 'data_transfer') {
                  if (context.mounted) {
                    _showTransferProgressDialog(
                      context: context,
                      title: 'Menerima Data Aplikasi',
                      statusNotifier: statusNotifier,
                      isSending: false,
                      onReady: (ctx) => progressCtx = ctx,
                    );
                  }
                  statusNotifier.value = 'Membaca paket data masuk...';
                  String serverTasks = dataDiterima['task_master'];
                  String serverJurnalZipBase64 =
                      dataDiterima['jurnal_aktivitas']; // Variabel sekarang menerima ZIP Base64
                  String serverZipBase64 = dataDiterima['checklist_zip'];
                  String serverNotesZipBase64 = dataDiterima['notes_zip'] ?? "";
                  String serverPromptsZipBase64 =
                      dataDiterima['prompts_zip'] ?? "";
                  String serverDocsZipBase64 =
                      dataDiterima['documents_zip'] ?? "";

                  statusNotifier.value = 'Mengekstrak Task Master...';
                  final Archive backupArchive = Archive();
                  List<int> tasksBytes = utf8.encode(serverTasks);
                  backupArchive.addFile(
                    ArchiveFile('my_tasks.json', tasksBytes.length, tasksBytes),
                  );

                  // Mendekompresi paket partisi Jurnal dari Server ke paket penulisan ZIP internal client
                  if (serverJurnalZipBase64.isNotEmpty) {
                    statusNotifier.value =
                        'Memproses berkas Jurnal Aktivitas Bulanan...';
                    List<int> jurnalZipBytes = base64Decode(
                      serverJurnalZipBase64,
                    );
                    Archive jurnalArchive = ZipDecoder().decodeBytes(
                      jurnalZipBytes,
                    );
                    for (ArchiveFile file in jurnalArchive) {
                      if (file.isFile) {
                        backupArchive.addFile(
                          ArchiveFile(
                            'jurnal_aktivitas/${file.name}',
                            file.content.length,
                            file.content,
                          ),
                        );
                      }
                    }
                  }

                  if (serverZipBase64.isNotEmpty) {
                    statusNotifier.value = 'Memproses data modul Checklist...';
                    List<int> checklistZipBytes = base64Decode(serverZipBase64);
                    Archive checklistArchive = ZipDecoder().decodeBytes(
                      checklistZipBytes,
                    );
                    for (ArchiveFile file in checklistArchive) {
                      if (file.isFile)
                        backupArchive.addFile(
                          ArchiveFile(
                            'my_checklist/${file.name}',
                            file.content.length,
                            file.content,
                          ),
                        );
                    }
                  }
                  if (serverNotesZipBase64.isNotEmpty) {
                    statusNotifier.value =
                        'Memproses berkas modul Catatan (Notes)...';
                    List<int> notesZipBytes = base64Decode(
                      serverNotesZipBase64,
                    );
                    Archive notesArchive = ZipDecoder().decodeBytes(
                      notesZipBytes,
                    );
                    for (ArchiveFile file in notesArchive) {
                      if (file.isFile)
                        backupArchive.addFile(
                          ArchiveFile(
                            'notes/${file.name}',
                            file.content.length,
                            file.content,
                          ),
                        );
                    }
                  }
                  if (serverPromptsZipBase64.isNotEmpty) {
                    statusNotifier.value = 'Memproses pustaka Prompt AI...';
                    List<int> promptsZipBytes = base64Decode(
                      serverPromptsZipBase64,
                    );
                    Archive promptsArchive = ZipDecoder().decodeBytes(
                      promptsZipBytes,
                    );
                    for (ArchiveFile file in promptsArchive) {
                      if (file.isFile)
                        backupArchive.addFile(
                          ArchiveFile(
                            'prompts/${file.name}',
                            file.content.length,
                            file.content,
                          ),
                        );
                    }
                  }
                  if (serverDocsZipBase64.isNotEmpty) {
                    statusNotifier.value =
                        'Menyusun berkas dokumen media fisik...';
                    List<int> docsZipBytes = base64Decode(serverDocsZipBase64);
                    Archive docsArchive = ZipDecoder().decodeBytes(
                      docsZipBytes,
                    );
                    for (ArchiveFile file in docsArchive) {
                      if (file.isFile)
                        backupArchive.addFile(
                          ArchiveFile(
                            file.name,
                            file.content.length,
                            file.content,
                          ),
                        );
                    }
                  }

                  statusNotifier.value = 'Menyusun berkas arsip ZIP final...';
                  final List<int>? finalZipBytes = ZipEncoder().encode(
                    backupArchive,
                  );
                  if (finalZipBytes == null) {
                    if (progressCtx != null && progressCtx!.mounted) {
                      Navigator.of(progressCtx!, rootNavigator: true).pop();
                    }
                    return;
                  }
                  String namaZipDinamis = getFormattedFileName(
                    'server_backup',
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
                    Navigator.of(progressCtx!, rootNavigator: true).pop();
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Sukses menerima data dari Server! Tersimpan: $namaZipDinamis',
                      ),
                      backgroundColor: Colors.teal,
                    ),
                  );
                }
              } catch (e) {
                if (progressCtx != null && progressCtx!.mounted) {
                  Navigator.of(progressCtx!, rootNavigator: true).pop();
                }
                debugPrint("Client gagal memproses data: $e");
              }

              if (!isDialogOpened && context.mounted) {
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
                                    ? 'Anda bisa memantau proses penerimaan otomatis, atau memilih metode sinkronisasi data lokal nirkabel HP ini ke Server.'
                                    : '  Hubungan terputus akibat server mati atau jaringan terganggu.',
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
                                ),
                                icon: const Icon(
                                  Icons.upload_file,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Kirim Full Backup Ke Server',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: isStillConnected
                                    ? () => triggerDocumentMirrorToServer()
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal[700],
                                ),
                                icon: const Icon(
                                  Icons.flip_camera_android_rounded,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  '  Cermin Dokumen ke Server',
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
              onLoadingStatusChanged(false);
              isStillConnected = false;
              if (clientDialogState != null) clientDialogState!(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    '  Hubungan ke Server terputus secara tiba-tiba!',
                  ),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
            onError: (err) {
              onLoadingStatusChanged(false);
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
            },
          );
    } catch (e) {
      onLoadingStatusChanged(false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terjadi kesalahan fatal jaringan.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});
  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isTorchOn = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code Server'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: _isTorchOn ? Colors.yellow : Colors.grey,
            ),
            onPressed: () {
              controller.toggleTorch();
              setState(() => _isTorchOn = !_isTorchOn);
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: MobileScanner(
        controller: controller,
        onDetect: (BarcodeCapture capture) {
          final Barcode? barcode = capture.barcodes.firstOrNull;
          if (barcode != null) {
            final String? code = barcode.rawValue;
            if (code != null && code.trim().isNotEmpty) {
              controller.stop();
              Navigator.pop(context, code.trim());
            }
          }
        },
      ),
    );
  }
}

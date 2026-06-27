import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:archive/archive_io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // DITAMBAHKAN
import '../../../../core/services/storage_service.dart';

class SharingClient {
  final StorageService _storageService = StorageService();

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
                // MODIFIKASI: Menggunakan Row agar ada tombol scan barcode di sebelah kanan input text
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ipController,
                        decoration: const InputDecoration(
                          labelText: 'Alamat IP Server Pengirim',
                          hintText: 'Contoh: 192.168.1.5',
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
                        // Buka halaman scanner dan tunggu hasilnya
                        final String? scannedIp = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const QRScannerScreen(),
                          ),
                        );

                        // Jika hasil scan tidak null, masukkan ke dalam controller dan update state dialog
                        if (scannedIp != null && scannedIp.trim().isNotEmpty) {
                          setDialogState(() {
                            ipController.text = scannedIp.trim();
                          });
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
                    if (!context.mounted) return;
                    Navigator.pop(ctx);
                    _receiveDataFromServerProcess(
                      alamatIP: targetIp,
                      context: context,
                      baseDir: baseDir,
                      getFormattedFileName: getFormattedFileName,
                      onLoadingStatusChanged: onLoadingStatusChanged,
                      onDataReceived: onDataReceived,
                    );
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
              onLoadingStatusChanged(false);

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

                  String namaZipDinamis = getFormattedFileName(
                    'server_backup',
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
              onLoadingStatusChanged(false);
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

// PERBAIKAN TOTAL: Menggunakan basis UI Stateful sederhana sesuai struktur BarcodeCapture versi terbaru Anda
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
          // Kontrol Senter Manual berbasis State Lokal (Bebas dari error kompilasi properti)
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: _isTorchOn ? Colors.yellow : Colors.grey,
            ),
            onPressed: () {
              controller.toggleTorch();
              setState(() {
                _isTorchOn = !_isTorchOn;
              });
            },
          ),
          // Kontrol Pembalik Kamera
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: MobileScanner(
        controller: controller,
        // DITERAPKAN: Menggunakan pencocokan model BarcodeCapture persis seperti dokumentasi resmi Anda
        onDetect: (BarcodeCapture capture) {
          final Barcode? barcode = capture.barcodes.firstOrNull;
          if (barcode != null) {
            final String? code = barcode.rawValue;
            if (code != null && code.trim().isNotEmpty) {
              controller
                  .stop(); // Hentikan engine kamera sebelum berpindah layar
              Navigator.pop(context, code.trim());
            }
          }
        },
      ),
    );
  }
}

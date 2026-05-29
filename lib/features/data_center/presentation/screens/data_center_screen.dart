import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:rutinitasku/features/data_center/presentation/widgets/backup_tab.dart';
import 'package:rutinitasku/features/data_center/presentation/widgets/local_sharing_tab.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/presentation/widgets/drawer_menu.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:archive/archive_io.dart';

import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// Import library tambahan seperti share_plus atau file_picker sesuai kebutuhan backup Anda

class DataCenterScreen extends StatefulWidget {
  const DataCenterScreen({super.key});

  @override
  State<DataCenterScreen> createState() => _DataCenterScreenState();
}

class _DataCenterScreenState extends State<DataCenterScreen> {
  final StorageService _storageService = StorageService();
  String _baseDir = 'Documents';
  HttpServer? _serverEksternal;

  List<File> _localBackupFiles = [];
  List<File> _serverBackupFiles = [];
  bool _isServerSelectionMode = false;
  final List<File> _selectedServerFiles = [];

  // === 2. TAMBAHKAN INIT STATE UNTUK MEMBACA SETTING DIRECTORY ===
  @override
  void initState() {
    super.initState();
    _loadBaseDirectory();
  }

  void _startMulaiServerSharing() async {
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

      // Jalankan server WebSocket di port 8090
      if (_serverEksternal != null) {
        await _serverEksternal!.close(force: true);
      }

      // === DAFTAR STATE BARU UNTUK HALAMAN DATA CENTER SERVER ===
      // Catatan: Anda bisa memindahkan variabel ini ke tingkat class state jika ingin
      // memantau jumlah client secara global di widget build utama.
      List<dynamic> daftarClientAktif = [];

      var handler = webSocketHandler((dynamic webSocket, dynamic protocol) {
        // Ambil info identitas unik atau gunakan hash kode dari objek WebSocket sebagai ID sementara
        final String clientId =
            "Client_${webSocket.hashCode.toString().substring(0, 4)}";

        // A. LOGIKA SAAT CLIENT BARU TERHUBUNG
        setState(() {
          daftarClientAktif.add(webSocket);
        });

        // Tampilkan notifikasi SnackBar bahwa client terhubung
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔌 [$clientId] Berhasil Terhubung ke Server!'),
            backgroundColor: Colors.green[800],
            duration: const Duration(seconds: 3),
          ),
        );

        // Mendengarkan data atau perintah yang masuk dari Client
        webSocket.stream.listen(
          (pesanMasuk) async {
            try {
              Map<String, dynamic> dataDiterima = jsonDecode(pesanMasuk);

              // LOGIKA A: Jika menerima paket data aplikasi dari Client
              if (dataDiterima['tipe_pesan'] == 'data_transfer') {
                String clientTasks = dataDiterima['task_master'];
                String clientJurnal = dataDiterima['jurnal_aktivitas'];
                String clientZipBase64 = dataDiterima['checklist_zip'];

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

                  setState(() {
                    _loadBaseDirectory();
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Sukses menerima data dari [$clientId]! Tersimpan: $namaZipDinamis',
                      ),
                      backgroundColor: Colors.teal,
                    ),
                  );
                }
              }
            } catch (err) {
              debugPrint("Server gagal memproses pesan dari $clientId: $err");
            }
          },
          // B. LOGIKA SAAT CLIENT TERPUTUS (DISCONNECT)
          onDone: () {
            setState(() {
              daftarClientAktif.remove(webSocket);
            });

            // Tampilkan notifikasi SnackBar bahwa client terputus
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ [$clientId] Memutuskan Koneksi / Terputus.'),
                backgroundColor: Colors.red[700],
                duration: const Duration(seconds: 3),
              ),
            );
            debugPrint("Koneksi perangkat $clientId terputus.");
          },
        );
      });

      _serverEksternal = await shelf_io.serve(
        handler,
        InternetAddress.anyIPv4,
        8090,
      );

      if (!mounted) return;

      // Fungsi pembantu untuk membungkus dan mengirim data lokal milik Server ke seluruh Client
      Future<void> fungsiKirimDataServer() async {
        if (daftarClientAktif.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Gagal! Belum ada perangkat penerima (Client) yang terhubung.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        String currentDir = await _storageService.getBaseDirSetting();
        File fileTasks = await _storageService.getTargetJsonFile(currentDir);
        String kontenTasks = await fileTasks.exists()
            ? await fileTasks.readAsString()
            : "{}";

        File fileJurnal = await _storageService.getJurnalJsonFile(currentDir);
        String kontenJurnal = await fileJurnal.exists()
            ? await fileJurnal.readAsString()
            : "[]";

        List<File> hubFiles = await _storageService.getAllChecklistHubs(
          currentDir,
        );
        final Archive archive = Archive();
        for (var file in hubFiles) {
          final String namaFile = file.path.split('/').last;
          final List<int> bytes = await file.readAsBytes();
          archive.addFile(ArchiveFile(namaFile, bytes.length, bytes));
        }
        final List<int>? zipBytes = ZipEncoder().encode(archive);
        String kontenZipBase64 = zipBytes != null ? base64Encode(zipBytes) : "";

        Map<String, dynamic> paketBesarKirim = {
          'tipe_pesan': 'data_transfer',
          'task_master': kontenTasks,
          'jurnal_aktivitas': kontenJurnal,
          'checklist_zip': kontenZipBase64,
        };

        // Kirim data ke setiap client yang sedang aktif terhubung (Broadcast)
        for (var socket in daftarClientAktif) {
          socket.sink.add(jsonEncode(paketBesarKirim));
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Berhasil mengirim data ke ${daftarClientAktif.length} Client!',
            ),
            backgroundColor: Colors.teal,
          ),
        );
      }

      // Tampilkan dialog kontrol server aktif beserta informasi jumlah client terhubung
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => StatefulBuilder(
          // StatefulBuilder digunakan agar informasi Client Terhubung update secara real-time di dalam dialog
          builder: (context, setDialogState) {
            // Pasang listener perubahan state utama ke dalam dialog state
            // (Memastikan UI di dalam dialog ikut ter-refresh saat callback handler memicu setState global)
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.wifi_tethering, color: Colors.indigo),
                  SizedBox(width: 8),
                  Text('Server Sharing Aktif'),
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

                  // === INFORMASI JUMLAH CLIENT PRODUKTIF YANG TERHUBUNG ===
                  Row(
                    children: [
                      Icon(
                        Icons.devices,
                        color: daftarClientAktif.isNotEmpty
                            ? Colors.green
                            : Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Perangkat Client Terhubung: ',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${daftarClientAktif.length}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: daftarClientAktif.isNotEmpty
                              ? Colors.green[800]
                              : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Status: Siap digunakan.\n\nSilakan tekan tombol di bawah jika Anda ingin mengirim data aktif komputer/HP ini ke Client.',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 12),

                  // === TOMBOL MANUAL UNTUK MENGIRIM DATA SISI SERVER ===
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: daftarClientAktif.isEmpty
                          ? null // Tombol dinonaktifkan jika tidak ada client terhubung
                          : () => fungsiKirimDataServer().then(
                              (_) => setDialogState(() {}),
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                      ),
                      icon: const Icon(
                        Icons.send_and_archive,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Kirim Data Ke Client',
                        style: TextStyle(color: Colors.white),
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
                    daftarClientAktif.clear();
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
      );
    } catch (e) {
      debugPrint("Gagal menyiapkan server dua arah: $e");
    }
  }

  void _tampilkanDialogHubungkanKeServer() async {
    // Ambil data riwayat IP dari SharedPreferences
    List<String> ipHistory = await _storageService.getIpHistory();

    // Otomatis isi text field dengan IP terakhir jika ada riwayat
    final ipController = TextEditingController(
      text: ipHistory.isNotEmpty ? ipHistory.first : '',
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        // Menggunakan StatefulBuilder agar list IP bisa update saat dihapus
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
                  keyboardType: TextInputType.text,
                ),

                // Tampilkan section riwayat jika list tidak kosong
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

                  // Bungkus dengan kontainer agar tidak meluber jika list panjang
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
                              // Hapus dari penyimpanan lokal
                              await _storageService.deleteIpFromHistory(
                                savedIp,
                              );
                              // Perbarui state di dalam dialog
                              setDialogState(() {
                                ipHistory.remove(savedIp);
                                if (ipController.text == savedIp) {
                                  ipController.clear();
                                }
                              });
                            },
                          ),
                          onTap: () {
                            // Jika IP di-tap, otomatis masukkan ke TextField
                            setDialogState(() {
                              ipController.text = savedIp;
                            });
                          },
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
                    // Simpan IP yang sukses dimasukkan ke dalam riwayat
                    await _storageService.saveIpToHistory(targetIp);

                    if (!mounted) return;
                    Navigator.pop(ctx);

                    // Jalankan fungsi bawaan Anda untuk mengambil data
                    _prosesTerimaDataDariServer(targetIp);
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

  void _prosesTerimaDataDariServer(String alamatIP) async {
    final urlWebSocket = 'ws://$alamatIP:8090';

    try {
      // Hubungkan koneksi pipa komunikasi ke Server
      final channel = WebSocketChannel.connect(Uri.parse(urlWebSocket));

      // Fungsi pembantu untuk membungkus dan mengirim data lokal milik Client ke Server
      Future<void> fungsiKirimDataClient() async {
        String currentDir = await _storageService.getBaseDirSetting();
        File fileTasks = await _storageService.getTargetJsonFile(currentDir);
        String kontenTasks = await fileTasks.exists()
            ? await fileTasks.readAsString()
            : "{}";

        File fileJurnal = await _storageService.getJurnalJsonFile(currentDir);
        String kontenJurnal = await fileJurnal.exists()
            ? await fileJurnal.readAsString()
            : "[]";

        List<File> hubFiles = await _storageService.getAllChecklistHubs(
          currentDir,
        );
        final Archive archive = Archive();
        for (var file in hubFiles) {
          final String namaFile = file.path.split('/').last;
          final List<int> bytes = await file.readAsBytes();
          archive.addFile(ArchiveFile(namaFile, bytes.length, bytes));
        }
        final List<int>? zipBytes = ZipEncoder().encode(archive);
        String kontenZipBase64 = zipBytes != null ? base64Encode(zipBytes) : "";

        Map<String, dynamic> paketBesarClient = {
          'tipe_pesan': 'data_transfer',
          'task_master': kontenTasks,
          'jurnal_aktivitas': kontenJurnal,
          'checklist_zip': kontenZipBase64,
        };

        channel.sink.add(jsonEncode(paketBesarClient));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data Anda sukses dikirimkan ke Server!'),
            backgroundColor: Colors.teal,
          ),
        );
      }

      // Dengarkan kiriman data yang dikirim oleh Server
      channel.stream.listen(
        (pesanMasuk) async {
          try {
            Map<String, dynamic> dataDiterima = jsonDecode(pesanMasuk);

            if (dataDiterima['tipe_pesan'] == 'data_transfer') {
              String serverTasks = dataDiterima['task_master'];
              String serverJurnal = dataDiterima['jurnal_aktivitas'];
              String serverZipBase64 = dataDiterima['checklist_zip'];

              final Archive backupArchive = Archive();
              List<int> tasksBytes = utf8.encode(serverTasks);
              backupArchive.addFile(
                ArchiveFile('my_tasks.json', tasksBytes.length, tasksBytes),
              );

              List<int> jurnalBytes = utf8.encode(serverJurnal);
              backupArchive.addFile(
                ArchiveFile('time_log.json', jurnalBytes.length, jurnalBytes),
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

              setState(() {
                _loadBaseDirectory();
              });

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
        },
        onError: (err) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Koneksi terputus atau gagal terhubung ke server!'),
            ),
          );
        },
        onDone: () {
          debugPrint("Koneksi client selesai.");
        },
      );

      if (!mounted) return;

      // Munculkan dialog kontrol kendali di sisi Client yang terhubung
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.cloud_done, color: Colors.teal),
              const SizedBox(width: 8),
              Text('Terhubung ke Server'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sukses tersambung dengan alamat IP: $alamatIP'),
              const SizedBox(height: 16),
              const Text(
                'Anda bisa memantau proses penerimaan otomatis, atau menekan tombol di bawah jika ingin mengirim balik data lokal HP ini ke Server tujuan.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // === TOMBOL MANUAL UNTUK MENGIRIM DATA SISI CLIENT ===
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => fungsiKirimDataClient(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                  ),
                  icon: const Icon(Icons.upload_file, color: Colors.white),
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
              child: const Text(
                'Putuskan Koneksi',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint("Gagal menjalankan transfer data client: $e");
    }
  }

  Future<void> _loadBaseDirectory() async {
    String dir = await _storageService.getBaseDirSetting();
    if (mounted) {
      setState(() {
        _baseDir = dir;
      });
      // Ambil daftar file backup lokal dan juga dari server
      _loadLocalBackups();
      _loadServerBackups(); // <-- TAMBAHKAN BARIS INI
    }
  }

  Future<void> _loadLocalBackups() async {
    List<File> files = await _storageService.getAllLocalBackupFiles(_baseDir);
    setState(() {
      _localBackupFiles = files.reversed.toList();
    });
  }

  // C. Tambahkan fungsi untuk melakukan Backup Semua Fitur (Menghasilkan berkas ZIP)
  void _buatBackupSemuaFitur() async {
    try {
      // 1. Membaca semua konten data yang ada saat ini
      File fileTasks = await _storageService.getTargetJsonFile(_baseDir);
      String kontenTasks = await fileTasks.exists()
          ? await fileTasks.readAsString()
          : "{}";

      File fileJurnal = await _storageService.getJurnalJsonFile(_baseDir);
      String kontenJurnal = await fileJurnal.exists()
          ? await fileJurnal.readAsString()
          : "[]";

      List<File> hubFiles = await _storageService.getAllChecklistHubs(_baseDir);

      // 2. Satukan semua berkas ke dalam satu objek Archive ZIP
      final Archive backupArchive = Archive();

      // Masukkan Task Master
      List<int> tasksBytes = utf8.encode(kontenTasks);
      backupArchive.addFile(
        ArchiveFile('my_tasks.json', tasksBytes.length, tasksBytes),
      );

      // Masukkan Jurnal Aktivitas
      List<int> jurnalBytes = utf8.encode(kontenJurnal);
      backupArchive.addFile(
        ArchiveFile('time_log.json', jurnalBytes.length, jurnalBytes),
      );

      // Masukkan semua Hub Checklist ke folder my_checklist di dalam ZIP
      for (var file in hubFiles) {
        final String namaFile = file.path.split('/').last;
        final List<int> bytes = await file.readAsBytes();
        backupArchive.addFile(
          ArchiveFile('my_checklist/$namaFile', bytes.length, bytes),
        );
      }

      // 3. Kompres menjadi format ZIP bytes
      final List<int>? finalZipBytes = ZipEncoder().encode(backupArchive);
      if (finalZipBytes == null) return;

      // 4. Berikan penamaan file yang sama seperti format di server_backup (menggunakan _getFormattedFileName)
      String namaZipDinamis = _getFormattedFileName('local_backup', 'zip');

      // 5. Simpan file ZIP ke folder storage/backup
      File fileZipTarget = await _storageService.getLocalBackupZipFile(
        _baseDir,
        namaZipDinamis,
      );
      await fileZipTarget.writeAsBytes(finalZipBytes);

      // 6. Refresh UI dan tampilkan notifikasi sukses
      _loadLocalBackups();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Backup semua fitur berhasil disimpan: $namaZipDinamis',
          ),
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      debugPrint("Gagal membuat backup lokal: $e");
    }
  }

  // =========================================================================
  // 1. LOGIKA UTAMA UNTUK TASK MASTER DATA
  // =========================================================================
  void _exportTaskMaster() async {
    try {
      // Ambil path direktori saat ini dan file datanya
      String currentDir = await _storageService.getBaseDirSetting();
      File fileAsli = await _storageService.getTargetJsonFile(currentDir);

      if (await fileAsli.exists()) {
        if (Platform.isLinux) {
          // --- LOGIKA KHUSUS LINUX (Save As) ---
          String? lokasiSimpan = await FilePicker.saveFile(
            dialogTitle: 'Simpan Backup Task Master',
            fileName: _getFormattedFileName('my_tasks_backup', 'json'),
            type: FileType.custom,
            allowedExtensions: ['json'],
          );

          if (lokasiSimpan != null) {
            await fileAsli.copy(lokasiSimpan);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Backup Berhasil Disimpan di Linux!'),
              ),
            );
          }
        } else {
          // --- LOGIKA KHUSUS ANDROID / OS LAIN (Share Pop-up) ---
          String namaDinamis = _getFormattedFileName('my_tasks_backup', 'json');
          final tempFile = await fileAsli.copy(
            '${Directory.systemTemp.path}/$namaDinamis',
          );
          await Share.shareXFiles([
            XFile(tempFile.path),
          ], text: 'Backup Task Master Data');
        }
      }
    } catch (e) {
      debugPrint("Gagal export: $e");
    }
  }

  // Jalur File: lib/features/data_center/presentation/screens/data_center_screen.dart
  void _importTaskMaster() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        String templatePath = result.files.single.path!;
        String fileContent = await File(templatePath).readAsString();

        File targetFile = await _storageService.getTargetJsonFile(_baseDir);
        await _storageService.saveJsonData(targetFile, fileContent);

        // KETERANGAN UBAH: Segarkan state lokal screen data center agar me-sync ulang path direktori dasar
        setState(() {
          _loadBaseDirectory();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data Task Master berhasil di-import!')),
        );
      }
    } catch (e) {
      debugPrint("Gagal import Task Master: $e");
    }
  }

  // =========================================================================
  // 2. LOGIKA UTAMA UNTUK JURNAL AKTIVITAS DATA
  // =========================================================================
  void _exportJurnal() async {
    try {
      String currentDir = await _storageService.getBaseDirSetting();
      File fileAsli = await _storageService.getJurnalJsonFile(currentDir);

      if (await fileAsli.exists()) {
        if (Platform.isLinux) {
          // --- LINUX: Save As ---
          String? lokasiSimpan = await FilePicker.saveFile(
            dialogTitle: 'Simpan Backup Jurnal Aktivitas',
            fileName: _getFormattedFileName('time_log_backup', 'json'),
            type: FileType.custom,
            allowedExtensions: ['json'],
          );

          if (lokasiSimpan != null) {
            await fileAsli.copy(lokasiSimpan);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Backup Jurnal Berhasil Disimpan di Linux!'),
              ),
            );
          }
        } else {
          // --- ANDROID: Share Pop-up ---
          String namaDinamis = _getFormattedFileName('time_log_backup', 'json');
          final tempFile = await fileAsli.copy(
            '${Directory.systemTemp.path}/$namaDinamis',
          );
          await Share.shareXFiles([
            XFile(tempFile.path),
          ], text: 'Backup Jurnal Aktivitas Data');
        }
      }
    } catch (e) {
      debugPrint("Gagal export Jurnal: $e");
    }
  }

  void _importJurnal() async {
    try {
      // Universal untuk Android & Linux
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        String templatePath = result.files.single.path!;
        String fileContent = await File(templatePath).readAsString();

        String currentDir = await _storageService.getBaseDirSetting();
        File targetFile = await _storageService.getJurnalJsonFile(currentDir);
        await _storageService.saveJsonData(targetFile, fileContent);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data Jurnal Aktivitas berhasil di-import!'),
          ),
        );
      }
    } catch (e) {
      debugPrint("Gagal import Jurnal: $e");
    }
  }

  // =========================================================================
  // 3. LOGIKA UTAMA UNTUK MY CHECKLIST DATA (Khusus karena folder berisi banyak file)
  // =========================================================================
  void _exportChecklist() async {
    try {
      String currentDir = await _storageService.getBaseDirSetting();
      List<File> hubFiles = await _storageService.getAllChecklistHubs(
        currentDir,
      );

      if (hubFiles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada data checklist untuk di-backup.'),
          ),
        );
        return;
      }

      // --- KETERANGAN UBAH DI SINI: Proses Membuat File ZIP ---
      // 1. Buat encoder / penampung data berkas ZIP
      final Archive archive = Archive();

      // 2. Masukkan semua file JSON checklist ke dalam data archive ZIP
      for (var file in hubFiles) {
        final String namaFile = file.path.split('/').last;
        final List<int> bytes = await file.readAsBytes();
        archive.addFile(ArchiveFile(namaFile, bytes.length, bytes));
      }

      // 3. Kompres data menjadi berkas berkode ZIP (.zip)
      final List<int>? zipBytes = ZipEncoder().encode(archive);
      if (zipBytes == null) return;

      // 4. Simpan file ZIP sementara di direktori temporary sistem
      // Ubah pembuatan file ZIP sementara
      String namaZipDinamis = _getFormattedFileName('checklist_backup', 'zip');
      final String tempPath = '${Directory.systemTemp.path}/$namaZipDinamis';
      final File zipFile = File(tempPath);
      await zipFile.writeAsBytes(zipBytes);
      // --------------------------------------------------------

      // Proses Pengiriman Berkas ZIP berdasarkan Platform OS
      if (Platform.isLinux) {
        // --- LINUX: Pilih lokasi simpan berkas ZIP langsung ---
        String? lokasiSimpan = await FilePicker.saveFile(
          dialogTitle: 'Simpan Backup Checklist (ZIP)',
          fileName: namaZipDinamis,
          type: FileType.custom,
          allowedExtensions: ['zip'],
        );

        if (lokasiSimpan != null) {
          await zipFile.copy(lokasiSimpan);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup ZIP Berhasil Disimpan!')),
          );
        }
      } else {
        // --- ANDROID: Share Pop-up satu file ZIP ---
        await Share.shareXFiles([
          XFile(zipFile.path),
        ], text: 'Backup Semua Hub Checklist Data (ZIP)');
      }
    } catch (e) {
      debugPrint("Gagal export ZIP Checklist: $e");
    }
  }

  void _importChecklist() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.isNotEmpty) {
        String currentDir = await _storageService.getBaseDirSetting();
        String targetFolder = await _storageService.getChecklistDirPath(
          currentDir,
        );
        int hitungSukses = 0;

        for (var pickedFile in result.files) {
          if (pickedFile.path != null) {
            String isiFile = await File(pickedFile.path!).readAsString();

            // --- KETERANGAN UBAH DI SINI: Logika Cek Nama Unik ---
            String namaFileBaru = pickedFile.name;
            File fileBaru = File('$targetFolder/$namaFileBaru');

            // Jika file sudah ada di folder tujuan, buat nama baru yang unik
            if (await fileBaru.exists()) {
              final String timestamp = DateTime.now().millisecondsSinceEpoch
                  .toString();
              // Mengubah "hub_data.json" menjadi "hub_data_1716942... .json"
              namaFileBaru = namaFileBaru.replaceAll(
                '.json',
                '_$timestamp.json',
              );
              fileBaru = File('$targetFolder/$namaFileBaru');
            }
            // -----------------------------------------------------

            await _storageService.saveJsonData(fileBaru, isiFile);
            hitungSukses++;
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Berhasil mengimport $hitungSukses file Hub Checklist!',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Gagal import Checklist: $e");
    }
  }

  // Letakkan fungsi ini di dalam class _DataCenterScreenState

  // Mengubah fungsi agar menerima parameter file yang dipilih dari list
  void _importSemuaDariZip(File zipFile) async {
    try {
      // Membaca bytes dari file ZIP target yang di-klik pengguna
      List<int> bytes = await zipFile.readAsBytes();

      // Dekode/Ekstrak file ZIP
      Archive archive = ZipDecoder().decodeBytes(bytes);
      int hitungChecklist = 0;

      // Iterasi ekstraksi isi ZIP ke folder aplikasi masing-masing
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
              String folderChecklist = await _storageService
                  .getChecklistDirPath(_baseDir);
              File target = File('$folderChecklist/$namaFileHub');
              await target.writeAsBytes(file.content);
              hitungChecklist++;
            }
          }
        }
      }

      setState(() {
        _loadBaseDirectory(); // Segarkan data UI
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Restore Berhasil! Data dari "${zipFile.path.split('/').last}" dipulihkan.',
          ),
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      debugPrint("Gagal mengimpor file ZIP: $e");
    }
  }

  // TAMBAHKAN fungsi baru ini untuk memuat file dari server
  Future<void> _loadServerBackups() async {
    List<File> files = await _storageService.getAllServerBackupFiles(_baseDir);
    setState(() {
      _serverBackupFiles = files.reversed.toList();
    });
  }

  // Fungsi utuh untuk mendeteksi alamat IP lokal (WiFi/LAN) perangkat pengirim
  Future<String> _getLocalIpAddress() async {
    try {
      // Mencari seluruh daftar antarmuka jaringan yang aktif pada perangkat
      List<NetworkInterface> interfaces = await NetworkInterface.list(
        includeLoopback: false, // Abaikan IP loopback lokal seperti 127.0.0.1
        type: InternetAddressType.IPv4, // Hanya ambil format alamat IPv4
      );

      for (var interface in interfaces) {
        for (var address in interface.addresses) {
          // Memastikan alamat IP tidak kosong dan merupakan IP jaringan lokal yang valid
          if (address.address.isNotEmpty) {
            return address
                .address; // Kembalikan IP pertama yang ditemukan (misal: 192.168.1.5)
          }
        }
      }
    } catch (e) {
      debugPrint("Gagal mendapatkan alamat IP: $e");
    }
    return "Tidak Diketahui"; // Kembalikan string default jika gagal atau offline
  }

  String _getFormattedFileName(String prefix, String extension) {
    final now = DateTime.now();

    // Array bantuan untuk penamaan hari dalam Bahasa Indonesia
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

    // Format tanggal: YYYY-MM-DD
    String tanggal =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    // Format jam, menit, dan detik: HH-mm-ss
    String waktu =
        "${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}";

    // Menghasilkan format: prefix_2026-05-28_Kamis_18-05-12.extension
    return "${prefix}_${tanggal}_${namaHari}_$waktu.$extension";
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Mengatur 2 Tab halaman
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Data Center'),
          backgroundColor: Colors.indigo[700],
          // Tambahkan bilah Tab di bagian bawah AppBar
          bottom: const TabBar(
            indicatorColor: Colors.amberAccent,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(
                icon: Icon(Icons.backup_outlined),
                text: 'Backup',
              ), // Diubah menjadi Backup dengan ikon yang sesuai
              Tab(icon: Icon(Icons.wifi_find_outlined), text: 'Local Sharing'),
            ],
          ),
        ),
        // Menerapkan Drawer Menu bawaan aplikasi Anda
        drawer: const DrawerMenu(isDataCenterActive: true),
        // TabBarView untuk menampilkan konten sesuai Tab yang dipilih
        body: TabBarView(
          children: [
            // TAB 1: Memanggil file/widget khusus Backup yang sudah dipisahkan
            BackupTab(
              localBackupFiles: _localBackupFiles,
              serverBackupFiles: _serverBackupFiles,
              onCreateBackup: () => _buatBackupSemuaFitur(),
              onDeleteBackup: (file) async {
                // Logika konfirmasi hapus dipanggil di sini, lalu:
                if (await file.exists()) {
                  await file.delete();
                  _loadLocalBackups(); // Memperbarui data list setelah dihapus
                }
              },
              // TAMBAHKAN callback baru untuk menghapus file backup server
              onDeleteServerBackup: (file) async {
                if (await file.exists()) {
                  await file.delete();
                  _loadServerBackups(); // Refresh daftar file server setelah dihapus
                }
              },

              // ==================================================
              // TULIS BARIS BARU INI DI SINI (Jangan hapus kode di atas atau di bawahnya)
              onRestoreAllZip: (file) => _importSemuaDariZip(file),
              onBackupTaskMaster: () => _exportTaskMaster(),
              onRestoreTaskMaster: () => _importTaskMaster(),
              onBackupChecklist: () => _exportChecklist(),
              onRestoreChecklist: () => _importChecklist(),
              onBackupJurnal: () => _exportJurnal(),
              onRestoreJurnal: () => _importJurnal(),
            ),

            // TAB 2: Memanggil file/widget khusus Local Sharing yang sudah dipisahkan
            LocalSharingTab(
              onSendFile: () => _startMulaiServerSharing(),
              onReceiveFile: () => _tampilkanDialogHubungkanKeServer(),
              serverBackupFiles: _serverBackupFiles,
              onDeleteServerBackup: (file) async {
                // === UBAH BAGIAN DI DALAM SINI ===
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

                // Jika user menekan tombol Hapus (true), maka file baru dihapus
                if (confirm && await file.exists()) {
                  await file.delete();
                  _loadServerBackups(); // Menyegarkan daftar setelah dihapus
                }
              },
              onRestoreAllZip: (file) => _importSemuaDariZip(file),
            ),
          ],
        ),
      ),
    );
  }
}

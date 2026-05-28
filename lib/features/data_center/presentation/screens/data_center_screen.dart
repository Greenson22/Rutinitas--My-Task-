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

  // === 2. TAMBAHKAN INIT STATE UNTUK MEMBACA SETTING DIRECTORY ===
  @override
  void initState() {
    super.initState();
    _loadBaseDirectory();
  }

  void _startMulaiServerSharing() async {
    setState(() {
      // Berikan keterangan kepada pengguna apa saja yang sedang dipersiapkan untuk dikirim
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Menyiapkan paket data: Task Master, Jurnal, dan ZIP Checklist...',
          ),
          backgroundColor: Colors.indigo,
        ),
      );
    });

    try {
      String currentDir = await _storageService.getBaseDirSetting();

      // A. Membaca data Task Master
      File fileTasks = await _storageService.getTargetJsonFile(currentDir);
      String kontenTasks = await fileTasks.readAsString();

      // B. Membaca data Jurnal Aktivitas
      File fileJurnal = await _storageService.getJurnalJsonFile(currentDir);
      String kontenJurnal = await fileJurnal.readAsString();

      // C. Membuat berkas ZIP Checklist (Logika dari fungsi _exportChecklist)
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

      // Konversi bytes ZIP ke String Base64 agar aman dikirim via teks JSON WebSocket
      String kontenZipBase64 = zipBytes != null ? base64Encode(zipBytes) : "";

      // Buat koneksi server WebSocket
      var handler = webSocketHandler((dynamic webSocket, dynamic protocol) {
        // Bungkus ketiga data tersebut ke dalam SATU paket JSON besar
        Map<String, dynamic> paketBesarKirim = {
          'task_master': kontenTasks,
          'jurnal_aktivitas': kontenJurnal,
          'checklist_zip': kontenZipBase64,
        };

        try {
          // Kirim paket data lengkap ke client penerima
          webSocket.sink.add(jsonEncode(paketBesarKirim));

          Future.delayed(const Duration(seconds: 1), () {
            webSocket.sink.close();
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Semua paket data sukses ditransfer ke penerima!'),
              backgroundColor: Colors.teal,
            ),
          );
        } catch (e) {
          debugPrint("Gagal mengirim data lewat stream: $e");
        }
      });

      // Jalankan server di port 8090
      if (_serverEksternal != null) {
        await _serverEksternal!.close(force: true);
      }
      _serverEksternal = await shelf_io.serve(
        handler,
        InternetAddress.anyIPv4,
        8090,
      );

      // Tampilkan dialog server aktif (Sesuaikan visual informasi filenya)
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Server Sharing Aktif'),
          content: const Text(
            'Status: Menunggu perangkat penerima terhubung...\n\nPaket yang akan dikirim:\n1. Task Master (.json)\n2. Jurnal Aktivitas (.json)\n3. Semua Hub Checklist (.zip)',
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
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint("Gagal menyiapkan server backup: $e");
    }
  }

  void _tampilkanDialogHubungkanKeServer() {
    final ipController = TextEditingController(text: 'Contoh: 192.168.1.5');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Masukkan IP Pengirim'),
        content: TextField(
          controller: ipController,
          decoration: const InputDecoration(labelText: 'Alamat IP Server'),
          keyboardType: TextInputType.values.first, // teks biasa/angka
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _prosesTerimaDataDariServer(ipController.text.trim());
            },
            child: const Text('Hubungkan & Ambil'),
          ),
        ],
      ),
    );
  }

  void _prosesTerimaDataDariServer(String alamatIP) async {
    final urlWebSocket = 'ws://$alamatIP:8090';

    try {
      final channel = WebSocketChannel.connect(Uri.parse(urlWebSocket));

      channel.stream.listen(
        (pesanMasuk) async {
          // 1. Dekode paket besar yang diterima dari server
          Map<String, dynamic> dataDiterima = jsonDecode(pesanMasuk);
          String kontenTasks = dataDiterima['task_master'];
          String kontenJurnal = dataDiterima['jurnal_aktivitas'];
          String kontenZipBase64 = dataDiterima['checklist_zip'];

          // 2. Buat wadah Archive baru untuk menyatukan semua data ke satu ZIP
          final Archive backupArchive = Archive();

          // A. Masukkan data Task Master berupa file JSON ke dalam archive
          List<int> tasksBytes = utf8.encode(kontenTasks);
          backupArchive.addFile(
            ArchiveFile('my_tasks.json', tasksBytes.length, tasksBytes),
          );

          // B. Masukkan data Jurnal Aktivitas berupa file JSON ke dalam archive
          List<int> jurnalBytes = utf8.encode(kontenJurnal);
          backupArchive.addFile(
            ArchiveFile('time_log.json', jurnalBytes.length, jurnalBytes),
          );

          // C. Masukkan semua isi file Checklist dari server ke dalam archive
          if (kontenZipBase64.isNotEmpty) {
            List<int> checklistZipBytes = base64Decode(kontenZipBase64);
            Archive checklistArchive = ZipDecoder().decodeBytes(
              checklistZipBytes,
            );

            // Memindahkan file-file di dalam zip checklist ke dalam folder khusus di ZIP utama
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

          // 3. Kompres seluruh materi archive di atas menjadi bytes berkas ZIP
          final List<int>? finalZipBytes = ZipEncoder().encode(backupArchive);
          if (finalZipBytes == null) return;

          // 4. Buat nama file ZIP dinamis berdasarkan format tanggal-hari-waktu yang Anda miliki
          String namaZipDinamis = _getFormattedFileName('server_backup', 'zip');

          // 5. Simpan file ZIP tersebut ke folder storage/backup_from_server
          File fileZipTarget = await _storageService.getBackupZipFile(
            _baseDir,
            namaZipDinamis,
          );
          await fileZipTarget.writeAsBytes(finalZipBytes);

          // Segarkan state halaman
          setState(() {
            _loadBaseDirectory();
          });

          // Tampilkan notifikasi sukses berupa nama file ZIP-nya
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Sukses menerima data! Disimpan dalam bentuk file: $namaZipDinamis',
              ),
              backgroundColor: Colors.teal,
              duration: const Duration(seconds: 4),
            ),
          );

          channel.sink.close();
        },
        onError: (err) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Koneksi terputus atau gagal terhubung!'),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint("Gagal mengambil data dari server: $e");
    }
  }

  Future<void> _loadBaseDirectory() async {
    String dir = await _storageService.getBaseDirSetting();
    if (mounted) {
      setState(() {
        _baseDir = dir;
      });
      // Ambil daftar file backup yang sudah ada di folder storage/backup
      _loadLocalBackups();
    }
  }

  Future<void> _loadLocalBackups() async {
    List<File> files = await _storageService.getAllLocalBackupFiles(_baseDir);
    setState(() {
      _localBackupFiles = files;
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
              onCreateBackup: () => _buatBackupSemuaFitur(),
              onDeleteBackup: (file) async {
                // Logika konfirmasi hapus dipanggil di sini, lalu:
                if (await file.exists()) {
                  await file.delete();
                  _loadLocalBackups(); // Memperbarui data list setelah dihapus
                }
              },
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
            ),
          ],
        ),
      ),
    );
  }
}

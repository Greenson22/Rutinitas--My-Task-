import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shelf_web_socket/src/web_socket_handler.dart';
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
          // 1. Dekode paket besar yang diterima
          Map<String, dynamic> dataDiterima = jsonDecode(pesanMasuk);

          String kontenTasks = dataDiterima['task_master'];
          String kontenJurnal = dataDiterima['jurnal_aktivitas'];
          String kontenZipBase64 = dataDiterima['checklist_zip'];

          // 2. Simpan otomatis file Task Master
          File fileTasksTarget = await _storageService.getTargetJsonFile(
            _baseDir,
          );
          await _storageService.saveJsonData(fileTasksTarget, kontenTasks);

          // 3. Simpan otomatis file Jurnal Aktivitas
          File fileJurnalTarget = await _storageService.getJurnalJsonFile(
            _baseDir,
          );
          await _storageService.saveJsonData(fileJurnalTarget, kontenJurnal);

          // 4. Ekstrak berkas ZIP Checklist Hub dan simpan ke folder checklist
          if (kontenZipBase64.isNotEmpty) {
            List<int> zipBytes = base64Decode(kontenZipBase64);
            Archive archive = ZipDecoder().decodeBytes(zipBytes);
            String folderChecklist = await _storageService.getChecklistDirPath(
              _baseDir,
            );

            for (ArchiveFile file in archive) {
              // PERBAIKAN: Mengubah 'dalam' menjadi 'in'
              if (file.isFile) {
                File fileHubLokal = File('$folderChecklist/${file.name}');
                // PERBAIKAN: Gunakan List<int>.from agar konversi data biner dari ZIP lebih aman
                await fileHubLokal.writeAsBytes(List<int>.from(file.content));
              }
            }
          }

          // Segarkan state halaman agar data baru langsung tersinkronisasi di UI
          setState(() {
            _loadBaseDirectory();
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Sukses menerima & memperbarui seluruh data aplikasi!',
              ),
              backgroundColor: Colors.teal,
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
          if (pickedFile.path != null && pickedFile.name != null) {
            String isiFile = await File(pickedFile.path!).readAsString();

            // --- KETERANGAN UBAH DI SINI: Logika Cek Nama Unik ---
            String namaFileBaru = pickedFile.name!;
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

  // Fungsi pembantu untuk membuat baris tombol manajemen data
  Widget _buildDataManagementRow({
    required String title,
    required IconData icon,
    required VoidCallback onExport,
    required VoidCallback onImport,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: Icon(icon, color: Colors.indigo, size: 28),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.upload, color: Colors.blue),
              tooltip: 'Export JSON',
              onPressed: onExport,
            ),
            IconButton(
              icon: const Icon(Icons.download, color: Colors.green),
              tooltip: 'Import JSON',
              onPressed: onImport,
            ),
          ],
        ),
      ),
    );
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
              Tab(icon: Icon(Icons.import_export), text: 'Export & Import'),
              Tab(icon: Icon(Icons.wifi_find_outlined), text: 'Local Sharing'),
            ],
          ),
        ),
        // Menerapkan Drawer Menu bawaan aplikasi Anda
        drawer: const DrawerMenu(isDataCenterActive: true),
        // TabBarView untuk menampilkan konten sesuai Tab yang dipilih
        body: TabBarView(
          children: [
            // Konten TAB 1: Manajemen Berkas / Backup Lokal (Fitur Lama Anda)
            ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildDataManagementRow(
                  title: 'Task Master Data',
                  icon: Icons.format_list_bulleted,
                  onExport: () => _exportTaskMaster(),
                  onImport: () => _importTaskMaster(),
                ),
                _buildDataManagementRow(
                  title: 'My Checklist Data',
                  icon: Icons.checklist_rtl,
                  onExport: () => _exportChecklist(),
                  onImport: () => _importChecklist(),
                ),
                _buildDataManagementRow(
                  title: 'Jurnal Aktivitas Data',
                  icon: Icons.menu_book,
                  onExport: () => _exportJurnal(),
                  onImport: () => _importJurnal(),
                ),
              ],
            ),

            // Konten TAB 2: Fitur Baru Local Sharing (WebSocket)
            _buildLocalSharingTab(),
          ],
        ),
      ),
    );
  }

  // Widget tampilan untuk Tab Local Sharing
  Widget _buildLocalSharingTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.share_location,
                      color: Colors.indigo[700],
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Kirim & Terima Data Lokal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo[900],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Text(
                  'Fitur ini memungkinkan Anda mengirim atau menerima file data secara langsung antar perangkat (Android/Linux) yang terhubung dalam satu jaringan Wi-Fi yang sama.',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
                const SizedBox(height: 20),

                // Pilihan Operasi 1: Menjadi Server (Pengirim)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo[50],
                    child: const Icon(Icons.cloud_upload, color: Colors.indigo),
                  ),
                  title: const Text(
                    'Mode Pengirim (Server)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Pilih file dari perangkat ini untuk dikirim ke perangkat lain',
                    style: TextStyle(fontSize: 11),
                  ),
                  trailing: ElevatedButton(
                    onPressed:
                        _startMulaiServerSharing, // Memanggil fungsi server Anda
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                    ),
                    child: const Text('Kirim File'),
                  ),
                ),
                const Divider(),

                // Pilihan Operasi 2: Menjadi Client (Penerima)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal[50],
                    child: const Icon(Icons.cloud_download, color: Colors.teal),
                  ),
                  title: const Text(
                    'Mode Penerima (Client)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Masukkan alamat IP pengirim untuk mengunduh file data',
                    style: TextStyle(fontSize: 11),
                  ),
                  trailing: ElevatedButton(
                    onPressed:
                        _tampilkanDialogHubungkanKeServer, // Memanggil fungsi client Anda
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[700],
                    ),
                    child: const Text('Terima File'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

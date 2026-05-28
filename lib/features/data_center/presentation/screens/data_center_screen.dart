import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/presentation/widgets/drawer_menu.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:archive/archive_io.dart';
// Import library tambahan seperti share_plus atau file_picker sesuai kebutuhan backup Anda

class DataCenterScreen extends StatefulWidget {
  const DataCenterScreen({super.key});

  @override
  State<DataCenterScreen> createState() => _DataCenterScreenState();
}

class _DataCenterScreenState extends State<DataCenterScreen> {
  final StorageService _storageService = StorageService();
  String _baseDir = 'Documents';

  // === 2. TAMBAHKAN INIT STATE UNTUK MEMBACA SETTING DIRECTORY ===
  @override
  void initState() {
    super.initState();
    _loadBaseDirectory();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Center'),
        backgroundColor: Colors.indigo[700],
      ),
      // Menerapkan Drawer Menu agar bisa berpindah halaman
      drawer: const DrawerMenu(
        isDataCenterActive: true,
      ), // Tambahkan parameter penanda jika perlu
      body: ListView(
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
    );
  }
}

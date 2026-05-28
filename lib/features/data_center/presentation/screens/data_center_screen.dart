import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/presentation/widgets/drawer_menu.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
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
      // Ambil file JSON asli dari storage service
      File file = await _storageService.getTargetJsonFile(_baseDir);
      if (await file.exists()) {
        // Share file tersebut ke luar agar pengguna bisa menyimpannya
        await Share.shareXFiles([
          XFile(file.path),
        ], text: 'Backup Task Master Data');
      }
    } catch (e) {
      debugPrint("Gagal export Task Master: $e");
    }
  }

  void _importTaskMaster() async {
    try {
      // Buka window pemilih file di HP/Laptop khusus file JSON
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        String templatePath = result.files.single.path!;
        // Baca isi file yang dipilih pengguna
        String fileContent = await File(templatePath).readAsString();

        // Ambil path file target aplikasi
        File targetFile = await _storageService.getTargetJsonFile(_baseDir);
        // Timpa file lama aplikasi dengan data baru
        await _storageService.saveJsonData(targetFile, fileContent);

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
      File file = await _storageService.getJurnalJsonFile(_baseDir);
      if (await file.exists()) {
        await Share.shareXFiles([
          XFile(file.path),
        ], text: 'Backup Jurnal Aktivitas Data');
      }
    } catch (e) {
      debugPrint("Gagal export Jurnal: $e");
    }
  }

  void _importJurnal() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        String templatePath = result.files.single.path!;
        String fileContent = await File(templatePath).readAsString();

        File targetFile = await _storageService.getJurnalJsonFile(_baseDir);
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
      // Ambil daftar seluruh file (.json) hub yang ada di dalam folder checklist
      List<File> hubFiles = await _storageService.getAllChecklistHubs(_baseDir);

      if (hubFiles.isNotEmpty) {
        // Konversi ke dalam bentuk daftar XFile untuk dibagikan secara masal sekaligus
        List<XFile> filesToShare = hubFiles
            .map((file) => XFile(file.path))
            .toList();
        await Share.shareXFiles(
          filesToShare,
          text: 'Backup Semua Hub Checklist Data',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada data checklist untuk di-backup.'),
          ),
        );
      }
    } catch (e) {
      debugPrint("Gagal export Checklist: $e");
    }
  }

  void _importChecklist() async {
    try {
      // Izinkan pengguna memilih banyak file JSON sekaligus (karena checklist per Hub dipisah per file)
      FilePickerResult? result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.isNotEmpty) {
        // Ambil path direktori folder checklist di aplikasi
        String targetFolder = await _storageService.getChecklistDirPath(
          _baseDir,
        );
        int hitungSukses = 0;

        for (var pickedFile in result.files) {
          if (pickedFile.path != null && pickedFile.name != null) {
            String isiFile = await File(pickedFile.path!).readAsString();
            // Buat file baru di folder tujuan aplikasi menggunakan nama file yang sama
            File fileBaru = File('$targetFolder/${pickedFile.name}');
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

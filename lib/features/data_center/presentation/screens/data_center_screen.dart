import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/presentation/widgets/drawer_menu.dart';
// Import library tambahan seperti share_plus atau file_picker sesuai kebutuhan backup Anda

class DataCenterScreen extends StatefulWidget {
  const DataCenterScreen({super.key});

  @override
  State<DataCenterScreen> createState() => _DataCenterScreenState();
}

class _DataCenterScreenState extends State<DataCenterScreen> {
  final StorageService _storageService = StorageService();

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

  // --- LOGIKA PROGRESS DI BAWAH INI KAN DIHUBUNGKAN KE STORAGE_SERVICE ---
  void _exportTaskMaster() async {
    // Logika mengambil file dari _storageService lalu membagikan/save ke luar
  }

  void _importTaskMaster() async {
    // Logika memilih file luar lalu menimpa data di _storageService
  }

  void _exportChecklist() async {
    /* ... */
  }
  void _importChecklist() async {
    /* ... */
  }
  void _exportJurnal() async {
    /* ... */
  }
  void _importJurnal() async {
    /* ... */
  }
}

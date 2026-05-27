// lib/features/task_master/presentation/widgets/settings_dialog.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class SettingsDialog extends StatefulWidget {
  final String currentBaseDir;
  final Function(String) onSave;

  const SettingsDialog({
    super.key,
    required this.currentBaseDir,
    required this.onSave,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late String _tempSelection;

  @override
  void initState() {
    super.initState();
    _tempSelection = widget.currentBaseDir;
  }

  Future<void> _pickDirectory() async {
    String? selectedDirectory = await FilePicker.getDirectoryPath();

    if (selectedDirectory != null) {
      setState(() {
        _tempSelection = selectedDirectory;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Pengaturan Folder Data'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Direktori Utama Saat Ini:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                _tempSelection,
                style: const TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Platform.isAndroid
                ? const SizedBox.shrink() // Sembunyikan tombol jika dijalankan di Android
                : ElevatedButton.icon(
                    onPressed: _pickDirectory,
                    icon: const Icon(Icons.folder_open, size: 20),
                    label: const Text('Pilih Folder Kustom'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),

            // === PERBAIKAN TEKS CATATAN INFORMASI FOLDER ===
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.indigo[700], size: 18),
                const SizedBox(width: 6),
                Text(
                  'Informasi Penyimpanan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[900],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Aplikasi akan otomatis membuat 3 subfolder berikut di dalam direktori terpilih untuk menyimpan data secara lokal:',
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
            const SizedBox(height: 8),
            _buildFolderInfoItem('📁 /mytask', 'Data manajemen tugas utama'),
            _buildFolderInfoItem(
              '📁 /my_checklist',
              'Data pengaturan checklist hub',
            ),
            _buildFolderInfoItem(
              '📁 /jurnal_aktivitas',
              'Data log waktu produktif harian',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_tempSelection);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
          child: const Text('Simpan', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  // Helper Widget untuk membuat list informasi folder yang rapi
  Widget _buildFolderInfoItem(String folderName, String description) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              folderName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),
          const Text(' : ', style: TextStyle(fontSize: 12, color: Colors.grey)),
          Expanded(
            flex: 6,
            child: Text(
              description,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

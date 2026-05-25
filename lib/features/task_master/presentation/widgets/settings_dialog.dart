import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // Import package baru

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

  // Fungsi untuk membuka file picker khusus folder
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
      title: const Text('Pengaturan Folder'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Direktori dasar saat ini:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            _tempSelection,
            style: const TextStyle(color: Colors.blueGrey, fontSize: 13),
          ),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed: _pickDirectory,
            icon: const Icon(Icons.folder_open),
            label: const Text('Pilih Folder Custom'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
          ),
          const SizedBox(height: 15),
          Text(
            'Catatan: Aplikasi akan otomatis membuat subfolder "/mytask/my_tasks.json" di dalam direktori terpilih.',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
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
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

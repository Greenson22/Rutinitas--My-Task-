import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pengaturan Folder Ubuntu'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilih direktori dasar untuk menyimpan data:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          RadioListTile<String>(
            title: const Text('Folder Documents (~/Documents)'),
            value: 'Documents',
            groupValue: _tempSelection,
            onChanged: (val) => setState(() => _tempSelection = val!),
          ),
          RadioListTile<String>(
            title: const Text('Folder Downloads (~/Downloads)'),
            value: 'Downloads',
            groupValue: _tempSelection,
            onChanged: (val) => setState(() => _tempSelection = val!),
          ),
          const SizedBox(height: 10),
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

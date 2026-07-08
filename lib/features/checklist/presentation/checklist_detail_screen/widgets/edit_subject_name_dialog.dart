import 'package:flutter/material.dart';

class EditSubjectNameDialog extends StatefulWidget {
  final String initialName;
  final Function(String newName) onSave;

  const EditSubjectNameDialog({
    super.key,
    required this.initialName,
    required this.onSave,
  });

  @override
  State<EditSubjectNameDialog> createState() => _EditSubjectNameDialogState();
}

class _EditSubjectNameDialogState extends State<EditSubjectNameDialog> {
  late final TextEditingController _editController;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Ubah Judul Checklist'),
      content: TextField(
        controller: _editController,
        decoration: const InputDecoration(
          labelText: 'Nama Judul Baru',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            final newName = _editController.text.trim();
            if (newName.isNotEmpty) {
              widget.onSave(newName);
            }
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
          child: const Text('Simpan', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

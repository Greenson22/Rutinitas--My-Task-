import 'package:flutter/material.dart';
import '../../data/models/task_model.dart';

class AddCategoryDialog extends StatefulWidget {
  final Function(String name, String icon) onSave;
  final TaskCategory? categoryToEdit; // Tambahkan parameter opsional ini

  const AddCategoryDialog({
    super.key,
    required this.onSave,
    this.categoryToEdit,
  });

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final _nameController = TextEditingController();
  final _iconController = TextEditingController(text: '📌');
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Jika ada data yang di-edit, pasang nilai awalnya ke dalam form
    if (widget.categoryToEdit != null) {
      _nameController.text = widget.categoryToEdit!.name;
      _iconController.text = widget.categoryToEdit!.icon;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.categoryToEdit != null;

    return AlertDialog(
      title: Text(isEditMode ? 'Ubah Kategori' : 'Tambah Kategori Baru'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nama Kategori'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama kategori tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _iconController,
              decoration: const InputDecoration(labelText: 'Emoji Ikon'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ikon tidak boleh kosong';
                }
                return null;
              },
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
            if (_formKey.currentState!.validate()) {
              widget.onSave(
                _nameController.text.trim(),
                _iconController.text.trim(),
              );
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

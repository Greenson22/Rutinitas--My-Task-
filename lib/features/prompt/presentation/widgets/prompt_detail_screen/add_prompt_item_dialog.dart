// lib/features/prompt/presentation/widgets/add_prompt_item_dialog.dart
import 'package:flutter/material.dart';
import '../../../data/models/prompt_model.dart';
import '../../controllers/prompt_controller.dart';

class AddPromptItemDialog extends StatefulWidget {
  final PromptGroup currentGroup;
  final PromptController controller;
  final Function(PromptGroup) onPromptAdded;

  const AddPromptItemDialog({
    super.key,
    required this.currentGroup,
    required this.controller,
    required this.onPromptAdded,
  });

  @override
  State<AddPromptItemDialog> createState() => _AddPromptItemDialogState();
}

class _AddPromptItemDialogState extends State<AddPromptItemDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.playlist_add, color: Colors.indigo),
          SizedBox(width: 8),
          Text('Tambah Item Prompt'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul / Peran (Title)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v!.trim().isEmpty ? 'Title tidak boleh kosong' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi Pendek (Opsional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contentController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Isi Perintah Prompt (Content)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    v!.trim().isEmpty ? 'Isi prompt tidak boleh kosong' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              // Memanggil fungsi simpan dari controller yang di-passing
              final updatedGroup = await widget.controller.addPromptItemToGroup(
                group: widget.currentGroup,
                title: _titleController.text,
                description: _descController.text,
                content: _contentController.text,
                context: context,
              );

              if (updatedGroup != null && mounted) {
                // Mengirim data terbaru kembali ke Screen Utama
                widget.onPromptAdded(updatedGroup);
              }

              if (context.mounted) {
                Navigator.pop(context);
              }
            }
          },
          child: const Text(
            'Simpan Prompt',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

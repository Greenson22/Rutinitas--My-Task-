// lib/features/prompt/presentation/widgets/prompt_detail_screen/add_prompt_item_dialog.dart
import 'package:flutter/material.dart';
import '../../../data/models/prompt_model.dart';
import '../../controllers/prompt_controller.dart';
import '../../../../../core/presentation/widgets/base_popup_dialog.dart';

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
    return BasePopupDialog(
      themeColor: Colors.indigo,
      titleColor: Colors.white,

      // 1. HEADER DIALOG
      title: Row(
        children: const [
          Icon(Icons.playlist_add, color: Colors.white, size: 24),
          SizedBox(width: 8),
          Text(
            'Tambah Item Prompt Baru',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),

      // 2. KONTEN / FORM FIELDS
      content: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Judul / Peran (Title)',
                hintText: 'Misal: Ahli SEO, Kode Reviewer',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) =>
                  v!.trim().isEmpty ? 'Title tidak boleh kosong' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Deskripsi Pendek (Opsional)',
                hintText: 'Keterangan singkat guna/fungsi prompt',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contentController,
              maxLines: 5,
              minLines: 3,
              decoration: const InputDecoration(
                labelText: 'Isi Perintah Prompt (Content)',
                hintText: 'Masukkan instruksi detail AI...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (v) =>
                  v!.trim().isEmpty ? 'Isi prompt tidak boleh kosong' : null,
            ),
          ],
        ),
      ),

      // 3. ACTIONS FOOTER PANEL
      footer: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final updatedGroup = await widget.controller
                      .addPromptItemToGroup(
                        group: widget.currentGroup,
                        title: _titleController.text.trim(),
                        description: _descController.text.trim(),
                        content: _contentController.text.trim(),
                        context: context,
                      );
                  if (updatedGroup != null && mounted) {
                    widget.onPromptAdded(updatedGroup);
                  }
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text(
                'Simpan Prompt',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

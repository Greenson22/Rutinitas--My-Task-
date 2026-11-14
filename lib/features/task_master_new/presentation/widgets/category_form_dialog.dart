import 'package:flutter/material.dart';

import '../../domain/entities/category.dart';
import '../../domain/operations/category_operations.dart';

/// Dialog tambah/edit kategori dengan validasi nama dan pemilih emoji.
class CategoryFormDialog extends StatefulWidget {
  const CategoryFormDialog({
    super.key,
    this.category,
    required this.onValidateName,
    required this.onSave,
  });

  /// `null` berarti mode tambah.
  final Category? category;
  final String? Function(String name) onValidateName;
  final Future<bool> Function(String name, String icon) onSave;

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  static const _emojiPresets = [
    '📌',
    '🏃',
    '📚',
    '💪',
    '🧘',
    '💧',
    '🥗',
    '😴',
    '💻',
    '🎯',
    '🎨',
    '🎵',
    '🧹',
    '💰',
    '🙏',
    '🌱',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _iconController;
  bool _submitting = false;
  String? _submitError;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _iconController = TextEditingController(
      text: widget.category?.icon ?? defaultCategoryIcon,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Ubah Kategori' : 'Tambah Kategori Baru'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                key: const Key('categoryNameField'),
                controller: _nameController,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nama Kategori',
                  hintText: 'Contoh: Olahraga',
                ),
                validator: (value) => widget.onValidateName(value ?? ''),
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('categoryIconField'),
                controller: _iconController,
                decoration: const InputDecoration(
                  labelText: 'Ikon Emoji',
                  hintText: 'Pilih atau ketik emoji',
                ),
                validator: (value) {
                  final icon = value?.trim() ?? '';
                  if (icon.isEmpty) return 'Ikon tidak boleh kosong';
                  if (icon.length > 16) return 'Ikon terlalu panjang';
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final emoji in _emojiPresets)
                    _EmojiChoice(
                      emoji: emoji,
                      selected: _iconController.text.trim() == emoji,
                      onTap: () {
                        _iconController.text = emoji;
                        setState(() {});
                      },
                    ),
                ],
              ),
              if (_submitError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _submitError!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('categoryCancelButton'),
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          key: const Key('categorySaveButton'),
          onPressed: _submitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _submitError = null;
    });

    final saved = await widget.onSave(
      _nameController.text.trim(),
      _iconController.text.trim(),
    );

    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _submitting = false;
        _submitError = 'Perubahan belum tersimpan. Silakan coba lagi.';
      });
    }
  }
}

class _EmojiChoice extends StatelessWidget {
  const _EmojiChoice({
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? Colors.indigo : Colors.blueGrey.withValues(alpha: 0.2),
            width: selected ? 2 : 1,
          ),
          color: selected
              ? Colors.indigo.withValues(alpha: 0.08)
              : Colors.transparent,
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 20)),
      ),
    );
  }
}

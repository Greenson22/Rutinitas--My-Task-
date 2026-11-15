import 'dart:convert';

import 'package:flutter/material.dart';

/// Editor JSON mentah di area Advanced.
///
/// Validasi dilakukan sebelum [onSave] dipanggil. Penyimpanan nyata tetap
/// melewati repository sehingga atomic write dan enkripsi tetap berlaku.
class RawJsonEditorDialog extends StatefulWidget {
  const RawJsonEditorDialog({
    super.key,
    required this.loadContent,
    required this.onSave,
  });

  final Future<String> Function() loadContent;
  final Future<bool> Function(String content) onSave;

  @override
  State<RawJsonEditorDialog> createState() => _RawJsonEditorDialogState();
}

class _RawJsonEditorDialogState extends State<RawJsonEditorDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  String? _validationError;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final content = await widget.loadContent();
      if (!mounted) return;
      setState(() {
        _controller.text = content;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'Gagal membaca file JSON: $error';
      });
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    final content = _controller.text;

    final Object? decoded;
    try {
      decoded = jsonDecode(content);
    } catch (error) {
      setState(() {
        _validationError = 'JSON tidak valid: $error';
        _saveError = null;
      });
      return;
    }
    if (decoded is! Map) {
      setState(() {
        _validationError = 'Akar JSON harus berupa objek.';
        _saveError = null;
      });
      return;
    }

    setState(() {
      _validationError = null;
      _saveError = null;
      _saving = true;
    });
    final saved = await widget.onSave(content);
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _saving = false;
      _saveError =
          'JSON gagal disimpan. Data lama tetap aman. Periksa kembali isi '
          'file atau banner kesalahan di layar utama.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.science_outlined, color: Colors.deepPurple),
          SizedBox(width: 8),
          Expanded(child: Text('Advanced: JSON mentah')),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 420,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.indigo),
              )
            : _loadError != null
            ? SingleChildScrollView(
                child: Text(
                  _loadError!,
                  key: const Key('rawJsonLoadError'),
                  style: const TextStyle(color: Colors.redAccent),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hanya untuk pengguna mahir. Perubahan disimpan dengan '
                    'atomic write dan tetap mengikuti pengaturan enkripsi.',
                    style: TextStyle(fontSize: 11, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TextField(
                      key: const Key('rawJsonEditorField'),
                      controller: _controller,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      keyboardType: TextInputType.multiline,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Struktur JSON Task Master...',
                        contentPadding: EdgeInsets.all(10),
                      ),
                    ),
                  ),
                  if (_validationError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _validationError!,
                      key: const Key('rawJsonValidationError'),
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (_saveError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _saveError!,
                      key: const Key('rawJsonSaveError'),
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          key: const Key('rawJsonSaveButton'),
          onPressed: _loading || _saving || _loadError != null ? null : _save,
          style: FilledButton.styleFrom(backgroundColor: Colors.indigo),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
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
}

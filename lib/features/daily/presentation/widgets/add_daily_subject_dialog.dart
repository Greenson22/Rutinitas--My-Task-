// lib/features/daily/presentation/widgets/add_daily_subject_dialog.dart

import 'package:flutter/material.dart';
import '../../data/models/daily_model.dart';

class AddDailySubjectDialog extends StatefulWidget {
  final Function(DailySubject newSubject) onSave;

  const AddDailySubjectDialog({super.key, required this.onSave});

  @override
  State<AddDailySubjectDialog> createState() => _AddDailySubjectDialogState();
}

class _AddDailySubjectDialogState extends State<AddDailySubjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _namaMateriController = TextEditingController();
  final _iconController = TextEditingController(text: '📚');
  final _subMateriInputController = TextEditingController();

  String _selectedSection = 'rutinitas_inti';
  final List<String> _subMateriItems = [];

  @override
  void dispose() {
    _namaMateriController.dispose();
    _iconController.dispose();
    _subMateriInputController.dispose();
    super.dispose();
  }

  void _addSubMateriItem() {
    final text = _subMateriInputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _subMateriItems.add(text);
      _subMateriInputController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Materi Harian Baru'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            children: [
              // Input Nama Materi
              TextFormField(
                controller: _namaMateriController,
                decoration: const InputDecoration(
                  labelText: 'Nama Materi / Rutinitas',
                  hintText: 'Contoh: Belajar Flutter, Olahraga',
                ),
                validator: (v) =>
                    v!.trim().isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 12),

              // Input Emoji Icon
              TextFormField(
                controller: _iconController,
                decoration: const InputDecoration(labelText: 'Emoji Ikon'),
                validator: (v) =>
                    v!.trim().isEmpty ? 'Ikon tidak boleh kosong' : null,
              ),
              const SizedBox(height: 12),

              // Pilihan Seksi / Kategori Penempatan
              DropdownButtonFormField<String>(
                value: _selectedSection,
                decoration: const InputDecoration(
                  labelText: 'Seksi Penempatan',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'fokus_utama',
                    child: Text('🎯 Fokus Utama'),
                  ),
                  DropdownMenuItem(
                    value: 'rutinitas_inti',
                    child: Text('🔄 Rutinitas Inti'),
                  ),
                  DropdownMenuItem(
                    value: 'aktivitas_pelengkap',
                    child: Text('🌱 Aktivitas Pelengkap'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSection = val);
                },
              ),
              const SizedBox(height: 16),

              const Divider(),
              const Text(
                'Daftar Sub-Materi Checklist (Opsional):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),

              // Input Tambah Item Sub-Materi
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _subMateriInputController,
                      decoration: const InputDecoration(
                        hintText: 'Tulis sub-materi...',
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_box, color: Colors.teal),
                    onPressed: _addSubMateriItem,
                  ),
                ],
              ),

              // Preview List Item yang akan ditambahkan
              if (_subMateriItems.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _subMateriItems.length,
                    itemBuilder: (context, idx) => ListTile(
                      dense: true,
                      title: Text(_subMateriItems[idx]),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 18,
                        ),
                        onPressed: () =>
                            setState(() => _subMateriItems.removeAt(idx)),
                      ),
                    ),
                  ),
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
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // Map list string ke object SubMateriItem model
              List<SubMateriItem> subMateriModels = _subMateriItems
                  .map(
                    (name) =>
                        SubMateriItem(namaMateri: name, progress: 'belum'),
                  )
                  .toList();

              final newSubject = DailySubject(
                namaMateri: _namaMateriController.text.trim(),
                icon: _iconController.text.trim(),
                section: _selectedSection,
                progress: 'belum',
                subMateri: subMateriModels,
                isHidden: false,
                backgroundColor: 4281166415, // Warna default (Tealish-Blue)
                textColor: 4294967295, // Putih
              );

              widget.onSave(newSubject);
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[700]),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

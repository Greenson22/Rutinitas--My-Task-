// lib/features/daily/presentation/widgets/add_daily_subject_dialog.dart

import 'package:flutter/material.dart';
import '../../data/models/daily_model.dart';
import 'package:flutter/services.dart'; // <--- Tambahkan ini di baris paling atas file

class AddDailySubjectDialog extends StatefulWidget {
  final Function(DailySubject newSubject) onSave;
  final List<String> existingSections;

  const AddDailySubjectDialog({
    super.key,
    required this.onSave,
    required this.existingSections, // <--- TAMBAHAN: Wajib diisi
  });

  @override
  State<AddDailySubjectDialog> createState() => _AddDailySubjectDialogState();
}

class _AddDailySubjectDialogState extends State<AddDailySubjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _namaMateriController = TextEditingController();
  final _iconController = TextEditingController(text: '📚');
  final _subMateriInputController = TextEditingController();

  late String _selectedSection;
  final List<String> _subMateriItems = [];

  @override
  void initState() {
    super.initState();
    // Mengeset nilai default dropdown ke seksi pertama yang tersedia,
    // atau string kosong jika belum ada seksi sama sekali.
    _selectedSection = widget.existingSections.isNotEmpty
        ? widget.existingSections.first
        : '';
  }

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
              // PERBAIKAN: Pilihan Seksi Penempatan Mengikuti Seksi Kustom Dinamis Hub
              if (widget.existingSections.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _selectedSection,
                  decoration: const InputDecoration(
                    labelText: 'Seksi Penempatan',
                  ),
                  // Render item dropdown secara otomatis dari daftar seksi yang ada
                  items: widget.existingSections.map((String sectionName) {
                    return DropdownMenuItem<String>(
                      value: sectionName,
                      child: Text('📁 $sectionName'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedSection = val);
                  },
                ),
              const SizedBox(height: 16),

              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Daftar Sub-Materi Checklist (Opsional):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  // === TOMBOL BARU: PASTE BANYAK LIST DARI CLIPBOARD ===
                  TextButton.icon(
                    icon: const Icon(
                      Icons.assignment_returned_outlined,
                      size: 16,
                      color: Colors.teal,
                    ),
                    label: const Text(
                      'Paste dari Clipboard',
                      style: TextStyle(fontSize: 11, color: Colors.teal),
                    ),
                    onPressed: () async {
                      ClipboardData? data = await Clipboard.getData(
                        Clipboard.kTextPlain,
                      );
                      if (data != null &&
                          data.text != null &&
                          data.text!.trim().isNotEmpty) {
                        List<String> lines = data.text!
                            .split('\n')
                            .where((line) => line.trim().isNotEmpty)
                            .toList();

                        if (lines.isEmpty) return;

                        // === TAHAP 1: DIALOG KONFIRMASI SEBELUM PASTE ===
                        bool? konfirmasi = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Konfirmasi Paste List'),
                            content: Text(
                              'Apakah Anda yakin ingin memasukkan ${lines.length} item dari clipboard Anda ke daftar sub-materi?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Batal'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                ),
                                child: const Text('Ya, Masukkan'),
                              ),
                            ],
                          ),
                        );

                        if (konfirmasi != true)
                          return; // Batalkan jika memilih tidak/batal

                        // Proses memasukkan data setelah dikonfirmasi
                        setState(() {
                          for (var line in lines) {
                            _subMateriItems.add(line.trim());
                          }
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Berhasil menempelkan ${lines.length} item list!',
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Clipboard kosong atau tidak valid.'),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Input Manual Satu per Satu (Tetap Dipertahankan)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _subMateriInputController,
                      decoration: const InputDecoration(
                        hintText: 'Tulis sub-materi manual...',
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

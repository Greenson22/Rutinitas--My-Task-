// lib/features/daily/presentation/widgets/daily_checklist_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/daily_model.dart';

class DailyChecklistDialog extends StatefulWidget {
  final DailySubject subject;
  final VoidCallback onDataChanged;

  const DailyChecklistDialog({
    super.key,
    required this.subject,
    required this.onDataChanged,
  });

  @override
  State<DailyChecklistDialog> createState() => _DailyChecklistDialogState();
}

class _DailyChecklistDialogState extends State<DailyChecklistDialog> {
  final TextEditingController _singleInputController = TextEditingController();

  @override
  void dispose() {
    _singleInputController.dispose();
    super.dispose();
  }

  // Fungsi konfirmasi umum
  Future<bool> _showConfirmDialog({
    required String title,
    required String content,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Konfirmasi'),
              ),
            ],
          ),
        ) ??
        false;
  }

  // Fungsi untuk menambah 1 sub-materi secara manual dengan konfirmasi
  Future<void> _addSingleSubMateri() async {
    final text = _singleInputController.text.trim();
    if (text.isEmpty) return;

    final confirm = await _showConfirmDialog(
      title: 'Tambah Sub-Materi',
      content: 'Apakah Anda yakin ingin menambahkan sub-materi "$text"?',
    );

    if (!confirm) return;

    setState(() {
      widget.subject.subMateri.add(
        SubMateriItem(namaMateri: text, progress: 'belum'),
      );
      _singleInputController.clear();
    });
    _updateSubjectOverallProgress();
    widget.onDataChanged();
  }

  // Fungsi untuk menempel banyak sub-materi dari clipboard dengan konfirmasi
  Future<void> _pasteSubMateriFromClipboard() async {
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null || data.text!.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clipboard kosong atau tidak valid')),
        );
      }
      return;
    }

    List<String> lines = data.text!
        .split(RegExp(r'\r?\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (lines.isEmpty) return;

    final confirm = await _showConfirmDialog(
      title: 'Tambah Banyak Sub-Materi',
      content:
          'Apakah Anda yakin ingin menambahkan ${lines.length} sub-materi dari clipboard?',
    );

    if (!confirm) return;

    setState(() {
      for (var line in lines) {
        widget.subject.subMateri.add(
          SubMateriItem(namaMateri: line, progress: 'belum'),
        );
      }
    });

    _updateSubjectOverallProgress();
    widget.onDataChanged();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berhasil menambahkan ${lines.length} sub-materi'),
        ),
      );
    }
  }

  // Fungsi untuk menghapus sub-materi dengan konfirmasi
  Future<void> _deleteSubMateri(SubMateriItem item) async {
    final confirm = await _showConfirmDialog(
      title: 'Hapus Sub-Materi',
      content: 'Apakah Anda yakin ingin menghapus "${item.namaMateri}"?',
    );

    if (!confirm) return;

    setState(() {
      widget.subject.subMateri.remove(item);
    });

    _updateSubjectOverallProgress();
    widget.onDataChanged();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sub-materi berhasil dihapus')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final belumSelesaiList = widget.subject.subMateri
        .where((item) => item.progress != 'selesai')
        .toList();
    final selesaiList = widget.subject.subMateri
        .where((item) => item.progress == 'selesai')
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Dialog
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(widget.subject.backgroundColor),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Text(
              widget.subject.namaMateri,
              style: TextStyle(
                color: Color(widget.subject.textColor),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // PANEL INPUT: Tambah Sub-Materi & Paste dari Clipboard
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _singleInputController,
                    decoration: const InputDecoration(
                      hintText: 'Tambah sub-materi baru...',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addSingleSubMateri(),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.add_box, color: Colors.teal),
                  tooltip: 'Tambah',
                  onPressed: _addSingleSubMateri,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.assignment_turned_in_rounded,
                    color: Colors.indigo,
                  ),
                  tooltip: 'Paste Banyak (Baris Baru)',
                  onPressed: _pasteSubMateriFromClipboard,
                ),
              ],
            ),
          ),
          const Divider(),

          // Konten List Item Checklist
          Flexible(
            child: widget.subject.subMateri.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text('Tidak ada item sub materi.'),
                  )
                : ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(12),
                    children: [
                      // SEKSI BELUM SELESAI
                      if (belumSelesaiList.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Text(
                            'Belum Selesai',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                        ...belumSelesaiList.map(
                          (item) => _buildChecklistTile(item),
                        ),
                      ],

                      if (belumSelesaiList.isNotEmpty && selesaiList.isNotEmpty)
                        const Divider(height: 24),

                      // SEKSI SELESAI
                      if (selesaiList.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Text(
                            'Selesai',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        ...selesaiList.map((item) => _buildChecklistTile(item)),
                      ],
                    ],
                  ),
          ),

          const Divider(height: 1),

          // Footer Panel Aksi
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    final confirm = await _showConfirmDialog(
                      title: 'Reset Semua Progress',
                      content:
                          'Apakah Anda yakin ingin mereset progress semua sub-materi kembali ke semula?',
                    );
                    if (!confirm) return;

                    setState(() {
                      for (var item in widget.subject.subMateri) {
                        item.progress = 'belum';
                        item.finishedDate = null;
                      }
                    });
                    widget.onDataChanged();
                  },
                  icon: const Icon(Icons.refresh, color: Colors.red, size: 18),
                  label: const Text(
                    'Reset',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(widget.subject.backgroundColor),
                  ),
                  child: Text(
                    'Tutup',
                    style: TextStyle(color: Color(widget.subject.textColor)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistTile(SubMateriItem item) {
    bool isChecked = item.progress == 'selesai';

    return Row(
      children: [
        Expanded(
          child: CheckboxListTile(
            title: Text(
              item.namaMateri,
              style: TextStyle(
                fontSize: 14,
                decoration: isChecked ? TextDecoration.lineThrough : null,
                color: isChecked ? Colors.grey : Colors.black87,
              ),
            ),
            value: isChecked,
            activeColor: Colors.teal,
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            contentPadding: EdgeInsets
                .zero, // Mengurangi padding bawaan agar muat dengan tombol hapus
            onChanged: (bool? checked) {
              setState(() {
                if (checked == true) {
                  item.progress = 'selesai';
                  final now = DateTime.now();
                  item.finishedDate =
                      "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
                } else {
                  item.progress = 'belum';
                  item.finishedDate = null;
                }
                _updateSubjectOverallProgress();
              });
              widget.onDataChanged();
            },
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.delete_outline,
            color: Colors.redAccent,
            size: 20,
          ),
          tooltip: 'Hapus Sub-materi',
          onPressed: () => _deleteSubMateri(item),
        ),
      ],
    );
  }

  void _updateSubjectOverallProgress() {
    int total = widget.subject.subMateri.length;
    int selesai = widget.subject.subMateri
        .where((sm) => sm.progress == 'selesai')
        .length;

    if (total == 0) {
      widget.subject.progress = 'belum';
    } else if (selesai == total) {
      widget.subject.progress = 'selesai';
    } else if (selesai > 0) {
      widget.subject.progress = 'sementara';
    } else {
      widget.subject.progress = 'belum';
    }
  }
}

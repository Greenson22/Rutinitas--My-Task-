// lib/features/daily/presentation/widgets/daily_checklist_dialog.dart

import 'package:flutter/material.dart';
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
  @override
  Widget build(BuildContext context) {
    // Memisahkan list secara visual menggunakan filtering (.where) tanpa mengacaukan susunan array asli
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
                  onPressed: () {
                    setState(() {
                      // RESET SEMUA KEMBALI KE POSISI SEMULA (PROGRESS: BELUM)
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

    return CheckboxListTile(
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

          // Update Status Progress Utama Subject
          _updateSubjectOverallProgress();
        });
        widget.onDataChanged();
      },
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

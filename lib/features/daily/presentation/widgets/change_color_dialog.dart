// lib/features/daily/presentation/widgets/change_color_dialog.dart

import 'package:flutter/material.dart';
import '../../data/models/daily_model.dart';

class ChangeColorDialog extends StatefulWidget {
  final DailySubject subject;
  final VoidCallback onColorSaved;

  const ChangeColorDialog({
    super.key,
    required this.subject,
    required this.onColorSaved,
  });

  @override
  State<ChangeColorDialog> createState() => _ChangeColorDialogState();
}

class _ChangeColorDialogState extends State<ChangeColorDialog> {
  late int _selectedBgColor;
  late int _selectedTextColor;

  @override
  void initState() {
    super.initState();
    _selectedBgColor = widget.subject.backgroundColor;
    _selectedTextColor = widget.subject.textColor;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: const [
          Icon(Icons.palette_outlined, color: Colors.teal),
          SizedBox(width: 8),
          Text('Ubah Warna Materi'),
        ],
      ),
      // PERBAIKAN: Bungkus isi kontent dengan SizedBox untuk mengatur width secara aman
      content: SizedBox(
        width: double
            .maxFinite, // Sekarang parameter width berada di tempat yang benar
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. LIVE PREVIEW COMPONENT
              const Text(
                'Pratinjau Tampilan:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(_selectedBgColor),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      widget.subject.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.subject.namaMateri,
                      style: TextStyle(
                        color: Color(_selectedTextColor),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Contoh Teks Sub-Materi / Detail',
                      style: TextStyle(
                        color: Color(_selectedTextColor).withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. PALETTE SELECTION GRID
              const Text(
                'Pilih Tema Warna:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: DailySubject.kustomPaletWarna.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, idx) {
                  final tema = DailySubject.kustomPaletWarna[idx];
                  final int bgHex = tema['bg'];
                  final int textHex = tema['text'];
                  final bool isSelected = _selectedBgColor == bgHex;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedBgColor = bgHex;
                        _selectedTextColor = textHex;
                      });
                    },
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(bgHex),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? Colors.black87
                              : Colors.grey.shade300,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: isSelected
                          ? Icon(Icons.check, color: Color(textHex), size: 18)
                          : const SizedBox.shrink(),
                    ),
                  );
                },
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
            widget.subject.backgroundColor = _selectedBgColor;
            widget.subject.textColor = _selectedTextColor;
            widget.onColorSaved();
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[700]),
          child: const Text(
            'Simpan Warna',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

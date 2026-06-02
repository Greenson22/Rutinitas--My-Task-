// lib/core/presentation/widgets/base_popup_dialog.dart
import 'package:flutter/material.dart';

class BasePopupDialog extends StatelessWidget {
  final Widget title;
  final Color themeColor;
  final Color titleColor;
  final Widget content;
  final Widget? footer; // Tambahan properti footer opsional

  const BasePopupDialog({
    super.key,
    required this.title,
    required this.themeColor,
    required this.titleColor,
    required this.content,
    this.footer, // Inisialisasi footer
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. HEADER (Warna Background & Judul)
          Container(
            width: double.infinity,
            // Hilangkan padding vertikal default yang terlalu tebal karena kita menggunakan icon button di header checklist
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: themeColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: title,
          ),

          // 2. KONTEN UTAMA (Body)
          Flexible(child: content),
          const Divider(height: 1),

          // 3. FOOTER (Gunakan custom jika ada, jika tidak gunakan default)
          footer ??
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                      ),
                      child: Text('Tutup', style: TextStyle(color: titleColor)),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

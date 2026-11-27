// lib/features/daily/presentation/widgets/checklist_detail/checklist_note_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // <--- BARU: Diperlukan untuk merender teks MD

class ChecklistNoteView extends StatelessWidget {
  final TextEditingController noteController;
  final Function(String) onChanged;
  final bool isMarkdownEnabled; // <--- BARU: Mengontrol status aktif format MD
  final bool isViewMode; // <--- BARU: Mengontrol mode pratinjau vs edit catatan

  const ChecklistNoteView({
    super.key,
    required this.noteController,
    required this.onChanged,
    required this.isMarkdownEnabled, // <--- BARU
    required this.isViewMode, // <--- BARU
  });

  @override
  Widget build(BuildContext context) {
    // =========================================================================
    // MODE VIEW & MARKDOWN AKTIF: Tampilkan Render Teks Kaya (Markdown)
    // =========================================================================
    if (isViewMode && isMarkdownEnabled) {
      final theme = Theme.of(context);
      final primaryColor = theme.colorScheme.primary;

      return Container(
        color: Colors.white,
        width: double.infinity,
        height: double.infinity,
        child: Markdown(
          padding: const EdgeInsets.all(16.0),
          data: noteController.text.isEmpty
              ? '*Catatan kosong.*'
              : noteController.text,
          selectable: true,
          styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
            p: const TextStyle(
              fontSize: 14.5,
              color: Colors.black87,
              height: 1.55,
            ),
            h1: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: primaryColor,
              height: 1.4,
            ),
            h2: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryColor,
              height: 1.4,
            ),
            h3: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: primaryColor,
              height: 1.4,
            ),
            listBullet: TextStyle(
              fontSize: 14.5,
              color: primaryColor,
              fontWeight: FontWeight.bold,
            ),
            code: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: Color(0xFF24292F),
              backgroundColor: Color(0xFFF3F4F6),
            ),
            codeblockPadding: const EdgeInsets.all(14),
            codeblockDecoration: BoxDecoration(
              color: const Color(0xFFF6F8FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD0D7DE)),
            ),
            blockquotePadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            blockquoteDecoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.06),
              border: Border(
                left: BorderSide(color: primaryColor, width: 4),
              ),
            ),
            horizontalRuleDecoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
          ),
        ),
      );
    }

    // =========================================================================
    // MODE EDIT / MARKDOWN NONAKTIF: Tampilkan Kolom TextField Utama
    // =========================================================================
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: noteController,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        readOnly:
            isViewMode, // Dikunci menjadi read-only jika sedang melihat dalam mode teks biasa
        style: TextStyle(
          fontFamily: isMarkdownEnabled
              ? 'Courier'
              : null, // Menggunakan Monospace jika MD menyala
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: isMarkdownEnabled
              ? 'Tulis catatan Anda di sini (Mendukung Markdown)...'
              : 'Tulis catatan Anda di sini...',
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.grey[400]),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

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
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16.0),
        width: double.infinity,
        height: double.infinity,
        child: Markdown(
          data: noteController.text.isEmpty
              ? '*Catatan kosong.*'
              : noteController.text,
          selectable: true,
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
            p: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
            h1: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
            h2: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
            h3: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
            code: TextStyle(
              backgroundColor: Colors.grey[200],
              color: Colors.red[700],
            ),
            codeblockDecoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
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

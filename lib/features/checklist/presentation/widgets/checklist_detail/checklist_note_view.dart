// lib/features/daily/presentation/widgets/checklist_detail/checklist_note_view.dart

import 'package:flutter/material.dart';

class ChecklistNoteView extends StatelessWidget {
  final TextEditingController noteController;
  final Function(String) onChanged;

  const ChecklistNoteView({
    super.key,
    required this.noteController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: noteController,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        decoration: InputDecoration(
          hintText: 'Tulis catatan Anda di sini...',
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.grey[400]),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

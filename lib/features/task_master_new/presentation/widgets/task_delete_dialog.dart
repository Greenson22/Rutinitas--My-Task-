import 'package:flutter/material.dart';

import '../../domain/entities/task.dart';

/// Dialog konfirmasi hapus tugas.
class DeleteTaskDialog extends StatelessWidget {
  const DeleteTaskDialog({super.key, required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final hasHistory = task.totalCount > 0 || task.history.isNotEmpty;

    return AlertDialog(
      title: const Text('Hapus tugas?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tugas "${task.name}" akan dihapus permanen.'),
          if (hasHistory) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.35),
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Seluruh hitungan dan riwayat harian tugas ini ikut '
                      'terhapus dan tidak dapat dikembalikan.',
                      style: TextStyle(fontSize: 12, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          key: const Key('deleteTaskCancelButton'),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          key: const Key('deleteTaskConfirmButton'),
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Hapus'),
        ),
      ],
    );
  }
}

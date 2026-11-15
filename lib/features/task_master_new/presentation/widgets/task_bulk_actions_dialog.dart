import 'package:flutter/material.dart';

import '../../domain/entities/category.dart';

/// Dialog konfirmasi hapus beberapa tugas sekaligus.
class BulkDeleteTasksDialog extends StatelessWidget {
  const BulkDeleteTasksDialog({super.key, required this.taskCount});

  final int taskCount;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Hapus $taskCount tugas?'),
      content: Text(
        '$taskCount tugas yang dipilih akan dihapus permanen beserta seluruh '
        'hitungan dan riwayat hariannya. Tindakan ini tidak dapat '
        'dikembalikan.',
      ),
      actions: [
        TextButton(
          key: const Key('bulkDeleteCancelButton'),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          key: const Key('bulkDeleteConfirmButton'),
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: Text('Hapus $taskCount tugas'),
        ),
      ],
    );
  }
}

/// Dialog pemilihan kategori tujuan saat memindahkan satu tugas.
class MoveTaskDialog extends StatelessWidget {
  const MoveTaskDialog({
    super.key,
    required this.taskName,
    required this.categories,
  });

  final String taskName;

  /// Kategori tujuan yang tersedia (kategori saat ini sudah dikecualikan).
  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pindahkan tugas'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pilih kategori tujuan untuk "$taskName". Tugas tetap memakai '
            'id, hitungan, dan riwayat yang sama.',
            style: const TextStyle(fontSize: 12, height: 1.45),
          ),
          const SizedBox(height: 10),
          if (categories.isEmpty)
            const Text('Belum ada kategori tujuan lain.')
          else
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final category in categories)
                      ListTile(
                        key: Key('moveTaskOption_${category.id}'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Text(
                          category.icon,
                          style: const TextStyle(fontSize: 18),
                        ),
                        title: Text(category.name),
                        onTap: () => Navigator.of(context).pop(category.id),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('moveTaskCancelButton'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
      ],
    );
  }
}

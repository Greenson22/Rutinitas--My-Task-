import 'package:flutter/material.dart';

import '../../domain/entities/category.dart';

/// Dialog konfirmasi hapus kategori, dengan peringatan bila masih berisi tugas.
class DeleteCategoryDialog extends StatelessWidget {
  const DeleteCategoryDialog({super.key, required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    final taskCount = category.tasks.length;

    return AlertDialog(
      title: const Text('Hapus kategori?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kategori "${category.name}" akan dihapus permanen.'),
          if (taskCount > 0) ...[
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Kategori ini masih memiliki $taskCount tugas. '
                      'Menghapus kategori juga akan menghapus semua tugas '
                      'dan riwayatnya.',
                      style: const TextStyle(fontSize: 12, height: 1.45),
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
          key: const Key('deleteCategoryCancelButton'),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          key: const Key('deleteCategoryConfirmButton'),
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

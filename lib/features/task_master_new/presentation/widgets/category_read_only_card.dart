import 'package:flutter/material.dart';

import '../../domain/entities/category.dart';
import 'task_read_only_tile.dart';

class CategoryReadOnlyCard extends StatelessWidget {
  const CategoryReadOnlyCard({
    super.key,
    required this.category,
    required this.todayKey,
  });

  final Category category;
  final String todayKey;

  @override
  Widget build(BuildContext context) {
    final tasks = [...category.tasks]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.indigo.withValues(alpha: 0.08),
                  child: Text(
                    category.icon,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            category.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (category.isHidden) const _HiddenBadge(),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${tasks.length} tugas',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blueGrey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            if (tasks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  'Belum ada tugas di kategori ini.',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.blueGrey[500],
                  ),
                ),
              )
            else
              ...tasks.map(
                (task) => TaskReadOnlyTile(task: task, todayKey: todayKey),
              ),
          ],
        ),
      ),
    );
  }
}

class _HiddenBadge extends StatelessWidget {
  const _HiddenBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.visibility_off, size: 11, color: Colors.blueGrey[600]),
          const SizedBox(width: 3),
          Text(
            'Disembunyikan',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey[600],
            ),
          ),
        ],
      ),
    );
  }
}

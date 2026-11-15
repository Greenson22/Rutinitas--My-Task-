import 'package:flutter/material.dart';

import '../../domain/entities/category.dart';
import 'task_tile.dart';

enum CategoryAction { edit, toggleHidden, delete }

/// Kartu kategori dengan ringkasan tugas dan aksi kelola.
class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.category,
    required this.todayKey,
    required this.onAction,
    required this.onOpen,
    this.isTaskJournalLinked,
  });

  final Category category;
  final String todayKey;
  final void Function(CategoryAction action) onAction;
  final VoidCallback onOpen;

  /// Menandai tugas yang tertaut ke aktivitas Jurnal.
  final bool Function(String taskId)? isTaskJournalLinked;

  @override
  Widget build(BuildContext context) {
    final tasks = [...category.tasks]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
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
                  PopupMenuButton<CategoryAction>(
                    key: Key('categoryMenu_${category.id}'),
                    tooltip: 'Aksi kategori',
                    onSelected: onAction,
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: CategoryAction.edit,
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Ubah'),
                        ),
                      ),
                      PopupMenuItem(
                        value: CategoryAction.toggleHidden,
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            category.isHidden
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          title: Text(
                            category.isHidden ? 'Tampilkan' : 'Sembunyikan',
                          ),
                        ),
                      ),
                      const PopupMenuItem(
                        value: CategoryAction.delete,
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          title: Text(
                            'Hapus',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
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
                  (task) => TaskTile(
                    task: task,
                    todayKey: todayKey,
                    showActiveStatus: false,
                    isJournalLinked:
                        isTaskJournalLinked?.call(task.id) ?? false,
                  ),
                ),
              const SizedBox(height: 2),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: Key('manageTasks_${category.id}'),
                  onPressed: onOpen,
                  icon: const Icon(Icons.tune, size: 18),
                  label: const Text('Kelola tugas'),
                ),
              ),
            ],
          ),
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

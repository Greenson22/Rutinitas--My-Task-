import 'package:flutter/material.dart';

import '../../domain/entities/category.dart';
import '../../domain/operations/dashboard_summary.dart';
import 'category_card.dart' show CategoryAction;

/// Kartu kategori ringkas pada dashboard.
///
/// Menampilkan ikon, nama, jumlah tugas aktif, dan ringkasan progres hari ini.
/// Detail tugas dibuka melalui halaman kategori agar dashboard tetap fokus.
class CategorySummaryCard extends StatelessWidget {
  const CategorySummaryCard({
    super.key,
    required this.category,
    required this.todayKey,
    required this.onAction,
    required this.onOpen,
  });

  final Category category;
  final String todayKey;
  final void Function(CategoryAction action) onAction;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final activeTasks = categoryActiveTaskCount(category);
    final targetTasks = categoryTargetTaskCount(category);
    final completedTargets = categoryCompletedTargetCount(category, todayKey);
    final activeToday = categoryActiveTodayCount(category, todayKey);

    return Card(
      key: Key('categoryCard_${category.id}'),
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 13, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 21,
                    backgroundColor: Colors.indigo.withValues(alpha: 0.08),
                    child: Text(
                      category.icon,
                      style: const TextStyle(fontSize: 19),
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
                              key: Key('manageTasks_${category.id}'),
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
                          '$activeTasks tugas aktif',
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
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      targetTasks == 0
                          ? 'Belum ada target hari ini'
                          : 'Hari ini $completedTargets / $targetTasks target',
                      key: Key('categoryProgress_${category.id}'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey[700],
                      ),
                    ),
                  ),
                  Text(
                    '$activeToday aktif hari ini',
                    style: TextStyle(fontSize: 11, color: Colors.blueGrey[500]),
                  ),
                ],
              ),
              if (targetTasks > 0) ...[
                const SizedBox(height: 7),
                Semantics(
                  label:
                      'Progres target ${category.name}: '
                      '$completedTargets dari $targetTasks',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: completedTargets / targetTasks,
                      minHeight: 6,
                      backgroundColor: Colors.indigo.withValues(alpha: 0.12),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.teal,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 2),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
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

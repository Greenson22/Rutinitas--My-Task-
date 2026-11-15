import 'package:flutter/material.dart';

import '../controllers/task_master_controller.dart';

/// Lembar bawah untuk mengubah urutan kategori.
///
/// Drag handle disediakan untuk pengguna pointer, sedangkan tombol panah
/// menjadi fallback aksesibilitas dan keyboard.
class CategoryReorderSheet extends StatelessWidget {
  const CategoryReorderSheet({super.key, required this.controller});

  final TaskMasterNewController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final categories = [...?controller.state.data?.categories]
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              key: const Key('categoryReorderSheet'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Urutkan kategori',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const Key('closeCategoryReorderButton'),
                      tooltip: 'Tutup',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const Text(
                  'Tarik pegangan untuk memindahkan kategori. Tombol panah '
                  'tersedia sebagai alternatif.',
                  style: TextStyle(fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: ReorderableListView.builder(
                    shrinkWrap: true,
                    buildDefaultDragHandles: false,
                    itemCount: categories.length,
                    onReorder: (oldIndex, newIndex) {
                      final target = newIndex > oldIndex
                          ? newIndex - 1
                          : newIndex;
                      if (target == oldIndex) return;
                      controller.reorderCategory(
                        categoryId: categories[oldIndex].id,
                        newIndex: target,
                      );
                    },
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return Card(
                        key: ValueKey('reorderCategory_${category.id}'),
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        color: Colors.indigo.withValues(alpha: 0.04),
                        child: ListTile(
                          contentPadding: const EdgeInsets.only(
                            left: 4,
                            right: 4,
                          ),
                          leading: ReorderableDragStartListener(
                            index: index,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Icons.drag_indicator_rounded,
                                key: Key('categoryDragHandle_${category.id}'),
                                color: Colors.blueGrey,
                              ),
                            ),
                          ),
                          title: Text(
                            '${category.icon} ${category.name}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: category.isHidden
                              ? const Text(
                                  'Disembunyikan',
                                  style: TextStyle(fontSize: 11),
                                )
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                key: Key('moveCategoryUp_${category.id}'),
                                tooltip: 'Naikkan ${category.name}',
                                visualDensity: VisualDensity.compact,
                                onPressed: index == 0
                                    ? null
                                    : () => controller.reorderCategory(
                                        categoryId: category.id,
                                        newIndex: index - 1,
                                      ),
                                icon: const Icon(
                                  Icons.keyboard_arrow_up_rounded,
                                ),
                              ),
                              IconButton(
                                key: Key('moveCategoryDown_${category.id}'),
                                tooltip: 'Turunkan ${category.name}',
                                visualDensity: VisualDensity.compact,
                                onPressed: index == categories.length - 1
                                    ? null
                                    : () => controller.reorderCategory(
                                        categoryId: category.id,
                                        newIndex: index + 1,
                                      ),
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

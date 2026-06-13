// lib/features/task_master/presentation/widgets/category_grid.dart

import 'package:flutter/material.dart';
import '../../data/models/task_model.dart';
import 'category_card.dart';

class CategoryGrid extends StatelessWidget {
  final List<TaskCategory> categoriesList;
  final bool isPageEditMode;
  final BoxConstraints constraints;
  final VoidCallback onToggleEditMode;
  final Function(TaskCategory) onTapCategory;
  final Function(TaskCategory) onEditCategory;
  final Function(TaskCategory) onDeleteCategory;
  final Function(TaskCategory) onToggleVisibility;
  final Function(int index, int direction) onMoveCategoryOrder;

  const CategoryGrid({
    super.key,
    required this.categoriesList,
    required this.isPageEditMode,
    required this.constraints,
    required this.onToggleEditMode,
    required this.onTapCategory,
    required this.onEditCategory,
    required this.onDeleteCategory,
    required this.onToggleVisibility,
    required this.onMoveCategoryOrder,
  });

  @override
  Widget build(BuildContext context) {
    int crossAxisCount = 2;
    if (constraints.maxWidth >= 1200) {
      crossAxisCount = 5;
    } else if (constraints.maxWidth >= 900) {
      crossAxisCount = 4;
    } else if (constraints.maxWidth >= 600) {
      crossAxisCount = 3;
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: isPageEditMode ? 1.3 : 1.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: categoriesList.length,
      itemBuilder: (context, index) {
        final category = categoriesList[index];
        return CategoryCard(
          category: category,
          isEditMode: isPageEditMode,
          onLongPress: onToggleEditMode,
          onTap: isPageEditMode ? () {} : () => onTapCategory(category),
          onEdit: () => onEditCategory(category),
          onDelete: () => onDeleteCategory(category),
          onToggleVisibility: () => onToggleVisibility(category),
          onMoveUp: index > 0 ? () => onMoveCategoryOrder(index, -1) : null,
          onMoveDown: index < categoriesList.length - 1
              ? () => onMoveCategoryOrder(index, 1)
              : null,
        );
      },
    );
  }
}

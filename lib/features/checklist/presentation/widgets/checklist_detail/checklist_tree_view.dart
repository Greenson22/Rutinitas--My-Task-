// lib/features/daily/presentation/widgets/checklist_detail/checklist_tree_view.dart

import 'package:flutter/material.dart';
import '../../../data/models/daily_model.dart';

class ChecklistTreeView extends StatelessWidget {
  final SubSubjectItem item;
  final int depth;
  final bool isEditMode;
  final List<SubSubjectItem> selectedItems;
  final SubSubjectItem? highlightedItem;
  final bool isFirst;
  final bool isLast;
  final Function(SubSubjectItem, bool) onSelectItem;
  final Function(SubSubjectItem, int) onMoveOrder;
  final VoidCallback onEditName;
  final VoidCallback onLongPressToggle;
  final Function(SubSubjectItem, bool?) onCheckStatusChanged; // <-- Diperbarui
  final Function(SubSubjectItem) onTapToggleStatus; // <-- Diperbarui
  final VoidCallback onAddChild;
  final VoidCallback onDeleteItem;

  const ChecklistTreeView({
    super.key,
    required this.item,
    required this.depth,
    required this.isEditMode,
    required this.selectedItems,
    required this.highlightedItem,
    required this.isFirst,
    required this.isLast,
    required this.onSelectItem,
    required this.onMoveOrder,
    required this.onEditName,
    required this.onLongPressToggle,
    required this.onCheckStatusChanged,
    required this.onTapToggleStatus,
    required this.onAddChild,
    required this.onDeleteItem,
  });

  @override
  Widget build(BuildContext context) {
    bool isChecked = item.progress == 'selesai';
    bool isCurrentlySelected = selectedItems.contains(item);
    bool isHighlighted = highlightedItem == item;
    double paddingLeft = (depth * 14.0).clamp(0.0, 48.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(vertical: 1),
          decoration: BoxDecoration(
            color: isHighlighted
                ? Colors.amber.withOpacity(0.35)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          padding: EdgeInsets.fromLTRB(paddingLeft, 2, 4, 2),
          child: Row(
            children: [
              if (isEditMode) ...[
                Checkbox(
                  value: isCurrentlySelected,
                  activeColor: Colors.indigo,
                  onChanged: (bool? checked) =>
                      onSelectItem(item, checked == true),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_upward, size: 16),
                  color: isFirst ? Colors.grey[300] : Colors.indigo,
                  onPressed: isFirst ? null : () => onMoveOrder(item, -1),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(2),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward, size: 16),
                  color: isLast ? Colors.grey[300] : Colors.indigo,
                  onPressed: isLast ? null : () => onMoveOrder(item, 1),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(2),
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: isEditMode
                    ? InkWell(
                        onTap: onEditName,
                        onLongPress: onLongPressToggle,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 4.0,
                          ),
                          child: Row(
                            children: [
                              if (item.subMateri.isNotEmpty)
                                const Icon(
                                  Icons.account_tree_outlined,
                                  size: 16,
                                  color: Colors.indigo,
                                ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item.subjectName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.edit_note,
                                color: Colors.blueGrey,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          Checkbox(
                            value: isChecked,
                            activeColor: Colors.teal,
                            onChanged: (bool? checked) => onCheckStatusChanged(
                              item,
                              checked,
                            ), // <-- Diperbarui
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () =>
                                  onTapToggleStatus(item), // <-- Diperbarui
                              onLongPress: onLongPressToggle,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Text(
                                  item.subjectName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    decoration: isChecked
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: isChecked
                                        ? Colors.grey
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              if (isEditMode) ...[
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.teal,
                    size: 18,
                  ),
                  onPressed: onAddChild,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                  onPressed: onDeleteItem,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
              ],
            ],
          ),
        ),
        if (item.subMateri.isNotEmpty)
          Column(
            children: List.generate(item.subMateri.length, (index) {
              final child = item.subMateri[index];
              return ChecklistTreeView(
                item: child,
                depth: depth + 1,
                isEditMode: isEditMode,
                selectedItems: selectedItems,
                highlightedItem: highlightedItem,
                isFirst: index == 0,
                isLast: index == item.subMateri.length - 1,
                onSelectItem: onSelectItem,
                onMoveOrder: onMoveOrder,
                onEditName: onEditName,
                onLongPressToggle: onLongPressToggle,
                onCheckStatusChanged:
                    onCheckStatusChanged, // <-- Diteruskan dengan aman
                onTapToggleStatus:
                    onTapToggleStatus, // <-- Diteruskan dengan aman
                onAddChild: onAddChild,
                onDeleteItem: onDeleteItem,
              );
            }),
          ),
      ],
    );
  }
}

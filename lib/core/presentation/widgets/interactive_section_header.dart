import 'package:flutter/material.dart';

class InteractiveSectionHeader extends StatelessWidget {
  final String sectionName;
  final Color themeColor;
  final bool isEditMode;
  final bool isFirst;
  final bool isLast;

  // Aksi
  final VoidCallback onToggleEdit;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback onEditName;
  final VoidCallback onDelete;
  final VoidCallback onAddItem;

  const InteractiveSectionHeader({
    super.key,
    required this.sectionName,
    required this.themeColor,
    required this.isEditMode,
    required this.isFirst,
    required this.isLast,
    required this.onToggleEdit,
    this.onMoveUp,
    this.onMoveDown,
    required this.onEditName,
    required this.onDelete,
    required this.onAddItem,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        splashColor: themeColor.withOpacity(0.1),
        highlightColor: themeColor.withOpacity(0.05),
        onLongPress: onToggleEdit,
        onTap: () {},
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: isEditMode
              ? const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0)
              : const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    sectionName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: themeColor,
                      letterSpacing: 0.8,
                    ),
                  ),
                  if (isEditMode)
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_upward,
                            size: 18,
                            color: Colors.blueGrey,
                          ),
                          onPressed: isFirst ? null : onMoveUp,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_downward,
                            size: 18,
                            color: Colors.blueGrey,
                          ),
                          onPressed: isLast ? null : onMoveDown,
                        ),
                        IconButton(
                          icon: Icon(Icons.edit, size: 18, color: themeColor),
                          onPressed: onEditName,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            size: 18,
                            color: Colors.redAccent,
                          ),
                          onPressed: onDelete,
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.add_circle_outline,
                            color: themeColor,
                            size: 18,
                          ),
                          onPressed: onAddItem,
                        ),
                      ],
                    ),
                ],
              ),
              const Divider(height: 2, thickness: 1),
            ],
          ),
        ),
      ),
    );
  }
}

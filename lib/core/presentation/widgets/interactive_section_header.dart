import 'package:flutter/material.dart';

class InteractiveSectionHeader extends StatelessWidget {
  final String sectionName;
  final Color themeColor;
  final bool isEditMode;
  final bool isFirst;
  final bool isLast;
  final bool isUpperCase;

  // Aksi
  final VoidCallback onToggleEdit;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback onEditName;
  final VoidCallback onDelete;
  final VoidCallback onAddItem;
  final VoidCallback? onToggleVisibility;
  final bool? isHidden;
  final VoidCallback? onToggleCollapse;
  final bool? isCollapsed;

  const InteractiveSectionHeader({
    super.key,
    required this.sectionName,
    required this.themeColor,
    required this.isEditMode,
    this.isUpperCase = true,
    required this.isFirst,
    required this.isLast,
    required this.onToggleEdit,
    this.onMoveUp,
    this.onMoveDown,
    required this.onEditName,
    required this.onDelete,
    required this.onAddItem,
    this.onToggleVisibility,
    this.isHidden,
    this.onToggleCollapse,
    this.isCollapsed,
  });

  @override
  Widget build(BuildContext context) {
    final String displayedTitle = isUpperCase
        ? sectionName.toUpperCase()
        : sectionName;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        splashColor: themeColor.withOpacity(0.1),
        highlightColor: themeColor.withOpacity(0.05),
        onLongPress: onToggleEdit,
        onTap: onToggleCollapse,
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onToggleCollapse != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: Icon(
                            isCollapsed == true
                                ? Icons.chevron_right
                                : Icons.expand_more,
                            size: 20,
                            color: themeColor,
                          ),
                        ),
                      Text(
                        displayedTitle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isHidden == true
                              ? themeColor.withValues(alpha: 0.5)
                              : themeColor,
                          letterSpacing: 0.8,
                        ),
                      ),
                      if (isHidden == true) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Tersembunyi',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.blueGrey,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onToggleVisibility != null)
                        IconButton(
                          icon: Icon(
                            isHidden == true
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 18,
                            color: isHidden == true
                                ? Colors.grey
                                : themeColor,
                          ),
                          tooltip: isHidden == true
                              ? 'Tampilkan Seksi'
                              : 'Sembunyikan Seksi',
                          onPressed: onToggleVisibility,
                        ),
                      if (isEditMode) ...[
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

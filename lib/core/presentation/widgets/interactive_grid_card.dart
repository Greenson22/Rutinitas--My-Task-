import 'package:flutter/material.dart';

class InteractiveGridCard extends StatelessWidget {
  final Color themeColor;
  final Widget content;
  final bool isEditMode;
  final bool isFirst;
  final bool isLast;
  final bool isHiddenStyle;

  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback? onMoveLeft;
  final VoidCallback? onMoveRight;
  final List<PopupMenuEntry<String>> popupMenuItems;
  final Function(String) onPopupSelected;

  const InteractiveGridCard({
    super.key,
    required this.themeColor,
    required this.content,
    required this.isEditMode,
    this.isFirst = false,
    this.isLast = false,
    this.isHiddenStyle = false,
    required this.onTap,
    required this.onLongPress,
    this.onMoveLeft,
    this.onMoveRight,
    required this.popupMenuItems,
    required this.onPopupSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isHiddenStyle ? Colors.grey : themeColor,
          width: 3.5,
        ),
      ),
      color: Colors.white,
      child: Column(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(16),
                bottom: Radius.circular(
                  isEditMode ? 0 : 16,
                ), // Berubah jadi tegak lurus jika mode edit
              ),
              onLongPress: onLongPress,
              onTap: isEditMode ? null : onTap,
              child: SizedBox.expand(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: content, // Masukkan layout Ikon, Text, Label ke sini
                ),
              ),
            ),
          ),
          if (isEditMode)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 18),
                    color: isFirst ? Colors.grey[300] : themeColor,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: isFirst ? null : onMoveLeft,
                  ),
                  PopupMenuButton<String>(
                    onSelected: onPopupSelected,
                    itemBuilder: (context) => popupMenuItems,
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.more_vert,
                      size: 18,
                      color: Colors.blueGrey,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    color: isLast ? Colors.grey[300] : themeColor,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: isLast ? null : onMoveRight,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

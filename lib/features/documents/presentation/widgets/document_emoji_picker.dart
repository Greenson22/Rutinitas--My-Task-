import 'package:flutter/material.dart';

/// Picker emoji terkurasi yang dipakai bersama untuk ikon group dan folder.
class DocumentEmojiPicker extends StatelessWidget {
  final String selectedEmoji;
  final ValueChanged<String> onSelected;

  const DocumentEmojiPicker({
    super.key,
    required this.selectedEmoji,
    required this.onSelected,
  });

  static const List<String> curatedEmojis = [
    '📁', '📂', '📄', '📝', '📚', '📖', '🗂️', '🗃️',
    '💼', '🏢', '🎓', '🏫', '🏠', '🏥', '🏦', '⚖️',
    '💡', '📌', '📎', '🔖', '🏷️', '🔒', '🔑', '⭐',
    '❤️', '🎯', '🚀', '🛠️', '⚙️', '💻', '📱', '📷',
    '🎵', '🎬', '🎨', '✈️', '🚗', '🧾', '💰', '📊',
  ];

  @override
  Widget build(BuildContext context) {
    final options = curatedEmojis.contains(selectedEmoji)
        ? curatedEmojis
        : [selectedEmoji, ...curatedEmojis];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Ikon:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(selectedEmoji, style: const TextStyle(fontSize: 20)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 150,
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final emoji = options[index];
              final isSelected = emoji == selectedEmoji;
              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onSelected(emoji),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.indigo.withValues(alpha: 0.18)
                        : Colors.transparent,
                    border: isSelected
                        ? Border.all(color: Colors.indigo, width: 1.5)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 20)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

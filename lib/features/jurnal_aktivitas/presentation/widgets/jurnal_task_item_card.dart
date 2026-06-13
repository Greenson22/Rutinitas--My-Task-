// lib/features/jurnal_aktivitas/presentation/widgets/jurnal_task_item_card.dart
import 'package:flutter/material.dart';
import '../../data/models/time_log_model.dart';

class JurnalTaskItemCard extends StatelessWidget {
  final TimeLogTask task;
  final int index;
  final int totalTasks;
  final bool isEditMode;
  final bool isLinked;
  final VoidCallback onLongPress;
  final Function(int direction) onMoveOrder;
  final VoidCallback onLinkTap;
  final VoidCallback onEditTap;
  final VoidCallback onDeleteTap;
  final VoidCallback onEditDurationTap;
  final VoidCallback onAddDurationTap;

  const JurnalTaskItemCard({
    super.key,
    required this.task,
    required this.index,
    required this.totalTasks,
    required this.isEditMode,
    required this.isLinked,
    required this.onLongPress,
    required this.onMoveOrder,
    required this.onLinkTap,
    required this.onEditTap,
    required this.onDeleteTap,
    required this.onEditDurationTap,
    required this.onAddDurationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onLongPress: onLongPress,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isEditMode ? Colors.amber[50] : Colors.teal[50],
          radius: 16,
          child: Icon(
            isEditMode ? Icons.edit_attributes : Icons.check_circle_outline,
            color: isEditMode ? Colors.amber[800] : Colors.teal,
            size: 18,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.nama,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (isLinked)
                  Padding(
                    padding: const EdgeInsets.only(left: 6.0),
                    child: Tooltip(
                      message: 'Terhubung dengan Task Master',
                      triggerMode: TooltipTriggerMode.tap,
                      child: const Icon(
                        Icons.link,
                        size: 16,
                        color: Colors.teal,
                      ),
                    ),
                  ),
              ],
            ),
            if (isEditMode) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8.0,
                runSpacing: 6.0,
                children: [
                  _buildMobileButton(
                    icon: Icons.arrow_upward,
                    color: index > 0 ? Colors.indigo : Colors.grey[300]!,
                    onPressed: index > 0 ? () => onMoveOrder(-1) : null,
                  ),
                  _buildMobileButton(
                    icon: Icons.arrow_downward,
                    color: index < totalTasks - 1
                        ? Colors.indigo
                        : Colors.grey[300]!,
                    onPressed: index < totalTasks - 1
                        ? () => onMoveOrder(1)
                        : null,
                  ),
                  _buildMobileButton(
                    icon: Icons.link,
                    color: Colors.teal,
                    onPressed: onLinkTap,
                  ),
                  _buildMobileButton(
                    icon: Icons.edit_note,
                    color: Colors.blueGrey,
                    onPressed: onEditTap,
                  ),
                  _buildMobileButton(
                    icon: Icons.delete_outline,
                    color: Colors.redAccent,
                    onPressed: onDeleteTap,
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: isEditMode
            ? const SizedBox.shrink()
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: onEditDurationTap,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Text(
                        ' ${task.durasiMenit} mnt',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[900],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle,
                      color: Colors.indigo,
                      size: 22,
                    ),
                    padding: const EdgeInsets.all(4),
                    onPressed: onAddDurationTap,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildMobileButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: onPressed == null ? Colors.grey[100] : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: onPressed == null
                ? Colors.grey[200]!
                : color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onPressed == null ? Colors.grey[400] : color,
        ),
      ),
    );
  }
}

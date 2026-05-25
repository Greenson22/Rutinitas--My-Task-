// lib/features/daily/presentation/widgets/daily_subtasks_dialog.dart

import 'package:flutter/material.dart';
import '../../../task_master/data/models/task_model.dart';

class DailySubtasksDialog extends StatefulWidget {
  final TaskItem task;
  final VoidCallback onDataChanged;

  const DailySubtasksDialog({
    super.key,
    required this.task,
    required this.onDataChanged,
  });

  @override
  State<DailySubtasksDialog> createState() => _DailySubtasksDialogState();
}

class _DailySubtasksDialogState extends State<DailySubtasksDialog> {
  final TextEditingController _newSubTaskController = TextEditingController();

  void _addSubTask() {
    final text = _newSubTaskController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      widget.task.subTasks.add(
        SubTaskItem(id: TaskItem.generateRandomId(), name: text, isDone: false),
      );
    });
    _newSubTaskController.clear();
    widget.onDataChanged();
  }

  @override
  void dispose() {
    _newSubTaskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Memisahkan daftar subtask untuk tampilan visual tanpa merubah index asli array
    final uncompletedSubTasks = widget.task.subTasks
        .where((st) => !st.isDone)
        .toList();
    final completedSubTasks = widget.task.subTasks
        .where((st) => st.isDone)
        .toList();

    return AlertDialog(
      title: Text('List Materi: ${widget.task.name}'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Input Tambah List SubTask Baru
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newSubTaskController,
                    decoration: const InputDecoration(
                      hintText: 'Tambah list baru...',
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_box, color: Colors.indigo),
                  onPressed: _addSubTask,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // List Konten
            Expanded(
              child: ListView(
                shrinkWrap: true,
                children: [
                  if (uncompletedSubTasks.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        'Belum Selesai',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                    ...uncompletedSubTasks.map(
                      (subTask) => _buildSubTaskTile(subTask),
                    ),
                  ],
                  if (completedSubTasks.isNotEmpty) ...[
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        'Selesai',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    ...completedSubTasks.map(
                      (subTask) => _buildSubTaskTile(subTask),
                    ),
                  ],
                  if (widget.task.subTasks.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: Text('Belum ada list item.')),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Fitur Reset: Mengembalikan semua status ke Belum Selesai (false)
            setState(() {
              for (var st in widget.task.subTasks) {
                st.isDone = false;
              }
            });
            widget.onDataChanged();
          },
          child: const Text('Reset List', style: TextStyle(color: Colors.red)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    );
  }

  Widget _buildSubTaskTile(SubTaskItem subTask) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(
        subTask.name,
        style: TextStyle(
          decoration: subTask.isDone ? TextDecoration.lineThrough : null,
          color: subTask.isDone ? Colors.grey : Colors.black87,
        ),
      ),
      leading: Checkbox(
        value: subTask.isDone,
        activeColor: Colors.indigo,
        onChanged: (bool? value) {
          setState(() {
            subTask.isDone = value ?? false;
          });
          widget.onDataChanged();
        },
      ),
      trailing: IconButton(
        icon: const Icon(
          Icons.delete_outline,
          size: 18,
          color: Colors.redAccent,
        ),
        onPressed: () {
          setState(() {
            widget.task.subTasks.removeWhere((st) => st.id == subTask.id);
          });
          widget.onDataChanged();
        },
      ),
    );
  }
}

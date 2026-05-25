import 'package:flutter/material.dart';
import '../../data/models/task_model.dart';
import 'edit_task_dialog.dart'; // Import dialog edit detail baru

class TasksDialog extends StatelessWidget {
  final TaskCategory category;
  final Function(TaskItem) onIncrementTask;
  final Function(TaskItem, int) onUpdateTargetToday;
  // Tambahkan callback untuk edit detail dan hapus tugas
  final Function(TaskItem, String, int, int, int, int, String?)
  onEditTaskDetail;
  final Function(TaskItem) onDeleteTask;

  const TasksDialog({
    super.key,
    required this.category,
    required this.onIncrementTask,
    required this.onUpdateTargetToday,
    required this.onEditTaskDetail,
    required this.onDeleteTask,
  });

  void _showTargetInputDialog(
    BuildContext context,
    TaskItem task,
    StateSetter setDialogState,
  ) {
    final controller = TextEditingController(
      text: task.targetCountToday.toString(),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Set Target Hari Ini (${task.name})'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Jumlah Target'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              final newTarget =
                  int.tryParse(controller.text) ?? task.targetCountToday;
              onUpdateTargetToday(task, newTarget);
              setDialogState(() {});
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // Fungsi untuk menampilkan form edit detail tugas lengkap
  void _showEditTaskDetailDialog(
    BuildContext context,
    TaskItem task,
    StateSetter setDialogState,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => EditTaskDialog(
        task: task,
        onSave:
            ({
              required newCount,
              required newCountToday,
              required newDate,
              required newName,
              required newTargetCount,
              required newTargetCountToday,
            }) {
              onEditTaskDetail(
                task,
                newName,
                newCount,
                newCountToday,
                newTargetCount,
                newTargetCountToday,
                newDate,
              );
              setDialogState(
                () {},
              ); // Memicu re-render UI dialog tugas secara instan
            },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setDialogState) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: const BoxDecoration(
                  color: Colors.indigo,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20.0),
                    topRight: Radius.circular(20.0),
                  ),
                ),
                child: Text(
                  'Kategori ${category.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Flexible(
                child: category.tasks.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text('Tidak ada tugas aktif di kategori ini.'),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: category.tasks.length,
                        itemBuilder: (context, index) {
                          final task = category.tasks[index];
                          String subtitleText =
                              '+${task.countToday} / ${task.targetCountToday} hari ini | Total: ${task.count} / ${task.targetCount}';
                          if (task.date != null) {
                            subtitleText += ' | Update: ${task.date}';
                          }

                          return ListTile(
                            dense: true,
                            leading: IconButton(
                              icon: const Icon(
                                Icons.add_circle_outline,
                                color: Colors.blue,
                                size: 28,
                              ),
                              onPressed: () {
                                onIncrementTask(task);
                                setDialogState(() {});
                              },
                            ),
                            title: Text(
                              task.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: InkWell(
                              onTap: () => _showTargetInputDialog(
                                context,
                                task,
                                setDialogState,
                              ),
                              child: Text(
                                subtitleText,
                                style: const TextStyle(
                                  color: Colors.blueGrey,
                                  fontSize: 11,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            // === UBAH TOMBOL TITIK TIGA MENJADI POPUP MENU ===
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert,
                                color: Colors.grey,
                              ),
                              padding: EdgeInsets.zero,
                              onSelected: (value) {
                                if (value == 'edit_detail') {
                                  _showEditTaskDetailDialog(
                                    context,
                                    task,
                                    setDialogState,
                                  );
                                } else if (value == 'delete_task') {
                                  onDeleteTask(task);
                                  setDialogState(
                                    () {},
                                  ); // Menghapus item dari list view dialog
                                }
                              },
                              itemBuilder: (BuildContext context) => [
                                const PopupMenuItem<String>(
                                  value: 'edit_detail',
                                  child: ListTile(
                                    leading: Icon(Icons.edit_note, size: 20),
                                    title: Text('Edit Detail'),
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                  ),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'delete_task',
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    title: Text(
                                      'Hapus',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tutup'),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Tambah Tugas'),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

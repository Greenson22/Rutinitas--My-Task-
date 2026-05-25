// lib/features/task_master/presentation/widgets/tasks_dialog.dart

import 'package:flutter/material.dart';
import '../../data/models/task_model.dart';
import 'edit_task_dialog.dart';

class TasksDialog extends StatelessWidget {
  final TaskCategory category;
  final Future<bool> Function(TaskItem) onIncrementTask;
  final Function(TaskItem, int) onUpdateTargetToday;
  final Function(TaskItem, String, int, int, int, int, String?, bool)
  onEditTaskDetail; // <--- TAMBAH PARAMS BOOL DI AKHIR
  final Future<bool> Function(TaskItem) onDeleteTask;

  const TasksDialog({
    super.key,
    required this.category,
    required this.onIncrementTask,
    required this.onUpdateTargetToday,
    required this.onEditTaskDetail,
    required this.onDeleteTask,
  });

  List<TextSpan> _buildIndonesianDateSpans(String? dateStr, bool isActive) {
    if (dateStr == null || dateStr.trim().isEmpty) return [];

    try {
      final DateTime parsedDate = DateTime.parse(dateStr);

      const List<String> namaHari = [
        'Senin',
        'Selasa',
        'Rabu',
        'Kamis',
        'Jumat',
        'Sabtu',
        'Minggu',
      ];
      const List<String> namaBulan = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember',
      ];

      final String hari = '(${namaHari[parsedDate.weekday - 1]}) ';
      final String tanggal = '${parsedDate.day} ';
      final String bulan = '${namaBulan[parsedDate.month - 1]} ';
      final String tahun = '${parsedDate.year}';

      return [
        TextSpan(
          text: ' | Update: ',
          style: TextStyle(
            color: isActive ? Colors.blueGrey : Colors.grey[400],
          ),
        ),
        TextSpan(
          text: hari,
          style: TextStyle(
            color: isActive ? Colors.purple[900] : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextSpan(
          text: tanggal,
          style: TextStyle(
            color: isActive ? Colors.pink[700] : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextSpan(
          text: bulan,
          style: TextStyle(
            color: isActive ? Colors.teal[700] : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextSpan(
          text: tahun,
          style: TextStyle(
            color: isActive ? Colors.deepOrange[700] : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ];
    } catch (_) {
      return [
        TextSpan(
          text: ' | Update: $dateStr',
          style: TextStyle(color: isActive ? Colors.purple : Colors.grey),
        ),
      ];
    }
  }

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
              required newIsActive, // <--- TANGKAP DATA SWITCH
            }) {
              onEditTaskDetail(
                task,
                newName,
                newCount,
                newCountToday,
                newTargetCount,
                newTargetCountToday,
                newDate,
                newIsActive, // <--- EVALUASI DATA KE CALLBACK UTAMA
              );
              setDialogState(() {});
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

                          String? todayText;
                          Color? todayColor;

                          if (task.targetCountToday == 0) {
                            if (task.countToday > 0) {
                              todayText = '+${task.countToday} hari ini';
                              todayColor = task.isActive
                                  ? Colors.green[700]!
                                  : Colors.grey;
                            } else {
                              todayText = null;
                            }
                          } else {
                            todayText =
                                '+${task.countToday} / ${task.targetCountToday} hari ini';
                            if (task.countToday >= task.targetCountToday) {
                              todayColor = task.isActive
                                  ? Colors.green[700]!
                                  : Colors.grey;
                            } else {
                              todayColor = task.isActive
                                  ? Colors.orange[700]!
                                  : Colors.grey;
                            }
                          }

                          String totalText = (todayText == null)
                              ? 'Total: ${task.count} / ${task.targetCount}'
                              : ' | Total: ${task.count} / ${task.targetCount}';

                          return ListTile(
                            dense: true,
                            // JIKA NONAKTIF, TOMBOL PLUS MATI & BERWARNA ABU-ABU
                            leading: IconButton(
                              icon: Icon(
                                Icons.add_circle_outline,
                                color: task.isActive
                                    ? Colors.blue
                                    : Colors.grey[400],
                                size: 28,
                              ),
                              onPressed: task.isActive
                                  ? () async {
                                      bool isUpdated = await onIncrementTask(
                                        task,
                                      );
                                      if (isUpdated) {
                                        setDialogState(() {});
                                      }
                                    }
                                  : null, // <--- KUNCI INPUT COUNT
                            ),
                            title: Text(
                              task.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: task.isActive
                                    ? Colors.black87
                                    : Colors
                                          .grey, // <--- WARNA TEKS UTAMA ABU-ABU
                              ),
                            ),
                            subtitle: Text.rich(
                              TextSpan(
                                children: [
                                  if (todayText != null)
                                    TextSpan(
                                      text: todayText,
                                      style: TextStyle(
                                        color: todayColor,
                                        fontWeight:
                                            (task.countToday >=
                                                        task.targetCountToday ||
                                                    task.targetCountToday ==
                                                        0) &&
                                                task.isActive
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  TextSpan(
                                    text: totalText,
                                    style: TextStyle(
                                      color: task.isActive
                                          ? Colors.blue[800]
                                          : Colors.grey,
                                    ),
                                  ),
                                  ..._buildIndonesianDateSpans(
                                    task.date,
                                    task.isActive,
                                  ),
                                ],
                              ),
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert,
                                color: Colors.grey,
                              ),
                              padding: EdgeInsets.zero,
                              onSelected: (value) async {
                                if (value == 'edit_detail') {
                                  _showEditTaskDetailDialog(
                                    context,
                                    task,
                                    setDialogState,
                                  );
                                } else if (value == 'delete_task') {
                                  bool isDeleted = await onDeleteTask(task);
                                  if (isDeleted) {
                                    setDialogState(() {});
                                  }
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

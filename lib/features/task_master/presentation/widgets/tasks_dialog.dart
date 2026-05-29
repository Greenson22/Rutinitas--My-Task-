// lib/features/task_master/presentation/widgets/tasks_dialog.dart

import 'package:flutter/material.dart';
import '../../data/models/task_model.dart';
import 'edit_task_dialog.dart';

class TasksDialog extends StatelessWidget {
  final TaskCategory category;
  final List<TaskCategory> allCategories;
  final Future<bool> Function(TaskItem) onIncrementTask;
  final Function(TaskItem, int) onUpdateTargetToday;
  final Function(TaskItem, String, int, int, int, int, String?, bool, int)
  onEditTaskDetail;
  final Future<bool> Function(TaskItem) onDeleteTask;
  final Function(List<String>, String) onBulkAction;
  final VoidCallback onAddTask; // <--- CALLBACK BARU UNTUK TAMBAH TUGAS
  final Function(TaskItem task, TaskCategory source, TaskCategory target)
  onMoveTaskCategory;
  final Function() onReorderTasks;

  const TasksDialog({
    super.key,
    required this.category,
    required this.allCategories,
    required this.onIncrementTask,
    required this.onUpdateTargetToday,
    required this.onEditTaskDetail,
    required this.onDeleteTask,
    required this.onBulkAction,
    required this.onAddTask,
    required this.onMoveTaskCategory,
    required this.onReorderTasks,
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
              required newIsActive,
              required newType,
            }) {
              // SEKARANG SUDAH AMAN: Parameter ke-9 sudah didefinisikan di konstruktor atas
              onEditTaskDetail(
                task,
                newName,
                newCount,
                newCountToday,
                newTargetCount,
                newTargetCountToday,
                newDate,
                newIsActive,
                newType,
              );
              setDialogState(() {});
            },
      ),
    );
  }

  // DIALOG KONFIRMASI UNTUK INCREMENT COUNT TUGAS SATUAN
  Future<void> _showConfirmIncrementDialog(
    BuildContext context,
    TaskItem task,
    VoidCallback onConfirm,
  ) async {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Progress?'),
        content: Text(
          'Apakah Anda yakin ingin menambah hitungan (count) pada tugas "${task.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              onConfirm();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            child: const Text('Ya, Tambah'),
          ),
        ],
      ),
    );
  }

  Future<void> _showConfirmBulkDialog(
    BuildContext context,
    String action,
    int count,
    VoidCallback onConfirm,
  ) async {
    String title = '';
    String content = '';

    if (action == 'delete') {
      title = 'Hapus $count Tugas sekaligus?';
      content = 'Tugas yang dihapus tidak dapat dikembalikan.';
    } else if (action == 'activate') {
      title = 'Aktifkan $count Tugas?';
      content = 'Tugas yang dipilih akan dihitung kembali di ringkasan.';
    } else {
      title = 'Nonaktifkan $count Tugas?';
      content = 'Tugas yang dinonaktifkan tidak akan dihitung di ringkasan.';
    }

    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              onConfirm();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'delete' ? Colors.red : Colors.indigo,
            ),
            child: const Text('Ya, Konfirmasi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isSelectionMode = false;
    List<String> selectedTaskIds = [];

    return StatefulBuilder(
      builder: (context, setDialogState) {
        bool isAllSelected =
            category.tasks.isNotEmpty &&
            category.tasks.every((task) => selectedTaskIds.contains(task.id));

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // HEADER DIALOG
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                decoration: const BoxDecoration(
                  color: Colors.indigo,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20.0),
                    topRight: Radius.circular(20.0),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Kategori ${category.name}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isSelectionMode && category.tasks.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Semua',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Theme(
                            data: ThemeData(
                              unselectedWidgetColor: Colors.white70,
                            ),
                            child: Checkbox(
                              activeColor: Colors.teal,
                              checkColor: Colors.white,
                              value: isAllSelected,
                              onChanged: (bool? checked) {
                                setDialogState(() {
                                  if (checked == true) {
                                    selectedTaskIds = category.tasks
                                        .map((t) => t.id)
                                        .toList();
                                  } else {
                                    selectedTaskIds.clear();
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    if (category.tasks.isNotEmpty)
                      IconButton(
                        icon: Icon(
                          isSelectionMode
                              ? Icons.check_box
                              : Icons.library_add_check,
                          color: Colors.white,
                        ),
                        tooltip: isSelectionMode
                            ? 'Selesai Pilih'
                            : 'Pilih Banyak',
                        onPressed: () {
                          setDialogState(() {
                            isSelectionMode = !isSelectionMode;
                            selectedTaskIds.clear();
                          });
                        },
                      ),
                  ],
                ),
              ),

              // KONTEN UTAMA LIST TUGAS
              Flexible(
                child: category.tasks.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text('Tidak ada tugas aktif di kategori ini.'),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: category.tasks.length,
                        // Bagian fungsi itemBuilder utuh di dalam TasksDialog
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
                            }
                          } else {
                            todayText =
                                '+${task.countToday} / ${task.targetCountToday} hari ini';
                            todayColor = task.isActive
                                ? (task.countToday >= task.targetCountToday
                                      ? Colors.green[700]!
                                      : Colors.orange[700]!)
                                : Colors.grey;
                          }

                          // Mengatur visual teks total progress
                          String totalText = '';
                          if (task.type == 1) {
                            totalText = (todayText == null)
                                ? 'Progress Total: ${task.count} / ${task.targetCount}'
                                : ' | Progress Total: ${task.count} / ${task.targetCount}';
                          } else {
                            totalText = (todayText == null)
                                ? 'Total: ${task.count}'
                                : ' | Total: ${task.count}';
                          }

                          // Menghitung persentase murni tanpa batasan clamp
                          double progressPercentage = 0.0;
                          if (task.type == 1 && task.targetCount > 0) {
                            progressPercentage =
                                (task.count / task.targetCount);
                          }

                          // LOGIKA DINAMIS WARNA PROGRESS YANG MULUS
                          Color dynamicProgressColor = Colors.grey;
                          if (task.isActive) {
                            if (progressPercentage <= 0.5) {
                              double t = progressPercentage / 0.5;
                              dynamicProgressColor = Color.lerp(
                                Colors.red,
                                Colors.orange,
                                t,
                              )!;
                            } else if (progressPercentage <= 1.0) {
                              double t = (progressPercentage - 0.5) / 0.5;
                              dynamicProgressColor = Color.lerp(
                                Colors.orange,
                                Colors.green,
                                t,
                              )!;
                            } else {
                              double t = ((progressPercentage - 1.0) / 1.0)
                                  .clamp(0.0, 1.0);
                              dynamicProgressColor = Color.lerp(
                                Colors.green,
                                Colors.teal,
                                t,
                              )!;
                            }
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  dense: true,
                                  leading: isSelectionMode
                                      ? Checkbox(
                                          value: selectedTaskIds.contains(
                                            task.id,
                                          ),
                                          onChanged: (bool? checked) {
                                            setDialogState(() {
                                              if (checked == true) {
                                                selectedTaskIds.add(task.id);
                                              } else {
                                                selectedTaskIds.remove(task.id);
                                              }
                                            });
                                          },
                                        )
                                      : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                Icons.add_circle_outline,
                                                color: task.isActive
                                                    ? Colors.blue
                                                    : Colors.grey[400],
                                                size: 24,
                                              ),
                                              onPressed: task.isActive
                                                  ? () => _showConfirmIncrementDialog(
                                                      context,
                                                      task,
                                                      () async {
                                                        bool isUpdated =
                                                            await onIncrementTask(
                                                              task,
                                                            );
                                                        if (isUpdated)
                                                          setDialogState(() {});
                                                      },
                                                    )
                                                  : null,
                                            ),
                                            // KONTROL URUTAN: Tombol Naik Posisi
                                            IconButton(
                                              icon: Icon(
                                                Icons.arrow_upward,
                                                size: 16,
                                                color: index > 0
                                                    ? Colors.indigo
                                                    : Colors.grey[300],
                                              ),
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                              onPressed: index > 0
                                                  ? () {
                                                      setDialogState(() {
                                                        final temp = category
                                                            .tasks[index];
                                                        category.tasks[index] =
                                                            category
                                                                .tasks[index -
                                                                1];
                                                        category.tasks[index -
                                                                1] =
                                                            temp;
                                                      });
                                                      onReorderTasks(); // Memanggil callback simpan urutan lokal
                                                    }
                                                  : null,
                                            ),
                                            // KONTROL URUTAN: Tombol Turun Posisi
                                            IconButton(
                                              icon: Icon(
                                                Icons.arrow_downward,
                                                size: 16,
                                                color:
                                                    index <
                                                        category.tasks.length -
                                                            1
                                                    ? Colors.indigo
                                                    : Colors.grey[300],
                                              ),
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                              onPressed:
                                                  index <
                                                      category.tasks.length - 1
                                                  ? () {
                                                      setDialogState(() {
                                                        final temp = category
                                                            .tasks[index];
                                                        category.tasks[index] =
                                                            category
                                                                .tasks[index +
                                                                1];
                                                        category.tasks[index +
                                                                1] =
                                                            temp;
                                                      });
                                                      onReorderTasks(); // Memanggil callback simpan urutan lokal
                                                    }
                                                  : null,
                                            ),
                                          ],
                                        ),
                                  title: Text(
                                    task.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: task.isActive
                                          ? Colors.black87
                                          : Colors.grey,
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
                                  trailing: isSelectionMode
                                      ? null
                                      : PopupMenuButton<String>(
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
                                              bool isDeleted =
                                                  await onDeleteTask(task);
                                              if (isDeleted)
                                                setDialogState(() {});
                                            } else if (value.startsWith(
                                              'move_to_',
                                            )) {
                                              String targetCategoryName = value
                                                  .replaceFirst('move_to_', '');
                                              final targetCategory =
                                                  allCategories.firstWhere(
                                                    (cat) =>
                                                        cat.name ==
                                                        targetCategoryName,
                                                  );

                                              // PERBAIKAN UTAMA: Memanggil langsung dari parameter instansiasi objek tanpa 'widget.' karena TasksDialog adalah StatelessWidget
                                              onMoveTaskCategory(
                                                task,
                                                category,
                                                targetCategory,
                                              );
                                              setDialogState(() {});
                                            }
                                          },
                                          itemBuilder: (BuildContext context) => [
                                            const PopupMenuItem<String>(
                                              value: 'edit_detail',
                                              child: ListTile(
                                                leading: Icon(
                                                  Icons.edit_note,
                                                  size: 20,
                                                ),
                                                title: Text('Edit Detail'),
                                                contentPadding: EdgeInsets.zero,
                                                dense: true,
                                              ),
                                            ),
                                            if (allCategories.length > 1)
                                              PopupMenuItem<String>(
                                                enabled: false,
                                                child: Text(
                                                  'Pindahkan Kategori:',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.indigo[700],
                                                  ),
                                                ),
                                              ),
                                            ...allCategories
                                                .where(
                                                  (cat) =>
                                                      cat.name != category.name,
                                                )
                                                .map((cat) {
                                                  return PopupMenuItem<String>(
                                                    value:
                                                        'move_to_${cat.name}',
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            left: 8.0,
                                                          ),
                                                      child: Row(
                                                        children: [
                                                          Text(
                                                            cat.icon,
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 14,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              cat.name,
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        13,
                                                                  ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                })
                                                .toList(),
                                            const PopupMenuDivider(),
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
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                                contentPadding: EdgeInsets.zero,
                                                dense: true,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                                if (task.type == 1)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 110.0,
                                      right: 24.0,
                                      bottom: 8.0,
                                      top: 2.0,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            child: LinearProgressIndicator(
                                              value: progressPercentage.clamp(
                                                0.0,
                                                1.0,
                                              ),
                                              backgroundColor: Colors.grey[300],
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    dynamicProgressColor,
                                                  ),
                                              minHeight: 6,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${(progressPercentage * 100).toStringAsFixed(0)}%',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: dynamicProgressColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              const Divider(height: 1),

              // FOOTER PANEL
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
                child: isSelectionMode
                    ? Row(
                        children: [
                          Text(
                            '${selectedTaskIds.length} Terpilih',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.orange[800],
                            ),
                            icon: const Icon(Icons.visibility_off, size: 18),
                            label: const Text(
                              'Matikan',
                              style: TextStyle(fontSize: 12),
                            ),
                            onPressed: selectedTaskIds.isEmpty
                                ? null
                                : () => _showConfirmBulkDialog(
                                    context,
                                    'deactivate',
                                    selectedTaskIds.length,
                                    () {
                                      onBulkAction(
                                        selectedTaskIds,
                                        'deactivate',
                                      );
                                      setDialogState(() {
                                        isSelectionMode = false;
                                        selectedTaskIds.clear();
                                      });
                                    },
                                  ),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.green[800],
                            ),
                            icon: const Icon(Icons.visibility, size: 18),
                            label: const Text(
                              'Aktifkan',
                              style: TextStyle(fontSize: 12),
                            ),
                            onPressed: selectedTaskIds.isEmpty
                                ? null
                                : () => _showConfirmBulkDialog(
                                    context,
                                    'activate',
                                    selectedTaskIds.length,
                                    () {
                                      onBulkAction(selectedTaskIds, 'activate');
                                      setDialogState(() {
                                        isSelectionMode = false;
                                        selectedTaskIds.clear();
                                      });
                                    },
                                  ),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            icon: const Icon(Icons.delete_sweep, size: 18),
                            label: const Text(
                              'Hapus',
                              style: TextStyle(fontSize: 12),
                            ),
                            onPressed: selectedTaskIds.isEmpty
                                ? null
                                : () => _showConfirmBulkDialog(
                                    context,
                                    'delete',
                                    selectedTaskIds.length,
                                    () {
                                      onBulkAction(selectedTaskIds, 'delete');
                                      setDialogState(() {
                                        isSelectionMode = false;
                                        selectedTaskIds.clear();
                                      });
                                    },
                                  ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Tutup'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(
                                context,
                              ); // Tutup dialog list tugas terlebih dahulu
                              onAddTask(); // Panggil fungsi tambah tugas
                            },
                            child: const Text('Tambah Tugas'),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }
}

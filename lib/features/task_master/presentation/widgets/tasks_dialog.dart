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
  final VoidCallback onAddTask; // CALLBACK BARU UNTUK TAMBAH TUGAS
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

  // PERBAIKAN & MODIFIKASI: Mengubah TextSpan lama menjadi struktur Widget Badge yang estetik[cite: 3]
  Widget _buildBeautifulDateTimeBadge(String? dateStr, bool isActive) {
    if (dateStr == null || dateStr.trim().isEmpty)
      return const SizedBox.shrink();

    try {
      // Pecah string berformat "YYYY-MM-DD HH:mm" menjadi bagian terpisah
      final parts = dateStr.trim().split(' ');
      final String rawDate = parts[0];
      final String rawTime = parts.length > 1 ? parts[1] : '--:--';

      final DateTime parsedDate = DateTime.parse(rawDate);
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
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];

      final String hari = namaHari[parsedDate.weekday - 1];
      final String formattedDate =
          "${parsedDate.day} ${namaBulan[parsedDate.month - 1]} ${parsedDate.year}";

      return Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? Colors.indigo.withOpacity(0.06) : Colors.grey[200],
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive
                ? Colors.indigo.withOpacity(0.15)
                : Colors.grey[300]!,
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.access_time_filled_rounded,
              size: 11,
              color: isActive ? Colors.indigo[700] : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              "$hari, $formattedDate",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isActive ? Colors.grey[800] : Colors.grey,
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              height: 8,
              width: 1,
              color: Colors.grey[400],
            ),
            Text(
              rawTime,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.pink[700] : Colors.grey,
              ),
            ),
          ],
        ),
      );
    } catch (_) {
      // Fallback aman jika data lama masih berformat "YYYY-MM-DD" biasa tanpa jam
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          'Update: $dateStr',
          style: TextStyle(
            fontSize: 10,
            color: isActive ? Colors.blueGrey : Colors.grey,
          ),
        ),
      );
    }
  }

  // Method ini dipertahankan kosong untuk menjaga integritas kompilasi parameter class lama jika dibutuhkan di file luar[cite: 3]
  List<TextSpan> _buildIndonesianDateSpans(String? dateStr, bool isActive) =>
      [];

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

                          // Menghitung persentase progres murni tanpa batas maks
                          double progressPercentage = 0.0;
                          if (task.type == 1 && task.targetCount > 0) {
                            progressPercentage =
                                (task.count / task.targetCount);
                          }

                          // POIN 2: LOGIKA DINAMIS WARNA PROGRESS YANG MULUS (TERMASUK OVERHEAT)
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
                            } else if (progressPercentage <= 1.5) {
                              // Tahap Overheat Awal (101% - 150%): Transisi Hijau menuju Ungu Ultraviolet
                              double t = ((progressPercentage - 1.0) / 0.5)
                                  .clamp(0.0, 1.0);
                              dynamicProgressColor = Color.lerp(
                                Colors.green,
                                Colors.deepPurpleAccent,
                                t,
                              )!;
                            } else {
                              // Tahap Overheat Ekstrem (> 150%): Ungu Tua Pekat
                              dynamicProgressColor = Colors.purple[900]!;
                            }
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onLongPress: () {
                                    setDialogState(() {
                                      if (!isSelectionMode) {
                                        isSelectionMode = true;
                                        selectedTaskIds.clear();
                                        selectedTaskIds.add(task.id);
                                      } else {
                                        isSelectionMode = false;
                                        selectedTaskIds.clear();
                                      }
                                    });
                                  },
                                  child: ListTile(
                                    dense: true,
                                    leading: isSelectionMode
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Checkbox(
                                                value: selectedTaskIds.contains(
                                                  task.id,
                                                ),
                                                onChanged: (bool? checked) {
                                                  setDialogState(() {
                                                    if (checked == true) {
                                                      selectedTaskIds.add(
                                                        task.id,
                                                      );
                                                    } else {
                                                      selectedTaskIds.remove(
                                                        task.id,
                                                      );
                                                      if (selectedTaskIds
                                                          .isEmpty) {
                                                        isSelectionMode = false;
                                                      }
                                                    }
                                                  });
                                                },
                                              ),
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
                                                        onReorderTasks();
                                                      }
                                                    : null,
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.arrow_downward,
                                                  size: 16,
                                                  color:
                                                      index <
                                                          category
                                                                  .tasks
                                                                  .length -
                                                              1
                                                      ? Colors.indigo
                                                      : Colors.grey[300],
                                                ),
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(),
                                                onPressed:
                                                    index <
                                                        category.tasks.length -
                                                            1
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
                                                        onReorderTasks();
                                                      }
                                                    : null,
                                              ),
                                            ],
                                          )
                                        : IconButton(
                                            icon: Icon(
                                              Icons.add_circle_outline,
                                              color: task.isActive
                                                  ? Colors.blue
                                                  : Colors.grey[400],
                                              size: 28,
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
                                                      // POIN 3: Ditambahkan pemeriksaan context.mounted pasca operasi asinkron
                                                      if (context.mounted &&
                                                          isUpdated) {
                                                        setDialogState(() {});
                                                      }
                                                    },
                                                  )
                                                : null,
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
                                    // UBAH PANEL SUBTITLE: Memanfaatkan Column agar struktur badge waktu berada di baris baru secara eksklusif[cite: 3]
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(height: 2),
                                        Text.rich(
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
                                            ],
                                          ),
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        // Panggilan render widget badge visual jam:menit buatan baru
                                        _buildBeautifulDateTimeBadge(
                                          task.date,
                                          task.isActive,
                                        ),
                                      ],
                                    ),
                                    trailing: Builder(
                                      builder: (buttonContext) {
                                        return PopupMenuButton<String>(
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
                                              if (context.mounted &&
                                                  isDeleted) {
                                                setDialogState(() {});
                                              }
                                            } else if (value ==
                                                'trigger_move_menu') {
                                              // MEMPERBAIKI KALKULASI KOORDINAT BERDASARKAN POSISI BUILDCONTEXT TOMBOL MENU TRICKY
                                              final RenderBox button =
                                                  buttonContext
                                                          .findRenderObject()
                                                      as RenderBox;
                                              final RenderBox overlay =
                                                  Overlay.of(context).context
                                                          .findRenderObject()
                                                      as RenderBox;

                                              // Membuat posisi RelativeRect presisi tepat di bawah button pemicu klik
                                              final RelativeRect position =
                                                  RelativeRect.fromRect(
                                                    Rect.fromPoints(
                                                      button.localToGlobal(
                                                        Offset.zero,
                                                        ancestor: overlay,
                                                      ),
                                                      button.localToGlobal(
                                                        button.size.bottomRight(
                                                          Offset.zero,
                                                        ),
                                                        ancestor: overlay,
                                                      ),
                                                    ),
                                                    Offset.zero & overlay.size,
                                                  );

                                              if (!context.mounted) return;

                                              final String?
                                              selectedTarget = await showMenu<String>(
                                                context: context,
                                                position: position,
                                                items: allCategories
                                                    .where(
                                                      (cat) =>
                                                          cat.name !=
                                                          category.name,
                                                    )
                                                    .map((cat) {
                                                      return PopupMenuItem<
                                                        String
                                                      >(
                                                        value: cat.name,
                                                        child: Row(
                                                          children: [
                                                            Text(
                                                              cat.icon,
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        14,
                                                                  ),
                                                            ),
                                                            const SizedBox(
                                                              width: 8,
                                                            ),
                                                            Text(
                                                              cat.name,
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        13,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    })
                                                    .toList(),
                                              );

                                              if (selectedTarget != null &&
                                                  context.mounted) {
                                                final targetCategory =
                                                    allCategories.firstWhere(
                                                      (cat) =>
                                                          cat.name ==
                                                          selectedTarget,
                                                    );
                                                onMoveTaskCategory(
                                                  task,
                                                  category,
                                                  targetCategory,
                                                );
                                                setDialogState(() {});
                                              }
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
                                            if (allCategories.length > 1) ...[
                                              const PopupMenuDivider(),
                                              const PopupMenuItem<String>(
                                                value: 'trigger_move_menu',
                                                child: ListTile(
                                                  leading: Icon(
                                                    Icons
                                                        .drive_file_move_outlined,
                                                    size: 20,
                                                    color: Colors.indigo,
                                                  ),
                                                  title: Text(
                                                    'Pindahkan Kategori',
                                                  ),
                                                  trailing: Icon(
                                                    Icons.chevron_right,
                                                    size: 16,
                                                    color: Colors.grey,
                                                  ),
                                                  contentPadding:
                                                      EdgeInsets.zero,
                                                  dense: true,
                                                ),
                                              ),
                                            ],
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
                                        );
                                      },
                                    ),
                                  ),
                                ),

                                if (task.type == 1)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      left: isSelectionMode ? 120.0 : 64.0,
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
                                              // Bar tetap dibatasi di angka 1.0 maksimal agar UI tidak overflow meluap
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
                              Navigator.pop(context);
                              onAddTask();
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

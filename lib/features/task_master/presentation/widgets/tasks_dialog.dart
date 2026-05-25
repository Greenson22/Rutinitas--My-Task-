// lib/features/task_master/presentation/widgets/tasks_dialog.dart

import 'package:flutter/material.dart';
import '../../data/models/task_model.dart';
import 'edit_task_dialog.dart';

class TasksDialog extends StatelessWidget {
  final TaskCategory category;
  final Future<bool> Function(TaskItem) onIncrementTask;
  final Function(TaskItem, int) onUpdateTargetToday;
  final Function(TaskItem, String, int, int, int, int, String?, bool)
  onEditTaskDetail;
  final Future<bool> Function(TaskItem) onDeleteTask;
  final Function(List<String>, String) onBulkAction;
  final VoidCallback onAddTask; // <--- CALLBACK BARU UNTUK TAMBAH TUGAS

  const TasksDialog({
    super.key,
    required this.category,
    required this.onIncrementTask,
    required this.onUpdateTargetToday,
    required this.onEditTaskDetail,
    required this.onDeleteTask,
    required this.onBulkAction,
    required this.onAddTask, // <--- WAJIB DIISI
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

                          String totalText = (todayText == null)
                              ? 'Total: ${task.count} / ${task.targetCount}'
                              : ' | Total: ${task.count} / ${task.targetCount}';

                          return ListTile(
                            dense: true,
                            leading: isSelectionMode
                                ? Checkbox(
                                    value: selectedTaskIds.contains(task.id),
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
                                : IconButton(
                                    icon: Icon(
                                      Icons.add_circle_outline,
                                      color: task.isActive
                                          ? Colors.blue
                                          : Colors.grey[400],
                                      size: 28,
                                    ),
                                    // PERBAIKAN: Menambahkan dialog konfirmasi sebelum menambah hitungan
                                    onPressed: task.isActive
                                        ? () => _showConfirmIncrementDialog(
                                            context,
                                            task,
                                            () async {
                                              bool isUpdated =
                                                  await onIncrementTask(task);
                                              if (isUpdated)
                                                setDialogState(() {});
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
                                        bool isDeleted = await onDeleteTask(
                                          task,
                                        );
                                        if (isDeleted) setDialogState(() {});
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
                          // PERBAIKAN: Mengaktifkan fungsionalitas tombol Tambah Tugas melalui callback
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

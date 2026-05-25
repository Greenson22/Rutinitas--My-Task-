import 'package:flutter/material.dart';
import '../../data/models/task_model.dart';
import 'edit_task_dialog.dart';

class TasksDialog extends StatelessWidget {
  final TaskCategory category;
  final Future<bool> Function(TaskItem)
  onIncrementTask; // <--- UBAH DI SINI MENJADI FUTURE<BOOL>
  final Function(TaskItem, int) onUpdateTargetToday;
  final Function(TaskItem, String, int, int, int, int, String?)
  onEditTaskDetail;
  final Future<bool> Function(TaskItem) onDeleteTask;

  const TasksDialog({
    super.key,
    required this.category,
    required this.onIncrementTask,
    required this.onUpdateTargetToday,
    required this.onEditTaskDetail,
    required this.onDeleteTask,
  });

  // Fungsi helper untuk memformat tanggal ke gaya Indonesia dengan warna terpisah
  List<TextSpan> _buildIndonesianDateSpans(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return [];

    try {
      final DateTime parsedDate = DateTime.parse(dateStr);

      // Map Nama Hari Indonesia
      const List<String> namaHari = [
        'Senin',
        'Selasa',
        'Rabu',
        'Kamis',
        'Jumat',
        'Sabtu',
        'Minggu',
      ];
      // Map Nama Bulan Indonesia
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
        const TextSpan(
          text: ' | Update: ',
          style: TextStyle(color: Colors.blueGrey),
        ),
        TextSpan(
          text: hari,
          style: TextStyle(
            color: Colors.purple[900],
            fontWeight: FontWeight.bold,
          ),
        ),
        TextSpan(
          text: tanggal,
          style: TextStyle(
            color: Colors.pink[700],
            fontWeight: FontWeight.bold,
          ),
        ),
        TextSpan(
          text: bulan,
          style: TextStyle(
            color: Colors.teal[700],
            fontWeight: FontWeight.bold,
          ),
        ),
        TextSpan(
          text: tahun,
          style: TextStyle(
            color: Colors.deepOrange[700],
            fontWeight: FontWeight.bold,
          ),
        ),
      ];
    } catch (_) {
      // Jika parsing gagal, kembalikan teks aslinya dengan warna default
      return [
        TextSpan(
          text: ' | Update: $dateStr',
          style: const TextStyle(color: Colors.purple),
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

                          // === LOGIKA STRUKTUR TEKS & PEWARNAAN SUBTITLE ===
                          String? todayText;
                          Color? todayColor;

                          if (task.targetCountToday == 0) {
                            if (task.countToday > 0) {
                              // Tanpa target harian, tapi sudah ada hitungan hari ini -> Tampilkan (Warna Hijau)
                              todayText = '+${task.countToday} hari ini';
                              todayColor = Colors.green[700]!;
                            } else {
                              // Tanpa target harian DAN hitungan masih 0 -> Jangan ditulis dlu (null)
                              todayText = null;
                            }
                          } else {
                            // Jika memiliki target harian, selalu tampilkan format lengkap
                            todayText =
                                '+${task.countToday} / ${task.targetCountToday} hari ini';
                            if (task.countToday >= task.targetCountToday) {
                              todayColor = Colors.green[700]!;
                            } else {
                              todayColor = Colors.orange[700]!;
                            }
                          }

                          // Tentukan teks penghubung pipa pembatas total count
                          String totalText = (todayText == null)
                              ? 'Total: ${task.count} / ${task.targetCount}'
                              : ' | Total: ${task.count} / ${task.targetCount}';

                          return ListTile(
                            dense: true,
                            leading: IconButton(
                              icon: const Icon(
                                Icons.add_circle_outline,
                                color: Colors.blue,
                                size: 28,
                              ),
                              onPressed: () async {
                                bool isUpdated = await onIncrementTask(task);
                                if (isUpdated) {
                                  setDialogState(() {});
                                }
                              },
                            ),
                            title: Text(
                              task.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            // Menggunakan Text.rich untuk segmentasi warna subtitle yang sangat spesifik
                            subtitle: Text.rich(
                              TextSpan(
                                children: [
                                  // 1. Bagian Progress Hari Ini (jika ada/memenuhi syarat tampil)
                                  if (todayText != null)
                                    TextSpan(
                                      text: todayText,
                                      style: TextStyle(
                                        color: todayColor,
                                        fontWeight:
                                            task.countToday >=
                                                    task.targetCountToday ||
                                                task.targetCountToday == 0
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  // 2. Bagian Total Count
                                  TextSpan(
                                    text: totalText,
                                    style: TextStyle(color: Colors.blue[800]),
                                  ),
                                  // 3. Bagian Tanggal dengan format Indonesia dan warna pecahan kustom
                                  ..._buildIndonesianDateSpans(task.date),
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

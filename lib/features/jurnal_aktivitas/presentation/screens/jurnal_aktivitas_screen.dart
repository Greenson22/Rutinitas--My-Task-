// lib/features/jurnal_aktivitas/presentation/screens/jurnal_aktivitas_screen.dart

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/presentation/widgets/drawer_menu.dart';
import '../../../task_master/data/models/task_model.dart';
import '../../data/models/time_log_model.dart';
import '../widgets/jurnal_statistik_dialog.dart';

class JurnalAktivitasScreen extends StatefulWidget {
  const JurnalAktivitasScreen({super.key});

  @override
  State<JurnalAktivitasScreen> createState() => _JurnalAktivitasScreenState();
}

class _JurnalAktivitasScreenState extends State<JurnalAktivitasScreen> {
  final StorageService _storageService = StorageService();

  List<TimeLogEntry> _logs = [];
  List<TaskCategory> _allTaskCategories = [];
  String _baseDir = '';
  String _fullJsonPath = '';
  bool _isLoading = true;

  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String _getTodayDateString() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  Future<void> _loadData() async {
    try {
      _baseDir = await _storageService.getBaseDirSetting();
      final File jsonFile = await _storageService.getJurnalJsonFile(_baseDir);
      _fullJsonPath = jsonFile.path;

      final String jsonString = await _storageService
          .loadOrInitializeJurnalJson(jsonFile);
      final List<dynamic> decodedJson = jsonDecode(jsonString);

      List<TimeLogEntry> loadedLogs = decodedJson
          .map((e) => TimeLogEntry.fromJson(e))
          .toList();

      final String todayStr = _getTodayDateString();
      bool hasTodayLog = loadedLogs.any((entry) => entry.tanggal == todayStr);

      if (!hasTodayLog && loadedLogs.isNotEmpty) {
        final lastLog = loadedLogs.last;
        List<TimeLogTask> copiedTasks = lastLog.tasks.map((task) {
          return TimeLogTask(
            id: task.id,
            nama: task.nama,
            durasiMenit: 0,
            kategori: task.kategori,
            linkedTaskIds: task.linkedTaskIds,
          );
        }).toList();

        final todayEntry = TimeLogEntry(tanggal: todayStr, tasks: copiedTasks);
        loadedLogs.add(todayEntry);

        final String jsonContent = jsonEncode(
          loadedLogs.map((e) => e.toJson()).toList(),
        );
        await _storageService.saveJsonData(jsonFile, jsonContent);
      } else if (loadedLogs.isEmpty) {
        loadedLogs.add(TimeLogEntry(tanggal: todayStr, tasks: []));
        final String jsonContent = jsonEncode(
          loadedLogs.map((e) => e.toJson()).toList(),
        );
        await _storageService.saveJsonData(jsonFile, jsonContent);
      }

      await _loadTaskMasterData();

      setState(() {
        _logs = loadedLogs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error loading jurnal data: $e");
    }
  }

  Future<void> _loadTaskMasterData() async {
    try {
      File taskFile = await _storageService.getTargetJsonFile(_baseDir);
      if (await taskFile.exists()) {
        String jsonString = await taskFile.readAsString();
        final Map<String, dynamic> parsedMap = jsonDecode(jsonString);
        final List<dynamic> catList = parsedMap['categories'] ?? [];
        _allTaskCategories = catList
            .map((json) => TaskCategory.fromJson(json))
            .toList();
      }
    } catch (e) {
      debugPrint("Error loading task master components: $e");
    }
  }

  Future<void> _saveData() async {
    try {
      final File jsonFile = await _storageService.getJurnalJsonFile(_baseDir);
      final String jsonContent = jsonEncode(
        _logs.map((e) => e.toJson()).toList(),
      );
      await _storageService.saveJsonData(jsonFile, jsonContent);
    } catch (e) {
      debugPrint("Error saving jurnal data: $e");
    }
  }

  bool _isTaskTrulyLinked(TimeLogTask jurnalTask) {
    if (jurnalTask.linkedTaskIds.isEmpty) return false;

    for (var category in _allTaskCategories) {
      for (var task in category.tasks) {
        if (jurnalTask.linkedTaskIds.contains(task.id)) {
          return true;
        }
      }
    }
    return false;
  }

  // === FITUR BARU: MEMINDAHKAN URUTAN AKTIVITAS PADA HARI INI ===
  void _moveTaskOrder(
    List<TimeLogTask> taskList,
    int currentIndex,
    int direction,
  ) async {
    int newIndex = currentIndex + direction;
    if (newIndex < 0 || newIndex >= taskList.length) return;

    setState(() {
      final temp = taskList[currentIndex];
      taskList[currentIndex] = taskList[newIndex];
      taskList[newIndex] = temp;
    });

    await _saveData();
  }

  void _tampilkanDialogLinkTugas(TimeLogTask jurnalTask) {
    final String todayStr = _getTodayDateString();
    final int todayLogIndex = _logs.indexWhere(
      (entry) => entry.tanggal == todayStr,
    );
    final List<TimeLogTask> todayTasks = todayLogIndex != -1
        ? _logs[todayLogIndex].tasks
        : [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Hubungkan: ${jurnalTask.nama}'),
              content: SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.5,
                child: _allTaskCategories.isEmpty
                    ? const Center(
                        child: Text(
                          "Tidak ada kategori tugas ditemukan di Task Master.",
                        ),
                      )
                    : ListView.builder(
                        itemCount: _allTaskCategories.length,
                        itemBuilder: (context, catIdx) {
                          final category = _allTaskCategories[catIdx];
                          return ExpansionTile(
                            leading: Text(
                              category.icon,
                              style: const TextStyle(fontSize: 18),
                            ),
                            title: Text(
                              category.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            children: category.tasks.map((taskItem) {
                              final bool isLinkedWithThis = jurnalTask
                                  .linkedTaskIds
                                  .contains(taskItem.id);

                              return ListTile(
                                dense: true,
                                title: Text(taskItem.name),
                                subtitle: Text(
                                  'Total hitungan: ${taskItem.count}',
                                ),
                                trailing: Icon(
                                  isLinkedWithThis
                                      ? Icons.link
                                      : Icons.link_off,
                                  color: isLinkedWithThis
                                      ? Colors.teal
                                      : Colors.grey,
                                ),
                                tileColor: isLinkedWithThis
                                    ? Colors.teal.withOpacity(0.05)
                                    : null,
                                onTap: () {
                                  setDialogState(() {
                                    if (isLinkedWithThis) {
                                      jurnalTask.linkedTaskIds.remove(
                                        taskItem.id,
                                      );
                                    } else {
                                      for (var t in todayTasks) {
                                        if (t.id != jurnalTask.id) {
                                          t.linkedTaskIds.remove(taskItem.id);
                                        }
                                      }
                                      jurnalTask.linkedTaskIds.clear();
                                      jurnalTask.linkedTaskIds.add(taskItem.id);
                                    }
                                  });
                                  _saveData();
                                  setState(() {});
                                },
                              );
                            }).toList(),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Selesai'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _tambahDurasiAktivitas(TimeLogTask task, {VoidCallback? onDone}) async {
    final bool? konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Waktu?'),
        content: Text(
          'Apakah Anda yakin ingin menambah durasi "${task.nama}" sebanyak 30 menit?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            child: const Text('Ya, Tambah'),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;

    // PERBAIKAN: Cari dan ubah langsung pada referensi list objek di dalam _logs
    for (var logEntry in _logs) {
      int idx = logEntry.tasks.indexWhere((t) => t.id == task.id);
      if (idx != -1) {
        setState(() {
          // Mengubah durasiMenit milik item asli di dalam list state _logs
          logEntry.tasks[idx].durasiMenit += 30;
        });
        break;
      }
    }

    await _saveData();
    if (onDone != null) onDone();
  }

  void _tampilkanDialogEditTimerLangsung(
    TimeLogTask task, {
    VoidCallback? onDone,
  }) {
    final TextEditingController timerController = TextEditingController(
      text: task.durasiMenit.toString(),
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ubah Durasi: ${task.nama}'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: timerController,
            decoration: const InputDecoration(
              labelText: 'Durasi Waktu (Menit)',
              border: OutlineInputBorder(),
              suffixText: 'mnt',
            ),
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null || v.trim().isEmpty)
                return 'Durasi tidak boleh kosong';
              if (int.tryParse(v.trim()) == null)
                return 'Masukkan angka yang valid';
              if (int.parse(v.trim()) < 0) return 'Durasi tidak boleh negatif';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final int newDuration = int.parse(timerController.text.trim());
                setState(() {
                  task.durasiMenit = newDuration;
                });
                await _saveData();
                if (onDone != null) onDone();
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _tampilkanDialogTambahAktivitas() {
    final TextEditingController inputController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Aktivitas Hari Ini'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: inputController,
            decoration: const InputDecoration(
              labelText: 'Nama Aktivitas / Tugas',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                v!.trim().isEmpty ? 'Nama tidak boleh kosong' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final String todayStr = _getTodayDateString();
                final int todayLogIndex = _logs.indexWhere(
                  (entry) => entry.tanggal == todayStr,
                );

                if (todayLogIndex != -1) {
                  final randomId = Random().nextInt(999999);
                  final newTask = TimeLogTask(
                    id: randomId,
                    nama: inputController.text.trim(),
                    durasiMenit: 0,
                    linkedTaskIds: [],
                  );

                  setState(() {
                    _logs[todayLogIndex].tasks.add(newTask);
                  });

                  await _saveData();
                  Navigator.pop(context);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _tampilkanDialogUbahAktivitas(TimeLogTask task) {
    final TextEditingController editController = TextEditingController(
      text: task.nama,
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Nama Aktivitas'),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(
            labelText: 'Nama Aktivitas Baru',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = editController.text.trim();
              if (newName.isNotEmpty) {
                setState(() {
                  task.nama = newName;
                });
                await _saveData();
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _hapusAktivitas(TimeLogTask task) async {
    final bool? konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Aktivitas?'),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${task.nama}" dari list hari ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (konfirmasi == true) {
      final String todayStr = _getTodayDateString();
      final int todayLogIndex = _logs.indexWhere(
        (entry) => entry.tanggal == todayStr,
      );

      if (todayLogIndex != -1) {
        setState(() {
          _logs[todayLogIndex].tasks.removeWhere((t) => t.id == task.id);
        });
        await _saveData();
      }
    }
  }

  void _tampilkanDialogRiwayat() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Membalikkan urutan list agar date terakhir/terbaru berada di paling atas
            final sortedLogs = _logs.reversed.toList();

            return AlertDialog(
              title: Row(
                children: const [
                  Icon(Icons.history, color: Colors.indigo),
                  SizedBox(width: 8),
                  Text('Riwayat Aktivitas'),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.6,
                child: sortedLogs.isEmpty
                    ? const Center(child: Text("Belum ada riwayat aktivitas."))
                    : ListView.builder(
                        itemCount: sortedLogs.length,
                        itemBuilder: (context, index) {
                          final log = sortedLogs[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ExpansionTile(
                              title: Text(
                                log.tanggal,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text('${log.tasks.length} aktivitas'),
                              children: log.tasks.map((task) {
                                final isLinked = _isTaskTrulyLinked(task);
                                return ListTile(
                                  dense: true,
                                  title: Row(
                                    children: [
                                      Expanded(child: Text(task.nama)),
                                      if (isLinked)
                                        const Icon(
                                          Icons.link,
                                          size: 14,
                                          color: Colors.teal,
                                        ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      InkWell(
                                        onTap: () =>
                                            _tampilkanDialogEditTimerLangsung(
                                              task,
                                              onDone: () =>
                                                  setDialogState(() {}),
                                            ),
                                        child: Text(
                                          '  ${task.durasiMenit} mnt',
                                          style: const TextStyle(
                                            decoration:
                                                TextDecoration.underline,
                                            color: Colors.indigo,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.link,
                                          color: Colors.blueGrey,
                                          size: 18,
                                        ),
                                        onPressed: () =>
                                            _tampilkanDialogLinkTugas(task),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add_circle,
                                          color: Colors.indigo,
                                          size: 20,
                                        ),
                                        onPressed: () => _tambahDurasiAktivitas(
                                          task,
                                          onDone: () => setDialogState(() {}),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final String todayStr = _getTodayDateString();
    final todayLogIndex = _logs.indexWhere(
      (entry) => entry.tanggal == todayStr,
    );
    final List<TimeLogTask> todayTasks = todayLogIndex != -1
        ? _logs[todayLogIndex].tasks
        : [];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Jurnal Aktivitas'),
        backgroundColor: Colors.indigo[700],
        actions: [
          // === TOMBOL EDIT DI SINI TELAH DIHAPUS ===
          // === TOMBOL STATISTIK (BARU) ===
          IconButton(
            icon: const Icon(Icons.analytics_outlined, color: Colors.white),
            tooltip: 'Lihat Statistik',
            onPressed: () {
              if (_logs.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Belum ada data untuk dianalisis.'),
                  ),
                );
                return;
              }
              showDialog(
                context: context,
                builder: (context) => JurnalStatistikDialog(logs: _logs),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: _tampilkanDialogRiwayat,
          ),
        ],
      ),
      drawer: const DrawerMenu(isJurnalActive: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.today, size: 20, color: Colors.teal),
                      const SizedBox(width: 8),
                      Text(
                        'Aktivitas Hari Ini ($todayStr)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo[900],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: todayTasks.isEmpty
                      ? const Center(
                          child: Text("Belum ada aktivitas dicatat hari ini."),
                        )
                      : ListView.builder(
                          itemCount: todayTasks.length,
                          itemBuilder: (context, index) {
                            final task = todayTasks[index];
                            final bool isLinked = _isTaskTrulyLinked(
                              task,
                            ); // Menghitung status tautan tugas
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                // === FITUR BARU: MENAHAN AKTIVITAS UNTUK AKTIF/NONAKTIFKAN MODE EDIT ===
                                onLongPress: () {
                                  setState(() {
                                    _isEditMode = !_isEditMode;
                                  });
                                },
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: _isEditMode
                                      ? Colors.amber[50]
                                      : Colors.teal[50],
                                  radius: 16,
                                  child: Icon(
                                    _isEditMode
                                        ? Icons.edit_attributes
                                        : Icons.check_circle_outline,
                                    color: _isEditMode
                                        ? Colors.amber[800]
                                        : Colors.teal,
                                    size: 18,
                                  ),
                                ),
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // MODIFIKASI DI SINI: Membungkus Judul Tugas dengan Row untuk menyisipkan ikon terhubung
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
                                        // Jikalau tugas terhubung dengan Tasks Master, munculkan ikon tautan berwarna teal
                                        if (isLinked)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 6.0,
                                            ),
                                            child: Tooltip(
                                              message:
                                                  'Terhubung dengan Task Master',
                                              triggerMode:
                                                  TooltipTriggerMode.tap,
                                              child: const Icon(
                                                Icons.link,
                                                size: 16,
                                                color: Colors.teal,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    // Jika Mode Edit AKTIF, tampilkan kumpulan tombol kontrol dengan Wrap agar ramah mobile
                                    if (_isEditMode) ...[
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8.0,
                                        runSpacing: 6.0,
                                        children: [
                                          _buildMobileEditButton(
                                            icon: Icons.arrow_upward,
                                            color: index > 0
                                                ? Colors.indigo
                                                : Colors.grey[300]!,
                                            onPressed: index > 0
                                                ? () => _moveTaskOrder(
                                                    todayTasks,
                                                    index,
                                                    -1,
                                                  )
                                                : null,
                                          ),
                                          _buildMobileEditButton(
                                            icon: Icons.arrow_downward,
                                            color: index < todayTasks.length - 1
                                                ? Colors.indigo
                                                : Colors.grey[300]!,
                                            onPressed:
                                                index < todayTasks.length - 1
                                                ? () => _moveTaskOrder(
                                                    todayTasks,
                                                    index,
                                                    1,
                                                  )
                                                : null,
                                          ),
                                          _buildMobileEditButton(
                                            icon: Icons.link,
                                            color: Colors.teal,
                                            onPressed: () =>
                                                _tampilkanDialogLinkTugas(task),
                                          ),
                                          _buildMobileEditButton(
                                            icon: Icons.edit_note,
                                            color: Colors.blueGrey,
                                            onPressed: () =>
                                                _tampilkanDialogUbahAktivitas(
                                                  task,
                                                ),
                                          ),
                                          _buildMobileEditButton(
                                            icon: Icons.delete_outline,
                                            color: Colors.redAccent,
                                            onPressed: () =>
                                                _hapusAktivitas(task),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: _isEditMode
                                    ? const SizedBox.shrink()
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            onTap: () =>
                                                _tampilkanDialogEditTimerLangsung(
                                                  task,
                                                ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.amber[50],
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: Colors.amber.shade200,
                                                ),
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
                                            onPressed: () =>
                                                _tambahDurasiAktivitas(task),
                                          ),
                                        ],
                                      ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _tampilkanDialogTambahAktivitas,
        backgroundColor: Colors.indigo[700],
        child: const Icon(Icons.add, size: 30, color: Colors.white),
      ),
    );
  }

  // Fungsi pembantu untuk membuat tombol edit yang rapi dan pas untuk ukuran layar HP
  Widget _buildMobileEditButton({
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

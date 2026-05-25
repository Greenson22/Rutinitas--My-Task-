// lib/features/jurnal_aktivitas/presentation/screens/jurnal_aktivitas_screen.dart

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/services/storage_service.dart';
import '../../../task_master/presentation/widgets/drawer_menu.dart';
import '../../data/models/time_log_model.dart';

class JurnalAktivitasScreen extends StatefulWidget {
  const JurnalAktivitasScreen({super.key});

  @override
  State<JurnalAktivitasScreen> createState() => _JurnalAktivitasScreenState();
}

class _JurnalAktivitasScreenState extends State<JurnalAktivitasScreen> {
  final StorageService _storageService = StorageService();

  List<TimeLogEntry> _logs = [];
  String _baseDir = '';
  String _fullJsonPath = '';
  bool _isLoading = true;

  // STATE BARU: Menandakan apakah halaman Jurnal sedang dalam mode edit (Ubah/Hapus)
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
        // Jika file benar-benar baru kosong, buat inisialisasi hari ini
        loadedLogs.add(TimeLogEntry(tanggal: todayStr, tasks: []));
        final String jsonContent = jsonEncode(
          loadedLogs.map((e) => e.toJson()).toList(),
        );
        await _storageService.saveJsonData(jsonFile, jsonContent);
      }

      setState(() {
        _logs = loadedLogs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error loading jurnal data: $e");
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

  void _tambahDurasiAktivitas(TimeLogTask task) async {
    for (var logEntry in _logs) {
      int idx = logEntry.tasks.indexWhere((t) => t.id == task.id);
      if (idx != -1) {
        setState(() {
          logEntry.tasks[idx] = TimeLogTask(
            id: task.id,
            nama: task.nama,
            durasiMenit: task.durasiMenit + 30,
            kategori: task.kategori,
            linkedTaskIds: task.linkedTaskIds,
          );
        });
        break;
      }
    }

    await _saveData();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⏱ Durasi "${task.nama}" ditambah 30 menit!'),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  // === FITUR BARU: DIALOG TAMBAH AKTIVITAS BARU ===
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
              hintText: 'Contoh: Rapat Tim, Belajar Dart',
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Aktivitas baru berhasil ditambahkan!'),
                    ),
                  );
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

  // === FITUR BARU: DIALOG UBAH NAMA AKTIVITAS ===
  // === DIALOG UBAH NAMA AKTIVITAS ===
  void _tampilkanDialogUbahAktivitas(TimeLogTask task) {
    // 1. Ubah task.name menjadi task.nama di sini
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
                  // 2. Ubah task.name menjadi task.nama di sini juga
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

  // === FITUR BARU: FUNGSI HAPUS AKTIVITAS ===
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aktivitas berhasil dihapus.')),
        );
      }
    }
  }

  void _tampilkanDialogRiwayat() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                child: _logs.isEmpty
                    ? const Center(child: Text("Belum ada riwayat aktivitas."))
                    : ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log = _logs[index];
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
                                return ListTile(
                                  dense: true,
                                  title: Text(task.nama),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('⏱ ${task.durasiMenit} mnt'),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add_circle,
                                          color: Colors.indigo,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          _tambahDurasiAktivitas(task);
                                          setDialogState(() {});
                                        },
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
          // TOMBOL EDIT UTAMA DI ATAS KANAN (APP BAR)
          IconButton(
            icon: Icon(
              _isEditMode ? Icons.check_circle : Icons.edit_note,
              size: 28,
            ),
            color: _isEditMode ? Colors.amberAccent : Colors.white,
            tooltip: _isEditMode
                ? 'Selesai Mengatur'
                : 'Ubah & Hapus Aktivitas',
            onPressed: () {
              setState(() {
                _isEditMode = !_isEditMode;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            tooltip: 'Lihat Riwayat',
            onPressed: _tampilkanDialogRiwayat,
          ),
        ],
      ),
      drawer: DrawerMenu(
        selectedBaseDir: _baseDir,
        fullJsonPath: _fullJsonPath,
        onOpenSettings: () {},
        isJurnalActive: true,
      ),
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
                          padding: const EdgeInsets.only(
                            bottom: 80,
                          ), // Beri ruang agar tidak tertutup FAB
                          itemBuilder: (context, index) {
                            final task = todayTasks[index];
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
                                leading: CircleAvatar(
                                  backgroundColor: _isEditMode
                                      ? Colors.amber[50]
                                      : Colors.teal[50],
                                  radius: 16,
                                  child: Icon(
                                    _isEditMode
                                        ? Icons.edit
                                        : Icons.check_circle_outline,
                                    color: _isEditMode
                                        ? Colors.amber[800]
                                        : Colors.teal,
                                    size: 18,
                                  ),
                                ),
                                title: Text(
                                  task.nama,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.5,
                                  ),
                                ),
                                // Jika Masuk Mode Edit, tampilkan kontrol ubah & hapus, sebaliknya tampilkan penambah durasi waktu harian
                                trailing: _isEditMode
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit_note,
                                              color: Colors.blueGrey,
                                            ),
                                            tooltip: 'Ubah Nama',
                                            onPressed: () =>
                                                _tampilkanDialogUbahAktivitas(
                                                  task,
                                                ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.redAccent,
                                            ),
                                            tooltip: 'Hapus',
                                            onPressed: () =>
                                                _hapusAktivitas(task),
                                          ),
                                        ],
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.amber[50],
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '⏱ ${task.durasiMenit} mnt',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.amber[900],
                                                fontSize: 12,
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
                                            tooltip: 'Tambah 30 Menit',
                                            constraints: const BoxConstraints(),
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
      // FLOATING ACTION BUTTON UNTUK TAMBAH AKTIVITAS BARU
      floatingActionButton: FloatingActionButton(
        onPressed: _tampilkanDialogTambahAktivitas,
        backgroundColor: Colors.indigo[700],
        child: const Icon(Icons.add, size: 30, color: Colors.white),
      ),
    );
  }
}

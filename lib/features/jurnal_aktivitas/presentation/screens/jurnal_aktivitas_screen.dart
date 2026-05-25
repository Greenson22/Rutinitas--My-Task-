// lib/features/jurnal_aktivitas/presentation/screens/jurnal_aktivitas_screen.dart

import 'dart:convert';
import 'dart:io';
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

      // LOGIKA OTOMATIS COPY AKTIVITAS SAAT BERGANTI HARI
      // Cek apakah hari ini sudah memiliki log aktivitas
      bool hasTodayLog = loadedLogs.any((entry) => entry.tanggal == todayStr);

      if (!hasTodayLog && loadedLogs.isNotEmpty) {
        // Ambil log paling terakhir/terbaru dari hari sebelumnya (indeks terakhir)
        final lastLog = loadedLogs.last;

        // Salin semua tugas dari hari sebelumnya, set durasi ke 0 menit
        List<TimeLogTask> copiedTasks = lastLog.tasks.map((task) {
          return TimeLogTask(
            id: task.id,
            nama: task.nama,
            durasiMenit: 0, // Reset waktu ke 0 menit
            kategori: task.kategori,
            linkedTaskIds: task.linkedTaskIds,
          );
        }).toList();

        // Buat entri baru untuk hari ini dengan tugas yang sudah dicopy
        final todayEntry = TimeLogEntry(tanggal: todayStr, tasks: copiedTasks);

        // Masukkan entri hari baru ke dalam list logs
        loadedLogs.add(todayEntry);

        // Langsung simpan perubahan otomatis ini ke file JSON
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

  // TAMPILKAN DIALOG RIWAYAT DAFTAR AKTIVITAS
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
                          padding: const EdgeInsets.only(bottom: 16),
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
                                  backgroundColor: Colors.teal[50],
                                  radius: 16,
                                  child: const Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.teal,
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
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.amber[50],
                                        borderRadius: BorderRadius.circular(6),
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
    );
  }
}

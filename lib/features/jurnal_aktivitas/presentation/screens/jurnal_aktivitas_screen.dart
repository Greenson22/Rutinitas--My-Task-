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
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _namaAktivitasController =
      TextEditingController();
  final TextEditingController _durasiController = TextEditingController();

  List<TimeLogEntry> _logs = [];
  String _baseDir = '';
  String _fullJsonPath = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _namaAktivitasController.dispose();
    _durasiController.dispose();
    super.dispose();
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

      setState(() {
        _logs = decodedJson.map((e) => TimeLogEntry.fromJson(e)).toList();
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

  void _tambahAktivitasKeLog() async {
    if (!_formKey.currentState!.validate()) return;

    final String nama = _namaAktivitasController.text.trim();
    final int durasi = int.parse(_durasiController.text.trim());
    final String todayStr = _getTodayDateString();

    setState(() {
      final newTempTask = TimeLogTask(
        id: DateTime.now().millisecondsSinceEpoch,
        nama: nama,
        durasiMenit: durasi,
        kategori: null,
        linkedTaskIds: [],
      );

      int existingDayIndex = _logs.indexWhere(
        (entry) => entry.tanggal == todayStr,
      );

      if (existingDayIndex != -1) {
        _logs[existingDayIndex].tasks.insert(0, newTempTask);
      } else {
        _logs.insert(0, TimeLogEntry(tanggal: todayStr, tasks: [newTempTask]));
      }

      _namaAktivitasController.clear();
      _durasiController.clear();
    });

    await _saveData();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✨ Aktivitas berhasil dicatat!'),
        backgroundColor: Colors.teal,
        duration: Duration(seconds: 2),
      ),
    );
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

  // TAMPILKAN DIALOG BARU UNTUK RIWAYAT DAFTAR AKTIVITAS 전체
  void _tampilkanDialogRiwayat() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.history, color: Colors.indigo),
                  const SizedBox(width: 8),
                  const Text('Riwayat Aktivitas'),
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
                                          setDialogState(
                                            () {},
                                          ); // Update tampilan di dalam dialog
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
    ).then(
      (_) => setState(() {}),
    ); // Pastikan halaman utama ikut segar setelah dialog ditutup
  }

  @override
  Widget build(BuildContext context) {
    final String todayStr = _getTodayDateString();

    // Memfilter log khusus untuk hari ini saja
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
                _buildFormInputCard(),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      const Icon(Icons.today, size: 18, color: Colors.teal),
                      const SizedBox(width: 6),
                      Text(
                        'Aktivitas Hari Ini ($todayStr)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo[900],
                        ),
                      ),
                    ],
                  ),
                ),

                // MENAMPILKAN HANYA AKTIVITAS HARI INI
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

  Widget _buildFormInputCard() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.rate_review_outlined, color: Colors.indigo[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Catat Aktivitas Baru',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo[900],
                    ),
                  ),
                ],
              ),
              const Divider(height: 20, thickness: 1),
              TextFormField(
                controller: _namaAktivitasController,
                decoration: InputDecoration(
                  labelText: 'Apa yang baru saja Anda lakukan?',
                  hintText: 'Contoh: Slicing UI Dashboard Flutter',
                  prefixIcon: const Icon(Icons.edit, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  isDense: true,
                ),
                validator: (v) =>
                    v!.trim().isEmpty ? 'Aktivitas tidak boleh kosong' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _durasiController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Durasi (Menit)',
                  hintText: '30',
                  prefixIcon: const Icon(Icons.timer_outlined, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  isDense: true,
                ),
                validator: (v) {
                  if (v!.trim().isEmpty) return 'Wajib isi';
                  if (int.tryParse(v.trim()) == null) return 'Angka saja';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _tambahAktivitasKeLog,
                  icon: const Icon(
                    Icons.playlist_add_check_rounded,
                    size: 22,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Simpan ke Jurnal',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

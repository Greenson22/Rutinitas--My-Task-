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

  // Controller untuk Form Input
  final TextEditingController _namaAktivitasController =
      TextEditingController();
  final TextEditingController _durasiController = TextEditingController();
  String _selectedKategori = 'Umum';

  List<TimeLogEntry> _logs = [];
  String _baseDir = '';
  String _fullJsonPath = '';
  bool _isLoading = true;

  // Daftar opsi kategori untuk mempermudah user
  final List<String> _daftarKategori = [
    'Umum',
    'Primary',
    'Secondary',
    'Target',
    'Habit',
    'Career',
    'Coding',
  ];

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
      // Buat objek aktivitas baru
      final newTempTask = TimeLogTask(
        id: DateTime.now()
            .millisecondsSinceEpoch, // Generate ID sederhana dari timestamp
        nama: nama,
        durasiMenit: durasi,
        kategori: _selectedKategori,
        linkedTaskIds: [],
      );

      // Cari apakah log hari ini sudah ada
      int existingDayIndex = _logs.indexWhere(
        (entry) => entry.tanggal == todayStr,
      );

      if (existingDayIndex != -1) {
        // Jika sudah ada log di tanggal hari ini, tambahkan task ke list teratas hari tersebut
        _logs[existingDayIndex].tasks.insert(0, newTempTask);
      } else {
        // Jika belum ada entri tanggal hari ini, buat entri tanggal baru di posisi teratas list
        _logs.insert(0, TimeLogEntry(tanggal: todayStr, tasks: [newTempTask]));
      }

      // Bersihkan form input setelah berhasil
      _namaAktivitasController.clear();
      _durasiController.clear();
      _selectedKategori = 'Umum';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Jurnal Aktivitas'),
        backgroundColor: Colors.indigo[700],
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
                // ================= SECTION 1: FORM INPUT YANG CANTIK =================
                _buildFormInputCard(),

                // Judul Pemisah Riwayat
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.history,
                        size: 18,
                        color: Colors.blueGrey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Riwayat Aktivitas Terkini',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo[900],
                        ),
                      ),
                    ],
                  ),
                ),

                // ================= SECTION 2: LIST RIWAYAT LOG =================
                Expanded(
                  child: _logs.isEmpty
                      ? const Center(
                          child: Text("Belum ada aktivitas dicatat hari ini."),
                        )
                      : ListView.builder(
                          itemCount: _logs.length,
                          padding: const EdgeInsets.only(bottom: 16),
                          itemBuilder: (context, index) {
                            final log = _logs[index];
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ExpansionTile(
                                leading: const Icon(
                                  Icons.calendar_today_rounded,
                                  color: Colors.indigo,
                                ),
                                title: Text(
                                  log.tanggal,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Text(
                                  '${log.tasks.length} Aktivitas terekam',
                                ),
                                initiallyExpanded:
                                    index ==
                                    0, // Buka penel hari ini secara otomatis
                                children: log.tasks.map((task) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        top: BorderSide(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                    ),
                                    child: ListTile(
                                      dense: true,
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
                                      subtitle: Text(
                                        task.kategori ?? 'Tanpa Kategori',
                                        style: TextStyle(
                                          color: Colors.indigo[400],
                                          fontSize: 11,
                                        ),
                                      ),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amber[50],
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
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
                                    ),
                                  );
                                }).toList(),
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

              // Input Nama Aktivitas
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

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Input Durasi Waktu
                  Expanded(
                    flex: 4,
                    child: TextFormField(
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
                  ),
                  const SizedBox(width: 12),

                  // Dropdown Pilihan Kategori
                  Expanded(
                    flex: 5,
                    child: DropdownButtonFormField<String>(
                      value: _selectedKategori,
                      decoration: InputDecoration(
                        labelText: 'Kategori',
                        prefixIcon: const Icon(Icons.tag, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        isDense: true,
                      ),
                      items: _daftarKategori.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setState(() => _selectedKategori = newValue);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Tombol Submit Masukkan Data
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

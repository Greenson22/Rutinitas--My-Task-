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
      setState(() {
        _isLoading = false;
      });
      debugPrint("Error loading jurnal data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jurnal Aktivitas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fitur tambah catatan akan segera hadir'),
                ),
              );
            },
          ),
        ],
      ),
      drawer: DrawerMenu(
        selectedBaseDir: _baseDir,
        fullJsonPath: _fullJsonPath,
        onOpenSettings:
            () {}, // Sesuaikan jika Anda memiliki fungsi setting global
        isJurnalActive: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
          ? const Center(child: Text("Belum ada data jurnal aktivitas"))
          : ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ExpansionTile(
                    title: Text(
                      log.tanggal,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${log.tasks.length} Kategori Tugas'),
                    children: log.tasks.map((task) {
                      return ListTile(
                        leading: Icon(
                          Icons.task_alt,
                          color: task.durasiMenit > 0
                              ? Colors.green
                              : Colors.grey,
                        ),
                        title: Text(task.nama),
                        subtitle: Text(task.kategori ?? 'Tanpa Kategori'),
                        trailing: Text(
                          '${task.durasiMenit} mnt',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
    );
  }
}

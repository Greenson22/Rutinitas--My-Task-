// lib/features/daily/presentation/screens/daily_screen.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/services/storage_service.dart';
import '../../../task_master/presentation/widgets/drawer_menu.dart';
import '../../../task_master/presentation/widgets/settings_dialog.dart';
import '../../data/models/daily_model.dart';
import '../widgets/daily_checklist_dialog.dart';

class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  final StorageService _storageService = StorageService();
  DailyData? _dailyData;
  String _selectedBaseDir = 'Documents';
  String _fullJsonPath = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDailyData();
  }

  Future<void> _loadDailyData() async {
    setState(() => _isLoading = true);
    try {
      _selectedBaseDir = await _storageService.getBaseDirSetting();
      File jsonFile = await _storageService.getDailyJsonFile(_selectedBaseDir);
      _fullJsonPath = jsonFile.path;

      String jsonString = await _storageService.loadOrInitializeDailyJson(
        jsonFile,
      );
      final Map<String, dynamic> parsedMap = jsonDecode(jsonString);

      setState(() {
        _dailyData = DailyData.fromJson(parsedMap);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error loading daily data: $e");
    }
  }

  Future<void> _saveDailyData() async {
    if (_dailyData == null) return;

    final Map<String, dynamic> updatedMap = _dailyData!.toJson();
    final String updatedJsonString = const JsonEncoder.withIndent(
      '  ',
    ).convert(updatedMap);

    try {
      File jsonFile = await _storageService.getDailyJsonFile(_selectedBaseDir);
      await _storageService.saveJsonData(jsonFile, updatedJsonString);
    } catch (e) {
      debugPrint("Error saving daily data: $e");
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => SettingsDialog(
        currentBaseDir: _selectedBaseDir,
        onSave: (newDir) async {
          await _storageService.saveBaseDirSetting(newDir);
          _loadDailyData();
        },
      ),
    );
  }

  void _openMateriChecklist(DailySubject subject) {
    showDialog(
      context: context,
      builder: (context) => DailyChecklistDialog(
        subject: subject,
        onDataChanged: () {
          _saveDailyData();
          setState(() {}); // Segarkan UI Utama DailyScreen
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(_dailyData?.topics ?? 'Daily Checklist'),
        backgroundColor:
            Colors.teal[700], // Pembeda warna tema dengan TaskMaster
      ),
      drawer: DrawerMenu(
        selectedBaseDir: _selectedBaseDir,
        fullJsonPath: _fullJsonPath,
        onOpenSettings: _showSettingsDialog,
        isDailyActive: true, // Menandai tab Daily aktif di sidebar
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _dailyData == null || _dailyData!.subjects.isEmpty
          ? const Center(child: Text('Tidak ada rutinitas harian ditemukan.'))
          : LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = 2;
                if (constraints.maxWidth >= 1200)
                  crossAxisCount = 5;
                else if (constraints.maxWidth >= 900)
                  crossAxisCount = 4;
                else if (constraints.maxWidth >= 600)
                  crossAxisCount = 3;

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 1.7,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _dailyData!.subjects.length,
                  itemBuilder: (context, index) {
                    final subject = _dailyData!.subjects[index];
                    int totalSub = subject.subMateri.length;
                    int selesaiSub = subject.subMateri
                        .where((sm) => sm.progress == 'selesai')
                        .length;

                    bool isAllDone = totalSub > 0 && totalSub == selesaiSub;

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: InkWell(
                        onTap: () => _openMateriChecklist(subject),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Color(
                                  subject.backgroundColor,
                                ).withOpacity(0.15),
                                radius: 24,
                                child: Text(
                                  subject.icon,
                                  style: const TextStyle(fontSize: 22),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      subject.namaMateri,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    // Progress Info
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isAllDone
                                            ? Colors.green[50]
                                            : Colors.amber[50],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        isAllDone
                                            ? 'Selesai Semua'
                                            : '$selesaiSub / $totalSub List',
                                        style: TextStyle(
                                          color: isAllDone
                                              ? Colors.green[800]
                                              : Colors.orange[900],
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

// lib/features/daily/presentation/screens/daily_screen.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/services/storage_service.dart';
import '../../../task_master/presentation/widgets/drawer_menu.dart';
import '../../../task_master/presentation/widgets/settings_dialog.dart';
import '../../data/models/daily_model.dart';
import '../widgets/daily_checklist_dialog.dart';
import '../widgets/add_daily_subject_dialog.dart';

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
          setState(() {});
        },
      ),
    );
  }

  void _showAddDailySubjectDialog() {
    showDialog(
      context: context,
      builder: (context) => AddDailySubjectDialog(
        onSave: (newSubject) async {
          if (_dailyData == null) return;
          setState(() {
            _dailyData!.subjects.add(newSubject);
          });
          await _saveDailyData();
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
        backgroundColor: Colors.teal[700],
      ),
      drawer: DrawerMenu(
        selectedBaseDir: _selectedBaseDir,
        fullJsonPath: _fullJsonPath,
        onOpenSettings: _showSettingsDialog,
        isDailyActive: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _dailyData == null || _dailyData!.subjects.isEmpty
          ? const Center(child: Text('Tidak ada rutinitas harian ditemukan.'))
          : LayoutBuilder(
              builder: (context, constraints) {
                final fokusUtamaList = _dailyData!.subjects
                    .where(
                      (s) =>
                          (s.section == 'fokus_utama' ||
                              s.section == 'focus') &&
                          !s.isHidden,
                    )
                    .toList();

                final rutinitasIntiList = _dailyData!.subjects
                    .where((s) => s.section == 'rutinitas_inti' && !s.isHidden)
                    .toList();

                final aktivitasPelengkapList = _dailyData!.subjects
                    .where(
                      (s) =>
                          (s.section == 'aktivitas_pelengkap' ||
                              s.section == 'queue') &&
                          !s.isHidden,
                    )
                    .toList();

                return ListView(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  children: [
                    if (fokusUtamaList.isNotEmpty)
                      _buildSectionHeader(
                        title: '🎯 Fokus Utama',
                        subtitle:
                            'Rutinitas krusial dengan prioritas tertinggi',
                        color: Colors.red[800]!,
                      ),
                    if (fokusUtamaList.isNotEmpty)
                      _buildCategoryGrid(fokusUtamaList, constraints),

                    if (rutinitasIntiList.isNotEmpty)
                      _buildSectionHeader(
                        title: '🔄 Rutinitas Inti',
                        subtitle:
                            'Kegiatan harian standar penunjang produktivitas',
                        color: Colors.indigo[800]!,
                      ),
                    if (rutinitasIntiList.isNotEmpty)
                      _buildCategoryGrid(rutinitasIntiList, constraints),

                    if (aktivitasPelengkapList.isNotEmpty)
                      _buildSectionHeader(
                        title: '🌱 Aktivitas Pelengkap',
                        subtitle: 'Kegiatan opsional dan pengembangan tambahan',
                        color: Colors.teal[800]!,
                      ),
                    if (aktivitasPelengkapList.isNotEmpty)
                      _buildCategoryGrid(aktivitasPelengkapList, constraints),

                    if (fokusUtamaList.isEmpty &&
                        rutinitasIntiList.isEmpty &&
                        aktivitasPelengkapList.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(
                          child: Text('Belum ada materi harian yang aktif.'),
                        ),
                      ),
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDailySubjectDialog,
        backgroundColor: Colors.teal[700],
        child: const Icon(Icons.add, size: 30, color: Colors.white),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          const Divider(height: 1, thickness: 1),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(
    List<DailySubject> subjectsList,
    BoxConstraints constraints,
  ) {
    int crossAxisCount = 2;
    if (constraints.maxWidth >= 1200) {
      crossAxisCount = 5;
    } else if (constraints.maxWidth >= 900) {
      crossAxisCount = 4;
    } else if (constraints.maxWidth >= 600) {
      crossAxisCount = 3;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio:
            0.9, // Sedikit disesuaikan agar pas dengan komponen yang lebih rapat
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: subjectsList.length,
      itemBuilder: (context, index) {
        final subject = subjectsList[index];
        int totalSub = subject.subMateri.length;
        int selesaiSub = subject.subMateri
            .where((sm) => sm.progress == 'selesai')
            .length;
        bool isAllDone = totalSub > 0 && totalSub == selesaiSub;

        String topListText = "Tidak ada list";
        Color topListColor = Colors.grey[600]!;
        TextDecoration? topListDecoration;

        if (subject.subMateri.isNotEmpty) {
          final firstItem = subject.subMateri.first;
          topListText = firstItem.namaMateri;
          if (firstItem.progress == 'selesai') {
            topListColor = Colors.green[700]!;
            topListDecoration = TextDecoration.lineThrough;
          } else {
            topListColor = Colors.black87;
          }
        }
        // KODE BARU (BORDEN PINGGIR TEBAL & BG BERSIH)
        return Card(
          elevation:
              3, // Sedikit dinaikkan agar bayangan lebih halus dan elegan
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Color(
                subject.backgroundColor,
              ), // Warna kustom dialihkan ke border
              width: 3.5, // Mengatur ketebalan garis pinggir sesuai keinginan
            ),
          ),
          color: Colors
              .white, // Latar belakang dibuat putih bersih agar kontras dengan border
          child: InkWell(
            onTap: () => _openMateriChecklist(subject),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. ICON EMOJI (Latar belakang avatar menggunakan warna border transparan)
                  CircleAvatar(
                    backgroundColor: Color(
                      subject.backgroundColor,
                    ).withOpacity(0.12),
                    radius: 30,
                    child: Text(
                      subject.icon,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),

                  // Jarak dari Icon ke Judul
                  const SizedBox(height: 12),

                  // 2. JUDUL UTAMA MATERI (Menggunakan warna gelap konstan agar mudah dibaca di atas warna putih)
                  Text(
                    subject.namaMateri,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87, // Menggunakan warna gelap standar
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),

                  // 3. TANGGAL BERWARNA
                  if (subject.isDateActive && subject.date != null) ...[
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        children: DailySubject.buildColoredDateSpans(
                          subject,
                          inHeader:
                              false, // Diubah ke false agar warnanya kontras pada background putih
                        ),
                      ),
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // Jarak dari area Judul/Tanggal ke Badge List Atas
                  const SizedBox(height: 16),

                  // 4. BADGE LIST PALING ATAS
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Color(subject.backgroundColor).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            isAllDone ? '🎉 Semua Selesai!' : '📌 $topListText',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isAllDone
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: Color(
                                subject.backgroundColor,
                              ), // Mengikuti rumpun warna subject
                              decoration: isAllDone ? null : topListDecoration,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Jarak dari Badge List Atas ke Tombol Progress
                  const SizedBox(height: 12),

                  // 5. BARIS JUMLAH PROGRESS (SOLID)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isAllDone
                          ? Colors.green[600]!.withOpacity(0.9)
                          : Colors.orange[500]!.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Color(subject.backgroundColor).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      isAllDone
                          ? 'Selesai Semua'
                          : '$selesaiSub / $totalSub List',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

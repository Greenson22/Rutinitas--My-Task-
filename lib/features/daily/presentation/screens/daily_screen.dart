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

  // STATE BARU: Menandakan apakah halaman Daily sedang dalam mode edit urutan & seksi
  bool _isPageEditMode = false;

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

  // === MEMINDAHKAN URUTAN MATERI ===
  void _moveSubjectOrder(
    List<DailySubject> sectionList,
    int currentIndex,
    int direction,
  ) async {
    int newIndex = currentIndex + direction;
    if (newIndex < 0 || newIndex >= sectionList.length) return;

    final itemA = sectionList[currentIndex];
    final itemB = sectionList[newIndex];

    int rawIdxA = _dailyData!.subjects.indexWhere(
      (s) => s.namaMateri == itemA.namaMateri,
    );
    int rawIdxB = _dailyData!.subjects.indexWhere(
      (s) => s.namaMateri == itemB.namaMateri,
    );

    if (rawIdxA != -1 && rawIdxB != -1) {
      setState(() {
        final temp = _dailyData!.subjects[rawIdxA];
        _dailyData!.subjects[rawIdxA] = _dailyData!.subjects[rawIdxB];
        _dailyData!.subjects[rawIdxB] = temp;
      });
      await _saveDailyData();
    }
  }

  // === MENGUBAH SEKSI PENEMPATAN MATERI ===
  void _changeSubjectSection(DailySubject subject, String newSection) async {
    setState(() {
      subject.section = newSection;
    });
    await _saveDailyData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Materi "${subject.namaMateri}" dipindahkan.'),
        duration: const Duration(seconds: 1),
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
        actions: [
          // TOMBOL EDIT UTAMA DI ATAS KANAN (APP BAR)
          IconButton(
            icon: Icon(
              _isPageEditMode ? Icons.check_circle : Icons.edit_note,
              size: 28,
            ),
            color: _isPageEditMode ? Colors.amberAccent : Colors.white,
            tooltip: _isPageEditMode
                ? 'Selesai Mengatur'
                : 'Atur Urutan & Seksi',
            onPressed: () {
              setState(() {
                _isPageEditMode = !_isPageEditMode;
              });
            },
          ),
        ],
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
                        title: '🧪 Aktivitas Pelengkap',
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
        // Responsif childAspectRatio berdasarkan mode edit aktif atau tidak
        childAspectRatio: _isPageEditMode ? 0.95 : 1.15,
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

        if (subject.subMateri.isNotEmpty) {
          final firstUnfinishedItem = subject.subMateri.firstWhere(
            (sm) => sm.progress != 'selesai',
            orElse: () => SubMateriItem(namaMateri: '', progress: 'selesai'),
          );

          if (firstUnfinishedItem.namaMateri.isNotEmpty) {
            topListText = firstUnfinishedItem.namaMateri;
          } else {
            topListText = "Semua Selesai!";
          }
        }

        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Color(subject.backgroundColor), width: 3.5),
          ),
          color: Colors.white,
          child: Column(
            children: [
              // Area Konten Utama Materi
              Expanded(
                child: InkWell(
                  onTap: _isPageEditMode
                      ? null
                      : () => _openMateriChecklist(subject),
                  borderRadius: BorderRadius.vertical(
                    top: const Radius.circular(12),
                    bottom: Radius.circular(_isPageEditMode ? 0 : 12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          subject.namaMateri,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        if (subject.isDateActive && subject.date != null) ...[
                          const SizedBox(height: 2),
                          Text.rich(
                            TextSpan(
                              children: DailySubject.buildColoredDateSpans(
                                subject,
                                inHeader: false,
                              ),
                            ),
                            style: const TextStyle(fontSize: 10),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Color(
                              subject.backgroundColor,
                            ).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  isAllDone
                                      ? '🎉 Semua Selesai!'
                                      : '📌 $topListText',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Color(subject.backgroundColor),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        LayoutBuilder(
                          builder: (context, barConstraints) {
                            double progressPercent = totalSub > 0
                                ? selesaiSub / totalSub
                                : 0.0;
                            Color solidProgressBarColor =
                                progressPercent <= 0.33
                                ? Colors.red[700]!
                                : (progressPercent <= 0.75
                                      ? Colors.orange[700]!
                                      : Colors.green[700]!);

                            return Container(
                              width: double.infinity,
                              height: 22,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Color(subject.backgroundColor),
                                  width: 1.2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: Stack(
                                  children: [
                                    Container(
                                      width:
                                          barConstraints.maxWidth *
                                          progressPercent,
                                      height: double.infinity,
                                      color: solidProgressBarColor,
                                    ),
                                    Center(
                                      child: Text(
                                        isAllDone
                                            ? 'Selesai Semua'
                                            : '$selesaiSub / $totalSub List',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // === KONTROL EDIT & PINDAH YANG MUNCUL JIKA MODE EDIT DI ATAS AKTIF ===
              if (_isPageEditMode) ...[
                Divider(height: 1, color: Colors.grey[300]),
                Container(
                  color: Colors.grey[50],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Tombol Urutan Kiri/Atas
                      IconButton(
                        icon: const Icon(Icons.arrow_back, size: 16),
                        color: index > 0 ? Colors.teal[700] : Colors.grey[300],
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: index > 0
                            ? () => _moveSubjectOrder(subjectsList, index, -1)
                            : null,
                      ),

                      // Dropdown untuk Pindah Seksi Penempatan langsung
                      PopupMenuButton<String>(
                        tooltip: 'Pindah Seksi',
                        icon: const Icon(
                          Icons.swap_horiz,
                          size: 16,
                          color: Colors.blueGrey,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onSelected: (value) =>
                            _changeSubjectSection(subject, value),
                        itemBuilder: (context) => [
                          if (subject.section != 'fokus_utama' &&
                              subject.section != 'focus')
                            const PopupMenuItem(
                              value: 'fokus_utama',
                              child: Text(
                                '🎯 Fokus Utama',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          if (subject.section != 'rutinitas_inti')
                            const PopupMenuItem(
                              value:
                                  'rutinitas_inti', // -> Nilai string tujuan sudah valid 'rutinitas_inti'
                              child: Text(
                                '🔄 Rutinitas Inti',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          if (subject.section != 'aktivitas_pelengkap' &&
                              subject.section != 'queue')
                            const PopupMenuItem(
                              value: 'aktivitas_pelengkap',
                              child: Text(
                                '🧪 Aktivitas Pelengkap',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                        ],
                      ),

                      // Tombol Urutan Kanan/Bawah
                      IconButton(
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        color: index < subjectsList.length - 1
                            ? Colors.teal[700]
                            : Colors.grey[300],
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: index < subjectsList.length - 1
                            ? () => _moveSubjectOrder(subjectsList, index, 1)
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

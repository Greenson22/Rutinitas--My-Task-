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
        // UBAH childAspectRatio dari 1.45 menjadi 0.65 agar bentuk kotak memanjang ke bawah (potrait)
        childAspectRatio: 0.65,
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

        // Mendapatkan sub-materi paling atas/pertama
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

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ), // Mengubah radius menjadi lebih rounded (16) sesuai gambar
          child: InkWell(
            onTap: () => _openMateriChecklist(subject),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 20.0,
                horizontal: 12.0,
              ), // Padding disesuaikan
              child: Column(
                mainAxisAlignment: MainAxisAlignment
                    .spaceBetween, // Menyebarkan posisi atas, tengah, bawah agar proporsional
                crossAxisAlignment: CrossAxisAlignment
                    .center, // Semua teks diatur ke tengah (Center)
                children: [
                  // 1. ICON EMOJI (DI ATAS TENGAH)
                  CircleAvatar(
                    backgroundColor: Color(
                      subject.backgroundColor,
                    ).withOpacity(0.15),
                    radius: 32, // Ukuran lingkaran dinaikkan agar lebih jelas
                    child: Text(
                      subject.icon,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // BLOCK INFORMASI UTAMA & TANGGAL
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 2. JUDUL UTAMA MATERI (Contoh: "Harians")
                      Text(
                        subject.namaMateri,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2, // Izinkan 2 baris jika teks panjang
                      ),

                      // 3. TANGGAL BERWARNA (Tepat di bawah judul)
                      if (subject.isDateActive && subject.date != null) ...[
                        const SizedBox(height: 4),
                        Text.rich(
                          TextSpan(
                            children: DailySubject.buildColoredDateSpans(
                              subject,
                            ),
                          ),
                          style: const TextStyle(fontSize: 13),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 8),

                  // 4. INFORMASI LIST PALING ATAS (Berbentuk Kotak Pil / Badge Abu-Abu)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200], // Background badge abu-abu tipis
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            isAllDone ? '🎉 Semua Selesai!' : '🔝 $topListText',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isAllDone
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isAllDone
                                  ? Colors.green[800]
                                  : topListColor,
                              decoration: isAllDone ? null : topListDecoration,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 5. BARIS JUMLAH PROGRESS (Menggunakan Container Lebar Berwarna penuh)
                  Container(
                    width: double.infinity, // Memenuhi lebar kartu
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isAllDone
                          ? Colors.green[600]
                          : Colors
                                .orange[500], // Meniru gaya warna solid di gambar referensi
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isAllDone
                          ? 'Selesai Semua'
                          : '$selesaiSub / $totalSub List',
                      style: const TextStyle(
                        color: Colors
                            .white, // Teks putih agar kontras dengan warna solid
                        fontSize: 13,
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

// lib/features/daily/presentation/screens/checklist_detail_screen.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/services/storage_service.dart';
import '../../data/models/daily_model.dart';
import '../widgets/daily_checklist_dialog.dart';
import '../widgets/add_daily_subject_dialog.dart';

class ChecklistDetailScreen extends StatefulWidget {
  final ChecklistHub hub;
  final String baseDir;

  const ChecklistDetailScreen({
    super.key,
    required this.hub,
    required this.baseDir,
  });

  @override
  State<ChecklistDetailScreen> createState() => _ChecklistDetailScreenState();
}

class _ChecklistDetailScreenState extends State<ChecklistDetailScreen> {
  final StorageService _storageService = StorageService();
  bool _isPageEditMode = false;
  late ChecklistHub _currentHub;

  @override
  void initState() {
    super.initState();
    _currentHub =
        widget.hub; // Mengambil data hub yang diklik dari layar sebelumnya
  }

  // Fungsi menyimpan khusus ke file JSON milik Hub ini saja
  Future<void> _saveHubData() async {
    final Map<String, dynamic> updatedMap = _currentHub.toJson();
    final String jsonString = const JsonEncoder.withIndent(
      '  ',
    ).convert(updatedMap);
    try {
      File jsonFile = await _storageService.getSpecificHubFile(
        widget.baseDir,
        _currentHub.id,
      );
      await _storageService.saveJsonData(jsonFile, jsonString);
    } catch (e) {
      debugPrint("Error saving hub data: $e");
    }
  }

  void _openMateriChecklist(DailySubject subject) {
    showDialog(
      context: context,
      builder: (context) => DailyChecklistDialog(
        subject: subject,
        onDataChanged: () {
          _saveHubData();
          setState(() {});
        },
      ),
    );
  }

  void _showAddSectionDialog() {
    // Fungsi baru untuk menambah Seksi Kustom (Misal: "Sembako Bulanan")
    final _sectionController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Seksi Penempatan'),
        content: TextField(
          controller: _sectionController,
          decoration: const InputDecoration(hintText: 'Nama Seksi Baru...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_sectionController.text.isNotEmpty) {
                setState(() {
                  _currentHub.semuaList.add(
                    ChecklistSection(
                      namaSeksi: _sectionController.text,
                      items: [],
                    ),
                  );
                });
                _saveHubData();
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Row(
          children: [
            Text(_currentHub.ikon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(_currentHub.namaHub),
          ],
        ),
        backgroundColor: Colors.teal[700],
        actions: [
          IconButton(
            icon: Icon(
              _isPageEditMode ? Icons.check_circle : Icons.edit_note,
              size: 28,
            ),
            color: _isPageEditMode ? Colors.amberAccent : Colors.white,
            onPressed: () => setState(() => _isPageEditMode = !_isPageEditMode),
          ),
        ],
      ),
      body: _currentHub.semuaList.isEmpty
          ? const Center(
              child: Text(
                'Belum ada seksi list di Hub ini. Tambahkan seksi baru!',
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: _currentHub.semuaList.length,
                  itemBuilder: (context, index) {
                    final section = _currentHub.semuaList[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          section.namaSeksi,
                          Colors.teal[800]!,
                        ),
                        _buildCategoryGrid(section.items, constraints),
                        if (_isPageEditMode)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: TextButton.icon(
                              onPressed: () {
                                // Tambah item ke dalam seksi ini
                                showDialog(
                                  context: context,
                                  builder: (context) => AddDailySubjectDialog(
                                    onSave: (newSubject) {
                                      setState(
                                        () => section.items.add(newSubject),
                                      );
                                      _saveHubData();
                                    },
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.add_box,
                                color: Colors.teal,
                              ),
                              label: Text(
                                'Tambah Item ke "${section.namaSeksi}"',
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSectionDialog,
        backgroundColor: Colors.teal[800],
        tooltip: 'Tambah Seksi Baru',
        child: const Icon(Icons.post_add, size: 30, color: Colors.white),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
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
          const Divider(height: 1, thickness: 1),
        ],
      ),
    );
  }

  // === UI PROGRESS BAR & KARTU LAMA ANDA TETAP AMAN DI SINI ===
  // === UI KOTAK UTUH DAN LENGKAP LAMA ANDA SEKARANG SUDAH DIKEMBALIKAN ===
  // === UI KOTAK UTUH DAN LENGKAP DENGAN FITUR MOVE POSISI YANG SUDAH DIPULIHKAN ===
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
                                color: Colors.grey[200],
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
                                          shadows: [
                                            Shadow(
                                              offset: Offset(0.5, 0.5),
                                              blurRadius: 1.0,
                                              color: Colors.black87,
                                            ),
                                          ],
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

              // === PERBAIKAN: KONTROL MOVE (PINDAH POSISI URUTAN KARTU) TELAH DIKEMBALIKAN ===
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
                      // Tombol Move Kiri / Atas Urutan Posisi Kartu
                      IconButton(
                        icon: const Icon(Icons.arrow_back, size: 16),
                        color: index > 0 ? Colors.teal[700] : Colors.grey[300],
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: index > 0
                            ? () {
                                setState(() {
                                  // Logika tukar posisi di dalam seksi kustom yang aktif
                                  final temp = subjectsList[index];
                                  subjectsList[index] = subjectsList[index - 1];
                                  subjectsList[index - 1] = temp;
                                });
                                _saveHubData(); // Auto-save urutan posisi baru ke JSON lokal
                              }
                            : null,
                      ),

                      // Popup Menu Pindah Seksi Penempatan secara Dinamis
                      PopupMenuButton<String>(
                        tooltip: 'Pindah Seksi',
                        icon: const Icon(
                          Icons.swap_horiz,
                          size: 16,
                          color: Colors.blueGrey,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onSelected: (targetSectionName) {
                          setState(() {
                            final itemToMove = subjectsList.removeAt(index);
                            _currentHub.semuaList
                                .firstWhere(
                                  (sec) => sec.namaSeksi == targetSectionName,
                                )
                                .items
                                .add(itemToMove);
                          });
                          _saveHubData();
                        },
                        itemBuilder: (context) => _currentHub.semuaList
                            .map(
                              (sec) => PopupMenuItem<String>(
                                value: sec.namaSeksi,
                                child: Text(
                                  sec.namaSeksi,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            )
                            .toList(),
                      ),

                      // Tombol Move Kanan / Bawah Urutan Posisi Kartu
                      IconButton(
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        color: index < subjectsList.length - 1
                            ? Colors.teal[700]
                            : Colors.grey[300],
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: index < subjectsList.length - 1
                            ? () {
                                setState(() {
                                  // Logika tukar posisi di dalam seksi kustom yang aktif
                                  final temp = subjectsList[index];
                                  subjectsList[index] = subjectsList[index + 1];
                                  subjectsList[index + 1] = temp;
                                });
                                _saveHubData(); // Auto-save urutan posisi baru ke JSON lokal
                              }
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

// lib/features/daily/presentation/controllers/checklist_detail_controller.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // TAMBAHAN: Diperlukan untuk utilitas interaksi Clipboard (Salin/Tempel)
import '../../../../core/services/storage_service.dart';
import '../../data/models/daily_model.dart';
import '../widgets/checklist_detail/checklist_dialog.dart';
import '../widgets/checklist_detail/add_checklist_subject_dialog.dart';
import '../screens/checklist_detail_screen.dart';

abstract class ChecklistDetailController extends State<ChecklistDetailScreen> {
  final StorageService storageService = StorageService();
  bool isPageEditMode = false;
  bool isSectionEditMode = false;
  late ChecklistGroup currentGroup;

  // State untuk menyimpan teks pencarian item
  String searchQuery = '';

  // PERBAIKAN: Mengubah nama seksi default/standar menjadi "Seksi Utama"
  static const String defaultSectionName = "Seksi Utama";

  @override
  void initState() {
    super.initState();
    currentGroup = widget.group; // Mengambil data hub dari layar sebelumnya
  }

  // Fungsi memperbarui query pencarian dari UI
  void updateSearchQuery(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
    });
  }

  // Fungsi menyimpan khusus ke file JSON milik Hub ini saja
  Future<void> saveGroupData() async {
    final Map<String, dynamic> updatedMap = currentGroup.toJson();
    final String jsonString = const JsonEncoder.withIndent(
      '  ',
    ).convert(updatedMap);
    try {
      File jsonFile = await storageService.getSpecificGroupFile(
        widget.baseDir,
        currentGroup.id,
      );
      await storageService.saveJsonData(jsonFile, jsonString);
    } catch (e) {
      debugPrint("Error saving group data: $e");
    }
  }

  // =========================================================================
  // FITUR BARU: Mengubah Status Visibilitas Item (Sembunyikan / Tampilkan)
  // =========================================================================
  Future<void> toggleSubjectVisibility(DailySubject subject) async {
    setState(() {
      // Membalikkan status boolean isHidden pada model subjek
      subject.isHidden = !subject.isHidden;
    });

    // Simpan perubahan status visibilitas ke berkas lokal
    await saveGroupData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            subject.isHidden
                ? 'Item "${subject.subjectName}" berhasil disembunyikan'
                : 'Item "${subject.subjectName}" berhasil ditampilkan kembali',
          ),
          backgroundColor: Colors.teal,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // =========================================================================
  // FITUR BARU: Memindahkan DailySubject ke Berkas Grup Lain dengan Konfirmasi
  // =========================================================================
  Future<void> moveChecklistToAnotherGroup({
    required List<DailySubject> currentSectionItems,
    required DailySubject subject,
    required ChecklistGroup targetGroup,
  }) async {
    final bool confirm =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.drive_file_move_rounded, color: Colors.teal),
                SizedBox(width: 8),
                Text('Konfirmasi Pindah Grup'),
              ],
            ),
            content: Text(
              'Apakah Anda yakin ingin memindahkan item "${subject.subjectName}" keluar dari grup saat ini menuju grup "${targetGroup.groupName}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: const Text(
                  'Ya, Pindahkan',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    try {
      // 1. Tentukan target penempatan seksi di dalam grup tujuan.
      String targetSectionName = defaultSectionName;
      if (targetGroup.allList.isNotEmpty) {
        targetSectionName = targetGroup.allList.first.sectionName;
      } else {
        targetGroup.allList.add(
          ChecklistSection(sectionName: targetSectionName, items: []),
        );
      }

      // 2. Sesuaikan penanda nama seksi internal pada model subjek
      subject.section = targetSectionName;

      // 3. Masukkan subjek ke dalam manifest struktur seksi grup target
      targetGroup.allList
          .firstWhere((sec) => sec.sectionName == targetSectionName)
          .items
          .add(subject);

      // 4. Konstruksi penyimpanan fisik ke disk file JSON grup tujuan secara independen
      final String targetJsonString = const JsonEncoder.withIndent(
        '  ',
      ).convert(targetGroup.toJson());
      File targetJsonFile = await storageService.getSpecificGroupFile(
        widget.baseDir,
        targetGroup.id,
      );
      await storageService.saveJsonData(targetJsonFile, targetJsonString);

      // 5. Jika sukses menulis file eksternal, barulah hapus subjek dari grup saat ini secara lokal
      setState(() {
        currentSectionItems.remove(subject);
      });

      // 6. Tulis ulang perubahan grup saat ini ke penyimpanan disk lokal
      await saveGroupData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Berhasil memindahkan "${subject.subjectName}" ke grup "${targetGroup.groupName}"!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Gagal memindahkan checklist antar grup: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Gagal memindahkan item akibat kesalahan penyimpanan file sistem.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // =========================================================================
  // FITUR UTAMA BARU: Dialog Editor Raw JSON Item Card (Sangat Interaktif)
  // =========================================================================
  void showEditJsonDialog(DailySubject subject) {
    final TextEditingController jsonController = TextEditingController();

    // Mengubah model subject saat ini menjadi format text JSON rapi (Pretty Print Indentation)
    try {
      final map = subject.toJson();
      jsonController.text = const JsonEncoder.withIndent('  ').convert(map);
    } catch (e) {
      jsonController.text = "{}";
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.data_object_rounded, color: Colors.deepOrange),
              SizedBox(width: 8),
              Text(
                'Edit Raw JSON Item',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height:
                MediaQuery.of(context).size.height *
                0.62, // Mengisi 62% tinggi layar agar area edit luas
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Peringatan: Struktur JSON harus valid. Perubahan properti sub-materi akan langsung diperbarui.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Sediakan tombol interaktif Salin & Tempel cepat tanpa repot block teks manual
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.copy_all,
                            color: Colors.indigo,
                            size: 20,
                          ),
                          tooltip: 'Salin JSON',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: jsonController.text),
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('JSON disalin ke clipboard!'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(width: 14),
                        IconButton(
                          icon: const Icon(
                            Icons.paste,
                            color: Colors.teal,
                            size: 20,
                          ),
                          tooltip: 'Tempel JSON',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () async {
                            final data = await Clipboard.getData(
                              Clipboard.kTextPlain,
                            );
                            if (data != null && data.text != null) {
                              jsonController.text = data.text!;
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TextField(
                    controller: jsonController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 13,
                      height: 1.3,
                    ), // Gaya font koding monospace
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      fillColor: Color(0xFFF8F9FA),
                      filled: true,
                      hintText:
                          'Masukkan atau tempel struktur objek JSON yang valid...',
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                try {
                  final String rawInput = jsonController.text.trim();
                  if (rawInput.isEmpty)
                    throw Exception("Konten JSON tidak boleh kosong.");

                  final decoded = jsonDecode(rawInput);
                  if (decoded is! Map<String, dynamic>) {
                    throw const FormatException(
                      'Format root JSON harus berupa Objek Map kriting {...}',
                    );
                  }

                  // Lakukan parsing instans baru untuk memvalidasi pemetaan tipe data model berlapis
                  final parsedSubject = DailySubject.fromJson(decoded);

                  setState(() {
                    // Update field per field secara presisi untuk menjaga sinkronisasi UI Grid Referensial
                    subject.subjectName = parsedSubject.subjectName;
                    subject.progress = parsedSubject.progress;
                    subject.subMateri = parsedSubject.subMateri;
                    subject.backgroundColor = parsedSubject.backgroundColor;
                    subject.textColor = parsedSubject.textColor;
                    subject.progressBarColor = parsedSubject.progressBarColor;
                    subject.icon = parsedSubject.icon;
                    subject.isHidden = parsedSubject.isHidden;
                    subject.type = parsedSubject.type;
                    subject.noteContent = parsedSubject.noteContent;
                    subject.date = parsedSubject.date;
                    subject.isDateActive = parsedSubject.isDateActive;
                    subject.dateType = parsedSubject.dateType;
                    subject.endDate = parsedSubject.endDate;
                    subject.isMarkdownEnabled = parsedSubject.isMarkdownEnabled;
                    subject.defaultExpanded = parsedSubject.defaultExpanded;

                    // Rekalkulasi status hierarkis sub-materi secara internal otomatis
                    for (var root in subject.subMateri) {
                      root.updateStatusFromChildren();
                    }
                  });

                  saveGroupData(); // Simpan permanen ke storage disk lokal harian
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Data JSON Card berhasil disimpan & diperbarui!',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  debugPrint("JSON Parse Error: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Gagal menyimpan! Format koding JSON tidak valid.\nDetail: $e',
                      ),
                      backgroundColor: Colors.redAccent,
                      duration: const Duration(
                        seconds: 4,
                      ), // Waktu tahan lama agar user sempat membaca error
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              child: const Text(
                'Simpan JSON',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void openMateriChecklist(DailySubject subject) {
    // Kumpulkan semua kotak materi (DailySubject) dari seluruh seksi yang tersedia
    List<DailySubject> allAvailableSubjects = [];
    for (var section in currentGroup.allList) {
      allAvailableSubjects.addAll(section.items);
    }

    showDialog(
      context: context,
      builder: (context) => DailyChecklistDialog(
        subject: subject,
        allAvailableSubjects:
            allAvailableSubjects, // Pindah ke kotak checklist lainnya
        onDataChanged: () {
          saveGroupData();
          setState(() {});
        },
      ),
    );
  }

  void showAddSectionDialog() {
    final sectionController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Seksi Penempatan'),
        content: TextField(
          controller: sectionController,
          decoration: const InputDecoration(hintText: 'Nama Seksi Baru...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (sectionController.text.isNotEmpty) {
                setState(() {
                  // Jika seksi pertama masih berupa seksi unik default, otomatis ubah namanya
                  if (currentGroup.allList.length == 1 &&
                      currentGroup.allList.first.sectionName ==
                          defaultSectionName) {
                    currentGroup.allList.first.sectionName = "Seksi Utama";
                  }

                  // Tambahkan seksi baru pilihan pengguna
                  currentGroup.allList.add(
                    ChecklistSection(
                      sectionName: sectionController.text.trim(),
                      items: [],
                    ),
                  );
                });
                saveGroupData();
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void addItemToSection(BuildContext context, ChecklistSection? targetSection) {
    showDialog(
      context: context,
      builder: (context) => AddDailySubjectDialog(
        existingSections: currentGroup.allList.isEmpty
            ? [defaultSectionName]
            : currentGroup.allList.map((sec) => sec.sectionName).toList(),
        onSave: (newSubject) {
          setState(() {
            // Jika ditambahkan saat kosong, buat seksi unik terlebih dahulu
            if (currentGroup.allList.isEmpty) {
              final newSection = ChecklistSection(
                sectionName: defaultSectionName,
                items: [newSubject],
              );
              currentGroup.allList.add(newSection);
            } else {
              // Jika seksi target ada, langsung masukkan ke seksi tersebut
              if (targetSection != null) {
                targetSection.items.add(newSubject);
              } else if (currentGroup.allList.isNotEmpty) {
                // Fallback ke seksi pertama jika targetSection bernilai null
                currentGroup.allList.first.items.add(newSubject);
              }
            }
          });
          saveGroupData();
        },
      ),
    );
  }

  void deleteItemFromSection(
    List<DailySubject> subjectsList,
    DailySubject subject,
  ) async {
    final bool confirm =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hapus Item Checklist?'),
            content: Text(
              'Apakah Anda yakin ingin menghapus "${subject.subjectName}" beserta seluruh sub-materinya?',
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
        ) ??
        false;

    if (confirm) {
      setState(() {
        subjectsList.remove(subject);
      });
      saveGroupData();
    }
  }

  void editSectionName(ChecklistSection section) {
    final editController = TextEditingController(text: section.sectionName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Nama Seksi'),
        content: TextField(controller: editController),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (editController.text.isNotEmpty) {
                setState(
                  () => section.sectionName = editController.text.trim(),
                );
                saveGroupData();
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void deleteSection(ChecklistSection section) async {
    final bool confirm =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hapus Seksi?'),
            content: Text(
              'Apakah Anda yakin ingin menghapus seksi "${section.sectionName}" beserta seluruh item di dalamnya?',
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
        ) ??
        false;

    if (confirm) {
      setState(() => currentGroup.allList.remove(section));
      saveGroupData();
    }
  }

  void moveSectionOrder(int currentIndex, int direction) {
    int newIndex = currentIndex + direction;
    if (newIndex < 0 || newIndex >= currentGroup.allList.length) return;

    setState(() {
      final temp = currentGroup.allList[currentIndex];
      currentGroup.allList[currentIndex] = currentGroup.allList[newIndex];
      currentGroup.allList[newIndex] = temp;
    });
    saveGroupData();
  }
}

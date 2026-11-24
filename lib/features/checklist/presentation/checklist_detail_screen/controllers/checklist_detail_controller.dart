// lib/features/daily/presentation/checklist_detail_screen/controllers/checklist_detail_controller.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rutinitasku/core/utils/atomic_write_helper.dart';
import '../../../../../core/services/storage_service.dart';
import '../../../../../core/utils/crypto_helper.dart'; // <--- IMPORT BARU UNTUK ENKRIPSI
import '../../../data/models/daily_model.dart';
import '../widgets/checklist_dialog.dart';
import '../widgets/add_checklist_subject_dialog.dart';
import '../checklist_detail_screen.dart';

abstract class ChecklistDetailController extends State<ChecklistDetailScreen> {
  final StorageService storageService = StorageService();
  bool isPageEditMode = false;
  bool isSectionEditMode = false;
  late ChecklistGroup currentGroup;
  String searchQuery = '';
  static const String defaultSectionName = "Seksi Utama";

  @override
  void initState() {
    super.initState();
    currentGroup = widget.group;
  }

  void updateSearchQuery(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
    });
  }

  // Fungsi menyimpan khusus ke file JSON milik Hub ini saja (Menghormati status isEncrypted)
  Future<void> saveGroupData() async {
    final Map<String, dynamic> updatedMap = currentGroup.toJson();
    String jsonString = const JsonEncoder.withIndent('  ').convert(updatedMap);

    try {
      File jsonFile = await storageService.getSpecificGroupFile(
        widget.baseDir,
        currentGroup.id,
      );

      if (currentGroup.isEncrypted) {
        String? password = await storageService.getEncryptionPassword();
        if (password != null && password.isNotEmpty) {
          // PERBAIKAN: Ubah decrypt menjadi encrypt
          jsonString = CryptoHelper.encrypt(jsonString, password);
        }
      }

      // PANGGIL HELPER DI SINI
      await AtomicWriteHelper.writeSafe(
        targetFile: jsonFile,
        content: jsonString,
      );
    } catch (e) {
      debugPrint("Error saving group data: $e");
    }
  }

  Future<void> toggleSectionHidden(ChecklistSection section) async {
    setState(() {
      section.isHidden = !section.isHidden;
    });

    await saveGroupData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            section.isHidden
                ? 'Seksi "${section.sectionName}" berhasil disembunyikan'
                : 'Seksi "${section.sectionName}" berhasil ditampilkan kembali',
          ),
          backgroundColor: Colors.teal,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> toggleSubjectVisibility(DailySubject subject) async {
    setState(() {
      subject.isHidden = !subject.isHidden;
    });

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
      String targetSectionName = defaultSectionName;
      if (targetGroup.allList.isNotEmpty) {
        targetSectionName = targetGroup.allList.first.sectionName;
      } else {
        targetGroup.allList.add(
          ChecklistSection(sectionName: targetSectionName, items: []),
        );
      }

      subject.section = targetSectionName;

      targetGroup.allList
          .firstWhere((sec) => sec.sectionName == targetSectionName)
          .items
          .add(subject);

      String targetJsonString = const JsonEncoder.withIndent(
        '  ',
      ).convert(targetGroup.toJson());

      // MODIFIKASI: Hormati properti enkripsi khusus group target!
      if (targetGroup.isEncrypted) {
        String? password = await storageService.getEncryptionPassword();
        if (password != null && password.isNotEmpty) {
          targetJsonString = CryptoHelper.encrypt(targetJsonString, password);
        }
      }

      File targetJsonFile = await storageService.getSpecificGroupFile(
        widget.baseDir,
        targetGroup.id,
      );

      await AtomicWriteHelper.writeSafe(
        targetFile: targetJsonFile,
        content: targetJsonString,
      );

      setState(() {
        currentSectionItems.remove(subject);
      });

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

  void showEditJsonDialog(DailySubject subject) {
    final TextEditingController jsonController = TextEditingController();

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
            height: MediaQuery.of(context).size.height * 0.62,
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
                    ),
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

                  final parsedSubject = DailySubject.fromJson(decoded);

                  setState(() {
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

                    for (var root in subject.subMateri) {
                      root.updateStatusFromChildren();
                    }
                  });

                  saveGroupData();
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
                      duration: const Duration(seconds: 4),
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
    List<DailySubject> allAvailableSubjects = [];
    for (var section in currentGroup.allList) {
      allAvailableSubjects.addAll(section.items);
    }

    showDialog(
      context: context,
      builder: (context) => DailyChecklistDialog(
        subject: subject,
        allAvailableSubjects: allAvailableSubjects,
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
                  if (currentGroup.allList.length == 1 &&
                      currentGroup.allList.first.sectionName ==
                          defaultSectionName) {
                    currentGroup.allList.first.sectionName = "Seksi Utama";
                  }

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
            if (currentGroup.allList.isEmpty) {
              final newSection = ChecklistSection(
                sectionName: defaultSectionName,
                items: [newSubject],
              );
              currentGroup.allList.add(newSection);
            } else {
              if (targetSection != null) {
                targetSection.items.add(newSubject);
              } else if (currentGroup.allList.isNotEmpty) {
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
    // Alur hapus seksi kosong: hapus langsung tanpa dialog konfirmasi
    if (section.items.isEmpty) {
      setState(() => currentGroup.allList.remove(section));
      saveGroupData();
      return;
    }

    final int totalItems = section.items.length;
    final int hiddenItemsCount = section.items.where((i) => i.isHidden).length;

    final String itemInfo = hiddenItemsCount > 0
        ? '$totalItems item ($hiddenItemsCount tersembunyi)'
        : '$totalItems item';

    final bool confirm =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 36),
            title: const Text('Hapus Seksi?'),
            content: Text(
              'Seksi "${section.sectionName}" masih berisi $itemInfo. Apakah Anda yakin ingin menghapus seksi ini beserta seluruh isinya?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Hapus Semua'),
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

  // =========================================================================
  // OPERASI INTI DAILY TRACKER
  // =========================================================================

  /// Menyimpan snapshot status seluruh item checklist hari ini secara rekursif.
  /// Jika sudah ada entri di hari yang sama, data akan di-overwrite.
  /// Mengembalikan string key tanggal yang berhasil disimpan (format yyyy-MM-dd).
  Future<String> saveTodayLog(DailySubject subject) async {
    final now = DateTime.now();
    final String todayKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final List<DailyLogEntry> entries = subject.subMateri
        .map((item) => DailyLogEntry.fromSubSubjectItem(item))
        .toList();

    subject.dailyLogs[todayKey] = entries;
    await saveGroupData();
    return todayKey;
  }

  /// Menampilkan dialog konfirmasi dan mereset status semua item checklist
  /// ke 'belum' dan currentValue ke 0 secara rekursif tanpa mengubah dailyLogs.
  Future<bool> resetForNewDay(DailySubject subject) async {
    final bool confirm =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Reset Hari Baru?'),
            content: Text(
              'Apakah Anda yakin ingin mereset seluruh item pada "${subject.subjectName}" untuk memulai hari baru? Status centang akan dikosongkan, namun riwayat DailyTracker yang sudah tersimpan tetap aman.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: const Text(
                  'Ya, Reset',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return false;

    void resetRecursive(List<SubSubjectItem> items) {
      for (var item in items) {
        item.progress = 'belum';
        item.currentValue = 0;
        if (item.subMateri.isNotEmpty) {
          resetRecursive(item.subMateri);
        }
      }
    }

    setState(() {
      resetRecursive(subject.subMateri);
    });

    await saveGroupData();
    return true;
  }

  /// Menghapus seluruh riwayat dailyLogs pada DailySubject.
  Future<void> deleteDailyLog(DailySubject subject) async {
    setState(() {
      subject.dailyLogs.clear();
    });
    await saveGroupData();
  }

  /// Menghapus entri dailyLogs yang memiliki key diawali dengan yearMonth (format yyyy-MM).
  Future<void> deleteDailyLogsByMonth(
    DailySubject subject,
    String yearMonth,
  ) async {
    setState(() {
      subject.dailyLogs.removeWhere((key, _) => key.startsWith(yearMonth));
    });
    await saveGroupData();
  }

  /// Memperbarui entri dailyLogs pada tanggal tertentu (dateKey) dengan daftar entri baru.
  Future<void> editDailyLogEntry(
    DailySubject subject,
    String dateKey,
    List<DailyLogEntry> updatedEntries,
  ) async {
    setState(() {
      subject.dailyLogs[dateKey] = updatedEntries;
    });
    await saveGroupData();
  }

  /// Menghapus entri dailyLogs pada tanggal tertentu (dateKey).
  Future<void> deleteDailyLogEntry(
    DailySubject subject,
    String dateKey,
  ) async {
    setState(() {
      subject.dailyLogs.remove(dateKey);
    });
    await saveGroupData();
  }
}

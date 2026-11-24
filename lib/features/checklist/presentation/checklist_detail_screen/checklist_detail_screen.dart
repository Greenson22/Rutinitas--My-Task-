// lib/features/daily/presentation/screens/checklist_detail_screen.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // TAAMBAHAN: Diperlukan untuk interaksi Clipboard (Salin/Tempel JSON)[cite: 5]
import 'package:rutinitasku/core/presentation/widgets/base_popup_dialog.dart';
import '../../data/models/daily_model.dart';
import '../../utils/checklist_calculation_helper.dart';
import 'controllers/checklist_detail_controller.dart';
import '../../../../core/presentation/widgets/grouped_section_layout.dart';
import '../../../../core/presentation/widgets/interactive_grid_card.dart';
import '../../../../core/presentation/widgets/interactive_section_header.dart';
import '../../../../core/presentation/widgets/universal_empty_state.dart'; // Using Universal Widget from Core[cite: 5]
import '../../../../core/presentation/widgets/adaptive_banner_ad.dart'; // <--- IMPORT WIDGET ADMOB BARU
import 'widgets/checklist_dialog.dart'; // Import Dialog kustom[cite: 5]
import '../daily_tracker_history_screen/daily_tracker_history_screen.dart';

class ChecklistDetailScreen extends StatefulWidget {
  final ChecklistGroup group;
  final String baseDir;

  // Parameter opsional penampung manifes seluruh subjek grup untuk sinkronisasi instan
  final List<ChecklistGroup>? allAvailableGroups;

  const ChecklistDetailScreen({
    super.key,
    required this.group,
    required this.baseDir,
    this.allAvailableGroups,
  });

  @override
  State<ChecklistDetailScreen> createState() => _ChecklistDetailScreenState();
}

class _ChecklistDetailScreenState extends ChecklistDetailController {
  List<ChecklistGroup> _loadedAllGroups = [];

  // === STATE SAKELAR GLOBAL: Tampil/Sembunyikan item tersembunyi ===
  bool _showHiddenItems = false;

  @override
  void initState() {
    super.initState();
    if (widget.allAvailableGroups != null) {
      _loadedAllGroups = widget.allAvailableGroups!;
    } else {
      _loadExtendedGroupsManifest();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Fungsi fail-safe untuk memuat daftar seluruh berkas grup checklist eksternal dari disk
  Future<void> _loadExtendedGroupsManifest() async {
    try {
      List<File> files = await storageService.getAllChecklistGroups(
        widget.baseDir,
      );
      List<ChecklistGroup> groups = [];
      for (var f in files) {
        if (!await f.exists()) continue;
        String content = await f.readAsString();
        String fName = f.path.split('/').last.replaceAll('.json', '');
        final trimmed = content.trim();
        if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
          final map = jsonDecode(trimmed);
          map['id'] = fName;
          groups.add(ChecklistGroup.fromJson(map));
        }
      }
      setState(() => _loadedAllGroups = groups);
    } catch (e) {
      debugPrint("Gagal memuat manifest grup eksternal: $e");
    }
  }

  // FITUR BARU: Menampilkan Dialog khusus untuk memilih kelompok Grup Tujuan Pemindahan Card Checklist
  void _showTargetGroupSelectionDialog({
    required ChecklistSection originalSection,
    required DailySubject subject,
  }) {
    // Saring grup yang valid (bukan grup aktif saat ini, dan bukan berkas korup)[cite: 5]
    final List<ChecklistGroup> validTargetGroups = _loadedAllGroups
        .where((g) => g.id != currentGroup.id && !g.id.startsWith("CORRUPTED_"))
        .toList();

    // Jika tidak ada grup lain selain grup ini, tampilkan notifikasi sama seperti Notes[cite: 5]
    if (validTargetGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada grup checklist lain yang tersedia.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Tampilkan Dialog berbasis BasePopupDialog dengan spesifikasi UI modul Notes[cite: 5]
    showDialog(
      context: context,
      builder: (dialogCtx) => BasePopupDialog(
        title: const Text(
          'Pindah Target Grup Tujuan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        themeColor:
            Colors.teal[700]!, // Menyesuaikan aksen Checklist (Teal)[cite: 5]
        titleColor: Colors.white,
        content: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih Grup Tujuan Pemindahan:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: validTargetGroups.length,
                  itemBuilder: (context, index) {
                    final targetGroupObj = validTargetGroups[index];
                    return ListTile(
                      dense: true,
                      leading: Text(
                        targetGroupObj.icon.isEmpty ? ' ' : targetGroupObj.icon,
                        style: const TextStyle(fontSize: 18),
                      ),
                      title: Text(
                        targetGroupObj.groupName,
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        targetGroupObj.sectionCategory,
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal[700],
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onPressed: () {
                          Navigator.pop(dialogCtx);
                          // Jalankan fungsi mutasi data ke controller utama
                          moveChecklistToAnotherGroup(
                            currentSectionItems: originalSection.items,
                            subject: subject,
                            targetGroup: targetGroupObj,
                          );
                        },
                        child: const Text(
                          'Pindah Ke Sini',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // FITUR UTAMA BARU: Dialog Editor Raw JSON Item Checklist (Sangat Interaktif)
  // =========================================================================
  void _showEditJsonDialog(DailySubject subject) {
    final TextEditingController jsonController = TextEditingController();

    // Transformasikan model subject saat ini menjadi raw teks JSON dengan Pretty Print (Indentation)[cite: 5]
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
                0.62, // Mengisi 62% tinggi layar agar luas dan presisi[cite: 5]
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Peringatan: Struktur JSON harus valid. Perubahan struktur sub-materi akan langsung diperbarui.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Menyediakan tombol interaktif Salin & Tempel cepat untuk meningkatkan UX[cite: 5]
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
                                  content: Text(
                                    'JSON berhasil disalin ke clipboard!',
                                  ),
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
                            final clipboardData = await Clipboard.getData(
                              Clipboard.kTextPlain,
                            );
                            if (clipboardData != null &&
                                clipboardData.text != null) {
                              jsonController.text = clipboardData.text!;
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
                    ), // Font bergaya monospace koding[cite: 5]
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      fillColor: Color(0xFFF8F9FA),
                      filled: true,
                      hintText:
                          'Tempel atau ketik modifikasi struktur objek JSON disini...',
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
                    throw Exception("Konten koding JSON tidak boleh kosong.");

                  final decodedJson = jsonDecode(rawInput);
                  if (decodedJson is! Map<String, dynamic>) {
                    throw const FormatException(
                      'Format root JSON utama wajib berupa Objek Map kriting {...}',
                    );
                  }

                  // Melakukan parsing data instans baru untuk memvalidasi data model[cite: 5]
                  final parsedSubject = DailySubject.fromJson(decodedJson);

                  setState(() {
                    // Update field demi field untuk mempertahankan sinkronisasi visual Grid[cite: 5]
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
                    subject.notePages = parsedSubject.notePages;
                    subject.currentNotePage = parsedSubject.currentNotePage;
                    subject.date = parsedSubject.date;
                    subject.isDateActive = parsedSubject.isDateActive;
                    subject.dateType = parsedSubject.dateType;
                    subject.endDate = parsedSubject.endDate;
                    subject.isMarkdownEnabled = parsedSubject.isMarkdownEnabled;
                    subject.defaultExpanded = parsedSubject.defaultExpanded;

                    // Jalankan rekursif updateStatus agar kalkulasi bar progress ikut sinkron otomatis[cite: 5]
                    for (var root in subject.subMateri) {
                      root.updateStatusFromChildren();
                    }
                  });

                  saveGroupData(); // Tulis perubahan ke dalam file penyimpanan fisik[cite: 5]
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Sempurna! Perubahan via JSON berhasil diterapkan.',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (err) {
                  debugPrint("Gagal memproses pengeditan JSON: $err");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Gagal menyimpan! Format atau parameter JSON tidak valid.\\nDetail: $err',
                      ),
                      backgroundColor: Colors.redAccent,
                      duration: const Duration(
                        seconds: 4,
                      ), // Waktu durasi lebih lama agar pengguna bisa menganalisis error kodingnya[cite: 5]
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

  // SOLUSI UTAMA: Meng-override fungsi openMateriChecklist dari Controller untuk menyuntikkan ukuran Dialog melar[cite: 5]
  @override
  void openMateriChecklist(DailySubject subject) {
    // Kumpulkan semua kotak materi (DailySubject) dari seluruh seksi yang tersedia untuk parameter dialog[cite: 5]
    List<DailySubject> allAvailableSubjects = [];
    for (var section in currentGroup.allList) {
      for (var item in section.items) {
        // SINKRONISASI AKTIF: Paksa isi properti item.section agar mutlak sesuai
        // dengan nama seksi tempat penampung visualnya saat ini sebelum dioper ke dialog.[cite: 5]
        item.section = section.sectionName;
        allAvailableSubjects.add(item);
      }
    }

    final double screenWidth = MediaQuery.of(context).size.width;

    // GlobalKey baru untuk mengakses status internal (_isNoteModified) dari dialog secara langsung[cite: 5]
    final globalDialogKey = GlobalKey<State<DailyChecklistDialog>>();

    // Fungsi lokal untuk menampilkan pop-up konfirmasi simpan/buang perubahan[cite: 5]
    Future<bool> _showExitConfirmationDialog(BuildContext targetCtx) async {
      final result = await showDialog<String>(
        context: targetCtx,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber),
              SizedBox(width: 8),
              Text('Perubahan Belum Disimpan'),
            ],
          ),
          content: const Text(
            'Apakah Anda ingin menyimpan perubahan pada catatan ini sebelum menutup?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(
                ctx,
                'cancel',
              ), // Tetap berada di dialog[cite: 5]
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(
                ctx,
                'discard',
              ), // Keluar dan buang perubahan[cite: 5]
              child: const Text(
                'Jangan Simpan',
                style: TextStyle(color: Colors.red),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(
                ctx,
                'save',
              ), // Simpan data lalu keluar[cite: 5]
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text(
                'Simpan',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );

      if (result == 'save') {
        // Melakukan pemanggilan paksa metode simpan bawaan dialog melalui State Object[cite: 5]
        final stateObj = globalDialogKey.currentState;
        if (stateObj != null && stateObj.mounted) {
          // Menggunakan pendekatan dinamik panggilan method privat atau method penolong di state target[cite: 5]
          try {
            (stateObj as dynamic).saveManualNoteExternal();
          } catch (_) {
            try {
              (stateObj as dynamic)._saveManualNote();
            } catch (e) {
              debugPrint("Gagal memanggil fungsi eksekusi simpan otomatis: $e");
            }
          }
        }
        return true; // Keluar setelah simpan berhasil[cite: 5]
      } else if (result == 'discard') {
        return true; // Keluar tanpa menyimpan[cite: 5]
      }
      return false; // Batalkan proses keluar, tetap di dialog edit[cite: 5]
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        // Bungkus dengan Theme kustom lokal agar widget Dialog internal milik BasePopupDialog ikut melebar[cite: 5]
        return Theme(
          data: Theme.of(dialogContext).copyWith(
            dialogTheme: DialogThemeData(
              // Jarak tepi luar dialog seminimal mungkin agar area checklist terasa luas[cite: 5]
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 24.0,
              ),
              // Konfigurasi pembatas melar: 92% layar smartphone, maksimal lebar 960px pada tablet/PC[cite: 5]
              constraints: BoxConstraints(
                minWidth: (screenWidth * 0.92).clamp(0.0, 960.0),
                maxWidth: 960,
              ),
            ),
          ),
          child: PopScope(
            canPop:
                false, // Menutup pop otomatis bawaan sistem demi intervensi dialog konfirmasi[cite: 5]
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;

              // Ambil status riil modifikasi catatan langsung dari state dialog kustom[cite: 5]
              final stateObj = globalDialogKey.currentState;
              bool hasNoteChanges = false;
              if (stateObj != null) {
                try {
                  hasNoteChanges =
                      (stateObj as dynamic).isNoteModifiedExternal ?? false;
                } catch (_) {
                  try {
                    hasNoteChanges =
                        (stateObj as dynamic)._isNoteModified ?? false;
                  } catch (_) {}
                }
              }

              // Pemicu validasi pop-up pengaman jika tipe dialog saat ini adalah catatan berkonten modifikasi[cite: 5]
              if (subject.type == 'note' && hasNoteChanges) {
                final shouldPop = await _showExitConfirmationDialog(
                  dialogContext,
                );
                if (shouldPop && dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              } else {
                Navigator.pop(dialogContext);
              }
            },
            child: DailyChecklistDialog(
              key:
                  globalDialogKey, // Pasang instans kunci kontrol state[cite: 5]
              subject: subject,
              allAvailableSubjects: allAvailableSubjects,
              allAvailableGroups:
                  _loadedAllGroups, // <-- OVERRIDE SINKRONISASI: Suntikkan seluruh manifest grup terunduh ke dialog[cite: 5]
              baseDir: widget
                  .baseDir, // <--- BARU: Menyuntikkan baseDir penyimpanan untuk sinkronisasi otomatis
              onDataChanged: () {
                saveGroupData();
                setState(() {});
              },
              // Parameter kustom penangan aksi tombol tutup dari internal widget[cite: 5]
              onCustomClosePressed: () async {
                final stateObj = globalDialogKey.currentState;
                bool hasNoteChanges = false;
                if (stateObj != null) {
                  try {
                    hasNoteChanges =
                        (stateObj as dynamic).isNoteModifiedExternal ?? false;
                  } catch (_) {
                    try {
                      hasNoteChanges =
                          (stateObj as dynamic)._isNoteModified ?? false;
                    } catch (_) {}
                  }
                }

                if (subject.type == 'note' && hasNoteChanges) {
                  final shouldPop = await _showExitConfirmationDialog(
                    dialogContext,
                  );
                  if (shouldPop && dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                } else {
                  Navigator.pop(dialogContext);
                }
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Tangani keadaan awal kosong dengan integrasi UniversalEmptyState terpusat (Tema Teal)
    if (currentGroup.allList.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey[200],
        appBar: AppBar(
          title: Row(
            children: [
              Text(currentGroup.icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(currentGroup.groupName),
            ],
          ),
          backgroundColor: Colors.teal[700],
          actions: const [],
        ),
        body: UniversalEmptyState(
          icon: Icons.fact_check_rounded,
          title: 'Materi Checklist Masih Kosong',
          description:
              'Kelompok grup checklist ini belum memiliki daftar tugas atau materi harian. Tekan tombol di bawah untuk membuat rutinitas pertama Anda.',
          buttonLabel: 'Tambah Item Pertama',
          themeColor: Colors.teal[700]!,
          onPressed: () => addItemToSection(context, null),
        ),
      );
    }

    // 2. Siapkan list seksi yang ditampilkan berdasarkan pengaturan visibilitas seksi
    final List<ChecklistSection> displayedSections = _showHiddenItems
        ? currentGroup.allList
        : currentGroup.allList.where((s) => !s.isHidden).toList();

    final List<String> allKeys = displayedSections
        .map((s) => s.sectionName)
        .toList();
    final int visibleKeysCount = allKeys.length;

    // 3. Bangun Map item yang telah disaring berdasarkan query pencarian (searchQuery) dan visibilitas (isHidden)[cite: 5]
    final Map<String, List<DailySubject>> allItems = {
      for (var section in displayedSections)
        section.sectionName: section.items.where((subject) {
          // Hanya muat seksi yang aktif (tidak disembunyikan) untuk grid utama[cite: 5]
          if (subject.isHidden) return false;
          if (searchQuery.isEmpty) return true;
          return subject.subjectName.toLowerCase().contains(searchQuery);
        }).toList(),
    };

    // =========================================================================
    // SINKRONISASI LOGIKA: TAMPILKAN SEKSI TERSEMBUNYI DI BAWAH PEMBATAS GARIS (DIVIDER)
    // =========================================================================
    if (_showHiddenItems) {
      for (var section in displayedSections) {
        final hiddenItemsInSection = section.items.where((subject) {
          if (!subject.isHidden) return false;
          if (searchQuery.isEmpty) return true;
          return subject.subjectName.toLowerCase().contains(searchQuery);
        }).toList();

        if (hiddenItemsInSection.isNotEmpty) {
          final String hiddenKey = '${section.sectionName}_hidden_key';
          allKeys.add(hiddenKey);
          allItems[hiddenKey] = hiddenItemsInSection;
        }
      }
    }

    // Hitung total item riil hasil penyaringan pencarian untuk memantau keadaan kosong[cite: 5]
    int totalFilteredItems = 0;
    allItems.forEach((key, list) => totalFilteredItems += list.length);

    // Dibungkus Scaffold terluar agar properti bottomNavigationBar bisa merender layout iklan[cite: 5]
    return Scaffold(
      body: GroupedSectionLayout<DailySubject>(
        title: '${currentGroup.icon} ${currentGroup.groupName}',
        forceShowMenu: false,
        isLoading: false,

        // Jika seksi visual di layout kosong DAN data raw kosong, baru tampilkan empty placeholder[cite: 5]
        isEmpty: displayedSections.isEmpty && totalFilteredItems == 0,
        emptyMessage: 'Item tidak ditemukan atau belum ada seksi.',

        sectionKeys: allKeys,
        groupedItems: allItems,

        isSelectMode: false,
        selectedItemsCount: 0,
        onClearSelection: () {},
        enableSearch: true,
        enableMultiSelect: false,

        // Hubungkan fungsi pencarian dan penambahan seksi utama ke layout AppBar[cite: 5]
        onSearchChanged: updateSearchQuery,
        onAddPressed: showAddSectionDialog,

        // === SELESAI: SAKELAR GLOBAL UNTUK MENGONTROL VISIBILITAS ITEM TERSEMBUNYI ===
        additionalAction: IconButton(
          icon: Icon(
            _showHiddenItems ? Icons.visibility : Icons.visibility_off,
            color: Colors.white,
          ),
          tooltip: _showHiddenItems
              ? 'Sembunyikan Item Nonaktif'
              : 'Tampilkan Item Tersembunyi',
          onPressed: () {
            setState(() {
              _showHiddenItems = !_showHiddenItems;
            });
          },
        ),

        sectionHeaderBuilder: (context, index, sectionKey, isLayoutEditMode) {
          // === RENDERING KONDISI TERSEMBUNYI DI BAWAH GARIS DIVIDER ===[cite: 5]
          if (index >= visibleKeysCount) {
            String originalName = sectionKey.replaceAll('_hidden_key', '');
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (index == visibleKeysCount)
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Divider(thickness: 2, color: Colors.grey),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    '$originalName (Tersembunyi)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.blueGrey,
                    ),
                  ),
                ),
              ],
            );
          }

          final section = displayedSections[index];

          return InteractiveSectionHeader(
            sectionName: section.sectionName,
            themeColor: Colors.teal[800]!,
            isEditMode: isLayoutEditMode ? true : isSectionEditMode,
            isUpperCase: false,
            isFirst: index == 0,
            isLast: index == visibleKeysCount - 1,
            isHidden: section.isHidden,
            onToggleVisibility: () => toggleSectionHidden(section),
            onToggleEdit: () {
              setState(() {
                isSectionEditMode = !isSectionEditMode;
              });
            },
            onMoveUp: () {
              final actualIndex = currentGroup.allList.indexOf(section);
              if (actualIndex > 0) moveSectionOrder(actualIndex, -1);
            },
            onMoveDown: () {
              final actualIndex = currentGroup.allList.indexOf(section);
              if (actualIndex >= 0 && actualIndex < currentGroup.allList.length - 1) {
                moveSectionOrder(actualIndex, 1);
              }
            },
            onEditName: () => editSectionName(section),
            onDelete: () => deleteSection(section),
            onAddItem: () => addItemToSection(context, section),
          );
        },

        gridItemBuilder: (context, subject, index, sectionItems, isLayoutEditMode) {
          // Menggunakan ChecklistCalculationHelper
          double totalSub = ChecklistCalculationHelper.countTotalItems(subject.subMateri);
          double selesaiSub = ChecklistCalculationHelper.countFinishedItems(subject.subMateri);
          bool isAllDone = totalSub > 0 && totalSub == selesaiSub;

          String topListText = "Tidak ada list";
          if (subject.subMateri.isNotEmpty) {
            // Cari item pertama yang belum selesai dan TIDAK dinonaktifkan[cite: 5]
            final firstUnfinishedItem = subject.subMateri.firstWhere(
              (sm) => sm.progress != 'selesai' && !sm.isDisabled,
              orElse: () =>
                  SubSubjectItem(subjectName: '', progress: 'selesai'),
            );
            if (firstUnfinishedItem.subjectName.isNotEmpty) {
              topListText = firstUnfinishedItem.subjectName;
            } else {
              topListText = "Semua Selesai!";
            }
          }

          // --- PEMPROSESAN LOGIKA PRATINU TEKS CATATAN MULTI-HALAMAN ---[cite: 5]
          String notePreviewText = "Catatan kosong...";
          String targetText = "";

          if (subject.notePages != null && subject.notePages!.isNotEmpty) {
            int activeIndex = subject.currentNotePage ?? 0;
            if (activeIndex >= 0 && activeIndex < subject.notePages!.length) {
              targetText = subject.notePages![activeIndex];
            }
          } else {
            targetText = subject.noteContent ?? "";
          }

          if (targetText.trim().isNotEmpty) {
            // Memisahkan teks berdasarkan spasi/whitespace berlebih[cite: 5]
            List<String> words = targetText.trim().split(RegExp(r'\s+'));
            if (words.length > 4) {
              // Mengambil 4 kata pertama dan menambahkan akhiran titik-titik[cite: 5]
              notePreviewText = '${words.take(4).join(' ')}...';
            } else {
              notePreviewText = words.join(' ');
            }
          }

          Widget cardContent = Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      subject.subjectName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: subject.isHidden ? Colors.grey : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (subject.isDailyTrackerEnabled) ...[
                    const SizedBox(width: 4),
                    Container(
                      key: const Key('daily_tracker_badge'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.teal.withValues(alpha: 0.5),
                          width: 0.8,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 10,
                            color: Colors.teal,
                          ),
                          SizedBox(width: 3),
                          Text(
                            'Daily',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
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

              // --- PENGKONDISIAN UTAMA BERDASARKAN TIPE SUBJECT ---[cite: 5]
              if (subject.type == 'note') ...[
                // TAMPILAN JIKA BERUPA CATATAN (NOTE)[cite: 5]
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Color(subject.backgroundColor).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.push_pin, // Ikon paku (push pin)[cite: 5]
                        size: 13,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(width: 4),
                      Theme(
                        data: Theme.of(context),
                        child: Flexible(
                          child: Text(
                            notePreviewText,
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(subject.backgroundColor),
                              fontStyle: FontStyle.italic,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Menyembunyikan progress bar dengan memberikan spacer kosong seukuran tingginya (22px)[cite: 5]
                const SizedBox(height: 22),
              ] else ...[
                // TAMPILAN NORMAL JIKA BERUPA LIST DAFTAR TUGAS[cite: 5]
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Color(subject.backgroundColor).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          isAllDone ? '  Semua Selesai!' : '  $topListText',
                          style: TextStyle(
                            fontSize: 12,
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
                    Color solidProgressBarColor = progressPercent <= 0.33
                        ? Colors.red[700]!
                        : (progressPercent <= 0.75
                              ? Colors.orange[700]!
                              : Colors.green[700]!);

                    // Hitung persentase dengan format 1 angka di belakang koma[cite: 5]
                    String percentageText = (progressPercent * 100)
                        .toStringAsFixed(1);

                    // Format cetak text pembagian angka agar menghilangkan sisa .0 jika bilangan bulat[cite: 5]
                    String selesaiText = selesaiSub % 1 == 0
                        ? selesaiSub.toInt().toString()
                        : selesaiSub.toStringAsFixed(1);
                    String totalText = totalSub % 1 == 0
                        ? totalSub.toInt().toString()
                        : totalSub.toStringAsFixed(1);

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
                              width: barConstraints.maxWidth * progressPercent,
                              height: double.infinity,
                              color: solidProgressBarColor,
                            ),
                            Center(
                              child: Text(
                                isAllDone
                                    ? 'Selesai Semua'
                                    : '$selesaiText / $totalText List ($percentageText%)',
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(0.8, 0.8),
                                      blurRadius: 2.0,
                                      color: Colors.white,
                                    ),
                                    Shadow(
                                      offset: Offset(-0.8, -0.8),
                                      blurRadius: 2.0,
                                      color: Colors.white,
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
              if (subject.isDailyTrackerEnabled && subject.type != 'note') ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Tooltip(
                        message: 'Simpan status hari ini',
                        child: OutlinedButton(
                          key: const Key('btn_save_today_log'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.teal.shade800,
                            side: BorderSide(color: Colors.teal.shade400, width: 1),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            minimumSize: const Size(0, 28),
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final savedDate = await saveTodayLog(subject);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Daily tracker "$savedDate" berhasil disimpan!',
                                ),
                                backgroundColor: Colors.teal,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save_rounded, size: 12),
                              SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  'Simpan Hari Ini',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Tooltip(
                        message: 'Reset centang untuk hari baru',
                        child: OutlinedButton(
                          key: const Key('btn_reset_for_new_day'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey.shade700,
                            side: BorderSide(color: Colors.grey.shade400, width: 1),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            minimumSize: const Size(0, 28),
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          onPressed: () async {
                            await resetForNewDay(subject);
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.refresh_rounded, size: 12),
                              SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  'Reset Hari Baru',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: Tooltip(
                    message: 'Lihat riwayat catatan harian',
                    child: OutlinedButton(
                      key: const Key('btn_view_history'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.indigo.shade700,
                        side: BorderSide(color: Colors.indigo.shade300, width: 1),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        minimumSize: const Size(0, 28),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DailyTrackerHistoryScreen(
                              subject: subject,
                              onDeleteAll: () => deleteDailyLog(subject),
                              onDeleteByMonth: (month) =>
                                  deleteDailyLogsByMonth(subject, month),
                              onEditEntry: (dateKey, updated) =>
                                  editDailyLogEntry(subject, dateKey, updated),
                              onDeleteEntry: (dateKey) =>
                                  deleteDailyLogEntry(subject, dateKey),
                            ),
                          ),
                        ).then((_) {
                          if (mounted) setState(() {});
                        });
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_rounded, size: 12),
                          SizedBox(width: 3),
                          Text(
                            'Lihat History',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );

          return InteractiveGridCard(
            themeColor: Color(subject.backgroundColor),
            content: subject.isDailyTrackerEnabled
                ? SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: cardContent,
                  )
                : cardContent,
            isEditMode: isLayoutEditMode ? true : isPageEditMode,
            isHiddenStyle: subject.isHidden,
            isFirst: index == 0,
            isLast: index == sectionItems.length - 1,
            onTap: () => openMateriChecklist(subject),
            onLongPress: () {
              setState(() {
                isPageEditMode = !isPageEditMode;
              });
            },
            onMoveLeft: () {
              setState(() {
                final originalSection = currentGroup.allList.firstWhere(
                  (sec) => sec.items.contains(subject),
                );
                int origIndex = originalSection.items.indexOf(subject);

                if (origIndex > 0) {
                  final temp = originalSection.items[origIndex];
                  originalSection.items[origIndex] =
                      originalSection.items[origIndex - 1];
                  originalSection.items[origIndex - 1] = temp;
                }
              });
              saveGroupData();
            },
            onMoveRight: () {
              setState(() {
                final originalSection = currentGroup.allList.firstWhere(
                  (sec) => sec.items.contains(subject),
                );
                int origIndex = originalSection.items.indexOf(subject);

                if (origIndex < originalSection.items.length - 1) {
                  final temp = originalSection.items[origIndex];
                  originalSection.items[origIndex] =
                      originalSection.items[origIndex + 1];
                  originalSection.items[origIndex + 1] = temp;
                }
              });
              saveGroupData();
            },
            popupMenuItems: [
              ...currentGroup.allList
                  .where((sec) => !sec.items.contains(subject))
                  .map(
                    (sec) => PopupMenuItem<String>(
                      value: 'INTERNAL_MOVE:${sec.sectionName}',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.drive_file_move_outlined,
                            size: 18,
                            color: Colors.teal,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Pindah ke Seksi: ${sec.sectionName}',
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              if (_loadedAllGroups
                  .where(
                    (g) =>
                        g.id != currentGroup.id &&
                        !g.id.startsWith("CORRUPTED_"),
                  )
                  .isNotEmpty) ...[
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'CHOOSE_EXTERNAL_GROUP_DIALOG',
                  child: Row(
                    children: [
                      Icon(
                        Icons.folder_shared_outlined,
                        size: 18,
                        color: Colors.indigo,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Pindahkan ke Grup Lain',
                        style: TextStyle(fontSize: 13, color: Colors.indigo),
                      ),
                    ],
                  ),
                ),
              ],
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'TOGGLE_DAILY_TRACKER',
                child: Row(
                  children: [
                    Icon(
                      subject.isDailyTrackerEnabled
                          ? Icons.event_busy_rounded
                          : Icons.event_available_rounded,
                      size: 18,
                      color: Colors.teal,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        subject.isDailyTrackerEnabled
                            ? 'Nonaktifkan DailyTracker'
                            : 'Aktifkan DailyTracker',
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'TOGGLE_VISIBILITY',
                child: Row(
                  children: [
                    Icon(
                      subject.isHidden
                          ? Icons.visibility
                          : Icons.visibility_off,
                      size: 18,
                      color: Colors.blueGrey[700],
                    ),
                    const SizedBox(width: 10),
                    Text(
                      subject.isHidden ? 'Tampilkan Item' : 'Sembunyikan Item',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),

              // === SELESAI INTEGRASI MENU POPUP: AKSI EDIT RAW JSON CARD ===[cite: 5]
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'EDIT_RAW_JSON',
                child: Row(
                  children: [
                    Icon(
                      Icons.data_object_rounded,
                      size: 18,
                      color: Colors.deepOrange,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Edit Raw JSON',
                      style: TextStyle(fontSize: 13, color: Colors.deepOrange),
                    ),
                  ],
                ),
              ),

              if (currentGroup.allList.length > 1 ||
                  _loadedAllGroups.length > 1)
                const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'DELETE_ACTION',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.redAccent,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Hapus Item',
                      style: TextStyle(fontSize: 13, color: Colors.redAccent),
                    ),
                  ],
                ),
              ),
            ],
            onPopupSelected: (value) {
              final originalSection = currentGroup.allList.firstWhere(
                (sec) => sec.items.contains(subject),
              );

              if (value == 'DELETE_ACTION') {
                deleteItemFromSection(originalSection.items, subject);
              } else if (value == 'TOGGLE_DAILY_TRACKER') {
                setState(() {
                  subject.isDailyTrackerEnabled =
                      !subject.isDailyTrackerEnabled;
                });
                saveGroupData();
              } else if (value == 'EDIT_RAW_JSON') {
                _showEditJsonDialog(
                  subject,
                ); // Memicu Editor Dialog JSON interaktif yang baru dibuat[cite: 5]
              } else if (value == 'CHOOSE_EXTERNAL_GROUP_DIALOG') {
                _showTargetGroupSelectionDialog(
                  originalSection: originalSection,
                  subject: subject,
                );
              } else if (value == 'TOGGLE_VISIBILITY') {
                toggleSubjectVisibility(subject);
              } else if (value.startsWith('INTERNAL_MOVE:')) {
                final String targetSectionName = value.replaceFirst(
                  'INTERNAL_MOVE:',
                  '',
                );
                setState(() {
                  originalSection.items.remove(subject);
                  currentGroup.allList
                      .firstWhere((sec) => sec.sectionName == targetSectionName)
                      .items
                      .add(subject);
                });
                saveGroupData();
              }
            },
          );
        },
      ),

      // MENGGUNAKAN WIDGET KUSTOM YANG BARU DAN MODULAR PADA FOOTER LAYOUT
      bottomNavigationBar: const AdaptiveBannerAd(
        adKey: 'checklist_detail_banner',
      ),
    );
  }
}

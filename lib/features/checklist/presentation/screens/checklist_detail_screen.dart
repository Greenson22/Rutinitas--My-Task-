// lib/features/daily/presentation/screens/checklist_detail_screen.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/daily_model.dart';
import '../controllers/checklist_detail_controller.dart';
import '../../../../core/presentation/widgets/grouped_section_layout.dart';
import '../../../../core/presentation/widgets/interactive_grid_card.dart';
import '../../../../core/presentation/widgets/interactive_section_header.dart';
import '../../../../core/presentation/widgets/universal_empty_state.dart'; // Using Universal Widget from Core
import '../widgets/checklist_detail/checklist_dialog.dart'; // Import Dialog kustom

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

  @override
  void initState() {
    super.initState();
    if (widget.allAvailableGroups != null) {
      _loadedAllGroups = widget.allAvailableGroups!;
    } else {
      _loadExtendedGroupsManifest();
    }
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

  // SOLUSI UTAMA: Meng-override fungsi openMateriChecklist dari Controller untuk menyuntikkan ukuran Dialog melar
  @override
  void openMateriChecklist(DailySubject subject) {
    // Kumpulkan semua kotak materi (DailySubject) dari seluruh seksi yang tersedia untuk parameter dialog
    List<DailySubject> allAvailableSubjects = [];
    for (var section in currentGroup.allList) {
      allAvailableSubjects.addAll(section.items);
    }

    final double screenWidth = MediaQuery.of(context).size.width;

    // GlobalKey baru untuk mengakses status internal (_isNoteModified) dari dialog secara langsung
    final globalDialogKey = GlobalKey<State<DailyChecklistDialog>>();

    // Fungsi lokal untuk menampilkan pop-up konfirmasi simpan/buang perubahan
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
              onPressed: () =>
                  Navigator.pop(ctx, 'cancel'), // Tetap berada di dialog
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(ctx, 'discard'), // Keluar dan buang perubahan
              child: const Text(
                'Jangan Simpan',
                style: TextStyle(color: Colors.red),
              ),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(ctx, 'save'), // Simpan data lalu keluar
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
        // Melakukan pemanggilan paksa metode simpan bawaan dialog melalui State Object
        final stateObj = globalDialogKey.currentState;
        if (stateObj != null && stateObj.mounted) {
          // Menggunakan pendekatan dinamik panggilan method privat atau method penolong di state target
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
        return true; // Keluar setelah simpan berhasil
      } else if (result == 'discard') {
        return true; // Keluar tanpa menyimpan
      }
      return false; // Batalkan proses keluar, tetap di dialog edit
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        // Bungkus dengan Theme kustom lokal agar widget Dialog internal milik BasePopupDialog ikut melebar
        return Theme(
          data: Theme.of(dialogContext).copyWith(
            dialogTheme: DialogThemeData(
              // Jarak tepi luar dialog seminimal mungkin agar area checklist terasa luas
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 24.0,
              ),
              // Konfigurasi pembatas melar: 92% layar smartphone, maksimal lebar 960px pada tablet/PC
              constraints: BoxConstraints(
                minWidth: (screenWidth * 0.92).clamp(0.0, 960.0),
                maxWidth: 960,
              ),
            ),
          ),
          child: PopScope(
            canPop:
                false, // Menutup pop otomatis bawaan sistem demi intervensi dialog konfirmasi
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;

              // Ambil status riil modifikasi catatan langsung dari state dialog kustom
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

              // Pemicu validasi pop-up pengaman jika tipe dialog saat ini adalah catatan berkonten modifikasi
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
              key: globalDialogKey, // Pasang instans kunci kontrol state
              subject: subject,
              allAvailableSubjects: allAvailableSubjects,
              onDataChanged: () {
                saveGroupData();
                setState(() {});
              },
              // Parameter kustom penangan aksi tombol tutup dari internal widget
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
    // Fungsi rekursif menggunakan double agar bisa menghitung nilai pecahan koma
    double _countTotalItems(List<SubSubjectItem> items) {
      double count = 0;
      for (var item in items) {
        if (item.subMateri.isNotEmpty) {
          // Jika memiliki anak (nested list), induk diabaikan dan lanjut menghitung turunannya
          count += _countTotalItems(item.subMateri);
        } else {
          // Jika daun akhir (bukan nested list), dihitung sebagai 1 item
          count += 1.0;
        }
      }
      return count;
    }

    // Fungsi rekursif menggunakan double untuk menghitung item selesai
    double _countFinishedItems(List<SubSubjectItem> items) {
      double count = 0;
      for (var item in items) {
        if (item.subMateri.isNotEmpty) {
          // Jika memiliki anak (nested list), telusuri anak-anaknya saja tanpa menghitung induk
          count += _countFinishedItems(item.subMateri);
        } else {
          // Hanya hitung item ujung (tanpa anak) yang status progressnya selesai
          if (item.progress == 'selesai') {
            count += 1.0;
          }
        }
      }
      return count;
    }

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

    // 2. Siapkan list kunci seksi untuk GroupedSectionLayout
    final List<String> sectionKeys = currentGroup.allList
        .map((s) => s.sectionName)
        .toList();

    // 3. Bangun Map item yang telah disaring berdasarkan query pencarian (searchQuery)
    final Map<String, List<DailySubject>> groupedItems = {
      for (var section in currentGroup.allList)
        section.sectionName: section.items.where((subject) {
          if (searchQuery.isEmpty) return true;
          return subject.subjectName.toLowerCase().contains(searchQuery);
        }).toList(),
    };

    // Hitung total item riil hasil penyaringan pencarian untuk memantau keadaan kosong
    int totalFilteredItems = 0;
    groupedItems.forEach((key, list) => totalFilteredItems += list.length);

    // 4. Gunakan Template GroupedSectionLayout
    return GroupedSectionLayout<DailySubject>(
      title: '${currentGroup.icon} ${currentGroup.groupName}',
      isLoading: false,

      // Jika seksi visual di layout kosong DAN data raw kosong, baru tampilkan empty placeholder
      isEmpty: currentGroup.allList.isEmpty && totalFilteredItems == 0,
      emptyMessage: 'Item tidak ditemukan atau belum ada seksi.',

      sectionKeys: sectionKeys,
      groupedItems: groupedItems,

      isSelectMode: false,
      selectedItemsCount: 0,
      onClearSelection: () {},
      enableSearch: true,
      enableMultiSelect: false,

      // Hubungkan fungsi pencarian dan penambahan seksi utama ke layout AppBar
      onSearchChanged: updateSearchQuery,
      onAddPressed: showAddSectionDialog,

      sectionHeaderBuilder: (context, index, sectionName, isLayoutEditMode) {
        final section = currentGroup.allList[index];

        // Evaluasi apakah ini seksi default tunggal yang perlu disembunyikan judulnya
        final bool hideHeader =
            currentGroup.allList.length == 1 &&
            section.sectionName == ChecklistDetailController.defaultSectionName;

        if (hideHeader) return const SizedBox.shrink();

        return InteractiveSectionHeader(
          sectionName: section.sectionName,
          themeColor: Colors.teal[800]!,
          isEditMode: isLayoutEditMode ? true : isSectionEditMode,
          isUpperCase: false,
          isFirst: index == 0,
          isLast: index == currentGroup.allList.length - 1,
          onToggleEdit: () {
            setState(() {
              isSectionEditMode = !isSectionEditMode;
            });
          },
          onMoveUp: () => moveSectionOrder(index, -1),
          onMoveDown: () => moveSectionOrder(index, 1),
          onEditName: () => editSectionName(section),
          onDelete: () => deleteSection(section),
          onAddItem: () => addItemToSection(context, section),
        );
      },

      gridItemBuilder: (context, subject, index, sectionItems, isLayoutEditMode) {
        // Menggunakan hitungan double koma
        double totalSub = _countTotalItems(subject.subMateri);
        double selesaiSub = _countFinishedItems(subject.subMateri);
        bool isAllDone = totalSub > 0 && totalSub == selesaiSub;

        String topListText = "Tidak ada list";
        if (subject.subMateri.isNotEmpty) {
          final firstUnfinishedItem = subject.subMateri.firstWhere(
            (sm) => sm.progress != 'selesai',
            orElse: () => SubSubjectItem(subjectName: '', progress: 'selesai'),
          );
          if (firstUnfinishedItem.subjectName.isNotEmpty) {
            topListText = firstUnfinishedItem.subjectName;
          } else {
            topListText = "Semua Selesai!";
          }
        }

        // --- PEMPROSESAN LOGIKA PRATINJAU TEKS CATATAN ---
        String notePreviewText = "Catatan kosong...";
        if (subject.noteContent != null &&
            subject.noteContent!.trim().isNotEmpty) {
          // Memisahkan teks berdasarkan spasi/whitespace berlebih
          List<String> words = subject.noteContent!.trim().split(
            RegExp(r'\s+'),
          );
          if (words.length > 4) {
            // Mengambil 4 kata pertama dan menambahkan akhiran titik-titik
            notePreviewText = '${words.take(4).join(' ')}...';
          } else {
            notePreviewText = words.join(' ');
          }
        }

        Widget cardContent = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              subject.subjectName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
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

            // --- PENGKONDISIAN UTAMA BERDASARKAN TIPE SUBJECT ---
            if (subject.type == 'note') ...[
              // TAMPILAN JIKA BERUPA CATATAN (NOTE)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(subject.backgroundColor).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.push_pin, // Ikon paku (push pin)
                      size: 13,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
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
                  ],
                ),
              ),
              // Menyembunyikan progress bar dengan memberikan spacer kosong seukuran tingginya (22px)
              const SizedBox(height: 22),
            ] else ...[
              // TAMPILAN NORMAL JIKA BERUPA LIST DAFTAR TUGAS
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
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
                        isAllDone ? '🎉 Semua Selesai!' : '📌 $topListText',
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

                  // Hitung persentase dengan format 1 angka di belakang koma
                  String percentageText = (progressPercent * 100)
                      .toStringAsFixed(1);

                  // Format cetak text pembagian angka agar menghilangkan sisa .0 jika bilangan bulat
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
          ],
        );

        return InteractiveGridCard(
          themeColor: Color(subject.backgroundColor),
          content: cardContent,
          isEditMode: isLayoutEditMode ? true : isPageEditMode,
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
              // Temukan seksi aslinya
              final originalSection = currentGroup.allList.firstWhere(
                (sec) => sec.items.contains(subject),
              );
              int origIndex = originalSection.items.indexOf(subject);

              // Geser ke kiri berdasarkan index list asli
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
              // Temukan seksi aslinya
              final originalSection = currentGroup.allList.firstWhere(
                (sec) => sec.items.contains(subject),
              );
              int origIndex = originalSection.items.indexOf(subject);

              // Geser ke kanan berdasarkan index list asli
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
            // Filter: Hanya tampilkan opsi pindah ke seksi LAIN (jangan tampilkan seksi saat ini)
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

            // =========================================================================
            // MENU BARU: PINDAHKAN KARTU CHECKLIST INI KE GRUP LAINNYA
            // =========================================================================
            if (_loadedAllGroups
                .where(
                  (g) =>
                      g.id != currentGroup.id && !g.id.startsWith("CORRUPTED_"),
                )
                .isNotEmpty) ...[
              const PopupMenuDivider(),
              ..._loadedAllGroups
                  .where(
                    (g) =>
                        g.id != currentGroup.id &&
                        !g.id.startsWith("CORRUPTED_"),
                  )
                  .map(
                    (targetGroup) => PopupMenuItem<String>(
                      value: 'EXTERNAL_GROUP_MOVE:${targetGroup.id}',
                      child: Row(
                        children: [
                          Text(
                            targetGroup.icon,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Pindahkan ke Grup: ${targetGroup.groupName}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.indigo,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],

            if (currentGroup.allList.length > 1 || _loadedAllGroups.length > 1)
              const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'DELETE_ACTION',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
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
            // Temukan seksi asli tempat subjek ini berada
            final originalSection = currentGroup.allList.firstWhere(
              (sec) => sec.items.contains(subject),
            );

            if (value == 'DELETE_ACTION') {
              // Lempar List ASLI ke controller agar bisa dihapus dari data utama
              deleteItemFromSection(originalSection.items, subject);
            }
            // Intervensi Aksi Perpindahan Eksternal Antar Berkas Grup Checklist
            else if (value.startsWith('EXTERNAL_GROUP_MOVE:')) {
              final String targetGroupId = value.replaceFirst(
                'EXTERNAL_GROUP_MOVE:',
                '',
              );
              final targetGroupObj = _loadedAllGroups.firstWhere(
                (g) => g.id == targetGroupId,
              );

              moveChecklistToAnotherGroup(
                currentSectionItems: originalSection.items,
                subject: subject,
                targetGroup: targetGroupObj,
              );
            }
            // Penanganan Aksi Mutasi Seksi Internal Bawaan
            else if (value.startsWith('INTERNAL_MOVE:')) {
              final String targetSectionName = value.replaceFirst(
                'INTERNAL_MOVE:',
                '',
              );
              setState(() {
                // Hapus dari seksi asli
                originalSection.items.remove(subject);

                // Tambahkan ke seksi tujuan
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
    );
  }
}

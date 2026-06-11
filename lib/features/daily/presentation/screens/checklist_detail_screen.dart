// lib/features/daily/presentation/screens/checklist_detail_screen.dart

import 'package:flutter/material.dart';
import '../../data/models/daily_model.dart';
import '../controllers/checklist_detail_controller.dart';
import '../../../../core/presentation/widgets/grouped_section_layout.dart';
import '../../../../core/presentation/widgets/interactive_grid_card.dart';
import '../../../../core/presentation/widgets/interactive_section_header.dart';

class ChecklistDetailScreen extends StatefulWidget {
  final ChecklistGroup group;
  final String baseDir;

  const ChecklistDetailScreen({
    super.key,
    required this.group,
    required this.baseDir,
  });

  @override
  State<ChecklistDetailScreen> createState() => _ChecklistDetailScreenState();
}

class _ChecklistDetailScreenState extends ChecklistDetailController {
  @override
  Widget build(BuildContext context) {
    // Fungsi rekursif untuk menghitung TOTAL seluruh item (termasuk nested list)
    int _countTotalItems(List<SubSubjectItem> items) {
      int count = 0;
      for (var item in items) {
        count++;
        if (item.subMateri.isNotEmpty) {
          count += _countTotalItems(item.subMateri);
        }
      }
      return count;
    }

    // Fungsi rekursif untuk menghitung seluruh item yang SELESAI (termasuk nested list)
    int _countFinishedItems(List<SubSubjectItem> items) {
      int count = 0;
      for (var item in items) {
        if (item.progress == 'selesai') {
          count++;
        }
        if (item.subMateri.isNotEmpty) {
          count += _countFinishedItems(item.subMateri);
        }
      }
      return count;
    }

    // 1. Tangani keadaan awal kosong dengan Scaffold bawaan agar tombol ElevatedButton tetap di tengah
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
        body: Center(
          child: ElevatedButton.icon(
            onPressed: () => addItemToSection(context, null),
            icon: const Icon(Icons.add_box),
            label: const Text('Tambah Item Pertama'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[700]),
          ),
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
        // Menggunakan fungsi rekursif agar nested list terhitung secara akurat
        int totalSub = _countTotalItems(subject.subMateri);
        int selesaiSub = _countFinishedItems(subject.subMateri);
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
                String percentageText = (progressPercent * 100).toStringAsFixed(
                  1,
                );

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
                                : '$selesaiSub / $totalSub List ($percentageText%)',
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
                    value: sec.sectionName,
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
                            'Pindah ke ${sec.sectionName}',
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            if (currentGroup.allList.length > 1) const PopupMenuDivider(),
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
            } else {
              setState(() {
                // Hapus dari seksi asli
                originalSection.items.remove(subject);

                // Tambahkan ke seksi tujuan
                currentGroup.allList
                    .firstWhere((sec) => sec.sectionName == value)
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

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
    // 1. Tangani state kosong dengan Scaffold bawaan agar tombol ElevatedButton tetap di tengah
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
        floatingActionButton: FloatingActionButton(
          onPressed: showAddSectionDialog,
          backgroundColor: Colors.teal[800],
          tooltip: 'Tambah Seksi Baru',
          child: const Icon(Icons.post_add, size: 30, color: Colors.white),
        ),
      );
    }

    // 2. Siapkan data kunci seksi dan map item untuk GroupedSectionLayout
    final List<String> sectionKeys = currentGroup.allList
        .map((s) => s.sectionName)
        .toList();
    final Map<String, List<DailySubject>> groupedItems = {
      for (var section in currentGroup.allList)
        section.sectionName: section.items,
    };

    // 3. Gunakan Template GroupedSectionLayout
    return GroupedSectionLayout<DailySubject>(
      title: '${currentGroup.icon} ${currentGroup.groupName}',
      appBarColor: Colors.teal[700]!,
      isLoading: false,
      isEmpty: false, // Sudah ditangani di atas
      sectionKeys: sectionKeys,
      groupedItems: groupedItems,
      childAspectRatio: isPageEditMode ? 0.95 : 1.4,
      floatingActionButton: FloatingActionButton(
        onPressed: showAddSectionDialog,
        backgroundColor: Colors.teal[800],
        tooltip: 'Tambah Seksi Baru',
        child: const Icon(Icons.post_add, size: 30, color: Colors.white),
      ),
      sectionHeaderBuilder: (context, index, sectionName) {
        final section = currentGroup.allList[index];

        // Evaluasi apakah ini seksi default tunggal yang perlu disembunyikan judulnya
        final bool hideHeader =
            currentGroup.allList.length == 1 &&
            section.sectionName == ChecklistDetailController.defaultSectionName;

        if (hideHeader) return const SizedBox.shrink();

        return InteractiveSectionHeader(
          sectionName: section.sectionName,
          themeColor: Colors.teal[800]!,
          isEditMode: isSectionEditMode,
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
      gridItemBuilder: (context, subject, index, sectionItems) {
        // Logika tampilan indikator progress
        int totalSub = subject.subMateri.length;
        int selesaiSub = subject.subMateri
            .where((sm) => sm.progress == 'selesai')
            .length;
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

        // Layout UI di dalam card (konten asli)
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
        );

        return InteractiveGridCard(
          themeColor: Color(subject.backgroundColor),
          content: cardContent,
          isEditMode: isPageEditMode,
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
              final temp = sectionItems[index];
              sectionItems[index] = sectionItems[index - 1];
              sectionItems[index - 1] = temp;
            });
            saveGroupData();
          },
          onMoveRight: () {
            setState(() {
              final temp = sectionItems[index];
              sectionItems[index] = sectionItems[index + 1];
              sectionItems[index + 1] = temp;
            });
            saveGroupData();
          },
          popupMenuItems: [
            // List Pindah Seksi
            ...currentGroup.allList.map(
              (sec) => PopupMenuItem<String>(
                value: sec.sectionName,
                child: Text(
                  'Pindah ke ${sec.sectionName}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            const PopupMenuDivider(),
            // Pilihan Hapus Item (Karena template InteractiveGridCard tidak menyediakan tombol delete)
            const PopupMenuItem<String>(
              value: 'DELETE_ACTION',
              child: Text(
                'Hapus Item',
                style: TextStyle(fontSize: 12, color: Colors.red),
              ),
            ),
          ],
          onPopupSelected: (value) {
            if (value == 'DELETE_ACTION') {
              deleteItemFromSection(sectionItems, subject);
            } else {
              setState(() {
                final itemToMove = sectionItems.removeAt(index);
                currentGroup.allList
                    .firstWhere((sec) => sec.sectionName == value)
                    .items
                    .add(itemToMove);
              });
              saveGroupData();
            }
          },
        );
      },
    );
  }
}

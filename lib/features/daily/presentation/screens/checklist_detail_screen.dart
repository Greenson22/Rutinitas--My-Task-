// lib/features/daily/presentation/screens/checklist_detail_screen.dart

import 'package:flutter/material.dart';
import '../../data/models/daily_model.dart';
import '../controllers/checklist_detail_controller.dart';

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
        actions: [],
      ),
      body: currentGroup.allList.isEmpty
          ? Center(
              child: ElevatedButton.icon(
                onPressed: () => addItemToSection(context, null),
                icon: const Icon(Icons.add_box),
                label: const Text('Tambah Item Pertama'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[700],
                ),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: currentGroup.allList.length,
                  itemBuilder: (context, index) {
                    final section = currentGroup.allList[index];

                    // Evaluasi apakah ini seksi default tunggal yang perlu disembunyikan judulnya
                    final bool hideHeader =
                        currentGroup.allList.length == 1 &&
                        section.sectionName ==
                            ChecklistDetailController.defaultSectionName;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          index,
                          section,
                          Colors.teal[800]!,
                          hideHeader,
                          () => addItemToSection(context, section),
                        ),
                        _buildCategoryGrid(section.items, constraints),
                      ],
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddSectionDialog,
        backgroundColor: Colors.teal[800],
        tooltip: 'Tambah Seksi Baru',
        child: const Icon(Icons.post_add, size: 30, color: Colors.white),
      ),
    );
  }

  Widget _buildSectionHeader(
    int index,
    ChecklistSection section,
    Color color,
    bool hideTitle,
    VoidCallback onAddPressed,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        splashColor: Colors.teal.withOpacity(0.1),
        highlightColor: Colors.teal.withOpacity(0.05),
        onLongPress: () {
          setState(() {
            isSectionEditMode = !isSectionEditMode;
          });
        },
        onTap: () {},
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: isSectionEditMode
              ? const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0)
              : const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  hideTitle
                      ? const SizedBox.shrink()
                      : Text(
                          section.sectionName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                  if (isSectionEditMode) ...[
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_upward,
                            size: 18,
                            color: Colors.blueGrey,
                          ),
                          onPressed: index > 0
                              ? () => moveSectionOrder(index, -1)
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_downward,
                            size: 18,
                            color: Colors.blueGrey,
                          ),
                          onPressed: index < currentGroup.allList.length - 1
                              ? () => moveSectionOrder(index, 1)
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            size: 18,
                            color: Colors.teal,
                          ),
                          onPressed: () => editSectionName(section),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            size: 18,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => deleteSection(section),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: Colors.teal,
                            size: 18,
                          ),
                          tooltip: 'Tambah Item ke Seksi Ini',
                          onPressed: onAddPressed,
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox.shrink(),
                  ],
                ],
              ),
              if (!hideTitle) const Divider(height: 8, thickness: 1),
            ],
          ),
        ),
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
        childAspectRatio: isPageEditMode ? 0.95 : 1.4,
        crossAxisSpacing: 0,
        mainAxisSpacing: 0,
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
            orElse: () => SubSubjectItem(subjectName: '', progress: 'selesai'),
          );

          if (firstUnfinishedItem.subjectName.isNotEmpty) {
            topListText = firstUnfinishedItem.subjectName;
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
              Expanded(
                child: InkWell(
                  onTap: isPageEditMode
                      ? null
                      : () => openMateriChecklist(subject),
                  onLongPress: () {
                    setState(() {
                      isPageEditMode = !isPageEditMode;
                    });
                  },
                  borderRadius: BorderRadius.vertical(
                    top: const Radius.circular(12),
                    bottom: Radius.circular(isPageEditMode ? 0 : 12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
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
              if (isPageEditMode) ...[
                Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, size: 16),
                        color: index > 0 ? Colors.teal[700] : Colors.grey[300],
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: index > 0
                            ? () {
                                setState(() {
                                  final temp = subjectsList[index];
                                  subjectsList[index] = subjectsList[index - 1];
                                  subjectsList[index - 1] = temp;
                                });
                                saveGroupData();
                              }
                            : null,
                      ),
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
                            currentGroup.allList
                                .firstWhere(
                                  (sec) => sec.sectionName == targetSectionName,
                                )
                                .items
                                .add(itemToMove);
                          });
                          saveGroupData();
                        },
                        itemBuilder: (context) => currentGroup.allList
                            .map(
                              (sec) => PopupMenuItem<String>(
                                value: sec.sectionName,
                                child: Text(
                                  sec.sectionName,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            )
                            .toList(),
                      ),
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
                                  final temp = subjectsList[index];
                                  subjectsList[index] = subjectsList[index + 1];
                                  subjectsList[index + 1] = temp;
                                });
                                saveGroupData();
                              }
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: Colors.redAccent,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Hapus Item Ini',
                        onPressed: () =>
                            deleteItemFromSection(subjectsList, subject),
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

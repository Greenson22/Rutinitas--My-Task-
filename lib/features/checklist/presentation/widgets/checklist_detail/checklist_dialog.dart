// lib/features/daily/presentation/widgets/checklist_dialog.dart

import 'package:flutter/material.dart';
import '../../../data/models/daily_model.dart';
import 'checklist_dialog/change_color_dialog.dart';
import 'checklist_dialog/checklist_control_panel.dart';
import 'checklist_dialog/checklist_tree_view.dart';
import 'checklist_dialog/checklist_note_view.dart';
import '../../controllers/checklist_dialog_controller.dart';
import '../../../../../core/presentation/widgets/base_popup_dialog.dart';

class DailyChecklistDialog extends StatefulWidget {
  final DailySubject subject;
  final VoidCallback onDataChanged;
  final List<DailySubject> allAvailableSubjects;
  final List<ChecklistGroup>? allAvailableGroups;
  final VoidCallback? onCustomClosePressed;
  final String? baseDir; // <--- TAMBAHKAN INI

  const DailyChecklistDialog({
    super.key,
    required this.subject,
    required this.onDataChanged,
    required this.allAvailableSubjects,
    this.allAvailableGroups,
    this.onCustomClosePressed,
    this.baseDir, // <--- TAMBAHKAN INI
  });

  @override
  State<DailyChecklistDialog> createState() => _DailyChecklistDialogState();
}

class _DailyChecklistDialogState extends ChecklistDialogController {
  @override
  Widget build(BuildContext context) {
    List<SubSubjectItem> allFlattened = [];
    getAllItemsFlattened(widget.subject.subMateri, allFlattened);

    bool isAllSelected =
        allFlattened.isNotEmpty &&
        allFlattened.every((i) => selectedItems.contains(i));
    List<SubSubjectItem> finishedItems = allFlattened
        .where((i) => i.progress == 'selesai')
        .toList();
    bool isAllFinishedSelected =
        finishedItems.isNotEmpty &&
        finishedItems.every((i) => selectedItems.contains(i));

    return BasePopupDialog(
      themeColor: Color(widget.subject.backgroundColor),
      titleColor: Color(widget.subject.textColor),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: InkWell(
              onTap: showEditSubjectNameDialog,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 4.0,
                  horizontal: 2.0,
                ),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${widget.subject.subjectName} ',
                        style: TextStyle(
                          color: Color(widget.subject.textColor),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.subject.isDateActive &&
                          widget.subject.date != null)
                        ...DailySubject.buildColoredDateSpans(
                          widget.subject,
                          inHeader: true,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.subject.type == 'note') ...[
                if (!isNoteViewMode) ...[
                  const Text(
                    'MD',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Transform.scale(
                    scale: 0.7,
                    child: Switch(
                      value: isMarkdownEnabled,
                      activeColor: Colors.tealAccent,
                      inactiveThumbColor: Colors.white70,
                      onChanged: (value) {
                        setState(() {
                          isMarkdownEnabled = value;
                          isNoteModified = true;
                        });
                      },
                    ),
                  ),
                ],
                IconButton(
                  icon: Icon(
                    isNoteViewMode ? Icons.edit : Icons.chrome_reader_mode,
                    color: Colors.white,
                    size: 20,
                  ),
                  tooltip: isNoteViewMode
                      ? 'Edit Catatan'
                      : 'Pratinjau Catatan',
                  onPressed: () =>
                      setState(() => isNoteViewMode = !isNoteViewMode),
                ),
              ],
              if (widget.subject.type == 'note' && isNoteModified)
                IconButton(
                  icon: const Icon(
                    Icons.save_as,
                    color: Colors.amberAccent,
                    size: 24,
                  ),
                  onPressed: saveManualNote,
                ),
              IconButton(
                icon: const Icon(Icons.palette, color: Colors.white, size: 20),
                onPressed: () => showDialog(
                  context: context,
                  builder: (ctx) => ChangeColorDialog(
                    subject: widget.subject,
                    onColorSaved: () => setState(() {}),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  widget.subject.type == 'note' ? Icons.checklist : Icons.notes,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    widget.subject.type = widget.subject.type == 'note'
                        ? 'list'
                        : 'note';
                    if (widget.subject.type == 'note') showControlPanel = false;
                  });
                  widget.onDataChanged();
                },
              ),
              if (widget.subject.type != 'note')
                IconButton(
                  icon: Icon(
                    showControlPanel ? Icons.tune : Icons.tune_outlined,
                    color: showControlPanel ? Colors.amberAccent : Colors.white,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => showControlPanel = !showControlPanel),
                ),
            ],
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: showControlPanel
                ? ChecklistControlPanel(
                    subject: widget.subject,
                    singleInputController: singleInputController,
                    onAddRootItem: addRootSubMateri,
                    onPasteFromClipboard: pasteFromClipboard,
                    onDateActiveChanged: (val) {
                      setState(() {
                        widget.subject.isDateActive = val;
                        if (val && (widget.subject.date ?? '').isEmpty) {
                          final now = DateTime.now();
                          widget.subject.date =
                              "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
                        }
                      });
                      widget.onDataChanged();
                    },
                    onDateTypeChanged: (val) {
                      if (val != null) {
                        setState(() {
                          widget.subject.dateType = val;
                          if (val == 'range' &&
                              (widget.subject.endDate ?? '').isEmpty) {
                            final besok = DateTime.now().add(
                              const Duration(days: 1),
                            );
                            widget.subject.endDate =
                                "${besok.year}-${besok.month.toString().padLeft(2, '0')}-${besok.day.toString().padLeft(2, '0')}";
                          }
                        });
                        widget.onDataChanged();
                      }
                    },
                    onSelectStartDate: () => selectSubjectDate(false),
                    onSelectEndDate: () => selectSubjectDate(true),
                    isEditMode: isEditMode,
                    isAllSelected: isAllSelected,
                    onSelectAllChanged: (checked) {
                      setState(() {
                        selectedItems.clear();
                        if (checked == true) selectedItems.addAll(allFlattened);
                      });
                    },
                    isAllFinishedSelected: isAllFinishedSelected,
                    onSelectAllFinishedChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          for (var i in finishedItems) {
                            if (!selectedItems.contains(i))
                              selectedItems.add(i);
                          }
                        } else {
                          selectedItems.removeWhere(
                            (i) => i.progress == 'selesai',
                          );
                        }
                      });
                    },
                    onMarkAllDone: markAllSubMateriAsDone,
                    hideFinishedItems: hideFinishedItems,
                    onToggleHideFinished: () =>
                        setState(() => hideFinishedItems = !hideFinishedItems),
                    defaultCardExpanded: widget.subject.defaultExpanded,
                    onDefaultExpandedPrefChanged:
                        toggleCardDefaultExpandedPreference,
                    onTriggerAllExpansion: expandOrCollapseAllMateri,
                    // --- MENGHUBUNGKAN AKSI POPUP DIALOG IMPOR JSON ---
                    onImportJsonPressed: showImportJsonDialog,
                  )
                : const SizedBox.shrink(),
          ),
          Flexible(
            child: widget.subject.type == 'note'
                ? ChecklistNoteView(
                    noteController: noteController,
                    isMarkdownEnabled: isMarkdownEnabled,
                    isViewMode: isNoteViewMode,
                    onChanged: (text) {
                      final orig = widget.subject.noteContent ?? '';
                      setState(() => isNoteModified = text != orig);
                    },
                  )
                : (widget.subject.subMateri.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Text('Tidak ada item sub materi.'),
                        )
                      : ListView(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 4,
                          ),
                          children: [
                            ...List.generate(widget.subject.subMateri.length, (
                              index,
                            ) {
                              final item = widget.subject.subMateri[index];
                              if (item.progress == 'selesai')
                                return const SizedBox.shrink();
                              return ChecklistTreeView(
                                item: item,
                                depth: 0,
                                isEditMode: isEditMode,
                                selectedItems: selectedItems,
                                highlightedItem: highlightedItem,
                                isFirst: index == 0,
                                isLast:
                                    index ==
                                    widget.subject.subMateri.length - 1,
                                onSelectItem: (target, add) => setState(
                                  () => add
                                      ? selectedItems.add(target)
                                      : selectedItems.remove(target),
                                ),
                                onMoveOrder: moveItemOrder,
                                onEditName: (targetItem) =>
                                    showEditNameDialog(targetItem),
                                onLongPressToggle: () => setState(() {
                                  isEditMode = !isEditMode;
                                  selectedItems.clear();
                                }),
                                onCheckStatusChanged: handleCheckStatusChanged,
                                onTapToggleStatus: handleTapToggleStatus,
                                onAddChild: (targetItem) =>
                                    addChildSubMateri(targetItem),
                                onDeleteItem: (targetItem) =>
                                    deleteSingleSubMateri(targetItem),
                                onToggleItemType: handleToggleItemType,
                                onUpdateProgressValue:
                                    showUpdateProgressValueDialog,
                                onToggleDisable: handleToggleDisableItem,
                                onToggleExpansion: toggleItemExpansion,
                              );
                            }),
                            if (!hideFinishedItems &&
                                widget.subject.subMateri.any(
                                  (i) => i.progress == 'selesai',
                                ))
                              const Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: 12.0,
                                  horizontal: 16.0,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        thickness: 1.5,
                                        color: Colors.green,
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10.0,
                                      ),
                                      child: Text(
                                        'List Telah Selesai',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        thickness: 1.5,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (!hideFinishedItems)
                              ...List.generate(
                                widget.subject.subMateri.length,
                                (index) {
                                  final item = widget.subject.subMateri[index];
                                  if (item.progress != 'selesai')
                                    return const SizedBox.shrink();
                                  return ChecklistTreeView(
                                    item: item,
                                    depth: 0,
                                    isEditMode: isEditMode,
                                    selectedItems: selectedItems,
                                    highlightedItem: highlightedItem,
                                    isFirst: index == 0,
                                    isLast:
                                        index ==
                                        widget.subject.subMateri.length - 1,
                                    onSelectItem: (target, add) => setState(
                                      () => add
                                          ? selectedItems.add(target)
                                          : selectedItems.remove(target),
                                    ),
                                    onMoveOrder: moveItemOrder,
                                    onEditName: (targetItem) =>
                                        showEditNameDialog(targetItem),
                                    onLongPressToggle: () => setState(() {
                                      isEditMode = !isEditMode;
                                      selectedItems.clear();
                                    }),
                                    onCheckStatusChanged:
                                        handleCheckStatusChanged,
                                    onTapToggleStatus: handleTapToggleStatus,
                                    onAddChild: (targetItem) =>
                                        addChildSubMateri(targetItem),
                                    onDeleteItem: (targetItem) =>
                                        deleteSingleSubMateri(targetItem),
                                    onToggleItemType: handleToggleItemType,
                                    onUpdateProgressValue:
                                        showUpdateProgressValueDialog,
                                    onToggleDisable: handleToggleDisableItem,
                                    onToggleExpansion: toggleItemExpansion,
                                  );
                                },
                              ),
                          ],
                        )),
          ),
        ],
      ),
      footer: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (isEditMode) ...[
              Text(
                '${selectedItems.length} Terpilih',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              Row(
                children: [
                  ButtonTheme(
                    child: ElevatedButton.icon(
                      onPressed: selectedItems.isEmpty
                          ? null
                          : () => showMoveSelectedItemsDialog(allFlattened),
                      icon: const Icon(
                        Icons.drive_file_move,
                        color: Colors.white,
                        size: 16,
                      ),
                      label: const Text(
                        'Pindah',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton.icon(
                    onPressed: selectedItems.isEmpty
                        ? null
                        : () async {
                            final confirm = await showConfirmDialog(
                              title: 'Hapus Masal',
                              content: 'Hapus seluruh item terpilih?',
                            );
                            if (!confirm) return;
                            setState(() {
                              for (var i in selectedItems) {
                                deleteItemFromTree(widget.subject.subMateri, i);
                              }
                              selectedItems.clear();
                            });
                            updateSubjectOverallProgress();
                            widget.onDataChanged();
                          },
                    icon: const Icon(
                      Icons.delete_sweep,
                      color: Colors.white,
                      size: 16,
                    ),
                    label: const Text(
                      'Hapus Masal',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  if (undoStack.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.undo, color: Colors.blueGrey),
                      onPressed: executeUndo,
                    ),
                  if (redoStack.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.redo, color: Colors.blueGrey),
                      onPressed: executeRedo,
                    ),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () async {
                      final confirm = await showConfirmDialog(
                        title: 'Reset Progress',
                        content:
                            'Reset semua progress menjadi Belum Selesai? (List nonaktif akan diabaikan)',
                      );
                      if (!confirm) return;
                      saveToHistory();
                      void resetRecursive(List<SubSubjectItem> list) {
                        for (var item in list) {
                          if (!item.isDisabled) {
                            item.progress = 'belum';
                            item.finishedDate = null;
                            // === PERUBAHAN: Jika tipenya countdown, reset ke nilai targetValue bukan 0 ===
                            if (item.itemType == 'countdown') {
                              item.currentValue = item.targetValue;
                            } else {
                              item.currentValue = 0;
                            }
                          }
                          resetRecursive(item.subMateri);
                        }
                      }

                      setState(() {
                        resetRecursive(widget.subject.subMateri);

                        if (widget.subject.isDateActive &&
                            widget.subject.dateType != 'range') {
                          final now = DateTime.now();
                          widget.subject.date =
                              "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
                        }
                      });
                      updateSubjectOverallProgress();
                      widget.onDataChanged();
                    },
                    onLongPress: () async {
                      final confirm = await showConfirmDialog(
                        title: 'Reset Total Checklist',
                        content:
                            'Apakah Anda yakin ingin mereset seluruh progress DAN mengaktifkan kembali semua list yang dinonaktifkan (tanda silang)?',
                      );
                      if (!confirm) return;
                      saveToHistory();
                      void forceResetAllRecursive(List<SubSubjectItem> list) {
                        for (var item in list) {
                          item.isDisabled = false;
                          item.progress = 'belum';
                          item.finishedDate = null;
                          // === PERUBAHAN: Jika tipenya countdown, reset ke nilai targetValue bukan 0 ===
                          if (item.itemType == 'countdown') {
                            item.currentValue = item.targetValue;
                          } else {
                            item.currentValue = 0;
                          }
                          forceResetAllRecursive(item.subMateri);
                        }
                      }

                      setState(() {
                        forceResetAllRecursive(widget.subject.subMateri);

                        if (widget.subject.isDateActive &&
                            widget.subject.dateType != 'range') {
                          final now = DateTime.now();
                          widget.subject.date =
                              "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
                        }
                      });
                      updateSubjectOverallProgress();
                      widget.onDataChanged();

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Seluruh list dan status dinonaktifkan berhasil di-reset total!',
                            ),
                            backgroundColor: Colors.deepOrange,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 8.0,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh, color: Colors.red, size: 18),
                          SizedBox(width: 4),
                          Text(
                            'Reset',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  if (widget.onCustomClosePressed != null) {
                    widget.onCustomClosePressed!();
                  } else {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(widget.subject.backgroundColor),
                ),
                child: Text(
                  'Tutup',
                  style: TextStyle(color: Color(widget.subject.textColor)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

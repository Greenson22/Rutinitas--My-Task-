// lib/features/daily/presentation/widgets/checklist_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rutinitasku/core/utils/string_helper.dart';
import 'package:rutinitasku/features/checklist/presentation/checklist_detail_screen/widgets/edit_item_relations_dialog.dart';
import 'package:rutinitasku/features/checklist/presentation/checklist_detail_screen/widgets/edit_subject_name_dialog.dart';
import 'package:rutinitasku/features/checklist/presentation/checklist_detail_screen/widgets/import_json_dialog.dart';
import 'package:rutinitasku/features/checklist/presentation/checklist_detail_screen/widgets/move_selected_items_dialog.dart';
import 'package:rutinitasku/features/checklist/presentation/checklist_detail_screen/widgets/update_progress_value_dialog.dart';
import '../../../data/models/daily_model.dart';
import 'change_color_dialog.dart';
import 'checklist_control_panel.dart';
import 'checklist_tree_view.dart';
import 'checklist_note_view.dart';
import '../controllers/checklist_dialog_controller.dart';
import '../../../../../core/presentation/widgets/base_popup_dialog.dart';

class DailyChecklistDialog extends StatefulWidget {
  final DailySubject subject;
  final VoidCallback onDataChanged;
  final List<DailySubject> allAvailableSubjects;
  final List<ChecklistGroup>? allAvailableGroups;
  final VoidCallback? onCustomClosePressed;
  final String? baseDir;

  const DailyChecklistDialog({
    super.key,
    required this.subject,
    required this.onDataChanged,
    required this.allAvailableSubjects,
    this.allAvailableGroups,
    this.onCustomClosePressed,
    this.baseDir,
  });

  @override
  State<DailyChecklistDialog> createState() => _DailyChecklistDialogState();
}

class _DailyChecklistDialogState extends ChecklistDialogController {
  // =========================================================================
  // IMPLEMENTASI SEMUA VIEW & DIALOG (UI ONLY)
  // =========================================================================

  Future<bool> showConfirmDialogView({
    required String title,
    required String content,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Konfirmasi'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void showEditSubjectNameDialogView() {
    showDialog(
      context: context,
      builder: (context) => EditSubjectNameDialog(
        initialName: widget.subject.subjectName,
        onSave: (newName) {
          setState(() => widget.subject.subjectName = newName);
          widget.onDataChanged();
        },
      ),
    );
  }

  void addChildSubMateriDialogView(SubSubjectItem parentItem) {
    final childController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tambah Anak di bawah "${parentItem.subjectName}"'),
        content: TextField(
          controller: childController,
          decoration: const InputDecoration(
            hintText: 'Nama anak sub-materi...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = childController.text.trim();
              if (text.isNotEmpty) {
                addChildSubMateriData(parentItem, text);
              }
              Navigator.pop(context);
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  void showImportJsonDialogView() {
    showDialog(
      context: context,
      builder: (context) => ImportJsonDialog(
        onImport: (rawInput) {
          try {
            importSubMateriFromJson(rawInput);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🎉 Sukses mengimpor dari data JSON!'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gagal memuat JSON! Detail: $e'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> selectSubjectDatePicker(bool isEndDate) async {
    DateTime initialDate = DateTime.now();
    String? dateToParse = isEndDate
        ? widget.subject.endDate
        : widget.subject.date;
    if (dateToParse != null && dateToParse.isNotEmpty) {
      try {
        initialDate = DateTime.parse(dateToParse);
      } catch (_) {}
    }
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        String formatted =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
        if (isEndDate) {
          widget.subject.endDate = formatted;
        } else {
          widget.subject.date = formatted;
        }
      });
      widget.onDataChanged();
    }
  }

  void pasteFromClipboardView() async {
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null || data!.text!.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Clipboard kosong.')));
      return;
    }
    List<String> lines = data.text!
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) return;

    bool konfirmasi = await showConfirmDialogView(
      title: 'Konfirmasi Paste Banyak List',
      content:
          'Apakah Anda yakin ingin menambahkan ${lines.length} item baru dari clipboard?',
    );

    if (konfirmasi) {
      pasteFromClipboardData(lines);
    }
  }

  void deleteSingleSubMateriView(SubSubjectItem item) async {
    bool confirm = await showConfirmDialogView(
      title: 'Hapus Sub-Materi',
      content:
          'Apakah Anda yakin ingin menghapus "${item.subjectName}" beserta seluruh turunannya?',
    );
    if (confirm) {
      deleteSingleSubMateriData(item);
    }
  }

  void deleteCurrentNotePageView() async {
    bool confirm = await showConfirmDialogView(
      title: 'Hapus Halaman',
      content:
          'Apakah Anda yakin ingin menghapus halaman catatan aktif saat ini secara permanen?',
    );
    if (confirm) {
      deleteCurrentNotePage();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🗑️ Halaman catatan berhasil dihapus!'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void handleTapToggleStatusView(SubSubjectItem target) {
    if (target.linkedSubjectName != null &&
        target.linkedSubjectName!.isNotEmpty) {
      _showLinkedPrerequisiteDialog(target);
      return;
    }
    if (target.itemType == 'progress' || target.itemType == 'countdown') {
      showUpdateProgressValueDialogView(target);
      return;
    }
    handleTapToggleStatusData(target);
  }

  int? _resolvePrerequisitePercentage(SubSubjectItem target) {
    final targetName = target.linkedSubjectName ?? '';
    final targetId = target.linkedSubjectId;
    if (targetName.isEmpty && (targetId == null || targetId.isEmpty)) {
      return null;
    }

    DailySubject? linkedCard;
    for (final sub in widget.allAvailableSubjects) {
      if ((targetId != null &&
              targetId.isNotEmpty &&
              sub.subjectName == targetId) ||
          sub.subjectName == targetName) {
        linkedCard = sub;
        break;
      }
    }
    if (linkedCard == null && widget.allAvailableGroups != null) {
      for (final group in widget.allAvailableGroups!) {
        for (final section in group.allList) {
          for (final sub in section.items) {
            if ((targetId != null &&
                    targetId.isNotEmpty &&
                    sub.subjectName == targetId) ||
                sub.subjectName == targetName) {
              linkedCard = sub;
              break;
            }
          }
          if (linkedCard != null) break;
        }
        if (linkedCard != null) break;
      }
    }

    if (linkedCard == null) return null;
    final List<SubSubjectItem> flatItems = [];
    getAllItemsFlattened(linkedCard.subMateri, flatItems);
    if (flatItems.isEmpty) return 0;
    final doneCount = flatItems.where((el) => el.progress == 'selesai').length;
    return ((doneCount / flatItems.length) * 100).round();
  }

  void _showLinkedPrerequisiteDialog(SubSubjectItem target) {
    final targetName = target.linkedSubjectName ?? '';
    final targetId = target.linkedSubjectId;

    DailySubject? linkedCard;
    for (final sub in widget.allAvailableSubjects) {
      if ((targetId != null && targetId.isNotEmpty && sub.subjectName == targetId) ||
          sub.subjectName == targetName) {
        linkedCard = sub;
        break;
      }
    }
    if (linkedCard == null && widget.allAvailableGroups != null) {
      for (final group in widget.allAvailableGroups!) {
        for (final section in group.allList) {
          for (final sub in section.items) {
            if ((targetId != null &&
                    targetId.isNotEmpty &&
                    sub.subjectName == targetId) ||
                sub.subjectName == targetName) {
              linkedCard = sub;
              break;
            }
          }
          if (linkedCard != null) break;
        }
        if (linkedCard != null) break;
      }
    }

    final List<SubSubjectItem> flatItems = [];
    if (linkedCard != null) {
      getAllItemsFlattened(linkedCard.subMateri, flatItems);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline_rounded, color: Colors.amber),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Item Terkunci Prasyarat',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selesaikan terlebih dahulu Card "${linkedCard != null ? '${linkedCard.icon} ${linkedCard.subjectName}' : targetName}" sebelum mencentang "${target.subjectName}":',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              if (flatItems.isEmpty)
                const Text(
                  'Tidak ada daftar item yang ditemukan pada Card prasyarat.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: flatItems.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = flatItems[index];
                      final isDone = item.progress == 'selesai';
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          isDone
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: isDone ? Colors.green : Colors.amber[700],
                          size: 20,
                        ),
                        title: Text(
                          item.subjectName,
                          style: TextStyle(
                            fontSize: 13,
                            decoration: isDone
                                ? TextDecoration.lineThrough
                                : null,
                            color: isDone ? Colors.grey : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void showUpdateProgressValueDialogView(SubSubjectItem item) {
    showDialog(
      context: context,
      builder: (context) => UpdateProgressValueDialog(
        item: item,
        onConfirm: (targetItem, value, isCountdown) {
          updateProgressValueData(targetItem, value, isCountdown);
        },
      ),
    );
  }

  void handleToggleItemTypeView(SubSubjectItem item, String targetType) {
    if (targetType == 'normal') {
      updateItemTypeData(item, 'normal', 0);
    } else {
      final targetController = TextEditingController();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            targetType == 'countdown'
                ? 'Set Target Angka Awal Hitung Mundur'
                : 'Set Target Angka Progres',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: targetController,
            keyboardType: TextInputType.number,
            autofocus: true,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Nil Value (Misal: 10, 1.000, 1.000.000)',
              border: OutlineInputBorder(),
            ),
            onChanged: (val) {
              if (val.isEmpty) return;
              String cleanText = val.replaceAll('.', '');
              String formattedText = StringHelper.formatRibuan(
                int.tryParse(cleanText) ?? 0,
              );
              targetController.value = TextEditingValue(
                text: formattedText,
                selection: TextSelection.collapsed(
                  offset: formattedText.length,
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final String rawText = targetController.text
                    .replaceAll('.', '')
                    .trim();
                final int? target = int.tryParse(rawText);
                if (target != null && target > 0) {
                  Navigator.pop(context);
                  updateItemTypeData(item, targetType, target);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
              ),
              child: const Text(
                'Set Target',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }
  }

  ({DailySubject sourceSubject, SubSubjectItem item})? _resolveMonitorRef(
    MonitorItemRef ref,
  ) {
    final sourceSubject = widget.allAvailableSubjects.firstWhere(
      (s) => s.subjectName == ref.sourceSubjectName,
      orElse: () => DailySubject(
        subjectName: '',
        progress: 'belum',
        subMateri: const [],
      ),
    );
    if (sourceSubject.subjectName.isEmpty) return null;

    final List<SubSubjectItem> flat = [];
    getAllItemsFlattened(sourceSubject.subMateri, flat);
    final sourceItem = flat.firstWhere(
      (i) => i.id == ref.sourceItemId,
      orElse: () => SubSubjectItem(subjectName: '', progress: 'belum'),
    );
    if (sourceItem.subjectName.isEmpty) return null;
    return (sourceSubject: sourceSubject, item: sourceItem);
  }

  void _showAddMonitorParentDialog({
    MonitorItemRef? existingParent,
    List<MonitorItemRef>? targetList,
  }) {
    final controller = TextEditingController(
      text: existingParent?.parentTitle ?? '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          existingParent == null ? 'Tambah Parent Monitor' : 'Ubah Nama Parent',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nama kelompok/parent...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = controller.text.trim();
              if (title.isEmpty) return;
              setState(() {
                if (existingParent != null) {
                  existingParent.parentTitle = title;
                } else {
                  (targetList ?? widget.subject.monitorItems).add(
                    MonitorItemRef(
                      isGroupParent: true,
                      parentTitle: title,
                    ),
                  );
                }
              });
              widget.onDataChanged();
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showMonitorParentActions(
    MonitorItemRef entry,
    List<MonitorItemRef> containerList,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.folder_outlined, color: Colors.indigo),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.parentTitle ?? 'Parent',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: Colors.teal),
              title: const Text('Tambah Item Monitor'),
              onTap: () {
                Navigator.pop(ctx);
                _showAddMonitorItemDialog(targetParent: entry);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.create_new_folder_outlined,
                color: Colors.indigo,
              ),
              title: const Text('Tambah Sub-Parent'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => entry.isExpanded = true);
                _showAddMonitorParentDialog(targetList: entry.children);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Colors.blueGrey),
              title: const Text('Ubah Nama Parent'),
              onTap: () {
                Navigator.pop(ctx);
                _showAddMonitorParentDialog(existingParent: entry);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text(
                'Hapus Parent',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => containerList.remove(entry));
                widget.onDataChanged();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonitorParentNode(
    MonitorItemRef entry,
    List<MonitorItemRef> containerList,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() => entry.isExpanded = !entry.isExpanded);
            widget.onDataChanged();
          },
          onLongPress: () => _showMonitorParentActions(entry, containerList),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Row(
              children: [
                Icon(
                  entry.isExpanded
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.keyboard_arrow_right_rounded,
                  size: 20,
                  color: Colors.indigo,
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.folder_outlined,
                  size: 18,
                  color: Colors.indigo,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    entry.parentTitle ?? 'Parent',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.indigo,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (entry.isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 18.0),
            child: entry.children.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: Text(
                      'Kosong — tahan parent untuk menambah item/sub-parent',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : Column(
                    children: List.generate(entry.children.length, (cIdx) {
                      final child = entry.children[cIdx];
                      if (child.isGroupParent) {
                        return _buildMonitorParentNode(child, entry.children);
                      }
                      return _buildMonitorShadowRow(
                        child,
                        entry.children,
                        cIdx,
                        entry.children.length,
                      );
                    }),
                  ),
          ),
      ],
    );
  }

  Widget _buildMonitorShadowRow(
    MonitorItemRef ref,
    List<MonitorItemRef> containerList,
    int index,
    int total,
  ) {
    final resolved = _resolveMonitorRef(ref);
    if (resolved == null) return const SizedBox.shrink();
    final sourceItem = resolved.item;
    final sourceSubject = resolved.sourceSubject;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: ChecklistTreeView(
            item: sourceItem,
            depth: 0,
            isEditMode: false,
            selectedItems: const [],
            highlightedItem: null,
            isFirst: index == 0,
            isLast: index == total - 1,
            monitorSourceLabel: 'Bayangan • Dari: ${sourceSubject.subjectName}',
            onSelectItem: (_, __) {},
            onMoveOrder: (_, __) {},
            onEditName: (target) => showEditNameDialogView(target),
            onLongPressToggle: () {},
            onCheckStatusChanged: (target, val) {
              setState(() {
                target.progress = (val == true) ? 'selesai' : 'belum';
                target.finishedDate =
                    (val == true) ? DateTime.now().toIso8601String() : null;
              });
              widget.onDataChanged();
            },
            onTapToggleStatus: (target) {
              handleTapToggleStatusView(target);
            },
            onAddChild: (_) {},
            onDeleteItem: (_) {},
            onToggleItemType: handleToggleItemTypeView,
            onUpdateProgressValue: showUpdateProgressValueDialogView,
            onToggleDisable: (target) {
              setState(() => target.isDisabled = !target.isDisabled);
              widget.onDataChanged();
            },
            onToggleExpansion: (target) {
              setState(() => target.isExpanded = !target.isExpanded);
            },
          ),
        ),
        IconButton(
          tooltip: 'Lepas dari Monitor',
          icon: const Icon(
            Icons.link_off_rounded,
            size: 18,
            color: Colors.redAccent,
          ),
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(6),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Lepas Item Bayangan?'),
                content: Text(
                  'Lepaskan "${sourceItem.subjectName}" dari daftar monitor?\n(Item asli di "${sourceSubject.subjectName}" tidak akan terhapus.)',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Batal'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Lepaskan'),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              setState(() {
                containerList.remove(ref);
              });
              widget.onDataChanged();
            }
          },
        ),
      ],
    );
  }

  Widget _buildMonitorListView() {
    final items = widget.subject.monitorItems;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Colors.indigo.withValues(alpha: 0.08),
          child: Row(
            children: [
              const Icon(
                Icons.monitor_heart_rounded,
                size: 16,
                color: Colors.indigo,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Mode Monitor Aktif',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.indigo,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _showAddMonitorParentDialog(),
                icon: const Icon(Icons.create_new_folder_outlined, size: 15),
                label: const Text('Parent', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: () => _showAddMonitorItemDialog(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Item', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'Belum ada item monitor.\nTekan "+ Parent" untuk membuat kelompok atau "+ Item" untuk memantau item dari card lain.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          )
        else
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final entry = items[index];
                if (entry.isGroupParent) {
                  return _buildMonitorParentNode(entry, items);
                }

                return _buildMonitorShadowRow(
                  entry,
                  items,
                  index,
                  items.length,
                );
              },
            ),
          ),
      ],
    );
  }

  void _showAddMonitorItemDialog({MonitorItemRef? targetParent}) {
    final targetList = targetParent != null
        ? targetParent.children
        : widget.subject.monitorItems;
    final otherSubjects = widget.allAvailableSubjects
        .where(
          (s) =>
              s.subjectName != widget.subject.subjectName &&
              s.type == 'list' &&
              s.subMateri.isNotEmpty,
        )
        .toList();

    final sections = otherSubjects.map((s) => s.section).toSet().toList();
    String? selectedSection = sections.length == 1 ? sections.first : null;
    DailySubject? selectedSubject;

    List<({SubSubjectItem item, int depth})> flattenWithDepth(
      List<SubSubjectItem> list, [
      int depth = 0,
    ]) {
      final result = <({SubSubjectItem item, int depth})>[];
      for (final item in list) {
        result.add((item: item, depth: depth));
        if (item.subMateri.isNotEmpty) {
          result.addAll(flattenWithDepth(item.subMateri, depth + 1));
        }
      }
      return result;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Widget body;
          String titleText = 'Pilih Seksi';

          if (otherSubjects.isEmpty) {
            titleText = 'Pilih Item untuk Dimonitor';
            body = const Text('Tidak ada card list lain di grup ini.');
          } else if (selectedSection == null) {
            titleText = '1. Pilih Seksi';
            body = ListView.builder(
              shrinkWrap: true,
              itemCount: sections.length,
              itemBuilder: (context, idx) {
                final sec = sections[idx];
                final count = otherSubjects
                    .where((s) => s.section == sec)
                    .length;
                return ListTile(
                  leading: const Icon(Icons.folder_outlined, color: Colors.indigo),
                  title: Text(sec),
                  subtitle: Text('$count card checklist'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    setDialogState(() => selectedSection = sec);
                  },
                );
              },
            );
          } else if (selectedSubject == null) {
            titleText = '2. Pilih Card ($selectedSection)';
            final cardsInSection = otherSubjects
                .where((s) => s.section == selectedSection)
                .toList();
            body = ListView.builder(
              shrinkWrap: true,
              itemCount: cardsInSection.length,
              itemBuilder: (context, idx) {
                final card = cardsInSection[idx];
                return ListTile(
                  leading: Text(card.icon, style: const TextStyle(fontSize: 18)),
                  title: Text(card.subjectName),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    setDialogState(() => selectedSubject = card);
                  },
                );
              },
            );
          } else {
            titleText = '3. Pilih Item (${selectedSubject!.subjectName})';
            final flatItems = flattenWithDepth(selectedSubject!.subMateri);
            body = ListView.builder(
              shrinkWrap: true,
              itemCount: flatItems.length,
              itemBuilder: (context, idx) {
                final entry = flatItems[idx];
                final it = entry.item;
                final depth = entry.depth;
                final alreadyAdded = targetList.any(
                  (m) =>
                      !m.isGroupParent &&
                      m.sourceSubjectName == selectedSubject!.subjectName &&
                      m.sourceItemId == it.id,
                );
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.only(
                    left: 12.0 + (depth * 18.0),
                    right: 8.0,
                  ),
                  leading: depth > 0
                      ? const Icon(
                          Icons.subdirectory_arrow_right,
                          size: 16,
                          color: Colors.grey,
                        )
                      : null,
                  title: Text(
                    it.subjectName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: depth == 0 ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: alreadyAdded
                      ? const Icon(
                          Icons.check_circle,
                          color: Colors.teal,
                          size: 20,
                        )
                      : const Icon(
                          Icons.add_circle_outline,
                          color: Colors.indigo,
                          size: 20,
                        ),
                  onTap: () {
                    setState(() {
                      if (alreadyAdded) {
                        targetList.removeWhere(
                          (m) =>
                              !m.isGroupParent &&
                              m.sourceSubjectName == selectedSubject!.subjectName &&
                              m.sourceItemId == it.id,
                        );
                      } else {
                        targetList.add(
                          MonitorItemRef(
                            sourceSubjectName: selectedSubject!.subjectName,
                            sourceItemId: it.id,
                          ),
                        );
                      }
                    });
                    setDialogState(() {});
                    widget.onDataChanged();
                  },
                );
              },
            );
          }

          return AlertDialog(
            title: Row(
              children: [
                if (selectedSubject != null ||
                    (selectedSection != null && sections.length > 1))
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setDialogState(() {
                        if (selectedSubject != null) {
                          selectedSubject = null;
                        } else {
                          selectedSection = null;
                        }
                      });
                    },
                  ),
                if (selectedSubject != null ||
                    (selectedSection != null && sections.length > 1))
                  const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    titleText,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: body,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Selesai'),
              ),
            ],
          );
        },
      ),
    );
  }

  void showEditNameDialogView(SubSubjectItem item) {
    showDialog(
      context: context,
      builder: (context) => EditItemRelationsDialog(
        item: item,
        currentSubject: widget.subject,
        allAvailableSubjects: widget.allAvailableSubjects,
        allAvailableGroups: widget.allAvailableGroups,
        getAllItemsFlattened: getAllItemsFlattened,
        onConfirm:
            ({
              required item,
              required newName,
              required linkedSubjectId,
              required linkedSubjectName,
              required accumulatorItemId,
              required accumulatorItemName,
              required linkedExternalCardName,
              required linkedExternalItemId,
              required linkedExternalItemName,
              required parsedCurrent,
              required parsedTarget,
              required selectedExternalCard,
              required textColor,
            }) {
              void applyTextColorRecursive(SubSubjectItem target, int? color) {
                target.textColor = color;
                for (final child in target.subMateri) {
                  applyTextColorRecursive(child, color);
                }
              }

              applyTextColorRecursive(item, textColor);
              updateItemNameAndRelationsData(
                item: item,
                newName: newName,
                linkedSubjectId: linkedSubjectId,
                linkedSubjectName: linkedSubjectName,
                accumulatorItemId: accumulatorItemId,
                accumulatorItemName: accumulatorItemName,
                linkedExternalCardName: linkedExternalCardName,
                linkedExternalItemId: linkedExternalItemId,
                linkedExternalItemName: linkedExternalItemName,
                parsedCurrent: parsedCurrent,
                parsedTarget: parsedTarget,
                selectedExternalCard: selectedExternalCard,
              );
            },
      ),
    );
  }

  void showMoveSelectedItemsDialogView(List<SubSubjectItem> allFlattened) {
    showDialog(
      context: context,
      builder: (context) => MoveSelectedItemsDialog(
        allFlattened: allFlattened,
        selectedItems: selectedItems,
        currentSubject: widget.subject,
        allAvailableSubjects: widget.allAvailableSubjects,
        onMoveToTarget: ({targetParent}) {
          moveSelectedItemsToTarget(targetParent: targetParent);
        },
        onMoveToOtherSubject: (targetSubject) {
          moveSelectedItemsToOtherSubject(targetSubject);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Berhasil memindahkan item ke kotak "${targetSubject.subjectName}"',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }
  // =========================================================================

  String? _resolveExternalAccumulationText(SubSubjectItem item) {
    if (item.linkedExternalCardName == null) return null;
    if (item.linkedExternalItemId == null && item.linkedExternalItemName == null) {
      return null;
    }

    final targetSubject = widget.allAvailableSubjects.firstWhere(
      (sub) => sub.subjectName == item.linkedExternalCardName,
      orElse: () =>
          DailySubject(subjectName: '', progress: 'belum', subMateri: []),
    );
    if (targetSubject.subjectName.isEmpty) return null;

    final List<SubSubjectItem> flattened = [];
    getAllItemsFlattened(targetSubject.subMateri, flattened);

    final targetItem = flattened.firstWhere(
      (el) {
        if (item.linkedExternalItemId != null &&
            item.linkedExternalItemId!.isNotEmpty) {
          return el.id == item.linkedExternalItemId;
        }
        return el.subjectName == item.linkedExternalItemName;
      },
      orElse: () => SubSubjectItem(subjectName: '', progress: 'belum'),
    );

    if (targetItem.subjectName.isEmpty) return null;
    return '(${_formatNumber(targetItem.currentValue)}/${_formatNumber(targetItem.targetValue)})';
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

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
              onTap: showEditSubjectNameDialogView,
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
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Color(widget.subject.backgroundColor).computeLuminance() > 0.5
                        ? Colors.black87
                        : Colors.white,
                    size: 22,
                  ),
                  tooltip: 'Opsi Catatan',
                  onSelected: (String value) {
                    if (value == 'toggle_view') {
                      setState(() => isNoteViewMode = !isNoteViewMode);
                    } else if (value == 'toggle_md') {
                      toggleMarkdownEnabled();
                    } else if (value == 'add_page') {
                      addNewNotePage();
                    } else if (value == 'delete_page') {
                      deleteCurrentNotePageView();
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<String>(
                      value: 'toggle_view',
                      child: Row(
                        children: [
                          Icon(
                            isNoteViewMode
                                ? Icons.edit
                                : Icons.chrome_reader_mode,
                            color: Colors.blueGrey,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isNoteViewMode
                                ? 'Edit Catatan'
                                : 'Pratinjau Catatan',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem<String>(
                      value: 'toggle_md',
                      child: Row(
                        children: [
                          Icon(
                            isMarkdownEnabled
                                ? Icons.toggle_on
                                : Icons.toggle_off_outlined,
                            color: isMarkdownEnabled
                                ? Colors.teal
                                : Colors.grey,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isMarkdownEnabled
                                  ? 'Markdown: Aktif'
                                  : 'Markdown: Nonaktif',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem<String>(
                      value: 'add_page',
                      child: Row(
                        children: const [
                          Icon(
                            Icons.note_add_outlined,
                            color: Colors.indigo,
                            size: 18,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Tambah Halaman',
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    if (notePages.length > 1) ...[
                      const PopupMenuDivider(),
                      PopupMenuItem<String>(
                        value: 'delete_page',
                        child: Row(
                          children: const [
                            Icon(
                              Icons.delete_forever_outlined,
                              color: Colors.redAccent,
                              size: 18,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Hapus Halaman Ini',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],

              if (widget.subject.type == 'note' && isNoteModified)
                IconButton(
                  icon: const Icon(
                    Icons.save_as,
                    color: Colors.amberAccent,
                    size: 24,
                  ),
                  onPressed: () {
                    saveManualNote();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('📝 Catatan disimpan!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              IconButton(
                icon: Icon(
                  Icons.palette,
                  color: Color(widget.subject.backgroundColor).computeLuminance() > 0.5
                      ? Colors.black87
                      : Colors.white,
                  size: 20,
                ),
                onPressed: () => showDialog(
                  context: context,
                  builder: (ctx) => ChangeColorDialog(
                    subject: widget.subject,
                    onColorSaved: () {
                      setState(() {});
                      widget.onDataChanged();
                    },
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  widget.subject.type == 'note' ? Icons.checklist : Icons.notes,
                  color: Color(widget.subject.backgroundColor).computeLuminance() > 0.5
                      ? Colors.black87
                      : Colors.white,
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
                  tooltip: widget.subject.isMonitorMode
                      ? 'Matikan Mode Monitor'
                      : 'Aktifkan Mode Monitor',
                  icon: Icon(
                    widget.subject.isMonitorMode
                        ? Icons.monitor_heart_rounded
                        : Icons.monitor_heart_outlined,
                    color: widget.subject.isMonitorMode
                        ? Colors.amberAccent
                        : (Color(widget.subject.backgroundColor).computeLuminance() > 0.5
                            ? Colors.black87
                            : Colors.white),
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      widget.subject.isMonitorMode =
                          !widget.subject.isMonitorMode;
                      if (widget.subject.isMonitorMode) {
                        isEditMode = false;
                      }
                    });
                    widget.onDataChanged();
                  },
                ),
              if (widget.subject.type != 'note')
                IconButton(
                  icon: Icon(
                    showControlPanel ? Icons.tune : Icons.tune_outlined,
                    color: showControlPanel
                        ? Colors.amberAccent
                        : (Color(widget.subject.backgroundColor).computeLuminance() > 0.5
                            ? Colors.black87
                            : Colors.white),
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
                    onPasteFromClipboard: pasteFromClipboardView,
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
                    onSelectStartDate: () => selectSubjectDatePicker(false),
                    onSelectEndDate: () => selectSubjectDatePicker(true),
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
                    onImportJsonPressed: showImportJsonDialogView,
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
                      // Modifikasi pelacakan perubahan teks agar sensitif terhadap halaman aktif saat ini
                      final String orig = notePages.isNotEmpty
                          ? notePages[currentNotePage]
                          : '';
                      setState(() => isNoteModified = text != orig);
                    },
                  )
                : (widget.subject.isMonitorMode
                      ? _buildMonitorListView()
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
                                resolvePrerequisitePercentage:
                                    _resolvePrerequisitePercentage,
                                onSelectItem: (target, add) => setState(
                                  () => add
                                      ? selectedItems.add(target)
                                      : selectedItems.remove(target),
                                ),
                                onMoveOrder: moveItemOrder,
                                onEditName: (targetItem) =>
                                    showEditNameDialogView(targetItem),
                                onLongPressToggle: () => setState(() {
                                  isEditMode = !isEditMode;
                                  selectedItems.clear();
                                }),
                                onCheckStatusChanged: handleCheckStatusChanged,
                                onTapToggleStatus: handleTapToggleStatusView,
                                onAddChild: (targetItem) =>
                                    addChildSubMateriDialogView(targetItem),
                                onDeleteItem: (targetItem) =>
                                    deleteSingleSubMateriView(targetItem),
                                onToggleItemType: handleToggleItemTypeView,
                                onUpdateProgressValue:
                                    showUpdateProgressValueDialogView,
                                onToggleDisable: handleToggleDisableItem,
                                onToggleExpansion: toggleItemExpansion,
                                resolveExternalAccumulationText:
                                    _resolveExternalAccumulationText,
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
                                    resolvePrerequisitePercentage:
                                        _resolvePrerequisitePercentage,
                                    onSelectItem: (target, add) => setState(
                                      () => add
                                          ? selectedItems.add(target)
                                          : selectedItems.remove(target),
                                    ),
                                    onMoveOrder: moveItemOrder,
                                    onEditName: (targetItem) =>
                                        showEditNameDialogView(targetItem),
                                    onLongPressToggle: () => setState(() {
                                      isEditMode = !isEditMode;
                                      selectedItems.clear();
                                    }),
                                    onCheckStatusChanged:
                                        handleCheckStatusChanged,
                                    onTapToggleStatus:
                                        handleTapToggleStatusView,
                                    onAddChild: (targetItem) =>
                                        addChildSubMateriDialogView(targetItem),
                                    onDeleteItem: (targetItem) =>
                                        deleteSingleSubMateriView(targetItem),
                                    onToggleItemType: handleToggleItemTypeView,
                                    onUpdateProgressValue:
                                        showUpdateProgressValueDialogView,
                                    onToggleDisable: handleToggleDisableItem,
                                    onToggleExpansion: toggleItemExpansion,
                                    resolveExternalAccumulationText:
                                        _resolveExternalAccumulationText,
                                  );
                                },
                              ),
                          ],
                        ))),
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
                          : () => showMoveSelectedItemsDialogView(allFlattened),
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
                            bool confirm = await showConfirmDialogView(
                              title: 'Hapus Masal',
                              content: 'Hapus seluruh item terpilih?',
                            );
                            if (confirm) {
                              setState(() {
                                for (var i in selectedItems) {
                                  deleteItemFromTree(
                                    widget.subject.subMateri,
                                    i,
                                  );
                                }
                                selectedItems.clear();
                              });
                              updateSubjectOverallProgress();
                              widget.onDataChanged();
                            }
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
                      bool confirm = await showConfirmDialogView(
                        title: 'Reset Progress',
                        content:
                            'Reset semua progress menjadi Belum Selesai? (List nonaktif akan diabaikan)',
                      );
                      if (confirm) resetProgressData(false);
                    },
                    onLongPress: () async {
                      bool confirm = await showConfirmDialogView(
                        title: 'Reset Total Checklist',
                        content:
                            'Apakah Anda yakin ingin mereset seluruh progress DAN mengaktifkan kembali semua list yang dinonaktifkan (tanda silang)?',
                      );
                      if (confirm) {
                        resetProgressData(true);
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

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // TOMBOL PINDAH HALAMAN: Hanya dirender apabila total halaman > 1
                  if (widget.subject.type == 'note' &&
                      notePages.length > 1) ...[
                    IconButton(
                      icon: Icon(
                        Icons.chevron_left,
                        color: Color(widget.subject.backgroundColor),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: currentNotePage > 0
                          ? () => switchNotePage(currentNotePage - 1)
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: Text(
                        '${currentNotePage + 1} / ${notePages.length}',
                        style: TextStyle(
                          color: Color(widget.subject.backgroundColor),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.chevron_right,
                        color: Color(widget.subject.backgroundColor),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: currentNotePage < notePages.length - 1
                          ? () => switchNotePage(currentNotePage + 1)
                          : null,
                    ),
                    const SizedBox(width: 10),
                  ],
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
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// lib/features/daily/presentation/widgets/checklist_detail/checklist_dialog/checklist_dialog_controller.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/daily_model.dart';
import '../widgets/checklist_detail/checklist_dialog.dart';
import '../widgets/checklist_detail/checklist_dialog/change_color_dialog.dart';
import '../../../../core/services/storage_service.dart';

abstract class ChecklistDialogController extends State<DailyChecklistDialog> {
  final TextEditingController singleInputController = TextEditingController();
  late TextEditingController noteController;

  bool isEditMode = false;
  bool showControlPanel = false;
  bool hideFinishedItems = false;

  final List<SubSubjectItem> selectedItems = [];
  final List<List<SubSubjectItem>> undoStack = [];
  final List<List<SubSubjectItem>> redoStack = [];

  SubSubjectItem? highlightedItem;
  bool isNoteModified = false;
  bool isMarkdownEnabled = false;
  bool isNoteViewMode = true;

  bool get isNoteModifiedExternal => isNoteModified;
  void saveManualNoteExternal() => saveManualNote();

  @override
  void initState() {
    super.initState();
    noteController = TextEditingController(
      text: widget.subject.noteContent ?? '',
    );
    isMarkdownEnabled = widget.subject.isMarkdownEnabled;
    isNoteViewMode = noteController.text.isNotEmpty;
  }

  @override
  void dispose() {
    singleInputController.dispose();
    noteController.dispose();
    super.dispose();
  }

  void saveToHistory() {
    final List<SubSubjectItem> currentSnapshot = widget.subject.subMateri
        .map((item) => item.clone())
        .toList();
    undoStack.add(currentSnapshot);
    redoStack.clear();
  }

  void executeUndo() {
    if (undoStack.isEmpty) return;
    setState(() {
      final List<SubSubjectItem> currentSnapshot = widget.subject.subMateri
          .map((item) => item.clone())
          .toList();
      redoStack.add(currentSnapshot);
      widget.subject.subMateri = undoStack.removeLast();
      updateSubjectOverallProgress();
    });
    widget.onDataChanged();
  }

  void executeRedo() {
    if (redoStack.isEmpty) return;
    setState(() {
      final List<SubSubjectItem> currentSnapshot = widget.subject.subMateri
          .map((item) => item.clone())
          .toList();
      undoStack.add(currentSnapshot);
      widget.subject.subMateri = redoStack.removeLast();
      updateSubjectOverallProgress();
    });
    widget.onDataChanged();
  }

  void markAllSubMateriAsDone() {
    if (widget.subject.subMateri.isEmpty) return;
    saveToHistory();
    final String formattedDate =
        "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";

    void markDoneRecursive(List<SubSubjectItem> list) {
      for (var item in list) {
        if (item.isDisabled ||
            (item.linkedSubjectName != null &&
                item.linkedSubjectName!.isNotEmpty)) {
          continue;
        }
        item.progress = 'selesai';
        item.finishedDate = formattedDate;
        if (item.subMateri.isNotEmpty) markDoneRecursive(item.subMateri);
      }
    }

    setState(() => markDoneRecursive(widget.subject.subMateri));
    updateSubjectOverallProgress();
    widget.onDataChanged();
  }

  // =========================================================================
  // FITUR REKURSIF BARU: Mengubah Status Parent Sekaligus Semua Anak di Bawahnya
  // =========================================================================
  void handleCheckStatusChanged(SubSubjectItem target, bool? checked) {
    if (target.linkedSubjectName != null &&
        target.linkedSubjectName!.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '⚠️ Item ini otomatis tercentang hanya jika Card "${target.linkedSubjectName}" selesai semua.',
          ),
          backgroundColor: Colors.amber[800],
        ),
      );
      return;
    }
    saveToHistory();
    setState(() {
      final String todayStr =
          "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";

      bool isDone = checked == true;

      // Fungsi internal untuk melakukan loop menurun ke setiap anak subMateri
      void toggleRecursive(SubSubjectItem item) {
        if (item.isDisabled) return;

        if (item.itemType == 'progress') {
          if (isDone) {
            item.currentValue = item.targetValue;
            item.progress = 'selesai';
            item.finishedDate = todayStr;
          } else {
            item.currentValue = 0;
            item.progress = 'belum';
            item.finishedDate = null;
          }
        } else {
          item.progress = isDone ? 'selesai' : 'belum';
          item.finishedDate = isDone ? todayStr : null;
        }

        for (var child in item.subMateri) {
          toggleRecursive(child);
        }
      }

      toggleRecursive(target);

      for (var r in widget.subject.subMateri) {
        r.updateStatusFromChildren();
      }
    });
    updateSubjectOverallProgress();
    widget.onDataChanged();
  }

  void handleTapToggleStatus(SubSubjectItem target) {
    if (target.linkedSubjectName != null &&
        target.linkedSubjectName!.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '⚠️ Item ini dikunci oleh penyelesaian Card "${target.linkedSubjectName}"',
          ),
          backgroundColor: Colors.amber[800],
        ),
      );
      return;
    }
    if (target.itemType == 'progress') {
      showUpdateProgressValueDialog(target);
      return;
    }
    saveToHistory();
    setState(() {
      final String todayStr =
          "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";

      // Ambil kebalikan status dari status parent saat ini
      bool isDone = target.progress != 'selesai';

      void toggleRecursive(SubSubjectItem item) {
        if (item.isDisabled) return;

        if (item.itemType == 'progress') {
          if (isDone) {
            item.currentValue = item.targetValue;
            item.progress = 'selesai';
            item.finishedDate = todayStr;
          } else {
            item.currentValue = 0;
            item.progress = 'belum';
            item.finishedDate = null;
          }
        } else {
          item.progress = isDone ? 'selesai' : 'belum';
          item.finishedDate = isDone ? todayStr : null;
        }

        for (var child in item.subMateri) {
          toggleRecursive(child);
        }
      }

      toggleRecursive(target);

      for (var r in widget.subject.subMateri) {
        r.updateStatusFromChildren();
      }
    });
    updateSubjectOverallProgress();
    widget.onDataChanged();
  }

  void addRootSubMateri() {
    final text = singleInputController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      widget.subject.subMateri.add(
        SubSubjectItem(subjectName: text, progress: 'belum'),
      );
      singleInputController.clear();
    });
    updateSubjectOverallProgress();
    widget.onDataChanged();
  }

  void addChildSubMateri(SubSubjectItem parentItem) {
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
                setState(
                  () => parentItem.subMateri.add(
                    SubSubjectItem(subjectName: text, progress: 'belum'),
                  ),
                );
                updateSubjectOverallProgress();
                widget.onDataChanged();
              }
              Navigator.pop(context);
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  bool deleteItemFromTree(
    List<SubSubjectItem> treeList,
    SubSubjectItem target,
  ) {
    if (treeList.contains(target)) {
      treeList.remove(target);
      return true;
    }
    for (var item in treeList) {
      if (deleteItemFromTree(item.subMateri, target)) return true;
    }
    return false;
  }

  void deleteSingleSubMateri(SubSubjectItem item) async {
    final confirm = await showConfirmDialog(
      title: 'Hapus Sub-Materi',
      content:
          'Apakah Anda yakin ingin menghapus "${item.subjectName}" beserta seluruh turunannya?',
    );
    if (!confirm) return;
    setState(() {
      deleteItemFromTree(widget.subject.subMateri, item);
      selectedItems.remove(item);
    });
    updateSubjectOverallProgress();
    widget.onDataChanged();
  }

  void showEditNameDialog(SubSubjectItem item) {
    final editController = TextEditingController(text: item.subjectName);
    ChecklistGroup? selectedGroupTarget;
    List<DailySubject> filteredCardTargets = [];
    String? localLinkedTarget = item.linkedSubjectName;

    if (localLinkedTarget != null && localLinkedTarget.isNotEmpty) {
      for (var group in widget.allAvailableGroups ?? <ChecklistGroup>[]) {
        for (var section in group.allList) {
          bool isFound = section.items.any(
            (sub) => sub.subjectName == localLinkedTarget,
          );
          if (isFound) {
            selectedGroupTarget = group;
            for (var sec in group.allList) {
              filteredCardTargets.addAll(sec.items);
            }
            break;
          }
        }
        if (selectedGroupTarget != null) break;
      }
    }

    final List<ChecklistGroup> validGroupsList =
        (widget.allAvailableGroups ?? <ChecklistGroup>[])
            .where((g) => !g.id.startsWith("CORRUPTED_"))
            .toList();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Ubah Item & Kaitan Card Lintas Grup'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: editController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Sub-Materi',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ChecklistGroup>(
                    value: selectedGroupTarget,
                    decoration: const InputDecoration(
                      labelText: '1. Pilih Kelompok Grup',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.group_work_outlined),
                    ),
                    hint: const Text('Pilih Grup Asal Card (Opsional)'),
                    items: [
                      const DropdownMenuItem<ChecklistGroup>(
                        value: null,
                        child: Text('Tidak Dikaitkan (Bebas Klik)'),
                      ),
                      ...validGroupsList.map(
                        (group) => DropdownMenuItem(
                          value: group,
                          child: Text('${group.icon} ${group.groupName}'),
                        ),
                      ),
                    ],
                    onChanged: (ChecklistGroup? targetGroup) {
                      setDialogState(() {
                        selectedGroupTarget = targetGroup;
                        filteredCardTargets.clear();
                        localLinkedTarget = null;
                        if (targetGroup != null) {
                          for (var section in targetGroup.allList) {
                            filteredCardTargets.addAll(section.items);
                          }
                          filteredCardTargets.removeWhere(
                            (sub) =>
                                sub.subjectName == widget.subject.subjectName,
                          );
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: localLinkedTarget,
                    disabledHint: const Text(
                      'Pilih kelompok grup terlebih dahulu...',
                    ),
                    decoration: InputDecoration(
                      labelText: '2. Pilih Card Prasyarat',
                      border: const OutlineInputBorder(),
                      enabled:
                          selectedGroupTarget != null &&
                          filteredCardTargets.isNotEmpty,
                      prefixIcon: const Icon(Icons.credit_card_rounded),
                    ),
                    hint: Text(
                      filteredCardTargets.isEmpty
                          ? 'Tidak ada card tersedia'
                          : 'Pilih Card Prasyarat',
                    ),
                    items: selectedGroupTarget == null
                        ? null
                        : filteredCardTargets
                              .map(
                                (sub) => DropdownMenuItem<String>(
                                  value: sub.subjectName,
                                  child: Text('Card: ${sub.subjectName}'),
                                ),
                              )
                              .toList(),
                    onChanged: selectedGroupTarget == null
                        ? null
                        : (String? val) =>
                              setDialogState(() => localLinkedTarget = val),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  final newName = editController.text.trim();
                  if (newName.isNotEmpty) {
                    setState(() {
                      item.subjectName = newName;
                      item.linkedSubjectName = selectedGroupTarget == null
                          ? null
                          : localLinkedTarget;
                    });
                    updateSubjectOverallProgress();
                    widget.onDataChanged();
                  }
                  Navigator.pop(context);
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  void showEditSubjectNameDialog() {
    final editController = TextEditingController(
      text: widget.subject.subjectName,
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Judul Checklist'),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(
            labelText: 'Nama Judul Baru',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = editController.text.trim();
              if (newName.isNotEmpty) {
                setState(() => widget.subject.subjectName = newName);
                widget.onDataChanged();
              }
              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void moveItemOrder(SubSubjectItem item, int direction) {
    bool moveItemInTree(
      List<SubSubjectItem> treeList,
      SubSubjectItem target,
      int dir,
    ) {
      if (treeList.contains(target)) {
        int idx = treeList.indexOf(target);
        int newIdx = idx + dir;
        if (newIdx >= 0 && newIdx < treeList.length) {
          final active = treeList.removeAt(idx);
          treeList.insert(newIdx, active);
          return true;
        }
        return false;
      }
      for (var sub in treeList) {
        if (moveItemInTree(sub.subMateri, target, dir)) return true;
      }
      return false;
    }

    setState(() {
      moveItemInTree(widget.subject.subMateri, item, direction);
      highlightedItem = item;
    });
    widget.onDataChanged();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && highlightedItem == item) {
        setState(() => highlightedItem = null);
      }
    });
  }

  void pasteFromClipboard() async {
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

    bool? konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Paste Banyak List'),
        content: Text(
          'Apakah Anda yakin ingin menambahkan ${lines.length} item baru dari clipboard?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Tambahkan'),
          ),
        ],
      ),
    );
    if (konfirmasi != true) return;

    setState(() {
      for (var line in lines) {
        widget.subject.subMateri.add(
          SubSubjectItem(subjectName: line.trim(), progress: 'belum'),
        );
      }
    });
    updateSubjectOverallProgress();
    widget.onDataChanged();
  }

  Future<void> selectSubjectDate(bool isEndDate) async {
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

  void saveManualNote() {
    setState(() {
      widget.subject.noteContent = noteController.text;
      widget.subject.isMarkdownEnabled = isMarkdownEnabled;
      isNoteModified = false;
      isNoteViewMode = true;
    });
    widget.onDataChanged();
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📝 Catatan disimpan!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void validateAndSetLinkedProgress(List<SubSubjectItem> list) {
    for (var item in list) {
      if (item.linkedSubjectName != null &&
          item.linkedSubjectName!.isNotEmpty) {
        DailySubject targetSubject = DailySubject(
          subjectName: '',
          progress: 'belum',
          subMateri: [],
        );
        if (widget.allAvailableGroups != null) {
          for (var group in widget.allAvailableGroups!) {
            for (var section in group.allList) {
              final found = section.items.firstWhere(
                (sub) => sub.subjectName == item.linkedSubjectName,
                orElse: () => DailySubject(
                  subjectName: '',
                  progress: 'belum',
                  subMateri: [],
                ),
              );
              if (found.subjectName.isNotEmpty) {
                targetSubject = found;
                break;
              }
            }
            if (targetSubject.subjectName.isNotEmpty) break;
          }
        }

        if (targetSubject.subjectName.isEmpty) {
          targetSubject = widget.allAvailableSubjects.firstWhere(
            (sub) => sub.subjectName == item.linkedSubjectName,
            orElse: () =>
                DailySubject(subjectName: '', progress: 'belum', subMateri: []),
          );
        }

        if (targetSubject.subjectName.isNotEmpty) {
          if (targetSubject.progress == 'selesai') {
            item.progress = 'selesai';
            if (item.finishedDate == null) {
              item.finishedDate =
                  "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
            }
          } else {
            item.progress = 'belum';
            item.finishedDate = null;
          }
        }
      }
      if (item.subMateri.isNotEmpty) {
        validateAndSetLinkedProgress(item.subMateri);
      }
    }
  }

  void updateSubjectOverallProgress() {
    validateAndSetLinkedProgress(widget.subject.subMateri);

    double countTotal(List<SubSubjectItem> list) {
      double total = 0;
      for (var i in list) {
        if (i.isDisabled) continue;
        total += i.subMateri.isNotEmpty ? countTotal(i.subMateri) : 1.0;
      }
      return total;
    }

    double countFinished(List<SubSubjectItem> list) {
      double fin = 0;
      for (var i in list) {
        if (i.isDisabled) continue;
        if (i.subMateri.isNotEmpty) {
          fin += countFinished(i.subMateri);
        } else if (i.progress == 'selesai') {
          fin += 1.0;
        }
      }
      return fin;
    }

    double total = countTotal(widget.subject.subMateri);
    double selesai = countFinished(widget.subject.subMateri);

    if (total == 0) {
      widget.subject.progress = 'belum';
    } else if (selesai == total) {
      widget.subject.progress = 'selesai';
    } else if (selesai > 0) {
      widget.subject.progress = 'sementara';
    } else {
      widget.subject.progress = 'belum';
    }

    if (widget.allAvailableGroups != null && widget.baseDir != null) {
      final storageService = StorageService();
      final String todayStr =
          "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";

      for (var group in widget.allAvailableGroups!) {
        bool groupChanged = false;

        for (var section in group.allList) {
          for (var sub in section.items) {
            void updateLinkedItemsRecursive(List<SubSubjectItem> items) {
              for (var item in items) {
                if (item.linkedSubjectName == widget.subject.subjectName) {
                  if (widget.subject.progress == 'selesai') {
                    if (item.progress != 'selesai') {
                      item.progress = 'selesai';
                      item.finishedDate = todayStr;
                      groupChanged = true;
                    }
                  } else {
                    if (item.progress == 'selesai') {
                      item.progress = 'belum';
                      item.finishedDate = null;
                      groupChanged = true;
                    }
                  }
                }
                if (item.subMateri.isNotEmpty) {
                  updateLinkedItemsRecursive(item.subMateri);
                }
              }
            }

            updateLinkedItemsRecursive(sub.subMateri);

            if (groupChanged) {
              for (var root in sub.subMateri) {
                root.updateStatusFromChildren();
              }
              double subTotal = countTotal(sub.subMateri);
              double subSelesai = countFinished(sub.subMateri);

              if (subTotal == 0) {
                sub.progress = 'belum';
              } else if (subSelesai == subTotal) {
                sub.progress = 'selesai';
              } else if (subSelesai > 0) {
                sub.progress = 'sementara';
              } else {
                sub.progress = 'belum';
              }
            }
          }
        }

        if (groupChanged) {
          try {
            final String jsonString = const JsonEncoder.withIndent(
              '  ',
            ).convert(group.toJson());
            storageService.getSpecificGroupFile(widget.baseDir!, group.id).then(
              (file) {
                storageService.saveJsonData(file, jsonString);
              },
            );
          } catch (e) {
            debugPrint("Gagal mensinkronisasikan berkas grup eksternal: $e");
          }
        }
      }
    }
  }

  void handleToggleDisableItem(SubSubjectItem item) {
    saveToHistory();
    setState(() {
      item.isDisabled = !item.isDisabled;
      if (item.isDisabled) {
        item.progress = 'belum';
        item.currentValue = 0;
        item.finishedDate = null;
      }
      for (var r in widget.subject.subMateri) {
        r.updateStatusFromChildren();
      }
    });
    updateSubjectOverallProgress();
    widget.onDataChanged();
  }

  void getAllItemsFlattened(
    List<SubSubjectItem> source,
    List<SubSubjectItem> destination,
  ) {
    for (var element in source) {
      destination.add(element);
      if (element.subMateri.isNotEmpty) {
        getAllItemsFlattened(element.subMateri, destination);
      }
    }
  }

  Future<bool> showConfirmDialog({
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

  void showMoveSelectedItemsDialog(List<SubSubjectItem> allFlattened) {
    List<SubSubjectItem> validTargets = allFlattened.where((item) {
      if (selectedItems.contains(item)) return false;
      return !selectedItems.any((selected) {
        bool isDescendant(SubSubjectItem parent, SubSubjectItem target) {
          if (parent.subMateri.contains(target)) return true;
          for (var child in parent.subMateri) {
            if (isDescendant(child, target)) return true;
          }
          return false;
        }

        return isDescendant(selected, item);
      });
    }).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pindahkan Item Terpilih ke...'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Pindah Posisi (Internal List Saat Ini):',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                      fontSize: 13,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.label_important,
                    color: Colors.indigo,
                  ),
                  title: const Text(
                    'Daftar Utama (Root List)',
                    style: TextStyle(fontSize: 14),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    moveSelectedItemsToTarget(targetParent: null);
                  },
                ),
                ...validTargets.map(
                  (target) => ListTile(
                    leading: const Icon(
                      Icons.subdirectory_arrow_right,
                      color: Colors.teal,
                      size: 20,
                    ),
                    title: Text(
                      target.subjectName,
                      style: const TextStyle(fontSize: 14),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      moveSelectedItemsToTarget(targetParent: target);
                    },
                  ),
                ),
                const Divider(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Pindahkan ke Kotak List Lain:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                      fontSize: 13,
                    ),
                  ),
                ),
                ...widget.allAvailableSubjects
                    .where((sub) => sub != widget.subject)
                    .map(
                      (targetSubject) => ListTile(
                        leading: Text(
                          targetSubject.icon,
                          style: const TextStyle(fontSize: 18),
                        ),
                        title: Text(
                          targetSubject.subjectName,
                          style: const TextStyle(fontSize: 14),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Colors.grey,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          moveSelectedItemsToOtherSubject(targetSubject);
                        },
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void moveSelectedItemsToOtherSubject(DailySubject targetSubject) {
    saveToHistory();
    setState(() {
      for (var item in selectedItems) {
        deleteItemFromTree(widget.subject.subMateri, item);
      }
      targetSubject.subMateri.addAll(selectedItems);
      selectedItems.clear();
      isEditMode = false;
    });

    for (var root in widget.subject.subMateri) {
      root.updateStatusFromChildren();
    }
    updateSubjectOverallProgress();

    double countTotal(List<SubSubjectItem> list) {
      double total = 0;
      for (var i in list) {
        total += i.subMateri.isNotEmpty ? countTotal(i.subMateri) : 1.0;
      }
      return total;
    }

    double countFinished(List<SubSubjectItem> list) {
      double fin = 0;
      for (var i in list) {
        fin += i.subMateri.isNotEmpty
            ? countFinished(i.subMateri)
            : (i.progress == 'selesai' ? 1.0 : 0.0);
      }
      return fin;
    }

    double t = countTotal(targetSubject.subMateri);
    double s = countFinished(targetSubject.subMateri);
    targetSubject.progress = t == 0
        ? 'belum'
        : (s == t ? 'selesai' : (s > 0 ? 'sementara' : 'belum'));

    widget.onDataChanged();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Berhasil memindahkan item ke kotak "${targetSubject.subjectName}"',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void moveSelectedItemsToTarget({SubSubjectItem? targetParent}) {
    saveToHistory();
    setState(() {
      for (var item in selectedItems) {
        deleteItemFromTree(widget.subject.subMateri, item);
      }
      if (targetParent == null) {
        widget.subject.subMateri.addAll(selectedItems);
      } else {
        targetParent.subMateri.addAll(selectedItems);
      }
      selectedItems.clear();
      isEditMode = false;
    });
    for (var root in widget.subject.subMateri) {
      root.updateStatusFromChildren();
    }
    updateSubjectOverallProgress();
    widget.onDataChanged();
  }

  void handleToggleItemType(SubSubjectItem item) {
    if (item.itemType == 'normal') {
      final targetController = TextEditingController();
      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Set Target Angka Progres',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: TextField(
                controller: targetController,
                keyboardType: TextInputType.number,
                autofocus: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Target Nil Value (Misal: 10, 1.000, 1.000.000)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  if (val.isEmpty) return;
                  String cleanText = val.replaceAll('.', '');
                  String formattedText = cleanText.replaceAllMapped(
                    RegExp(r'\B(?=(\d{3})+(?!\d))'),
                    (match) => '.',
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
                      setState(() {
                        item.itemType = 'progress';
                        item.targetValue = target;
                        item.currentValue = 0;
                        item.progress = 'belum';
                      });
                      for (var r in widget.subject.subMateri) {
                        r.updateStatusFromChildren();
                      }
                      updateSubjectOverallProgress();
                      widget.onDataChanged();
                      Navigator.pop(context);
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
            );
          },
        ),
      );
    } else {
      setState(() {
        item.itemType = 'normal';
        item.targetValue = 0;
        item.currentValue = 0;
        item.progress = 'belum';
      });
      for (var r in widget.subject.subMateri) {
        r.updateStatusFromChildren();
      }
      updateSubjectOverallProgress();
      widget.onDataChanged();
    }
  }

  void showUpdateProgressValueDialog(SubSubjectItem item) {
    final valueController = TextEditingController();
    String formatDialogNum(int num) => num.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Input Angka Progres untuk "${item.subjectName}"',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progres saat ini: ${formatDialogNum(item.currentValue)} / ${formatDialogNum(item.targetValue)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: valueController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Jumlah Angka Tambahan (Misal: 1.000)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    if (val.isEmpty) return;
                    String cleanText = val.replaceAll('.', '');
                    String formattedText = cleanText.replaceAllMapped(
                      RegExp(r'\B(?=(\d{3})+(?!\d))'),
                      (match) => '.',
                    );
                    valueController.value = TextEditingValue(
                      text: formattedText,
                      selection: TextSelection.collapsed(
                        offset: formattedText.length,
                      ),
                    );
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final String rawText = valueController.text
                      .replaceAll('.', '')
                      .trim();
                  final int? addValue = int.tryParse(rawText);
                  if (addValue != null && addValue > 0) {
                    saveToHistory();
                    setState(() {
                      item.currentValue = item.currentValue + addValue;
                      if (item.currentValue >= item.targetValue) {
                        item.progress = 'selesai';
                        item.finishedDate =
                            "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
                      } else {
                        item.progress = 'belum';
                        item.finishedDate = null;
                      }
                      for (var r in widget.subject.subMateri) {
                        r.updateStatusFromChildren();
                      }
                    });
                    updateSubjectOverallProgress();
                    widget.onDataChanged();
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: const Text(
                  'Tambah',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

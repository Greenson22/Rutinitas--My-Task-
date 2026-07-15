// lib/features/daily/presentation/widgets/checklist_detail/checklist_dialog/checklist_dialog_controller.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:rutinitasku/core/utils/atomic_write_helper.dart'; // <--- IMPORT BARU UNTUK ATOMIC WRITE
import '../../../data/models/daily_model.dart';
import '../widgets/checklist_dialog.dart';
import '../../../../../core/services/storage_service.dart';

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

  // =========================================================================
  // STATE BARU: MANAJEMEN PAGING HALAMAN CATATAN
  // =========================================================================
  int currentNotePage = 0;
  List<String> notePages = [];

  bool get isNoteModifiedExternal => isNoteModified;
  void saveManualNoteExternal() => saveManualNote();

  @override
  void initState() {
    super.initState();

    // Inisialisasi daftar halaman catatan dinamis
    if (widget.subject.notePages != null &&
        widget.subject.notePages!.isNotEmpty) {
      notePages = List<String>.from(widget.subject.notePages!);
    } else {
      // Fail-safe migrasi dari skema catatan satu halaman versi lama
      notePages = [widget.subject.noteContent ?? ''];
    }

    // Mengunci posisi halaman aktif dari objek manifes
    currentNotePage = widget.subject.currentNotePage ?? 0;
    if (currentNotePage >= notePages.length || currentNotePage < 0) {
      currentNotePage = 0;
    }

    noteController = TextEditingController(text: notePages[currentNotePage]);

    isMarkdownEnabled = widget.subject.isMarkdownEnabled;
    isNoteViewMode = noteController.text.isNotEmpty;

    _applyDefaultExpansion(
      widget.subject.subMateri,
      widget.subject.defaultExpanded,
    );
  }

  @override
  void dispose() {
    singleInputController.dispose();
    noteController.dispose();
    super.dispose();
  }

  // =========================================================================
  // LOGIKA MANAJEMEN HALAMAN CATATAN (NEW PAGE METHODS)
  // =========================================================================

  void addNewNotePage() {
    // Jalankan komit penyimpanan otomatis jika halaman aktif saat ini sedang diubah
    if (isNoteModified) {
      notePages[currentNotePage] = noteController.text;
    }

    setState(() {
      notePages.add(''); // Alokasikan halaman string kosong baru
      currentNotePage = notePages.length - 1;
      noteController.text = notePages[currentNotePage];
      isNoteViewMode = false; // Langsung arahkan fokus ke mode Edit
      isNoteModified = true;
    });

    _syncNoteDataToModel();
  }

  void switchNotePage(int newIndex) {
    if (newIndex < 0 || newIndex >= notePages.length) return;

    // Komit perubahan teks sebelum melompat ke indeks halaman lain
    if (isNoteModified) {
      notePages[currentNotePage] = noteController.text;
    }

    setState(() {
      currentNotePage = newIndex;
      noteController.text = notePages[currentNotePage];
      isNoteModified = false;
      isNoteViewMode = noteController.text.isNotEmpty;
    });

    _syncNoteDataToModel();
  }

  void deleteCurrentNotePage() {
    if (notePages.length <= 1) {
      // Jika halaman tunggal, bersihkan konten teks ke bentuk dasar
      setState(() {
        notePages[0] = '';
        noteController.text = '';
        isNoteModified = true;
      });
      saveManualNote();
      return;
    }

    setState(() {
      notePages.removeAt(currentNotePage);
      if (currentNotePage >= notePages.length) {
        currentNotePage = notePages.length - 1;
      }
      noteController.text = notePages[currentNotePage];
      isNoteModified = true;
    });

    saveManualNote();
  }

  void _syncNoteDataToModel() {
    widget.subject.notePages = notePages;
    widget.subject.currentNotePage = currentNotePage;
    // Fallback sinkronisasi properti string tunggal versi lama agar card layout terluar tidak crash
    widget.subject.noteContent = notePages.isNotEmpty ? notePages[0] : '';
    widget.onDataChanged();
  }

  // =========================================================================
  // LOGIKA PENGATURAN STATE & TREE FOLDING
  // =========================================================================

  void _applyDefaultExpansion(List<SubSubjectItem> items, bool expand) {
    for (var item in items) {
      item.isExpanded = expand;
      if (item.subMateri.isNotEmpty) {
        _applyDefaultExpansion(item.subMateri, expand);
      }
    }
  }

  void toggleItemExpansion(SubSubjectItem item) {
    setState(() => item.isExpanded = !item.isExpanded);
  }

  void expandOrCollapseAllMateri(bool expand) {
    setState(() => _applyDefaultExpansion(widget.subject.subMateri, expand));
  }

  void toggleCardDefaultExpandedPreference(bool val) {
    setState(() => widget.subject.defaultExpanded = val);
    widget.onDataChanged();
  }

  // =========================================================================
  // LOGIKA RIWAYAT (UNDO / REDO)
  // =========================================================================

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

  // =========================================================================
  // LOGIKA PERUBAHAN STATUS & PROGRESS
  // =========================================================================

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
        if (item.itemType == 'countdown') {
          item.currentValue = 0;
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

  void resetProgressData(bool totalReset) {
    saveToHistory();
    void resetRecursive(List<SubSubjectItem> list) {
      for (var item in list) {
        if (totalReset) item.isDisabled = false;

        if (!item.isDisabled) {
          item.progress = 'belum';
          item.finishedDate = null;
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
      if (widget.subject.isDateActive && widget.subject.dateType != 'range') {
        final now = DateTime.now();
        widget.subject.date =
            "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      }
    });
    updateSubjectOverallProgress();
    widget.onDataChanged();
  }

  void handleCheckStatusChanged(SubSubjectItem target, bool? checked) {
    saveToHistory();
    setState(() {
      final String todayStr =
          "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
      bool isDone = checked == true;

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
        } else if (item.itemType == 'countdown') {
          if (isDone) {
            item.currentValue = 0;
            item.progress = 'selesai';
            item.finishedDate = todayStr;
          } else {
            item.currentValue = item.targetValue;
            item.progress = 'belum';
            item.finishedDate = null;
          }
        } else {
          item.progress = isDone ? 'selesai' : 'belum';
          item.finishedDate = isDone ? todayStr : null;
        }

        for (var child in item.subMateri) toggleRecursive(child);
      }

      toggleRecursive(target);
      for (var r in widget.subject.subMateri) r.updateStatusFromChildren();
    });
    updateSubjectOverallProgress();
    widget.onDataChanged();
  }

  void handleTapToggleStatusData(SubSubjectItem target) {
    saveToHistory();
    setState(() {
      final String todayStr =
          "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
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
        } else if (item.itemType == 'countdown') {
          if (isDone) {
            item.currentValue = 0;
            item.progress = 'selesai';
            item.finishedDate = todayStr;
          } else {
            item.currentValue = item.targetValue;
            item.progress = 'belum';
            item.finishedDate = null;
          }
        } else {
          item.progress = isDone ? 'selesai' : 'belum';
          item.finishedDate = isDone ? todayStr : null;
        }

        for (var child in item.subMateri) toggleRecursive(child);
      }

      toggleRecursive(target);
      for (var r in widget.subject.subMateri) r.updateStatusFromChildren();
    });
    updateSubjectOverallProgress();
    widget.onDataChanged();
  }

  void updateProgressValueData(
    SubSubjectItem item,
    int addValue,
    bool isCountdown,
  ) {
    saveToHistory();
    setState(() {
      if (isCountdown) {
        item.currentValue = item.currentValue - addValue;
        if (item.currentValue <= 0) {
          item.currentValue = 0;
          item.progress = 'selesai';
          item.finishedDate =
              "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
        } else {
          item.progress = 'belum';
          item.finishedDate = null;
        }
      } else {
        item.currentValue = item.currentValue + addValue;
        if (item.currentValue >= item.targetValue) {
          item.progress = 'selesai';
          item.finishedDate =
              "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
        } else {
          item.progress = 'belum';
          item.finishedDate = null;
        }
      }

      if (item.accumulatorItemName != null &&
          item.accumulatorItemName!.isNotEmpty) {
        List<SubSubjectItem> flattened = [];
        getAllItemsFlattened(widget.subject.subMateri, flattened);
        final accumulatorTarget = flattened.firstWhere(
          (el) => el.subjectName == item.accumulatorItemName,
          orElse: () => SubSubjectItem(subjectName: '', progress: 'belum'),
        );

        if (accumulatorTarget.subjectName.isNotEmpty) {
          if (accumulatorTarget.itemType == 'countdown') {
            accumulatorTarget.currentValue -= addValue;
            if (accumulatorTarget.currentValue <= 0) {
              accumulatorTarget.currentValue = 0;
              accumulatorTarget.progress = 'selesai';
              accumulatorTarget.finishedDate =
                  "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
            } else {
              accumulatorTarget.progress = 'belum';
              accumulatorTarget.finishedDate = null;
            }
          } else {
            accumulatorTarget.currentValue += addValue;
            if (accumulatorTarget.itemType == 'progress' &&
                accumulatorTarget.targetValue > 0) {
              if (accumulatorTarget.currentValue >=
                  accumulatorTarget.targetValue) {
                accumulatorTarget.progress = 'selesai';
                accumulatorTarget.finishedDate =
                    "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
              } else {
                accumulatorTarget.progress = 'belum';
                accumulatorTarget.finishedDate = null;
              }
            }
          }
        }
      }

      if (item.linkedExternalCardName != null &&
          item.linkedExternalItemName != null) {
        final externalCard = widget.allAvailableSubjects.firstWhere(
          (sub) => sub.subjectName == item.linkedExternalCardName,
          orElse: () =>
              DailySubject(subjectName: '', progress: 'belum', subMateri: []),
        );

        if (externalCard.subjectName.isNotEmpty) {
          List<SubSubjectItem> extFlattened = [];
          getAllItemsFlattened(externalCard.subMateri, extFlattened);
          final extItemTarget = extFlattened.firstWhere(
            (el) => el.subjectName == item.linkedExternalItemName,
            orElse: () => SubSubjectItem(subjectName: '', progress: 'belum'),
          );

          if (extItemTarget.subjectName.isNotEmpty) {
            if (extItemTarget.itemType == 'countdown') {
              extItemTarget.currentValue -= addValue;
              if (extItemTarget.currentValue <= 0) {
                extItemTarget.currentValue = 0;
                extItemTarget.progress = 'selesai';
                extItemTarget.finishedDate =
                    "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
              } else {
                extItemTarget.progress = 'belum';
                extItemTarget.finishedDate = null;
              }
            } else {
              extItemTarget.currentValue += addValue;
              if (extItemTarget.itemType == 'progress' &&
                  extItemTarget.targetValue > 0) {
                if (extItemTarget.currentValue >= extItemTarget.targetValue) {
                  extItemTarget.progress = 'selesai';
                  extItemTarget.finishedDate =
                      "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
                } else {
                  extItemTarget.progress = 'belum';
                  extItemTarget.finishedDate = null;
                }
              }
            }
            for (var root in externalCard.subMateri) {
              root.updateStatusFromChildren();
            }
            _forceSaveExternalCardData(externalCard);
          }
        }
      }
      for (var r in widget.subject.subMateri) r.updateStatusFromChildren();
    });
    updateSubjectOverallProgress();
    widget.onDataChanged();
  }

  // =========================================================================
  // LOGIKA MUTASI STRUKTUR & DATA ITEM
  // =========================================================================

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

  void addChildSubMateriData(SubSubjectItem parentItem, String text) {
    setState(
      () => parentItem.subMateri.add(
        SubSubjectItem(subjectName: text, progress: 'belum'),
      ),
    );
    updateSubjectOverallProgress();
    widget.onDataChanged();
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

  void deleteSingleSubMateriData(SubSubjectItem item) {
    setState(() {
      deleteItemFromTree(widget.subject.subMateri, item);
      selectedItems.remove(item);
    });
    updateSubjectOverallProgress();
    widget.onDataChanged();
  }

  void pasteFromClipboardData(List<String> lines) {
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

  void updateItemTypeData(
    SubSubjectItem item,
    String targetType,
    int targetValue,
  ) {
    setState(() {
      item.itemType = targetType;
      item.targetValue = targetValue;
      item.currentValue = targetType == 'countdown' ? targetValue : 0;
      item.progress = 'belum';
    });
    for (var r in widget.subject.subMateri) r.updateStatusFromChildren();
    updateSubjectOverallProgress();
    widget.onDataChanged();
  }

  void updateItemNameAndRelationsData({
    required SubSubjectItem item,
    required String newName,
    required String? linkedSubjectName,
    required String? accumulatorItemName,
    required String? linkedExternalCardName,
    required String? linkedExternalItemName,
    required int parsedCurrent,
    required int parsedTarget,
    required DailySubject? selectedExternalCard,
  }) {
    saveToHistory();
    setState(() {
      item.subjectName = newName;
      item.linkedSubjectName = linkedSubjectName;
      item.accumulatorItemName = accumulatorItemName;
      item.linkedExternalCardName = linkedExternalCardName;
      item.linkedExternalItemName = linkedExternalItemName;

      if (item.itemType == 'progress' || item.itemType == 'countdown') {
        item.currentValue = parsedCurrent;
        item.targetValue = parsedTarget > 0 ? parsedTarget : 1;

        if (item.itemType == 'countdown') {
          if (item.currentValue <= 0) {
            item.currentValue = 0;
            item.progress = 'selesai';
            if (item.finishedDate == null) {
              item.finishedDate =
                  "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
            }
          } else {
            item.progress = 'belum';
            item.finishedDate = null;
          }
        } else {
          if (item.currentValue >= item.targetValue) {
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
    });
    updateSubjectOverallProgress();
    widget.onDataChanged();
    if (selectedExternalCard != null && linkedExternalItemName != null) {
      _forceSaveExternalCardData(selectedExternalCard);
    }
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
    if (mounted && highlightedItem == item) {
      setState(() => highlightedItem = null);
    }
  }

  void moveSelectedItemsToOtherSubject(DailySubject targetSubject) {
    saveToHistory();
    setState(() {
      // 1. Hapus semua item yang dipilih dari tree asal terlebih dahulu
      for (var item in selectedItems) {
        deleteItemFromTree(widget.subject.subMateri, item);
      }

      // 2. Saring item terpilih agar item yang merupakan "anak" dari item terpilih lainnya tidak di-insert ulang
      final topLevelItemsToMove = selectedItems.where((item) {
        bool hasParentInSelection(
          List<SubSubjectItem> checklist,
          SubSubjectItem target,
        ) {
          for (var element in checklist) {
            if (element.subMateri.contains(target)) return true;
            if (hasParentInSelection(element.subMateri, target)) return true;
          }
          return false;
        }

        // Jika parent dari item ini juga ada di dalam selectedItems, jangan masukkan lagi
        return !hasParentInSelection(selectedItems, item);
      }).toList();

      // 3. Masukkan hanya top-level items yang disaring ke target baru
      targetSubject.subMateri.addAll(topLevelItemsToMove);
      selectedItems.clear();
      isEditMode = false;
    });

    // Logika kalkulasi progress di bawah tetap sama...
    for (var root in widget.subject.subMateri) root.updateStatusFromChildren();
    updateSubjectOverallProgress();

    double countTotal(List<SubSubjectItem> list) {
      double total = 0;
      for (var i in list)
        total += i.subMateri.isNotEmpty ? countTotal(i.subMateri) : 1.0;
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
  }

  void moveSelectedItemsToTarget({SubSubjectItem? targetParent}) {
    saveToHistory();
    setState(() {
      // 1. Hapus semua dari tree asal
      for (var item in selectedItems) {
        deleteItemFromTree(widget.subject.subMateri, item);
      }

      // 2. Saring hanya top-level items dari list yang dipilih
      final topLevelItemsToMove = selectedItems.where((item) {
        bool hasParentInSelection(
          List<SubSubjectItem> checklist,
          SubSubjectItem target,
        ) {
          for (var element in checklist) {
            if (element.subMateri.contains(target)) return true;
            if (hasParentInSelection(element.subMateri, target)) return true;
          }
          return false;
        }

        return !hasParentInSelection(selectedItems, item);
      }).toList();

      // 3. Tambahkan ke target parent internal yang dituju
      if (targetParent == null) {
        widget.subject.subMateri.addAll(topLevelItemsToMove);
      } else {
        targetParent.subMateri.addAll(topLevelItemsToMove);
      }
      selectedItems.clear();
      isEditMode = false;
    });

    for (var root in widget.subject.subMateri) root.updateStatusFromChildren();
    updateSubjectOverallProgress();
    widget.onDataChanged();
  }

  void importSubMateriFromJson(String jsonString) {
    saveToHistory();
    final decoded = jsonDecode(jsonString.trim());
    setState(() {
      if (decoded is List) {
        for (var itemJson in decoded) {
          if (itemJson is Map<String, dynamic>) {
            widget.subject.subMateri.add(SubSubjectItem.fromJson(itemJson));
          }
        }
      } else if (decoded is Map<String, dynamic>) {
        widget.subject.subMateri.add(SubSubjectItem.fromJson(decoded));
      } else {
        throw const FormatException(
          'Struktur JSON harus berupa Objek {} atau Array []',
        );
      }
      _applyDefaultExpansion(
        widget.subject.subMateri,
        widget.subject.defaultExpanded,
      );
    });
    updateSubjectOverallProgress();
    widget.onDataChanged();
  }

  void handleToggleDisableItem(SubSubjectItem item) {
    saveToHistory();
    setState(() {
      // Menentukan status target baru (kebalikan dari status induk saat ini)
      final bool targetDisableStatus = !item.isDisabled;

      // Fungsi internal rekursif untuk mengubah status induk beserta seluruh anak bersarangnya
      void toggleDisableRecursive(SubSubjectItem currentItem, bool isDisabled) {
        currentItem.isDisabled = isDisabled;
        if (isDisabled) {
          currentItem.progress = 'belum';
          currentItem.currentValue = currentItem.itemType == 'countdown'
              ? currentItem.targetValue
              : 0;
          currentItem.finishedDate = null;
        }

        // Telusuri struktur pohon subMateri lebih dalam jika ada
        for (var child in currentItem.subMateri) {
          toggleDisableRecursive(child, isDisabled);
        }
      }

      // Jalankan rekursif dari item utama yang dipilih
      toggleDisableRecursive(item, targetDisableStatus);

      // Sinkronisasi status naik kembali ke atas (parent status calculation)
      for (var r in widget.subject.subMateri) r.updateStatusFromChildren();
    });
    updateSubjectOverallProgress();
    widget.onDataChanged();
  }

  void saveManualNote() {
    setState(() {
      notePages[currentNotePage] = noteController.text;
      isNoteModified = false;
      isNoteViewMode = true;
    });
    _syncNoteDataToModel();
  }

  // =========================================================================
  // LOGIKA SISTEM (SINKRONISASI, AKUMULASI, UTILITIES)
  // =========================================================================

  void _forceSaveExternalCardData(DailySubject targetCard) {
    if (widget.allAvailableGroups != null && widget.baseDir != null) {
      final storageService = StorageService();
      for (var group in widget.allAvailableGroups!) {
        bool match = false;
        for (var sec in group.allList) {
          if (sec.items.contains(targetCard)) {
            match = true;
            break;
          }
        }
        if (match) {
          final String jsonString = const JsonEncoder.withIndent(
            '  ',
          ).convert(group.toJson());
          storageService.getSpecificGroupFile(widget.baseDir!, group.id).then((
            file,
          ) async {
            // TERAPKAN ATOMIC WRITE DI SINI[cite: 1, 2]
            await AtomicWriteHelper.writeSafe(
              targetFile: file,
              content: jsonString,
            );
          });
          break;
        }
      }
    }
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
      final String =
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
                      item.finishedDate = String;
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
                if (item.subMateri.isNotEmpty)
                  updateLinkedItemsRecursive(item.subMateri);
              }
            }

            updateLinkedItemsRecursive(sub.subMateri);

            if (groupChanged) {
              for (var root in sub.subMateri) root.updateStatusFromChildren();
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
            final jsonString = const JsonEncoder.withIndent(
              '  ',
            ).convert(group.toJson());
            storageService.getSpecificGroupFile(widget.baseDir!, group.id).then(
              (file) async {
                // TERAPKAN ATOMIC WRITE DI SINI[cite: 1, 2]
                await AtomicWriteHelper.writeSafe(
                  targetFile: file,
                  content: jsonString,
                );
              },
            );
          } catch (e) {
            debugPrint("Gagal mensinkronisasikan berkas grup eksternal: $e");
          }
        }
      }
    }
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
}

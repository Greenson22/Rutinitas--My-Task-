// lib/features/notes/presentation/controllers/note_detail_controller.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rutinitasku/core/services/storage_service.dart';
import 'package:rutinitasku/core/utils/atomic_write_helper.dart';
import 'package:rutinitasku/core/utils/crypto_helper.dart';
import '../../models/note_model.dart';

class NoteDetailController {
  final StorageService _storageService = StorageService();
  late NoteGroup currentGroup;
  List<NoteGroup> childFolders = [];
  final VoidCallback onStateChanged;
  final BuildContext context;

  NoteDetailController({
    required NoteGroup noteGroup,
    required this.onStateChanged,
    required this.context,
  }) {
    currentGroup = noteGroup;
  }

  // === MODIFIKASI: PROTEKSI ANTI-KORUP DATA DENGAN ATOMIC WRITE ===
  Future<void> _saveGroupToFile(NoteGroup group) async {
    try {
      final baseDir = await _storageService.getBaseDirSetting();
      final File targetFile = File('$baseDir/notes/${group.id}.json');
      bool isEncrypted = await _storageService.isEncryptionEnabled();
      String? password = await _storageService.getEncryptionPassword();

      String jsonString = _storageService.formatJsonPretty(group.toJson());

      if (isEncrypted && password != null) {
        jsonString = CryptoHelper.encrypt(jsonString, password);
      }

      await AtomicWriteHelper.writeSafe(
        targetFile: targetFile,
        content: jsonString,
      );
    } catch (e) {
      debugPrint(
        "Gagal menyimpan pembaruan grup (Helper Atomic Write Error): $e",
      );
    }
  }

  Future<void> saveCurrentGroup() async {
    await _saveGroupToFile(currentGroup);
  }

  Future<void> loadChildFolders() async {
    final allGroups = await getAllNoteGroups();
    childFolders = allGroups
        .where((g) => g.parentId == currentGroup.id)
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    onStateChanged();
  }

  Future<void> createSubFolder({
    required String name,
    required String icon,
  }) async {
    final newFolder = NoteGroup(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      groupName: name,
      icon: icon,
      notes: [],
      sectionName: currentGroup.sectionName,
      parentId: currentGroup.id,
      orderIndex: childFolders.length,
    );
    await _saveGroupToFile(newFolder);
    await loadChildFolders();
  }

  Future<void> renameSubFolder(
    NoteGroup folder,
    String newName,
    String newIcon,
  ) async {
    folder.groupName = newName;
    folder.icon = newIcon;
    await _saveGroupToFile(folder);
    await loadChildFolders();
  }

  Future<void> moveSubFolder(NoteGroup folder, String? newParentId) async {
    folder.parentId = newParentId;
    await _saveGroupToFile(folder);
    await loadChildFolders();
  }

  Future<void> deleteSubFolder(NoteGroup folder) async {
    final allGroups = await getAllNoteGroups();
    final Set<String> idsToDelete = {folder.id};
    bool added = true;
    while (added) {
      added = false;
      for (var g in allGroups) {
        if (g.parentId != null &&
            idsToDelete.contains(g.parentId) &&
            !idsToDelete.contains(g.id)) {
          idsToDelete.add(g.id);
          added = true;
        }
      }
    }

    final baseDir = await _storageService.getBaseDirSetting();
    for (var id in idsToDelete) {
      final file = File('$baseDir/notes/$id.json');
      if (await file.exists()) {
        await file.delete();
      }
    }
    await loadChildFolders();
  }

  String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  Future<bool> showConfirmDialog({
    required String title,
    required String content,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                SizedBox(width: 8),
                Text('Konfirmasi Hapus'),
              ],
            ),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Hapus',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void addFieldKey({
    required StateSetter setDialogState,
    required List<String> currentFieldKeys,
    required Map<String, String> currentFieldTypes,
    required Map<String, TextEditingController> formControllers,
    required List<Map<String, TextEditingController>> tableRows,
    required Function() triggerChange,
    required String key,
    required String type,
  }) {
    if (!currentFieldKeys.contains(key)) {
      setDialogState(() {
        currentFieldKeys.add(key);
        currentFieldTypes[key] = type;

        // Menentukan default value awal untuk tipe data Option
        String defaultVal = '';
        if (type == 'Boolean') {
          defaultVal = 'Tidak';
        } else if (type.startsWith('Option:')) {
          String optionsRaw = type.substring(type.indexOf(':') + 1);
          List<String> options = optionsRaw
              .split(',')
              .map((e) => e.trim())
              .toList();
          defaultVal = options.isNotEmpty ? options.first : '';
        }

        formControllers[key] = TextEditingController(text: defaultVal);
        for (var row in tableRows) {
          row[key] = TextEditingController(text: defaultVal);
        }
        triggerChange();
      });
    }
  }

  void removeFieldKey({
    required StateSetter setDialogState,
    required List<String> currentFieldKeys,
    required Map<String, String> currentFieldTypes,
    required Map<String, TextEditingController> formControllers,
    required List<Map<String, TextEditingController>> tableRows,
    required Function() triggerChange,
    required String key,
  }) async {
    final bool confirm = await showConfirmDialog(
      title: 'Hapus Kolom Baru',
      content:
          'Apakah Anda yakin ingin menghapus kolom "$key"? Seluruh data pada kolom ini di semua baris akan ikut terhapus permanen.',
    );
    if (!confirm) return;

    setDialogState(() {
      currentFieldKeys.remove(key);
      currentFieldTypes.remove(key);
      formControllers[key]?.dispose();
      formControllers.remove(key);
      for (var row in tableRows) {
        row[key]?.dispose();
        row.remove(key);
      }
      triggerChange();
    });
  }

  void renameFieldKey({
    required StateSetter setDialogState,
    required List<String> currentFieldKeys,
    required Map<String, String> currentFieldTypes,
    required Map<String, TextEditingController> formControllers,
    required List<Map<String, TextEditingController>> tableRows,
    required Function() triggerChange,
    required String oldKey,
    required String newKey,
  }) {
    if (newKey.isEmpty || oldKey == newKey) return;

    if (currentFieldKeys.contains(newKey)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama kolom sudah digunakan!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setDialogState(() {
      int index = currentFieldKeys.indexOf(oldKey);
      if (index != -1) {
        currentFieldKeys[index] = newKey;
      }
      final String type = currentFieldTypes.remove(oldKey) ?? 'String';
      currentFieldTypes[newKey] = type;
      final TextEditingController? formCtrl = formControllers.remove(oldKey);
      if (formCtrl != null) {
        formControllers[newKey] = formCtrl;
      }
      for (var row in tableRows) {
        final TextEditingController? rowCtrl = row.remove(oldKey);
        if (rowCtrl != null) {
          row.addAll({newKey: rowCtrl});
        }
      }
      triggerChange();
    });
  }

  void updateFieldType({
    required StateSetter setDialogState,
    required Map<String, String> currentFieldTypes,
    required List<Map<String, TextEditingController>> tableRows,
    required Function() triggerChange,
    required String key,
    required String newType,
  }) {
    setDialogState(() {
      currentFieldTypes[key] = newType;
      for (var row in tableRows) {
        if (row[key] != null) {
          String currentText = row[key]!.text.trim();
          if (newType == 'Boolean') {
            if (currentText != 'Ya' && currentText != 'Tidak') {
              row[key]!.text = 'Tidak';
            }
          } else if (newType == 'Numerik') {
            if (double.tryParse(currentText) == null) {
              row[key]!.text = '0';
            }
          }
        }
      }
      triggerChange();
    });
  }

  void sortTable({
    required StateSetter setDialogState,
    required List<Map<String, TextEditingController>> tableRows,
    required Map<String, String> currentFieldTypes,
    required Function() triggerChange,
    required String key,
    required int columnIndex,
    required int? currentSortColumnIndex,
    required bool currentIsAscending,
    required Function(int?, bool) onSortUpdated,
  }) {
    setDialogState(() {
      bool targetAscending = true;
      int? targetColumnIndex = columnIndex;

      if (currentSortColumnIndex == columnIndex) {
        targetAscending = !currentIsAscending;
      } else {
        targetColumnIndex = columnIndex;
        targetAscending = true;
      }
      onSortUpdated(targetColumnIndex, targetAscending);

      String type = currentFieldTypes[key] ?? 'String';
      tableRows.sort((a, b) {
        final valA = a[key]?.text.trim() ?? '';
        final valB = b[key]?.text.trim() ?? '';
        if (type == 'Numerik') {
          final numA = double.tryParse(valA) ?? 0.0;
          final numB = double.tryParse(valB) ?? 0.0;
          return targetAscending ? numA.compareTo(numB) : numB.compareTo(numA);
        }
        return targetAscending
            ? valA.toLowerCase().compareTo(valB.toLowerCase())
            : valB.toLowerCase().compareTo(valA.toLowerCase());
      });
      triggerChange();
    });
  }

  void removeRow({
    required StateSetter setDialogState,
    required List<Map<String, TextEditingController>> tableRows,
    required Function() triggerChange,
    required int index,
  }) async {
    final bool confirm = await showConfirmDialog(
      title: 'Hapus Baris Data',
      content:
          'Apakah Anda yakin ingin menghapus baris data ke-${index + 1} ini secara permanen?',
    );
    if (!confirm) return;

    setDialogState(() {
      final removedRow = tableRows.removeAt(index);
      removedRow.values.forEach((controller) => controller.dispose());
      triggerChange();
    });
  }

  void moveRow({
    required StateSetter setDialogState,
    required List<Map<String, TextEditingController>> tableRows,
    required Function() triggerChange,
    required int currentIndex,
    required bool moveUp,
  }) {
    setDialogState(() {
      if (moveUp && currentIndex > 0) {
        final temp = tableRows[currentIndex];
        tableRows[currentIndex] = tableRows[currentIndex - 1];
        tableRows[currentIndex - 1] = temp;
        triggerChange();
      } else if (!moveUp && currentIndex < tableRows.length - 1) {
        final temp = tableRows[currentIndex];
        tableRows[currentIndex] = tableRows[currentIndex + 1];
        tableRows[currentIndex + 1] = temp;
        triggerChange();
      }
    });
  }

  // === PENAMBAHAN PARAMETER: notePages dan currentNotePage ===
  Future<NoteModel> performSave({
    required NoteModel? existingNote,
    required String originalTitle,
    required String currentType,
    required TextEditingController titleController,
    required TextEditingController contentController,
    required TextEditingController backContentController,
    required List<String> currentFieldKeys,
    required Map<String, String> currentFieldTypes,
    required List<Map<String, TextEditingController>> tableRows,
    bool isMarkdownEnabled = false,
    List<String>? notePages, // <--- BARU
    int? currentNotePage, // <--- BARU
  }) async {
    String finalTitle = titleController.text.trim();
    if (finalTitle.isEmpty) finalTitle = originalTitle;

    List<Map<String, String>> finalTableData = [];
    for (var rowControllers in tableRows) {
      Map<String, String> rowData = {};
      rowControllers.forEach((key, controller) {
        rowData[key] = controller.text.trim();
      });
      finalTableData.add(rowData);
    }

    // Ekstrak teks pratinjau utama untuk parameter content bawaan
    String fallbackContent = '';
    if (notePages != null && notePages.isNotEmpty) {
      fallbackContent = notePages[0];
    } else {
      fallbackContent = contentController.text.trim();
    }

    final newNote = NoteModel(
      id: existingNote?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: finalTitle,
      content: fallbackContent,
      backContent: backContentController.text.trim(),
      createdAt: existingNote?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      type: currentType,
      fieldKeys: currentFieldKeys,
      fieldTypes: currentFieldTypes,
      tableData: finalTableData,
      isMarkdownEnabled: isMarkdownEnabled,
      notePages: notePages,
      currentNotePage: currentNotePage,
    );

    if (existingNote == null) {
      currentGroup.notes.add(newNote);
    } else {
      final index = currentGroup.notes.indexWhere(
        (n) => n.id == existingNote.id,
      );
      if (index != -1) currentGroup.notes[index] = newNote;
    }

    onStateChanged();
    await saveCurrentGroup();
    return newNote;
  }

  void deleteNote(NoteModel note) async {
    currentGroup.notes.removeWhere((n) => n.id == note.id);
    onStateChanged();
    await saveCurrentGroup();
  }

  Future<List<NoteGroup>> getAllNoteGroups() async {
    try {
      final baseDir = await _storageService.getBaseDirSetting();
      final files = await _storageService.getAllNoteGroups(baseDir);
      bool isEncrypted = await _storageService.isEncryptionEnabled();
      String? password = await _storageService.getEncryptionPassword();

      List<NoteGroup> loadedGroups = [];

      for (var file in files) {
        if (!await file.exists()) continue;
        String content = await file.readAsString();
        if (isEncrypted && password != null && content.contains(':')) {
          content = CryptoHelper.decrypt(content, password);
        }
        loadedGroups.add(NoteGroup.fromJson(jsonDecode(content)));
      }

      return loadedGroups;
    } catch (e) {
      debugPrint("Gagal memuat seluruh data daftar grup notes: $e");
      return [];
    }
  }

  Future<void> moveMassiveNotes(
    List<NoteModel> selectedItems,
    NoteGroup targetGroup,
  ) async {
    if (selectedItems.isEmpty || currentGroup.id == targetGroup.id) return;

    final selectedIds = selectedItems.map((e) => e.id).toSet();
    targetGroup.notes.addAll(selectedItems);
    currentGroup.notes.removeWhere((note) => selectedIds.contains(note.id));

    onStateChanged();
    await saveCurrentGroup();

    try {
      final baseDir = await _storageService.getBaseDirSetting();
      final File targetFile = File('$baseDir/notes/${targetGroup.id}.json');
      bool isEncrypted = await _storageService.isEncryptionEnabled();
      String? password = await _storageService.getEncryptionPassword();

      String jsonString = _storageService.formatJsonPretty(
        targetGroup.toJson(),
      );

      if (isEncrypted && password != null) {
        jsonString = CryptoHelper.encrypt(jsonString, password);
      }

      await AtomicWriteHelper.writeSafe(
        targetFile: targetFile,
        content: jsonString,
      );
    } catch (e) {
      debugPrint(
        "Gagal mengamankan penyimpanan grup target saat memindahkan notes: $e",
      );
    }
  }

  Future<void> deleteMassiveNotes(List<NoteModel> selectedItems) async {
    if (selectedItems.isEmpty) return;

    final bool confirm = await showConfirmDialog(
      title: 'Hapus Masal Item Notes',
      content:
          'Apakah Anda yakin ingin menghapus ${selectedItems.length} item notes yang dipilih secara masal? Tindakan ini tidak dapat dibatalkan.',
    );

    if (!confirm) return;

    final selectedIds = selectedItems.map((e) => e.id).toSet();
    currentGroup.notes.removeWhere((note) => selectedIds.contains(note.id));
    onStateChanged();
    await saveCurrentGroup();
  }

  void moveFieldKey({
    required StateSetter setDialogState,
    required List<String> currentFieldKeys,
    required Function() triggerChange,
    required int oldIndex,
    required int newIndex,
  }) {
    setDialogState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final String item = currentFieldKeys.removeAt(oldIndex);
      currentFieldKeys.insert(newIndex, item);
      triggerChange();
    });
  }
}

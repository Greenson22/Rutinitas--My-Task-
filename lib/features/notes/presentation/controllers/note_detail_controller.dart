import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rutinitasku/core/services/storage_service.dart';
import 'package:rutinitasku/core/utils/crypto_helper.dart';
import '../../models/note_model.dart';

class NoteDetailController {
  final StorageService _storageService = StorageService();

  late NoteGroup currentGroup;
  final VoidCallback onStateChanged;
  final BuildContext context;

  NoteDetailController({
    required NoteGroup noteGroup,
    required this.onStateChanged,
    required this.context,
  }) {
    currentGroup = noteGroup;
  }

  Future<void> saveCurrentGroup() async {
    try {
      final baseDir = await _storageService.getBaseDirSetting();
      final jsonString = _storageService.formatJsonPretty(
        currentGroup.toJson(),
      );
      await _storageService.saveNoteGroup(baseDir, currentGroup.id, jsonString);
    } catch (e) {
      debugPrint("Gagal menyimpan pembaruan grup: $e");
    }
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

        String defaultVal = type == 'Boolean' ? 'Tidak' : '';
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

  // BARU: Fungsi untuk mengubah nama kolom dan memigrasikan datanya di setiap baris
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

    // Validasi jika nama kolom baru sudah ada
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
      // 1. Perbarui daftar kunci utama
      int index = currentFieldKeys.indexOf(oldKey);
      if (index != -1) {
        currentFieldKeys[index] = newKey;
      }

      // 2. Migrasikan tipe data map
      final String type = currentFieldTypes.remove(oldKey) ?? 'String';
      currentFieldTypes[newKey] = type;

      // 3. Migrasikan controller form input utama
      final TextEditingController? formCtrl = formControllers.remove(oldKey);
      if (formCtrl != null) {
        formControllers[newKey] = formCtrl;
      }

      // 4. Urus migrasi data pada setiap baris tersimpan
      for (var row in tableRows) {
        final TextEditingController? rowCtrl = row.remove(oldKey);
        if (rowCtrl != null) {
          row.addAll({newKey: rowCtrl});
        }
      }

      triggerChange();
    });
  }

  // BARU: Fungsi untuk mengubah tipe data kolom dan memvalidasi nilai yang sudah ada
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

  // BARU: Fungsi untuk memindahkan posisi baris data tabel (naik atau turun)
  void moveRow({
    required StateSetter setDialogState,
    required List<Map<String, TextEditingController>> tableRows,
    required Function() triggerChange,
    required int currentIndex,
    required bool moveUp,
  }) {
    setDialogState(() {
      if (moveUp && currentIndex > 0) {
        // Tukar ke atas
        final temp = tableRows[currentIndex];
        tableRows[currentIndex] = tableRows[currentIndex - 1];
        tableRows[currentIndex - 1] = temp;
        triggerChange();
      } else if (!moveUp && currentIndex < tableRows.length - 1) {
        // Tukar ke bawah
        final temp = tableRows[currentIndex];
        tableRows[currentIndex] = tableRows[currentIndex + 1];
        tableRows[currentIndex + 1] = temp;
        triggerChange();
      }
    });
  }

  Future<NoteModel> performSave({
    required NoteModel? existingNote,
    required String originalTitle,
    required String currentType,
    required TextEditingController titleController,
    required TextEditingController contentController,
    required TextEditingController
    backContentController, // <--- BARU: Menambahkan parameter controller sisi belakang
    required List<String> currentFieldKeys,
    required Map<String, String> currentFieldTypes,
    required List<Map<String, TextEditingController>> tableRows,
    bool isMarkdownEnabled = false,
  }) async {
    String finalTitle = titleController.text.trim();
    if (finalTitle.isEmpty) finalTitle = originalTitle;

    List<Map<String, String>> finalTableData = [];
    if (currentType == 'table') {
      for (var rowControllers in tableRows) {
        Map<String, String> rowData = {};
        rowControllers.forEach((key, controller) {
          rowData[key] = controller.text.trim();
        });
        finalTableData.add(rowData);
      }
    }

    final newNote = NoteModel(
      id: existingNote?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: finalTitle,
      content: currentType == 'text' ? contentController.text.trim() : '',
      backContent: backContentController.text
          .trim(), // <--- BARU: Menyimpan konten sisi belakang
      createdAt: existingNote?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      type: currentType,
      fieldKeys: currentType == 'table' ? currentFieldKeys : [],
      fieldTypes: currentType == 'table' ? currentFieldTypes : {},
      tableData: currentType == 'table' ? finalTableData : [],
      isMarkdownEnabled: isMarkdownEnabled,
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

  // =========================================================================
  // FITUR BARU: AMBIL SELURUH DATA GRUP NOTE DARI STORAGE SERVICE (Mendukung Dekripsi)
  // =========================================================================
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

  // =========================================================================
  // FITUR BARU: MANAJEMEN PEMINDAHAN MASSAL (BULK MOVE NOTES)
  // =========================================================================
  Future<void> moveMassiveNotes(
    List<NoteModel> selectedItems,
    NoteGroup targetGroup,
  ) async {
    if (selectedItems.isEmpty || currentGroup.id == targetGroup.id) return;

    // 1. Dapatkan sekumpulan ID unik item terpilih untuk mempercepat proses penyaringan
    final selectedIds = selectedItems.map((e) => e.id).toSet();

    // 2. Tambahkan semua item catatan terpilih ke list milik grup tujuan
    targetGroup.notes.addAll(selectedItems);

    // 3. Keluarkan item-item catatan terpilih dari list milik grup asal saat ini
    currentGroup.notes.removeWhere((note) => selectedIds.contains(note.id));

    // 4. Picu pembaruan state pada UI lokal layar detail asal
    onStateChanged();

    // 5. Tulis perubahan struktur data grup asal (currentGroup) ke penyimpanan lokal
    await saveCurrentGroup();

    // 6. Tulis perubahan struktur data grup target ke penyimpanan lokal secara persisten
    try {
      final baseDir = await _storageService.getBaseDirSetting();
      final jsonString = _storageService.formatJsonPretty(targetGroup.toJson());
      await _storageService.saveNoteGroup(baseDir, targetGroup.id, jsonString);
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

    // PERBAIKAN: Gunakan pembandingan ID agar dipastikan item dengan ID yang sama terhapus
    // Kita buat daftar ID dari item yang dipilih terlebih dahulu agar proses filter lebih cepat
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
      // Penyesuaian indeks bawaan dari ReorderableListView
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final String item = currentFieldKeys.removeAt(oldIndex);
      currentFieldKeys.insert(newIndex, item);
      triggerChange();
    });
  }
}

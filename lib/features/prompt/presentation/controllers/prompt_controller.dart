// lib/features/prompt/presentation/controllers/prompt_controller.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:rutinitasku/core/services/storage_service.dart';
import '../../data/models/prompt_model.dart';

class PromptController extends ChangeNotifier {
  final StorageService _storageService = StorageService();

  List<PromptGroup> _promptGroups = [];
  bool _isLoading = true;
  bool _isSectionEditMode = false;
  bool _isCardEditMode = false;
  final List<String> _localEmptySections = [];

  // State tambahan untuk Fitur Multi-Select Prompt Item
  final Set<String> _selectedPromptIds = {};

  // Getters
  List<PromptGroup> get promptGroups => _promptGroups;
  bool get isLoading => _isLoading;
  bool get isSectionEditMode => _isSectionEditMode;
  bool get isCardEditMode => _isCardEditMode;
  List<String> get localEmptySections => _localEmptySections;

  // Getter Multi-Select
  bool get isMultiSelectMode => _selectedPromptIds.isNotEmpty;
  Set<String> get selectedPromptIds => _selectedPromptIds;

  // Setters / Toggles
  void toggleSectionEditMode() {
    _isSectionEditMode = !_isSectionEditMode;
    notifyListeners();
  }

  void toggleCardEditMode() {
    _isCardEditMode = !_isCardEditMode;
    notifyListeners();
  }

  // Fungsi Interaksi Multi-Select
  void toggleSelectPromptItem(String itemId) {
    if (_selectedPromptIds.contains(itemId)) {
      _selectedPromptIds.remove(itemId);
    } else {
      _selectedPromptIds.add(itemId);
    }
    notifyListeners();
  }

  void clearSelectedPrompts() {
    _selectedPromptIds.clear();
    notifyListeners();
  }

  // Memuat data dari storage
  Future<void> loadAllPrompts(BuildContext context) async {
    _isLoading = true;
    notifyListeners();
    try {
      final baseDir = await _storageService.getBaseDirSetting();
      final files = await _storageService.getAllPromptGroups(baseDir);
      List<PromptGroup> loadedGroups = [];
      for (var file in files) {
        final content = await file.readAsString();
        final jsonMap = jsonDecode(content);
        loadedGroups.add(PromptGroup.fromJson(jsonMap));
      }
      _promptGroups = loadedGroups;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat data prompt: $e')));
      }
    }
  }

  // Menambah seksi baru kosong
  void addSection(String sectionName, BuildContext context) {
    final String cleanName = sectionName.trim().toUpperCase();
    if (cleanName.isNotEmpty) {
      if (!_localEmptySections.contains(cleanName)) {
        _localEmptySections.add(cleanName);
        notifyListeners();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Seksi "$cleanName" berhasil dibuat! Tekan tahan judul seksi lalu tekan tombol + untuk menambah group.',
          ),
          backgroundColor: Colors.indigo,
        ),
      );
    }
  }

  // Mengubah urutan seksi
  void moveSectionOrder(int index, int direction, BuildContext context) async {
    final Map<String, List<PromptGroup>> sectionsMap = {};
    for (var group in _promptGroups) {
      final secName = group.sectionName.isEmpty
          ? 'GENERAL'
          : group.sectionName.toUpperCase();
      if (!sectionsMap.containsKey(secName)) {
        sectionsMap[secName] = [];
      }
      sectionsMap[secName]!.add(group);
    }

    for (var sec in _localEmptySections) {
      sectionsMap.putIfAbsent(sec, () => []);
    }

    final sectionKeys = sectionsMap.keys.toList();
    if (sectionKeys.contains('GENERAL')) {
      sectionKeys.remove('GENERAL');
      sectionKeys.insert(0, 'GENERAL');
    }

    int targetIndex = index + direction;
    if (targetIndex < 0 || targetIndex >= sectionKeys.length) return;

    final currentSectionName = sectionKeys[index];
    final targetSectionName = sectionKeys[targetIndex];

    if (_localEmptySections.contains(currentSectionName) ||
        _localEmptySections.contains(targetSectionName)) {
      final int idxA = _localEmptySections.indexOf(currentSectionName);
      final int idxB = _localEmptySections.indexOf(targetSectionName);
      if (idxA != -1 && idxB != -1) {
        final temp = _localEmptySections[idxA];
        _localEmptySections[idxA] = _localEmptySections[idxB];
        _localEmptySections[idxB] = temp;
      }
    }

    final List<PromptGroup> reorderedGroups = [];
    final tempKey = sectionKeys[index];
    sectionKeys[index] = sectionKeys[targetIndex];
    sectionKeys[targetIndex] = tempKey;

    for (var key in sectionKeys) {
      if (sectionsMap.containsKey(key)) {
        reorderedGroups.addAll(sectionsMap[key]!);
      }
    }
    _promptGroups = reorderedGroups;
    notifyListeners();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Seksi beserta seluruh isinya berhasil dipindahkan!'),
        duration: Duration(milliseconds: 700),
      ),
    );

    try {
      final baseDir = await _storageService.getBaseDirSetting();
      for (var group in _promptGroups) {
        final String jsonString = _storageService.formatJsonPretty(
          group.toJson(),
        );
        await _storageService.savePromptGroup(baseDir, group.id, jsonString);
      }
    } catch (e) {
      debugPrint("Gagal mengamankan urutan seksi: $e");
      if (context.mounted) loadAllPrompts(context);
    }
  }

  // Mengubah nama seksi
  Future<void> editSectionName(
    String oldName,
    String newName,
    BuildContext context,
  ) async {
    final String cleanOldName = oldName.trim().toUpperCase();
    final String cleanNewName = newName.trim().toUpperCase();

    if (cleanNewName.isEmpty || cleanOldName == cleanNewName) return;

    _isLoading = true;
    notifyListeners();

    try {
      if (_localEmptySections.contains(cleanOldName)) {
        final int indexSeksi = _localEmptySections.indexOf(cleanOldName);
        if (indexSeksi != -1) {
          _localEmptySections[indexSeksi] = cleanNewName;
        }
      }

      final baseDir = await _storageService.getBaseDirSetting();
      List<PromptGroup> groupsToUpdate = [];
      for (var group in _promptGroups) {
        final currentSecName = group.sectionName.isEmpty
            ? 'GENERAL'
            : group.sectionName.toUpperCase();
        if (currentSecName == cleanOldName) {
          groupsToUpdate.add(group);
        }
      }

      for (var group in groupsToUpdate) {
        final updatedGroup = PromptGroup(
          id: group.id,
          title: group.title,
          sectionName: cleanNewName,
          icon: group.icon,
          lastUpdated: DateTime.now().toIso8601String(),
          prompts: group.prompts,
        );
        final String jsonString = _storageService.formatJsonPretty(
          updatedGroup.toJson(),
        );
        await _storageService.savePromptGroup(baseDir, group.id, jsonString);
      }

      for (var group in _promptGroups) {
        final currentSecName = group.sectionName.isEmpty
            ? 'GENERAL'
            : group.sectionName.toUpperCase();
        if (currentSecName == cleanOldName) {
          int idx = _promptGroups.indexOf(group);
          if (idx != -1) {
            _promptGroups[idx] = PromptGroup(
              id: group.id,
              title: group.title,
              sectionName: cleanNewName,
              icon: group.icon,
              lastUpdated: DateTime.now().toIso8601String(),
              prompts: group.prompts,
            );
          }
        }
      }
      _isSectionEditMode = true;
      if (context.mounted) await loadAllPrompts(context);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengubah nama seksi: $e')),
        );
      }
    }
  }

  // Menghapus seksi
  Future<void> deleteSection(String sectionName, BuildContext context) async {
    _isLoading = true;
    notifyListeners();
    try {
      final String targetUpper = sectionName.toUpperCase();
      if (_localEmptySections.contains(targetUpper)) {
        _localEmptySections.remove(targetUpper);
      }

      final baseDir = await _storageService.getBaseDirSetting();
      for (var group in _promptGroups) {
        final currentSecName = group.sectionName.isEmpty
            ? 'GENERAL'
            : group.sectionName.toUpperCase();
        if (currentSecName == targetUpper) {
          await _storageService.deletePromptGroup(baseDir, group.id);
        }
      }
      _isSectionEditMode = true;
      if (context.mounted) await loadAllPrompts(context);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menghapus seksi: $e')));
      }
    }
  }

  // Menambah group prompt baru
  Future<void> addPromptGroup({
    required String title,
    required String icon,
    required String section,
    required BuildContext context,
  }) async {
    try {
      final baseDir = await _storageService.getBaseDirSetting();
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final targetSection = section.trim().isEmpty ? 'General' : section.trim();

      final newGroup = PromptGroup(
        id: id,
        title: title.trim(),
        sectionName: targetSection,
        icon: icon.trim().isEmpty ? '📝' : icon.trim(),
        lastUpdated: DateTime.now().toIso8601String(),
        prompts: [],
      );

      final String jsonString = _storageService.formatJsonPretty(
        newGroup.toJson(),
      );
      await _storageService.savePromptGroup(baseDir, id, jsonString);
      _localEmptySections.remove(targetSection.toUpperCase());

      if (context.mounted) await loadAllPrompts(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan group: $e')));
      }
    }
  }

  // Mengubah urutan group horizontal
  void moveGroupOrderHorizontal(
    List<PromptGroup> currentList,
    int index,
    int direction,
  ) async {
    int targetIndex = index + direction;
    if (targetIndex < 0 || targetIndex >= currentList.length) return;

    final item = currentList.removeAt(index);
    currentList.insert(targetIndex, item);

    final List<PromptGroup> updatedGlobal = [];
    final Set<String> processedSections = {};
    for (var g in _promptGroups) {
      final sec = g.sectionName.toUpperCase();
      if (!processedSections.contains(sec)) {
        processedSections.add(sec);
        if (sec == item.sectionName.toUpperCase()) {
          updatedGlobal.addAll(currentList);
        } else {
          updatedGlobal.addAll(
            _promptGroups.where((x) => x.sectionName.toUpperCase() == sec),
          );
        }
      }
    }
    _promptGroups = updatedGlobal;
    notifyListeners();

    try {
      final baseDir = await _storageService.getBaseDirSetting();
      for (var group in _promptGroups) {
        final String jsonString = _storageService.formatJsonPretty(
          group.toJson(),
        );
        await _storageService.savePromptGroup(baseDir, group.id, jsonString);
      }
    } catch (e) {
      debugPrint("Gagal mengamankan urutan group: $e");
    }
  }

  // Edit Nama & Ikon Group
  Future<void> editGroup(
    PromptGroup group,
    String newTitle,
    String newIcon,
    BuildContext context,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      final baseDir = await _storageService.getBaseDirSetting();
      final updatedGroup = PromptGroup(
        id: group.id,
        title: newTitle.trim(),
        sectionName: group.sectionName,
        icon: newIcon.trim().isEmpty ? '📝' : newIcon.trim(),
        lastUpdated: DateTime.now().toIso8601String(),
        prompts: group.prompts,
      );

      final String jsonString = _storageService.formatJsonPretty(
        updatedGroup.toJson(),
      );
      await _storageService.savePromptGroup(baseDir, group.id, jsonString);
      if (context.mounted) await loadAllPrompts(context);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengubah group: $e')));
      }
    }
  }

  // Memindahkan grup ke seksi lain
  Future<void> moveGroupToSection(
    PromptGroup group,
    String targetSection,
    BuildContext context,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      final baseDir = await _storageService.getBaseDirSetting();
      final updatedGroup = PromptGroup(
        id: group.id,
        title: group.title,
        sectionName: targetSection,
        icon: group.icon,
        lastUpdated: DateTime.now().toIso8601String(),
        prompts: group.prompts,
      );

      final String jsonString = _storageService.formatJsonPretty(
        updatedGroup.toJson(),
      );
      await _storageService.savePromptGroup(baseDir, group.id, jsonString);
      _localEmptySections.remove(targetSection.toUpperCase());
      if (context.mounted) await loadAllPrompts(context);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memindahkan seksi group: $e')),
        );
      }
    }
  }

  // Menghapus item group
  Future<void> deleteGroupItem(PromptGroup group, BuildContext context) async {
    _isLoading = true;
    notifyListeners();
    try {
      final baseDir = await _storageService.getBaseDirSetting();
      await _storageService.deletePromptGroup(baseDir, group.id);
      if (context.mounted) await loadAllPrompts(context);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menghapus group: $e')));
      }
    }
  }

  Future<PromptGroup?> addPromptItemToGroup({
    required PromptGroup group,
    required String title,
    required String description,
    required String content,
    required BuildContext context,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final baseDir = await _storageService.getBaseDirSetting();
      final String newItemId = 'item_${DateTime.now().millisecondsSinceEpoch}';

      final newPromptItem = PromptItem(
        id: newItemId,
        actAs: title.trim(),
        content: content.trim(),
        isFavorite: false,
      );

      group.prompts.add(newPromptItem);

      final String jsonString = _storageService.formatJsonPretty(
        group.toJson(),
      );
      await _storageService.savePromptGroup(baseDir, group.id, jsonString);

      if (context.mounted) {
        await loadAllPrompts(context);
      }

      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Prompt "${title.trim()}" berhasil ditambahkan!'),
            backgroundColor: Colors.indigo,
          ),
        );
      }

      return _promptGroups.firstWhere(
        (element) => element.id == group.id,
        orElse: () => group,
      );
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menambahkan item prompt: $e')),
        );
      }
      return null;
    }
  }

  // =============== FITUR EDIT, HAPUS, PINDAH, SALIN PROMPT ===============

  // Mengedit item prompt
  Future<PromptGroup?> editPromptItem({
    required PromptGroup group,
    required String itemId,
    required String newActAs,
    required String newDescription,
    required String newContent,
    required BuildContext context,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final baseDir = await _storageService.getBaseDirSetting();
      final index = group.prompts.indexWhere((p) => p.id == itemId);

      if (index != -1) {
        final oldItem = group.prompts[index];
        group.prompts[index] = PromptItem(
          id: oldItem.id,
          actAs: newActAs.trim(),
          content: newContent.trim(),
          description: newDescription.trim(),
          isFavorite: oldItem.isFavorite,
        );

        final String jsonString = _storageService.formatJsonPretty(
          group.toJson(),
        );
        await _storageService.savePromptGroup(baseDir, group.id, jsonString);

        if (context.mounted) {
          await loadAllPrompts(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prompt berhasil diperbarui!')),
          );
        }
      }
      _isLoading = false;
      notifyListeners();
      return _promptGroups.firstWhere(
        (g) => g.id == group.id,
        orElse: () => group,
      );
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memperbarui prompt: $e')));
      }
      return null;
    }
  }

  // Menghapus item prompt tunggal
  Future<PromptGroup?> deletePromptItem({
    required PromptGroup group,
    required String itemId,
    required BuildContext context,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final baseDir = await _storageService.getBaseDirSetting();
      group.prompts.removeWhere((p) => p.id == itemId);

      final String jsonString = _storageService.formatJsonPretty(
        group.toJson(),
      );
      await _storageService.savePromptGroup(baseDir, group.id, jsonString);

      if (context.mounted) {
        await loadAllPrompts(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prompt berhasil dihapus!')),
        );
      }
      _isLoading = false;
      notifyListeners();
      return _promptGroups.firstWhere(
        (g) => g.id == group.id,
        orElse: () => group,
      );
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menghapus prompt: $e')));
      }
      return null;
    }
  }

  // Memindah atau Menyalin item prompt
  Future<PromptGroup?> moveOrCopyPromptItem({
    required PromptGroup sourceGroup,
    required PromptGroup targetGroup,
    required PromptItem item,
    required bool isCopy,
    required BuildContext context,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final baseDir = await _storageService.getBaseDirSetting();
      final String newItemId = 'item_${DateTime.now().millisecondsSinceEpoch}';

      final newItem = PromptItem(
        id: newItemId,
        actAs: item.actAs,
        content: item.content,
        isFavorite: item.isFavorite,
      );

      if (sourceGroup.id == targetGroup.id) {
        sourceGroup.prompts.add(newItem);
        if (!isCopy) {
          sourceGroup.prompts.removeWhere((p) => p.id == item.id);
        }

        final String sourceJson = _storageService.formatJsonPretty(
          sourceGroup.toJson(),
        );
        await _storageService.savePromptGroup(
          baseDir,
          sourceGroup.id,
          sourceJson,
        );
      } else {
        targetGroup.prompts.add(newItem);

        final String targetJson = _storageService.formatJsonPretty(
          targetGroup.toJson(),
        );
        await _storageService.savePromptGroup(
          baseDir,
          targetGroup.id,
          targetJson,
        );

        if (!isCopy) {
          sourceGroup.prompts.removeWhere((p) => p.id == item.id);

          final String sourceJson = _storageService.formatJsonPretty(
            sourceGroup.toJson(),
          );
          await _storageService.savePromptGroup(
            baseDir,
            sourceGroup.id,
            sourceJson,
          );
        }
      }

      if (context.mounted) {
        await loadAllPrompts(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCopy
                  ? 'Prompt berhasil disalin!'
                  : 'Prompt berhasil dipindahkan!',
            ),
          ),
        );
      }

      _isLoading = false;
      notifyListeners();
      return _promptGroups.firstWhere(
        (g) => g.id == sourceGroup.id,
        orElse: () => sourceGroup,
      );
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memproses prompt: $e')));
      }
      return null;
    }
  }

  // =============== FITUR BARU: HAPUS MASSAL (MULTIPLE DELETE) ===============
  Future<PromptGroup?> deleteSelectedPromptItems({
    required PromptGroup group,
    required BuildContext context,
  }) async {
    if (_selectedPromptIds.isEmpty) return group;

    _isLoading = true;
    notifyListeners();
    try {
      final baseDir = await _storageService.getBaseDirSetting();

      // Menghapus semua item prompt yang id-nya terdaftar di dalam set terpilih
      group.prompts.removeWhere((p) => _selectedPromptIds.contains(p.id));

      final String jsonString = _storageService.formatJsonPretty(
        group.toJson(),
      );
      await _storageService.savePromptGroup(baseDir, group.id, jsonString);

      // Reset daftar pilihan kembali kosong setelah berhasil dihapus
      _selectedPromptIds.clear();

      if (context.mounted) {
        await loadAllPrompts(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Semua prompt terpilih berhasil dihapus!'),
          ),
        );
      }
      _isLoading = false;
      notifyListeners();
      return _promptGroups.firstWhere(
        (g) => g.id == group.id,
        orElse: () => group,
      );
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus beberapa prompt: $e')),
        );
      }
      return null;
    }
  }
}

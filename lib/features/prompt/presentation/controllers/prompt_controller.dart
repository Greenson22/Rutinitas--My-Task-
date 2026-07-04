// lib/features/prompt/presentation/controllers/prompt_controller.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:rutinitasku/core/services/storage_service.dart';
import 'package:rutinitasku/core/utils/crypto_helper.dart';
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

  // State tambahan untuk Fitur Pencarian Dinamis
  String _searchQuery = '';

  // STATE BARU: Menyimpan jenis pengurutan aktif ('manual', 'az', 'za')
  String currentSortType = 'manual';

  // Getters
  List<PromptGroup> get promptGroups => _promptGroups;
  bool get isLoading => _isLoading;
  bool get isSectionEditMode => _isSectionEditMode;
  bool get isCardEditMode => _isCardEditMode;
  List<String> get localEmptySections => _localEmptySections;

  // Getter Multi-Select
  bool get isMultiSelectMode => _selectedPromptIds.isNotEmpty;
  Set<String> get selectedPromptIds => _selectedPromptIds;

  // Getter Pencarian
  String get searchQuery => _searchQuery;

  // =========================================================================
  // LOGIKA FILTER PENCARIAN (DYNAMIC FILTERING)
  // =========================================================================

  List<PromptGroup> get filteredPromptGroups {
    if (_searchQuery.isEmpty) {
      return _promptGroups;
    }

    return _promptGroups
        .map((group) {
          final bool matchesGroupTitle = group.title.toLowerCase().contains(
            _searchQuery,
          );

          final matchedPrompts = group.prompts.where((prompt) {
            return prompt.actAs.toLowerCase().contains(_searchQuery) ||
                (prompt.description?.toLowerCase().contains(_searchQuery) ??
                    false) ||
                prompt.activeVersion.content.toLowerCase().contains(
                  _searchQuery,
                );
          }).toList();

          if (matchesGroupTitle || matchedPrompts.isNotEmpty) {
            return PromptGroup(
              id: group.id,
              title: group.title,
              sectionName: group.sectionName,
              icon: group.icon,
              lastUpdated: group.lastUpdated,
              orderIndex: group.orderIndex,
              prompts: matchesGroupTitle ? group.prompts : matchedPrompts,
            );
          }
          return null;
        })
        .whereType<PromptGroup>()
        .toList();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  void toggleSectionEditMode() {
    _isSectionEditMode = !_isSectionEditMode;
    notifyListeners();
  }

  void toggleCardEditMode() {
    _isCardEditMode = !_isCardEditMode;
    notifyListeners();
  }

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

  // =========================================================================
  // PERBAIKAN LOGIKA MUAT DATA (HANYA MEMUAT PLAIN TEXT)
  // =========================================================================
  Future<void> loadAllPrompts(BuildContext context) async {
    _isLoading = true;
    notifyListeners();
    try {
      final baseDir = await _storageService.getBaseDirSetting();
      final files = await _storageService.getAllPromptGroups(baseDir);

      List<PromptGroup> loadedGroups = [];

      for (var file in files) {
        if (!await file.exists()) continue;
        String content = await file.readAsString();
        String fileName = file.path.split('/').last.replaceAll('.json', '');

        try {
          // Bypass pengecekan enkripsi, langsung coba decode JSON
          final jsonMap = jsonDecode(content);
          loadedGroups.add(PromptGroup.fromJson(jsonMap));
        } catch (parseError) {
          debugPrint(
            "Gagal memuat atau mendecode berkas prompt ${file.path}: $parseError",
          );

          // MEKANISME CARD MERAH: Jika file lama masih terkunci (enkripsi versi terdahulu)
          // Masukkan objek mock penanda korup sehingga user bisa merestore-nya
          loadedGroups.add(
            PromptGroup(
              id: "CORRUPTED_${DateTime.now().millisecondsSinceEpoch}_$fileName",
              title: fileName,
              icon: '⚠️',
              sectionName: 'BERKAS RUSAK / TERKUNCI',
              isHidden: false,
              prompts: [],
            ),
          );
        }
      }
      _promptGroups = loadedGroups;

      // Mengurutkan berdasarkan orderIndex
      _promptGroups.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

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

    // Menulis ulang orderIndex setiap kali seksi digeser
    try {
      final baseDir = await _storageService.getBaseDirSetting();
      for (int i = 0; i < _promptGroups.length; i++) {
        final group = _promptGroups[i];
        if (group.id.startsWith("CORRUPTED_"))
          continue; // Guard clause berkas rusak

        final updatedGroup = PromptGroup(
          id: group.id,
          title: group.title,
          sectionName: group.sectionName,
          icon: group.icon,
          lastUpdated: group.lastUpdated,
          orderIndex: i, // Memberi urutan index baru sesuai posisinya
          prompts: group.prompts,
        );

        final String jsonString = _storageService.formatJsonPretty(
          updatedGroup.toJson(),
        );
        await _storageService.savePromptGroup(
          baseDir,
          updatedGroup.id,
          jsonString,
        );
        _promptGroups[i] = updatedGroup;
      }
    } catch (e) {
      debugPrint("Gagal mengamankan urutan seksi: $e");
      if (context.mounted) loadAllPrompts(context);
    }
  }

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
        if (group.id.startsWith("CORRUPTED_"))
          continue; // Guard clause berkas rusak
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
          orderIndex: group.orderIndex,
          prompts: group.prompts,
        );
        final String jsonString = _storageService.formatJsonPretty(
          updatedGroup.toJson(),
        );
        await _storageService.savePromptGroup(baseDir, group.id, jsonString);
      }

      for (var group in _promptGroups) {
        if (group.id.startsWith("CORRUPTED_"))
          continue; // Guard clause berkas rusak
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
              orderIndex: group.orderIndex,
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
        if (group.id.startsWith("CORRUPTED_"))
          continue; // Guard clause berkas rusak
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
        orderIndex: _promptGroups.length, // Letakkan urutan paling akhir
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

    // Menyimpan ulang indeks seluruh kotak agar tetap persisten di storage
    try {
      final baseDir = await _storageService.getBaseDirSetting();
      for (int i = 0; i < _promptGroups.length; i++) {
        final currentGroup = _promptGroups[i];
        if (currentGroup.id.startsWith("CORRUPTED_"))
          continue; // Guard clause berkas rusak

        final updatedGroup = PromptGroup(
          id: currentGroup.id,
          title: currentGroup.title,
          sectionName: currentGroup.sectionName,
          icon: currentGroup.icon,
          lastUpdated: currentGroup.lastUpdated,
          orderIndex: i, // Memperbarui urutan kotak
          prompts: currentGroup.prompts,
        );

        final String jsonString = _storageService.formatJsonPretty(
          updatedGroup.toJson(),
        );
        await _storageService.savePromptGroup(
          baseDir,
          updatedGroup.id,
          jsonString,
        );

        _promptGroups[i] = updatedGroup; // Update global state
      }
    } catch (e) {
      debugPrint("Gagal mengamankan urutan group: $e");
    }
  }

  Future<void> editGroup(
    PromptGroup group,
    String newTitle,
    String newIcon,
    BuildContext context,
  ) async {
    if (group.id.startsWith("CORRUPTED_")) return; // Guard clause berkas rusak
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
        orderIndex: group.orderIndex,
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

  Future<void> moveGroupToSection(
    PromptGroup group,
    String targetSection,
    BuildContext context,
  ) async {
    if (group.id.startsWith("CORRUPTED_")) return; // Guard clause berkas rusak
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
        orderIndex: group.orderIndex,
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

  Future<void> deleteGroupItem(PromptGroup group, BuildContext context) async {
    _isLoading = true;
    notifyListeners();
    try {
      final baseDir = await _storageService.getBaseDirSetting();

      // Mengambil ID asli jika dikirim dari mock data yang berawalan CORRUPTED_
      String targetId = group.id;
      if (targetId.startsWith("CORRUPTED_")) {
        targetId = targetId.replaceFirst(RegExp(r'CORRUPTED_\d+_'), '');
      }

      await _storageService.deletePromptGroup(baseDir, targetId);
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
    if (group.id.startsWith("CORRUPTED_"))
      return null; // Guard clause berkas rusak
    _isLoading = true;
    notifyListeners();
    try {
      final baseDir = await _storageService.getBaseDirSetting();
      final String newItemId = 'item_${DateTime.now().millisecondsSinceEpoch}';
      final String initialVersionId =
          'v_${DateTime.now().millisecondsSinceEpoch}';

      final newPromptItem = PromptItem(
        id: newItemId,
        actAs: title.trim(),
        description: description.trim().isEmpty ? null : description.trim(),
        isFavorite: false,
        activeVersionId: initialVersionId,
        versions: [
          PromptVersion(
            id: initialVersionId,
            versionName: 'v1.0',
            content: content.trim(),
          ),
        ],
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

  Future<PromptGroup?> editPromptItem({
    required PromptGroup group,
    required String itemId,
    required String newActAs,
    required String newDescription,
    required String newContent,
    required BuildContext context,
  }) async {
    if (group.id.startsWith("CORRUPTED_"))
      return null; // Guard clause berkas rusak
    _isLoading = true;
    notifyListeners();
    try {
      final baseDir = await _storageService.getBaseDirSetting();
      final index = group.prompts.indexWhere((p) => p.id == itemId);

      if (index != -1) {
        final oldItem = group.prompts[index];

        final updatedVersions = oldItem.versions.map((v) {
          if (v.id == oldItem.activeVersionId) {
            return PromptVersion(
              id: v.id,
              versionName: v.versionName,
              content: newContent.trim(),
            );
          }
          return v;
        }).toList();

        group.prompts[index] = PromptItem(
          id: oldItem.id,
          actAs: newActAs.trim(),
          description: newDescription.trim().isEmpty
              ? null
              : newDescription.trim(),
          isFavorite: oldItem.isFavorite,
          activeVersionId: oldItem.activeVersionId,
          versions: updatedVersions,
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

  Future<PromptGroup?> deletePromptItem({
    required PromptGroup group,
    required String itemId,
    required BuildContext context,
  }) async {
    if (group.id.startsWith("CORRUPTED_"))
      return null; // Guard clause berkas rusak
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

  Future<PromptGroup?> moveOrCopyPromptItem({
    required PromptGroup sourceGroup,
    required PromptGroup targetGroup,
    required PromptItem item,
    required bool isCopy,
    required BuildContext context,
  }) async {
    if (sourceGroup.id.startsWith("CORRUPTED_") ||
        targetGroup.id.startsWith("CORRUPTED_"))
      return null;
    _isLoading = true;
    notifyListeners();
    try {
      final baseDir = await _storageService.getBaseDirSetting();
      final String newItemId = 'item_${DateTime.now().millisecondsSinceEpoch}';

      final newItem = PromptItem(
        id: newItemId,
        actAs: item.actAs,
        description: item.description,
        isFavorite: item.isFavorite,
        activeVersionId: item.activeVersionId,
        versions: item.versions,
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

  Future<PromptGroup?> deleteSelectedPromptItems({
    required PromptGroup group,
    required BuildContext context,
  }) async {
    if (group.id.startsWith("CORRUPTED_"))
      return null; // Guard clause berkas rusak
    if (_selectedPromptIds.isEmpty) return group;

    _isLoading = true;
    notifyListeners();
    try {
      final baseDir = await _storageService.getBaseDirSetting();

      group.prompts.removeWhere((p) => _selectedPromptIds.contains(p.id));

      final String jsonString = _storageService.formatJsonPretty(
        group.toJson(),
      );
      await _storageService.savePromptGroup(baseDir, group.id, jsonString);

      _selectedPromptIds.clear();

      if (context.mounted) {
        await loadAllPrompts(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All prompt terpilih berhasil dihapus!'),
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

  Future<PromptGroup?> moveSelectedPromptItems({
    required PromptGroup sourceGroup,
    required PromptGroup targetGroup,
    required BuildContext context,
  }) async {
    if (sourceGroup.id.startsWith("CORRUPTED_") ||
        targetGroup.id.startsWith("CORRUPTED_"))
      return null;
    if (_selectedPromptIds.isEmpty) return sourceGroup;

    _isLoading = true;
    notifyListeners();

    try {
      final baseDir = await _storageService.getBaseDirSetting();

      final itemsToMove = sourceGroup.prompts
          .where((p) => _selectedPromptIds.contains(p.id))
          .toList();

      if (sourceGroup.id == targetGroup.id) {
        _selectedPromptIds.clear();
      } else {
        final List<PromptItem> preparedItems = itemsToMove.map((item) {
          return PromptItem(
            id: 'item_${DateTime.now().millisecondsSinceEpoch}_${item.id}',
            actAs: item.actAs,
            description: item.description,
            isFavorite: item.isFavorite,
            activeVersionId: item.activeVersionId,
            versions: item.versions,
          );
        }).toList();

        targetGroup.prompts.addAll(preparedItems);
        final String targetJson = _storageService.formatJsonPretty(
          targetGroup.toJson(),
        );
        await _storageService.savePromptGroup(
          baseDir,
          targetGroup.id,
          targetJson,
        );

        sourceGroup.prompts.removeWhere(
          (p) => _selectedPromptIds.contains(p.id),
        );
        final String sourceJson = _storageService.formatJsonPretty(
          sourceGroup.toJson(),
        );
        await _storageService.savePromptGroup(
          baseDir,
          sourceGroup.id,
          sourceJson,
        );
      }

      _selectedPromptIds.clear();

      if (context.mounted) {
        await loadAllPrompts(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All prompt terpilih berhasil dipindahkan!'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memindahkan beberapa prompt: $e')),
        );
      }
      return null;
    }
  }

  Future<PromptGroup?> toggleFavoritePromptItem({
    required PromptGroup group,
    required String itemId,
    required BuildContext context,
  }) async {
    if (group.id.startsWith("CORRUPTED_"))
      return null; // Guard clause berkas rusak
    _isLoading = true;
    notifyListeners();
    try {
      final baseDir = await _storageService.getBaseDirSetting();
      final index = group.prompts.indexWhere((p) => p.id == itemId);

      if (index != -1) {
        final oldItem = group.prompts[index];
        group.prompts[index] = PromptItem(
          id: oldItem.id,
          actAs: oldItem.actAs,
          description: oldItem.description,
          isFavorite: !oldItem.isFavorite,
          activeVersionId: oldItem.activeVersionId,
          versions: oldItem.versions,
        );

        final String jsonString = _storageService.formatJsonPretty(
          group.toJson(),
        );
        await _storageService.savePromptGroup(baseDir, group.id, jsonString);

        if (context.mounted) {
          await loadAllPrompts(context);
          final String statusText = group.prompts[index].isFavorite
              ? 'ditambahkan ke favorit'
              : 'dihapus dari favorit';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Prompt "${oldItem.actAs}" $statusText!')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui status favorit: $e')),
        );
      }
      return null;
    }
  }

  // =========================================================================
  // SISTEM MANAJEMEN VERSI (VERSION CONTROL MANAGEMENT)
  // =========================================================================

  Future<void> switchPromptVersion({
    required PromptGroup group,
    required String itemId,
    required String versionId,
    required BuildContext context,
  }) async {
    if (group.id.startsWith("CORRUPTED_")) return; // Guard clause berkas rusak
    try {
      final baseDir = await _storageService.getBaseDirSetting();
      final groupIdx = _promptGroups.indexWhere((g) => g.id == group.id);
      if (groupIdx == -1) return;

      final promptIdx = _promptGroups[groupIdx].prompts.indexWhere(
        (p) => p.id == itemId,
      );
      if (promptIdx == -1) return;

      _promptGroups[groupIdx].prompts[promptIdx].activeVersionId = versionId;

      final String jsonString = _storageService.formatJsonPretty(
        _promptGroups[groupIdx].toJson(),
      );
      await _storageService.savePromptGroup(baseDir, group.id, jsonString);
      notifyListeners();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memindahkan versi: $e')));
      }
    }
  }

  Future<void> createNewPromptVersion({
    required PromptGroup group,
    required String itemId,
    required String versionName,
    required BuildContext context,
  }) async {
    if (group.id.startsWith("CORRUPTED_")) return; // Guard clause berkas rusak
    _isLoading = true;
    notifyListeners();
    try {
      final baseDir = await _storageService.getBaseDirSetting();
      final groupIdx = _promptGroups.indexWhere((g) => g.id == group.id);
      if (groupIdx == -1) return;

      final promptIdx = _promptGroups[groupIdx].prompts.indexWhere(
        (p) => p.id == itemId,
      );
      if (promptIdx == -1) return;

      final currentPrompt = _promptGroups[groupIdx].prompts[promptIdx];
      final currentActiveContent = currentPrompt.activeVersion.content;
      final String newVersionId = 'v_${DateTime.now().millisecondsSinceEpoch}';

      final newVersion = PromptVersion(
        id: newVersionId,
        versionName: versionName.trim().isEmpty
            ? 'v${currentPrompt.versions.length + 1}.0'
            : versionName.trim(),
        content: currentActiveContent,
      );

      currentPrompt.versions.add(newVersion);
      currentPrompt.activeVersionId = newVersionId;

      final String jsonString = _storageService.formatJsonPretty(
        _promptGroups[groupIdx].toJson(),
      );
      await _storageService.savePromptGroup(baseDir, group.id, jsonString);

      if (context.mounted) {
        await loadAllPrompts(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Versi baru "${newVersion.versionName}" berhasil ditambahkan!',
            ),
          ),
        );
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuat versi baru: $e')));
      }
    }
  }

  // =========================================================================
  // FITUR BARU: EDIT & HAPUS VERSI PROMPT
  // =========================================================================

  /// Mengedit nama versi prompt yang sudah ada tanpa mengubah konten teksnya
  Future<void> editPromptVersionName({
    required PromptGroup group,
    required String itemId,
    required String versionId,
    required String newVersionName,
    required BuildContext context,
  }) async {
    if (group.id.startsWith("CORRUPTED_")) return; // Guard clause berkas rusak
    _isLoading = true;
    notifyListeners();
    try {
      final baseDir = await _storageService.getBaseDirSetting();
      final groupIdx = _promptGroups.indexWhere((g) => g.id == group.id);
      if (groupIdx == -1) return;

      final promptIdx = _promptGroups[groupIdx].prompts.indexWhere(
        (p) => p.id == itemId,
      );
      if (promptIdx == -1) return;

      final currentPrompt = _promptGroups[groupIdx].prompts[promptIdx];
      final versionIdx = currentPrompt.versions.indexWhere(
        (v) => v.id == versionId,
      );
      if (versionIdx == -1) return;

      final oldVersion = currentPrompt.versions[versionIdx];
      currentPrompt.versions[versionIdx] = PromptVersion(
        id: oldVersion.id,
        versionName: newVersionName.trim(),
        content: oldVersion.content,
      );

      final String jsonString = _storageService.formatJsonPretty(
        _promptGroups[groupIdx].toJson(),
      );
      await _storageService.savePromptGroup(baseDir, group.id, jsonString);

      if (context.mounted) {
        await loadAllPrompts(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nama versi berhasil diperbarui!')),
        );
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengedit nama versi: $e')),
        );
      }
    }
  }

  /// Menghapus versi prompt spesifik dan memindahkan status aktif jika versi aktif dihapus
  Future<void> deletePromptVersion({
    required PromptGroup group,
    required String itemId,
    required String versionId,
    required BuildContext context,
  }) async {
    if (group.id.startsWith("CORRUPTED_")) return; // Guard clause berkas rusak
    _isLoading = true;
    notifyListeners();
    try {
      final baseDir = await _storageService.getBaseDirSetting();
      final groupIdx = _promptGroups.indexWhere((g) => g.id == group.id);
      if (groupIdx == -1) return;

      final promptIdx = _promptGroups[groupIdx].prompts.indexWhere(
        (p) => p.id == itemId,
      );
      if (promptIdx == -1) return;

      final currentPrompt = _promptGroups[groupIdx].prompts[promptIdx];

      if (currentPrompt.versions.length <= 1) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak dapat menghapus satu-satunya versi!'),
            ),
          );
        }
        _isLoading = false;
        notifyListeners();
        return;
      }

      currentPrompt.versions.removeWhere((v) => v.id == versionId);

      if (currentPrompt.activeVersionId == versionId) {
        currentPrompt.activeVersionId = currentPrompt.versions.first.id;
      }

      final String jsonString = _storageService.formatJsonPretty(
        _promptGroups[groupIdx].toJson(),
      );
      await _storageService.savePromptGroup(baseDir, group.id, jsonString);

      if (context.mounted) {
        await loadAllPrompts(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Versi berhasil dihapus!')),
        );
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menghapus versi: $e')));
      }
    }
  }

  Future<void> toggleGroupVisibility(
    PromptGroup group,
    BuildContext context,
  ) async {
    if (group.id.startsWith("CORRUPTED_")) return; // Guard clause berkas rusak
    _isLoading = true;
    notifyListeners();
    try {
      group.isHidden = !group.isHidden; // Balikkan status visibilitas
      final baseDir = await _storageService.getBaseDirSetting();
      final String jsonString = _storageService.formatJsonPretty(
        group.toJson(),
      );
      await _storageService.savePromptGroup(baseDir, group.id, jsonString);

      // Muat ulang data secara otomatis setelah berhasil disimpan
      await loadAllPrompts(context);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint("Gagal mengubah visibilitas prompt group: $e");
    }
  }

  // =========================================================================
  // FITUR BARU: LOGIKA PROSES PENGURUTAN ITEM PROMPT
  // =========================================================================
  void sortPromptItems({
    required PromptGroup group,
    required String sortType,
    required BuildContext context,
  }) async {
    currentSortType = sortType;

    if (sortType == 'az') {
      group.prompts.sort(
        (a, b) => a.actAs.toLowerCase().compareTo(b.actAs.toLowerCase()),
      );
    } else if (sortType == 'za') {
      group.prompts.sort(
        (a, b) => b.actAs.toLowerCase().compareTo(a.actAs.toLowerCase()),
      );
    } else {
      // Mode Manual: Diurutkan kembali berdasarkan ID/Waktu pembuatan item prompt
      group.prompts.sort((a, b) => a.id.compareTo(b.id));
    }

    notifyListeners();

    try {
      final baseDir = await _storageService.getBaseDirSetting();
      final String jsonString = _storageService.formatJsonPretty(
        group.toJson(),
      );
      await _storageService.savePromptGroup(baseDir, group.id, jsonString);
    } catch (e) {
      debugPrint("Gagal menyimpan urutan prompt group: $e");
    }
  }

  // =========================================================================
  // FITUR BARU: PENYELAMAT DEKRIPSI MANUAL UNTUK BERKAS PROMPT TERKUNCI
  // =========================================================================
  Future<void> saveGroupDataToFile(PromptGroup group) async {
    try {
      final baseDir = await _storageService.getBaseDirSetting();

      // Ambil nama file asli (bersihkan prefix corrupted jika ada)
      String fileName = group.id;
      if (fileName.startsWith("CORRUPTED_")) {
        fileName = fileName.replaceFirst(RegExp(r'CORRUPTED_\d+_'), '');
      }

      final File jsonFile = File('$baseDir/$fileName.json');
      final String jsonString = _storageService.formatJsonPretty(
        group.toJson(),
      );

      // Bypass enkripsi, simpan langsung sebagai plain text secara permanen
      await jsonFile.writeAsString(jsonString);

      debugPrint("Berhasil memulihkan file fisik prompt: ${jsonFile.path}");
    } catch (e) {
      debugPrint("Gagal menulis file pemulihan prompt: $e");
      rethrow;
    }
  }
}

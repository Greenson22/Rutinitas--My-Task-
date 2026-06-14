// lib/features/prompt/presentation/controllers/prompt_controller.dart
import 'dart:convert';
import 'dart:io' as java_io;
import 'package:flutter/material.dart';
import 'package:rutinitasku/core/services/storage_service.dart';
import '../../data/models/prompt_model.dart';
import '../../../../core/utils/crypto_helper.dart';

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

  // STATE BARU: Sinkronisasi ikon status enkripsi global di AppBar lokal
  bool isGlobalEncryptionEnabled = false;

  // Getters
  List<PromptGroup> get promptGroups => _promptGroups;
  bool get isLoading => _isLoading;
  bool get isSectionEditMode => _isSectionEditMode;
  bool get isCardEditMode => _isCardEditMode;
  List<String> get localEmptySections => _localEmptySections;
  bool get isMultiSelectMode => _selectedPromptIds.isNotEmpty;
  Set<String> get selectedPromptIds => _selectedPromptIds;
  String get searchQuery => _searchQuery;

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

  // MODIFIKASI UTAMA: Memuat berkas dengan alur Enkripsi Otomatis dan Fallback Komprehensif
  Future<void> loadAllPrompts(BuildContext context) async {
    _isLoading = true;
    notifyListeners();
    try {
      // BERIKAN JEDA MIKRO: Menjamin penulisan enkripsi massal selesai di disk storage (Sama seperti Notes)
      await Future.delayed(const Duration(milliseconds: 150));

      final baseDir = await _storageService.getBaseDirSetting();
      final files = await _storageService.getAllPromptGroups(baseDir);

      bool isEncrypted = await _storageService.isEncryptionEnabled();
      String? password = await _storageService.getEncryptionPassword();

      // Sinkronisasikan status enkripsi sistem untuk kontrol UI ikon AppBar
      isGlobalEncryptionEnabled = isEncrypted;

      List<PromptGroup> loadedGroups = [];
      List<String> autoEncryptedFiles = [];

      for (var file in files) {
        try {
          if (!await file.exists()) continue;
          String content = await file.readAsString();

          final trimmedContent = content.trim();
          bool isRawJson =
              trimmedContent.startsWith('{') || trimmedContent.startsWith('[');
          String fileName = file.path.split('/').last.replaceAll('.json', '');

          if (isEncrypted && password != null) {
            if (!isRawJson) {
              // Kondisi Normal: File terenkripsi, lakukan dekripsi seperti biasa
              content = CryptoHelper.decrypt(content, password);
            } else {
              // === SEKUENS OTOMATIS BERKAS BELUM TERENKRIPSI ===
              try {
                final PromptGroup parsedGroup = PromptGroup.fromJson(
                  jsonDecode(content),
                );
                final String encryptedContent = CryptoHelper.encrypt(
                  _storageService.formatJsonPretty(parsedGroup.toJson()),
                  password,
                );
                await file.writeAsString(encryptedContent);
                autoEncryptedFiles.add(parsedGroup.title);
                debugPrint(
                  "Otomatis mengamankan berkas prompt belum terenkripsi: ${file.path}",
                );
              } catch (autoEncryptError) {
                debugPrint(
                  "Gagal mengamankan otomatis berkas mentah prompt: $autoEncryptError",
                );
              }
            }
          }

          final jsonMap = jsonDecode(content);
          loadedGroups.add(PromptGroup.fromJson(jsonMap));
        } catch (fileError) {
          debugPrint(
            "Gagal memuat atau mendekripsi berkas prompt ${file.path}: $fileError",
          );
          String fileName = file.path.split('/').last.replaceAll('.json', '');

          // TETAP TAMPILKAN SEBAGAI CARD: Buat tiruan PromptGroup rusak (Sama seperti Notes)
          loadedGroups.add(
            PromptGroup(
              id: "CORRUPTED_${DateTime.now().millisecondsSinceEpoch}_$fileName",
              title: fileName,
              sectionName: "BERKAS RUSAK",
              icon: "⚠️",
              lastUpdated: DateTime.now().toIso8601String(),
              prompts: [],
            ),
          );
        }
      }

      _promptGroups = loadedGroups;
      _promptGroups.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      _isLoading = false;
      notifyListeners();

      // Pemicu notifikasi penyelarasan sukses jika ada
      if (autoEncryptedFiles.isNotEmpty && context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Menyelaraskan Keamanan: Berkas [${autoEncryptedFiles.join(", ")}] telah otomatis dienkripsi sesuai pengaturan sistem.',
            ),
            backgroundColor: Colors.teal,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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

  // MODIFIKASI: Interseptor penyimpanan untuk enkripsi global data sebelum disimpan ke disk
  Future<void> _writeGroupToStorage(String baseDir, PromptGroup group) async {
    if (group.id.startsWith("CORRUPTED_")) return;

    bool isEncrypted = await _storageService.isEncryptionEnabled();
    String? password = await _storageService.getEncryptionPassword();

    String jsonString = _storageService.formatJsonPretty(group.toJson());

    if (isEncrypted && password != null) {
      jsonString = CryptoHelper.encrypt(jsonString, password);
    }

    await _storageService.savePromptGroup(baseDir, group.id, jsonString);
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
            'Seksi "$cleanName" berhasil dibuat! Tekan tombol + di kanannya untuk menambah group.',
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

    try {
      final baseDir = await _storageService.getBaseDirSetting();
      for (int i = 0; i < _promptGroups.length; i++) {
        final group = _promptGroups[i];
        final updatedGroup = PromptGroup(
          id: group.id,
          title: group.title,
          sectionName: group.sectionName,
          icon: group.icon,
          lastUpdated: group.lastUpdated,
          orderIndex: i,
          prompts: group.prompts,
        );
        await _writeGroupToStorage(baseDir, updatedGroup);
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
        await _writeGroupToStorage(baseDir, updatedGroup);
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
        icon: icon.trim().isEmpty ? '📁' : icon.trim(),
        lastUpdated: DateTime.now().toIso8601String(),
        orderIndex: _promptGroups.length,
        prompts: [],
      );

      await _writeGroupToStorage(baseDir, newGroup);
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

    try {
      final baseDir = await _storageService.getBaseDirSetting();
      for (int i = 0; i < _promptGroups.length; i++) {
        final currentGroup = _promptGroups[i];
        final updatedGroup = PromptGroup(
          id: currentGroup.id,
          title: currentGroup.title,
          sectionName: currentGroup.sectionName,
          icon: currentGroup.icon,
          lastUpdated: currentGroup.lastUpdated,
          orderIndex: i,
          prompts: currentGroup.prompts,
        );
        await _writeGroupToStorage(baseDir, updatedGroup);
        _promptGroups[i] = updatedGroup;
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
    _isLoading = true;
    notifyListeners();
    try {
      final baseDir = await _storageService.getBaseDirSetting();
      final updatedGroup = PromptGroup(
        id: group.id,
        title: newTitle.trim(),
        sectionName: group.sectionName,
        icon: newIcon.trim().isEmpty ? '📁' : newIcon.trim(),
        lastUpdated: DateTime.now().toIso8601String(),
        orderIndex: group.orderIndex,
        prompts: group.prompts,
      );
      await _writeGroupToStorage(baseDir, updatedGroup);
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
      await _writeGroupToStorage(baseDir, updatedGroup);
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
      String targetId = group.id;
      if (targetId.startsWith("CORRUPTED_")) {
        targetId = targetId.replaceFirst(RegExp(r'CORRUPTED_\d+_'), '');
      }
      await _storageService.deletePromptGroup(baseDir, targetId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Berkas "${group.title}" berhasil dihapus secara permanen!',
            ),
          ),
        );
        await loadAllPrompts(context);
      }
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
      await _writeGroupToStorage(baseDir, group);

      if (context.mounted) await loadAllPrompts(context);
      _isLoading = false;
      notifyListeners();
      return _promptGroups.firstWhere(
        (element) => element.id == group.id,
        orElse: () => group,
      );
    } catch (e) {
      _isLoading = false;
      notifyListeners();
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

        await _writeGroupToStorage(baseDir, group);
        if (context.mounted) await loadAllPrompts(context);
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
      return null;
    }
  }

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
      await _writeGroupToStorage(baseDir, group);
      if (context.mounted) await loadAllPrompts(context);
      _isLoading = false;
      notifyListeners();
      return _promptGroups.firstWhere(
        (g) => g.id == group.id,
        orElse: () => group,
      );
    } catch (e) {
      _isLoading = false;
      notifyListeners();
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
        await _writeGroupToStorage(baseDir, sourceGroup);
      } else {
        targetGroup.prompts.add(newItem);
        await _writeGroupToStorage(baseDir, targetGroup);
        if (!isCopy) {
          sourceGroup.prompts.removeWhere((p) => p.id == item.id);
          await _writeGroupToStorage(baseDir, sourceGroup);
        }
      }
      if (context.mounted) await loadAllPrompts(context);
      _isLoading = false;
      notifyListeners();
      return _promptGroups.firstWhere(
        (g) => g.id == sourceGroup.id,
        orElse: () => sourceGroup,
      );
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<PromptGroup?> deleteSelectedPromptItems({
    required PromptGroup group,
    required BuildContext context,
  }) async {
    if (_selectedPromptIds.isEmpty) return group;
    _isLoading = true;
    notifyListeners();
    try {
      final baseDir = await _storageService.getBaseDirSetting();
      group.prompts.removeWhere((p) => _selectedPromptIds.contains(p.id));
      await _writeGroupToStorage(baseDir, group);
      _selectedPromptIds.clear();
      if (context.mounted) await loadAllPrompts(context);
      _isLoading = false;
      notifyListeners();
      return _promptGroups.firstWhere(
        (g) => g.id == group.id,
        orElse: () => group,
      );
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<PromptGroup?> moveSelectedPromptItems({
    required PromptGroup sourceGroup,
    required PromptGroup targetGroup,
    required BuildContext context,
  }) async {
    if (_selectedPromptIds.isEmpty) return sourceGroup;
    _isLoading = true;
    notifyListeners();
    try {
      final baseDir = await _storageService.getBaseDirSetting();
      final itemsToMove = sourceGroup.prompts
          .where((p) => _selectedPromptIds.contains(p.id))
          .toList();

      if (sourceGroup.id != targetGroup.id) {
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
        await _writeGroupToStorage(baseDir, targetGroup);

        sourceGroup.prompts.removeWhere(
          (p) => _selectedPromptIds.contains(p.id),
        );
        await _writeGroupToStorage(baseDir, sourceGroup);
      }
      _selectedPromptIds.clear();
      if (context.mounted) await loadAllPrompts(context);
      _isLoading = false;
      notifyListeners();
      return _promptGroups.firstWhere(
        (g) => g.id == sourceGroup.id,
        orElse: () => sourceGroup,
      );
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<PromptGroup?> toggleFavoritePromptItem({
    required PromptGroup group,
    required String itemId,
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
          actAs: oldItem.actAs,
          description: oldItem.description,
          isFavorite: !oldItem.isFavorite,
          activeVersionId: oldItem.activeVersionId,
          versions: oldItem.versions,
        );
        await _writeGroupToStorage(baseDir, group);
        if (context.mounted) await loadAllPrompts(context);
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
      return null;
    }
  }

  Future<void> switchPromptVersion({
    required PromptGroup group,
    required String itemId,
    required String versionId,
    required BuildContext context,
  }) async {
    try {
      final baseDir = await _storageService.getBaseDirSetting();
      final groupIdx = _promptGroups.indexWhere((g) => g.id == group.id);
      if (groupIdx == -1) return;

      final promptIdx = _promptGroups[groupIdx].prompts.indexWhere(
        (p) => p.id == itemId,
      );
      if (promptIdx == -1) return;

      _promptGroups[groupIdx].prompts[promptIdx].activeVersionId = versionId;
      await _writeGroupToStorage(baseDir, _promptGroups[groupIdx]);
      notifyListeners();
    } catch (e) {
      debugPrint("Gagal ganti versi: $e");
    }
  }

  Future<void> createNewPromptVersion({
    required PromptGroup group,
    required String itemId,
    required String versionName,
    required BuildContext context,
  }) async {
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

      await _writeGroupToStorage(baseDir, _promptGroups[groupIdx]);
      if (context.mounted) await loadAllPrompts(context);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> editPromptVersionName({
    required PromptGroup group,
    required String itemId,
    required String versionId,
    required String newVersionName,
    required BuildContext context,
  }) async {
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

      await _writeGroupToStorage(baseDir, _promptGroups[groupIdx]);
      if (context.mounted) await loadAllPrompts(context);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deletePromptVersion({
    required PromptGroup group,
    required String itemId,
    required String versionId,
    required BuildContext context,
  }) async {
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
        _isLoading = false;
        notifyListeners();
        return;
      }

      currentPrompt.versions.removeWhere((v) => v.id == versionId);
      if (currentPrompt.activeVersionId == versionId) {
        currentPrompt.activeVersionId = currentPrompt.versions.first.id;
      }

      await _writeGroupToStorage(baseDir, _promptGroups[groupIdx]);
      if (context.mounted) await loadAllPrompts(context);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleGroupVisibility(
    PromptGroup group,
    BuildContext context,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      group.isHidden = !group.isHidden;
      final baseDir = await _storageService.getBaseDirSetting();
      await _writeGroupToStorage(baseDir, group);
      await loadAllPrompts(context);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  // LOGIKA DEKRIPSI MANUAL BERKAS PROMPT (PERSIS SEPERTI DI NOTES & CHECKLIST)
  Future<void> handleManualDecrypt(
    PromptGroup corruptedGroup,
    String inputPassword,
    BuildContext context,
  ) async {
    _isLoading = true;
    notifyListeners();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final baseDir = await _storageService.getBaseDirSetting();
      final String originalFileName = corruptedGroup.id.replaceFirst(
        RegExp(r'CORRUPTED_\d+_'),
        '',
      );

      final file = java_io.File('$baseDir/prompts/$originalFileName.json');
      if (!await file.exists()) {
        throw Exception("Berkas fisik prompt tidak ditemukan di penyimpanan.");
      }

      String rawContent = await file.readAsString();
      String decryptedContent = CryptoHelper.decrypt(
        rawContent.trim(),
        inputPassword,
      );

      final Map<String, dynamic> parsedJson = jsonDecode(decryptedContent);
      PromptGroup decryptedGroup = PromptGroup.fromJson(parsedJson);

      await _writeGroupToStorage(baseDir, decryptedGroup);

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Berkas prompt "${decryptedGroup.title}" berhasil didekripsi dan dipulihkan!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint("Gagal melakukan dekripsi manual berkas prompt: $e");
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Gagal mendekripsi! Kata sandi salah atau struktur data JSON memang rusak.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      await loadAllPrompts(context);
    }
  }
}

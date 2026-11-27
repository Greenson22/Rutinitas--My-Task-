// lib/features/documents/presentation/controllers/documents_controller.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/atomic_write_helper.dart'; // <--- TAMBAHAN: Import Atomic Write Helper[cite: 1, 3]
import '../../data/models/document_model.dart';
import '../../data/services/document_checklist_link_service.dart';
import '../../data/services/document_file_service.dart';

class DocumentsController extends ChangeNotifier {
  final StorageService storageService = StorageService();

  DocumentFileService get _fileService =>
      DocumentFileService(baseDir: selectedBaseDir);

  final DocumentChecklistLinkService _linkService =
      DocumentChecklistLinkService();

  bool isLoading = false;
  bool isPageEditMode = false;
  bool isSectionEditMode = false;
  bool showHiddenSection = false;
  String searchQuery = '';
  String selectedBaseDir = 'Documents';

  List<DocumentGroup> allGroupRaw = [];
  Map<String, List<DocumentGroup>> groupedVisibleGroup = {};
  Map<String, List<DocumentGroup>> groupedHiddenGroup = {};

  Map<String, int> groupFileCounts = {};

  final Set<String> collapsedSections = {};
  bool isSectionCollapsed(String sectionName) =>
      collapsedSections.contains(sectionName);

  bool showHiddenSections = false;
  final Set<String> hiddenSections = {};
  bool isSectionHidden(String sectionName) =>
      hiddenSections.contains(sectionName);

  Future<void> toggleSectionCollapse(String sectionName) async {
    if (collapsedSections.contains(sectionName)) {
      collapsedSections.remove(sectionName);
    } else {
      collapsedSections.add(sectionName);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final rememberCollapse =
        prefs.getBool('sections_remember_collapse_state') ?? true;
    if (rememberCollapse) {
      await prefs.setString(
        'docs_collapsed_sections',
        jsonEncode(collapsedSections.toList()),
      );
    }
  }

  void toggleShowHiddenSections() {
    showHiddenSections = !showHiddenSections;
    notifyListeners();
  }

  Future<void> toggleSectionHidden(String sectionName) async {
    if (hiddenSections.contains(sectionName)) {
      hiddenSections.remove(sectionName);
    } else {
      hiddenSections.add(sectionName);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'docs_hidden_sections',
      jsonEncode(hiddenSections.toList()),
    );
  }

  DocumentsController() {
    loadGroupsData();
  }

  Future<void> loadGroupsData() async {
    isLoading = true;
    notifyListeners();

    try {
      selectedBaseDir = await storageService.getBaseDirSetting();
      List<File> files = await storageService.getAllDocumentGroups(
        selectedBaseDir,
      );

      List<DocumentGroup> loadedGroups = [];
      for (var f in files) {
        if (!await f.exists()) continue;
        String content = await f.readAsString();
        String fName = f.path.split('/').last.replaceAll('.json', '');

        final trimmed = content.trim();
        if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
          try {
            final map = jsonDecode(trimmed);
            map['id'] = fName;
            loadedGroups.add(DocumentGroup.fromJson(map));
          } catch (_) {}
        }
      }

      // <--- BARU: Urutkan data berdasarkan orderIndex sesaat setelah diload
      loadedGroups.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

      allGroupRaw = loadedGroups;

      final prefs = await SharedPreferences.getInstance();
      final defaultCollapsed =
          prefs.getBool('sections_default_collapsed') ?? false;
      final rememberCollapse =
          prefs.getBool('sections_remember_collapse_state') ?? true;
      collapsedSections.clear();
      final allSectionNames = loadedGroups
          .map((g) => g.sectionCategory)
          .toSet();
      if (rememberCollapse) {
        final rawCollapsed = prefs.getString('docs_collapsed_sections');
        if (rawCollapsed != null) {
          final decoded = jsonDecode(rawCollapsed) as List<dynamic>;
          collapsedSections.addAll(decoded.map((e) => e.toString()));
        } else if (defaultCollapsed) {
          collapsedSections.addAll(allSectionNames);
        }
      } else if (defaultCollapsed) {
        collapsedSections.addAll(allSectionNames);
      }

      hiddenSections.clear();
      final rawHidden = prefs.getString('docs_hidden_sections');
      if (rawHidden != null) {
        final decodedHidden = jsonDecode(rawHidden) as List<dynamic>;
        hiddenSections.addAll(decodedHidden.map((e) => e.toString()));
      }
      await _countPhysicalFiles();
      _groupData();
    } catch (e) {
      debugPrint("Gagal memuat Document Groups: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _countPhysicalFiles() async {
    groupFileCounts.clear();
    for (var group in allGroupRaw) {
      groupFileCounts[group.id] = await _fileService.countFiles(group.id);
    }
  }

  // <--- PERUBAHAN: Menerapkan mekanisme Atomic Write saat menyimpan file JSON[cite: 3]
  Future<void> saveGroupDataToFile(DocumentGroup group) async {
    try {
      File file = await storageService.getSpecificDocumentGroupFile(
        selectedBaseDir,
        group.id,
      );

      // Menggunakan formating JSON Pretty Print agar struktur data file .json rapi
      String jsonStr = const JsonEncoder.withIndent(
        '  ',
      ).convert(group.toJson());

      // EKSEKUSI PENULISAN SECARA AMAN DENGAN ATOMIC WRITE[cite: 1, 3]
      await AtomicWriteHelper.writeSafe(targetFile: file, content: jsonStr);

      await _fileService.ensureGroupDirectory(group.id);
    } catch (e) {
      debugPrint(
        "Gagal menyimpan Document Group dengan aman (Atomic Write): $e",
      );
    }
  }

  // <--- BARU: Fungsi untuk menghitung dan menyimpan ulang seluruh urutan
  Future<void> recalculateAndSaveAllOrder() async {
    int globalIndex = 0;

    // Kumpulkan semua keys (Seksi) unik sesuai urutannya
    List<String> visibleKeys = groupedVisibleGroup.keys.toList();
    List<String> hiddenKeys = groupedHiddenGroup.keys.toList();
    List<String> allKeys = [...visibleKeys];

    for (var key in hiddenKeys) {
      if (!allKeys.contains(key)) {
        allKeys.add(key);
      }
    }

    // Hitung ulang secara sekuensial (global) dari atas ke bawah
    for (String key in allKeys) {
      if (groupedVisibleGroup.containsKey(key)) {
        for (var group in groupedVisibleGroup[key]!) {
          group.orderIndex = globalIndex;
          globalIndex++;
          await saveGroupDataToFile(group);
        }
      }
      if (groupedHiddenGroup.containsKey(key)) {
        for (var group in groupedHiddenGroup[key]!) {
          group.orderIndex = globalIndex;
          globalIndex++;
          await saveGroupDataToFile(group);
        }
      }
    }

    // Urutkan ulang master list di memory
    allGroupRaw.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    notifyListeners();
  }

  void _groupData() {
    groupedVisibleGroup.clear();
    groupedHiddenGroup.clear();

    for (var group in allGroupRaw) {
      if (searchQuery.isNotEmpty &&
          !group.groupName.toLowerCase().contains(searchQuery.toLowerCase())) {
        continue;
      }
      if (group.isHidden) {
        groupedHiddenGroup
            .putIfAbsent(group.sectionCategory, () => [])
            .add(group);
      } else {
        groupedVisibleGroup
            .putIfAbsent(group.sectionCategory, () => [])
            .add(group);
      }
    }
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    searchQuery = query.toLowerCase();
    _groupData();
  }

  void toggleShowHiddenSection() {
    showHiddenSection = !showHiddenSection;
    notifyListeners();
  }

  void togglePageEditMode() {
    isPageEditMode = !isPageEditMode;
    notifyListeners();
  }

  void toggleSectionEditMode() {
    isSectionEditMode = !isSectionEditMode;
    notifyListeners();
  }

  void addLocalMainSection(String sectionName) {
    if (!groupedVisibleGroup.containsKey(sectionName)) {
      groupedVisibleGroup[sectionName] = [];
      notifyListeners();
    }
  }

  Future<void> createGroupAtSection(
    String name,
    String icon,
    String section,
  ) async {
    final newGroup = DocumentGroup(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      groupName: name,
      icon: icon,
      sectionCategory: section,
      allList: [],
      orderIndex: allGroupRaw.length, // <--- BARU: Berikan urutan paling akhir
    );
    await saveGroupDataToFile(newGroup);
    await loadGroupsData(); // Refresh untuk memastikan data baru masuk grouping
  }

  Future<void> deleteGroup(DocumentGroup group) async {
    File targetFile = await storageService.getSpecificDocumentGroupFile(
      selectedBaseDir,
      group.id,
    );
    if (await targetFile.exists()) {
      await targetFile.delete();
    }
    await _fileService.deleteGroupDirectory(group.id);
    await _linkService.clearLinksForGroup(group.id);
    await loadGroupsData();
  }

  Future<void> toggleGroupVisibility(DocumentGroup group) async {
    group.isHidden = !group.isHidden;
    await saveGroupDataToFile(group);
    await loadGroupsData(); // Load ulang agar terfilter dengan benar
  }

  Future<void> moveGroupToAnotherSection(
    DocumentGroup group,
    String newSection,
  ) async {
    group.sectionCategory = newSection;
    await saveGroupDataToFile(group);
    await loadGroupsData();
  }

  Future<void> updateMainSectionName(String oldName, String newName) async {
    for (var group in allGroupRaw) {
      if (group.sectionCategory == oldName) {
        group.sectionCategory = newName;
        await saveGroupDataToFile(group);
      }
    }
    await loadGroupsData();
  }

  Future<void> deleteMainSection(String sectionName) async {
    final groupsToDelete = allGroupRaw
        .where((g) => g.sectionCategory == sectionName)
        .toList();
    for (var group in groupsToDelete) {
      await deleteGroup(group);
    }
  }

  // <--- DIPERBARUI: Simpan posisi persisten saat grup digeser (kiri/kanan)
  Future<void> moveGroupOrder(
    List<DocumentGroup> sectionItems,
    int index,
    int direction,
  ) async {
    int newIndex = index + direction;
    if (newIndex < 0 || newIndex >= sectionItems.length) return;

    final temp = sectionItems[index];
    sectionItems[index] = sectionItems[newIndex];
    sectionItems[newIndex] = temp;

    notifyListeners(); // Feedback visual instan
    await recalculateAndSaveAllOrder(); // Simpan di background
  }

  // <--- DIPERBARUI: Simpan posisi persisten saat seksi digeser (atas/bawah)
  Future<void> moveMainSectionOrder(String sectionKey, int direction) async {
    final keys = groupedVisibleGroup.keys.toList();
    int index = keys.indexOf(sectionKey);
    if (index == -1) return;

    int newIndex = index + direction;
    if (newIndex < 0 || newIndex >= keys.length) return;

    final targetSectionKey = keys[newIndex];
    final tempMap = <String, List<DocumentGroup>>{};

    for (var key in keys) {
      if (key == sectionKey) {
        tempMap[targetSectionKey] = groupedVisibleGroup[targetSectionKey] ?? [];
      } else if (key == targetSectionKey) {
        tempMap[sectionKey] = groupedVisibleGroup[sectionKey] ?? [];
      } else {
        tempMap[key] = groupedVisibleGroup[key] ?? [];
      }
    }

    groupedVisibleGroup = tempMap;
    notifyListeners(); // Feedback visual instan
    await recalculateAndSaveAllOrder(); // Simpan di background
  }

  List<DocumentGroup> getAvailableTargetGroups(String currentGroupId) {
    return allGroupRaw.where((group) => group.id != currentGroupId).toList();
  }

  /// Mengembalikan path relatif sebuah folder terhadap root group.
  String folderRelativePath(DocumentGroup group, String? folderId) {
    if (folderId == null || folderId.isEmpty) return '';
    final byId = {for (final f in group.folders) f.id: f};
    final segments = <String>[];
    String? currentId = folderId;
    final visited = <String>{};
    while (currentId != null && currentId.isNotEmpty) {
      if (!visited.add(currentId)) break;
      final folder = byId[currentId];
      if (folder == null) break;
      segments.add(folder.name);
      currentId = folder.parentId;
    }
    return segments.reversed.join('/');
  }

  /// Daftar folder anak langsung di bawah [parentId], diurutkan A-Z.
  List<DocumentFolder> getChildFolders(DocumentGroup group, String? parentId) {
    final normalizedParent = (parentId == null || parentId.isEmpty)
        ? null
        : parentId;
    final children = group.folders
        .where((f) => f.parentId == normalizedParent)
        .toList();
    children.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return children;
  }

  /// Membuat folder baru di dalam [groupId] (di bawah [parentId]).
  /// Mengembalikan `null` jika berhasil, atau pesan error jika gagal.
  Future<String?> createFolder({
    required String groupId,
    String? parentId,
    required String name,
    String icon = '📁',
  }) async {
    final group = allGroupRaw.where((g) => g.id == groupId).firstOrNull;
    if (group == null) return 'Group tidak ditemukan';

    final sanitized = _fileService.sanitizeFolderName(name);
    if (sanitized.isEmpty) return 'Nama folder tidak valid';

    final normalizedParent = (parentId == null || parentId.isEmpty)
        ? null
        : parentId;
    final duplicate = group.folders.any(
      (f) =>
          f.parentId == normalizedParent &&
          f.name.toLowerCase() == sanitized.toLowerCase(),
    );
    if (duplicate) return 'Folder "$sanitized" sudah ada di lokasi ini';

    final newFolder = DocumentFolder(
      id: 'fld_${DateTime.now().millisecondsSinceEpoch}',
      name: sanitized,
      icon: icon,
      parentId: normalizedParent,
      orderIndex: getChildFolders(group, normalizedParent).length,
    );
    group.folders.add(newFolder);
    final relPath = folderRelativePath(group, newFolder.id);
    await _fileService.createFolderDirectory(groupId, relPath);
    await saveGroupDataToFile(group);
    await loadGroupsData();
    return null;
  }

  /// Mengubah nama (dan opsional ikon) folder.
  Future<String?> renameFolder({
    required String groupId,
    required String folderId,
    required String newName,
    String? newIcon,
  }) async {
    final group = allGroupRaw.where((g) => g.id == groupId).firstOrNull;
    if (group == null) return 'Group tidak ditemukan';
    final folder = group.folders.where((f) => f.id == folderId).firstOrNull;
    if (folder == null) return 'Folder tidak ditemukan';

    final sanitized = _fileService.sanitizeFolderName(newName);
    if (sanitized.isEmpty) return 'Nama folder tidak valid';

    final duplicate = group.folders.any(
      (f) =>
          f.id != folderId &&
          f.parentId == folder.parentId &&
          f.name.toLowerCase() == sanitized.toLowerCase(),
    );
    if (duplicate) return 'Folder "$sanitized" sudah ada di lokasi ini';

    final oldPath = folderRelativePath(group, folderId);
    folder.name = sanitized;
    if (newIcon != null && newIcon.isNotEmpty) {
      folder.icon = newIcon;
    }
    final newPath = folderRelativePath(group, folderId);
    if (oldPath != newPath) {
      await _fileService.renameFolderDirectory(groupId, oldPath, newPath);
      await _linkService.updateFolderLinkPrefix(groupId, oldPath, newPath);
    }
    await saveGroupDataToFile(group);
    await loadGroupsData();
    return null;
  }

  /// Memindahkan folder ke [newParentId] di group yang sama.
  Future<String?> moveFolder({
    required String groupId,
    required String folderId,
    String? newParentId,
  }) async {
    final group = allGroupRaw.where((g) => g.id == groupId).firstOrNull;
    if (group == null) return 'Group tidak ditemukan';
    final folder = group.folders.where((f) => f.id == folderId).firstOrNull;
    if (folder == null) return 'Folder tidak ditemukan';

    final normalizedParent = (newParentId == null || newParentId.isEmpty)
        ? null
        : newParentId;
    if (normalizedParent == folderId ||
        _isDescendantFolder(group, ancestorId: folderId, candidateId: normalizedParent)) {
      return 'Tidak dapat memindahkan folder ke dalam dirinya sendiri atau turunannya';
    }

    final duplicate = group.folders.any(
      (f) =>
          f.id != folderId &&
          f.parentId == normalizedParent &&
          f.name.toLowerCase() == folder.name.toLowerCase(),
    );
    if (duplicate) {
      return 'Folder "${folder.name}" sudah ada di folder tujuan';
    }

    final oldPath = folderRelativePath(group, folderId);
    folder.parentId = normalizedParent;
    final newPath = folderRelativePath(group, folderId);
    if (oldPath != newPath) {
      await _fileService.moveFolderDirectory(groupId, oldPath, newPath);
      await _linkService.updateFolderLinkPrefix(groupId, oldPath, newPath);
    }
    await saveGroupDataToFile(group);
    await loadGroupsData();
    return null;
  }

  /// Menghapus folder beserta seluruh subfolder dan berkas fisiknya secara rekursif.
  Future<bool> deleteFolder({
    required String groupId,
    required String folderId,
  }) async {
    final group = allGroupRaw.where((g) => g.id == groupId).firstOrNull;
    if (group == null) return false;
    final relPath = folderRelativePath(group, folderId);
    if (relPath.isEmpty) return false;

    final toRemove = <String>{folderId};
    bool added = true;
    while (added) {
      added = false;
      for (final f in group.folders) {
        if (f.parentId != null &&
            toRemove.contains(f.parentId) &&
            toRemove.add(f.id)) {
          added = true;
        }
      }
    }

    group.folders.removeWhere((f) => toRemove.contains(f.id));
    await _fileService.deleteFolderDirectory(groupId, relPath);
    await _linkService.clearLinksFor(groupId, relPath);
    await saveGroupDataToFile(group);
    await loadGroupsData();
    return true;
  }

  bool _isDescendantFolder(
    DocumentGroup group, {
    required String ancestorId,
    required String? candidateId,
  }) {
    if (candidateId == null) return false;
    final byId = {for (final f in group.folders) f.id: f};
    String? current = candidateId;
    final visited = <String>{};
    while (current != null && current.isNotEmpty) {
      if (current == ancestorId) return true;
      if (!visited.add(current)) break;
      current = byId[current]?.parentId;
    }
    return false;
  }
}

// lib/features/documents/presentation/controllers/documents_controller.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/services/storage_service.dart';
import '../../data/models/document_model.dart';

class DocumentsController extends ChangeNotifier {
  final StorageService storageService = StorageService();

  bool isLoading = false;
  bool isPageEditMode = false;
  bool isSectionEditMode = false;
  bool showHiddenSection = false;
  String searchQuery = '';
  String selectedBaseDir = 'Documents';

  List<DocumentGroup> allGroupRaw = [];
  Map<String, List<DocumentGroup>> groupedVisibleGroup = {};
  Map<String, List<DocumentGroup>> groupedHiddenGroup = {};

  // TAMBAHAN: Menyimpan jumlah file asli per grup
  Map<String, int> groupFileCounts = {};

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

      allGroupRaw = loadedGroups;
      await _countPhysicalFiles(); // Hitung file asli
      _groupData();
    } catch (e) {
      debugPrint("Gagal memuat Document Groups: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // LOGIKA BARU: Menghitung file dalam folder grup fisik (kecuali .json)
  Future<void> _countPhysicalFiles() async {
    groupFileCounts.clear();
    for (var group in allGroupRaw) {
      final dir = Directory('$selectedBaseDir/my_documents/${group.id}');
      if (await dir.exists()) {
        final files = dir
            .listSync()
            .whereType<File>()
            .where((f) => !f.path.endsWith('.json'))
            .toList();
        groupFileCounts[group.id] = files.length;
      } else {
        groupFileCounts[group.id] = 0;
      }
    }
  }

  Future<void> saveGroupDataToFile(DocumentGroup group) async {
    try {
      File file = await storageService.getSpecificDocumentGroupFile(
        selectedBaseDir,
        group.id,
      );
      String jsonStr = jsonEncode(group.toJson());
      await file.writeAsString(jsonStr);

      // Buat folder fisik untuk grup ini jika belum ada
      final dir = Directory('$selectedBaseDir/my_documents/${group.id}');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      await loadGroupsData();
    } catch (e) {
      debugPrint("Gagal menyimpan Document Group: $e");
    }
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
    );
    await saveGroupDataToFile(newGroup);
  }

  Future<void> deleteGroup(DocumentGroup group) async {
    // 1. Hapus JSON konfigurasi
    File targetFile = await storageService.getSpecificDocumentGroupFile(
      selectedBaseDir,
      group.id,
    );
    if (await targetFile.exists()) {
      await targetFile.delete();
    }
    // 2. Hapus Folder Fisik beserta isinya
    Directory groupDir = Directory('$selectedBaseDir/my_documents/${group.id}');
    if (await groupDir.exists()) {
      await groupDir.delete(recursive: true);
    }
    await loadGroupsData();
  }

  // --- SISA FUNGSI SAMA SEPERTI SEBELUMNYA (toggleGroupVisibility, moveGroupToAnotherSection, dll) ---
  Future<void> toggleGroupVisibility(DocumentGroup group) async {
    group.isHidden = !group.isHidden;
    await saveGroupDataToFile(group);
  }

  Future<void> moveGroupToAnotherSection(
    DocumentGroup group,
    String newSection,
  ) async {
    group.sectionCategory = newSection;
    await saveGroupDataToFile(group);
  }

  Future<void> updateMainSectionName(String oldName, String newName) async {
    for (var group in allGroupRaw) {
      if (group.sectionCategory == oldName) {
        group.sectionCategory = newName;
        await saveGroupDataToFile(group);
      }
    }
  }

  Future<void> deleteMainSection(String sectionName) async {
    final groupsToDelete = allGroupRaw
        .where((g) => g.sectionCategory == sectionName)
        .toList();
    for (var group in groupsToDelete) {
      await deleteGroup(group);
    }
  }

  void moveGroupOrder(
    List<DocumentGroup> sectionItems,
    int index,
    int direction,
  ) {
    int newIndex = index + direction;
    if (newIndex < 0 || newIndex >= sectionItems.length) return;
    final temp = sectionItems[index];
    sectionItems[index] = sectionItems[newIndex];
    sectionItems[newIndex] = temp;
    notifyListeners();
  }

  void moveMainSectionOrder(String sectionKey, int direction) {
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
    notifyListeners();
  }
}

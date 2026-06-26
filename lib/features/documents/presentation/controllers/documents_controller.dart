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

      // <--- BARU: Urutkan data berdasarkan orderIndex sesaat setelah diload
      loadedGroups.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

      allGroupRaw = loadedGroups;
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

      final dir = Directory('$selectedBaseDir/my_documents/${group.id}');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    } catch (e) {
      debugPrint("Gagal menyimpan Document Group: $e");
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
    Directory groupDir = Directory('$selectedBaseDir/my_documents/${group.id}');
    if (await groupDir.exists()) {
      await groupDir.delete(recursive: true);
    }
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

  Future<bool> movePhysicalFiles({
    required List<File> filesToMove,
    required String currentGroupId,
    required String targetGroupId,
  }) async {
    if (filesToMove.isEmpty) return false;
    try {
      final String baseDir = await storageService.getBaseDirSetting();
      final Directory targetDir = Directory(
        '$baseDir/my_documents/$targetGroupId',
      );

      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      for (var file in filesToMove) {
        if (await file.exists()) {
          final String fileName = file.path.split('/').last;
          final String targetPath = '${targetDir.path}/$fileName';

          String finalTargetPath = targetPath;
          if (await File(targetPath).exists()) {
            final int lastDot = fileName.lastIndexOf('.');
            final String nameOnly = lastDot != -1
                ? fileName.substring(0, lastDot)
                : fileName;
            final String ext = lastDot != -1 ? fileName.substring(lastDot) : '';
            final String timestamp = DateTime.now().millisecondsSinceEpoch
                .toString()
                .substring(8);
            finalTargetPath = '${targetDir.path}/${nameOnly}_$timestamp$ext';
          }
          await file.rename(finalTargetPath);
        }
      }
      await loadGroupsData();
      return true;
    } catch (e) {
      debugPrint("Gagal memindahkan berkas fisik antar-grup: $e");
      return false;
    }
  }
}

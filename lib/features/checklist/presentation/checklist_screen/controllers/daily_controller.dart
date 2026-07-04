// lib/features/daily/presentation/controllers/daily_controller.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../../core/services/storage_service.dart';
import '../../../data/models/daily_model.dart';

class DailyController extends ChangeNotifier {
  final StorageService _storageService = StorageService();

  // State Variables
  List<ChecklistGroup> allGroupRaw = [];
  List<ChecklistGroup> hiddenGroup = [];
  String selectedBaseDir = 'Documents';
  bool isLoading = true;

  bool isPageEditMode = false;
  bool showHiddenSection = false;
  bool isSectionEditMode = false;

  // State untuk menyimpan text pencarian
  String searchQuery = '';

  // State untuk melacak seksi kosong yang baru ditambahkan secara lokal
  final List<String> _localEmptySections = [];

  final Map<String, List<ChecklistGroup>> groupedVisibleGroup = {};
  final Map<String, List<ChecklistGroup>> groupedHiddenGroup = {};

  // Toggle UI States
  void togglePageEditMode() {
    isPageEditMode = !isPageEditMode;
    notifyListeners();
  }

  void toggleShowHiddenSection() {
    showHiddenSection = !showHiddenSection;
    notifyListeners();
  }

  void toggleSectionEditMode() {
    isSectionEditMode = !isSectionEditMode;
    notifyListeners();
  }

  // Fungsi untuk memperbarui query pencarian
  void updateSearchQuery(String query) {
    searchQuery = query.toLowerCase();
    _processGroupsDisplay();
  }

  // Load Data (Plain Text Mode)
  Future<void> loadGroupsData() async {
    isLoading = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 150));

      selectedBaseDir = await _storageService.getBaseDirSetting();
      List<File> groupFiles = await _storageService.getAllChecklistGroups(
        selectedBaseDir,
      );

      groupFiles.sort((a, b) {
        String nameA = a.path.split('/').last;
        String nameB = b.path.split('/').last;
        return nameA.compareTo(nameB);
      });

      List<ChecklistGroup> loadedGroups = [];

      for (var file in groupFiles) {
        if (!await file.exists()) continue;
        String jsonString = await file.readAsString();
        String fileName = file.path.split('/').last.replaceAll('.json', '');

        try {
          // Langsung parse dari text (tanpa dekripsi otomatis)
          final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
          jsonMap['id'] = fileName; // Force ID

          loadedGroups.add(ChecklistGroup.fromJson(jsonMap));
        } catch (error) {
          debugPrint(
            "Gagal memuat berkas checklist (Mungkin terenkripsi versi lama): $error",
          );

          // Tampilkan mock card untuk berkas korup/lama
          loadedGroups.add(
            ChecklistGroup(
              id: "CORRUPTED_${DateTime.now().millisecondsSinceEpoch}_$fileName",
              groupName: fileName,
              icon: '⚠️',
              sectionCategory: 'Berkas Rusak / Terenkripsi',
              isHidden: false,
              allList: [],
            ),
          );
        }
      }

      allGroupRaw = loadedGroups;
      _processGroupsDisplay();
    } catch (e) {
      isLoading = false;
      notifyListeners();
      debugPrint("Error loading groups: $e");
    }
  }

  // Pengelompokan Tampilan
  void _processGroupsDisplay() {
    final filteredList = allGroupRaw.where((group) {
      if (searchQuery.isEmpty) return true;
      return group.groupName.toLowerCase().contains(searchQuery);
    }).toList();

    final visibleList = filteredList.where((group) => !group.isHidden).toList();
    final hiddenList = filteredList.where((group) => group.isHidden).toList();

    groupedVisibleGroup.clear();
    groupedHiddenGroup.clear();

    for (var section in _localEmptySections) {
      groupedVisibleGroup[section] = [];
    }

    for (var group in visibleList) {
      String kategori = group.sectionCategory.trim().isEmpty
          ? "Lainnya"
          : group.sectionCategory;
      groupedVisibleGroup.putIfAbsent(kategori, () => []);
      groupedVisibleGroup[kategori]!.add(group);
    }

    for (var group in hiddenList) {
      String kategori = group.sectionCategory.trim().isEmpty
          ? "Lainnya"
          : group.sectionCategory;
      groupedHiddenGroup.putIfAbsent(kategori, () => []);
      groupedHiddenGroup[kategori]!.add(group);
    }

    hiddenGroup = hiddenList;
    isLoading = false;
    notifyListeners();
  }

  void addLocalMainSection(String sectionName) {
    if (!_localEmptySections.contains(sectionName)) {
      _localEmptySections.add(sectionName);
    }
    groupedVisibleGroup.putIfAbsent(sectionName, () => []);
    notifyListeners();
  }

  Future<void> createGroupAtSection(
    String groupName,
    String icon,
    String targetMainSection,
  ) async {
    int nextIndex = allGroupRaw.length;
    String newId = "${nextIndex}_hub_${DateTime.now().millisecondsSinceEpoch}";
    ChecklistGroup newGroup = ChecklistGroup(
      id: newId,
      groupName: groupName,
      icon: icon,
      sectionCategory: targetMainSection,
      isHidden: false,
      allList: [],
    );

    _localEmptySections.remove(targetMainSection);

    await saveGroupDataToFile(newGroup);
    await Future.delayed(const Duration(milliseconds: 150));
    await loadGroupsData();
  }

  // Bypass enkripsi - simpan ke plain text
  Future<void> saveGroupDataToFile(ChecklistGroup group) async {
    if (group.id.startsWith("CORRUPTED_")) return;

    try {
      File groupFile = await _storageService.getSpecificGroupFile(
        selectedBaseDir,
        group.id,
      );

      String jsonString = const JsonEncoder.withIndent(
        '  ',
      ).convert(group.toJson());

      // Bypass saveJsonData(enkripsi) -> Tulis langsung sebagai String
      await groupFile.writeAsString(jsonString);
    } catch (e) {
      debugPrint("Gagal menyimpan berkas grup checklist: $e");
    }
  }

  Future<void> toggleGroupVisibility(ChecklistGroup group) async {
    if (group.id.startsWith("CORRUPTED_")) return;
    group.isHidden = !group.isHidden;
    await saveGroupDataToFile(group);
    _processGroupsDisplay();
  }

  Future<void> updateGroup(
    ChecklistGroup group,
    String newName,
    String newIcon,
  ) async {
    if (group.id.startsWith("CORRUPTED_")) return;
    group.groupName = newName;
    group.icon = newIcon;
    await saveGroupDataToFile(group);
    await loadGroupsData();
  }

  Future<void> deleteGroup(ChecklistGroup group) async {
    try {
      String targetId = group.id;
      if (targetId.startsWith("CORRUPTED_")) {
        targetId = targetId.replaceFirst(RegExp(r'CORRUPTED_\d+_'), '');
      }

      File groupFile = await _storageService.getSpecificGroupFile(
        selectedBaseDir,
        targetId,
      );
      if (await groupFile.exists()) {
        await groupFile.delete();
      }
      await loadGroupsData();
    } catch (e) {
      debugPrint("Error deleting group file: $e");
    }
  }

  Future<void> moveGroupOrder(
    List<ChecklistGroup> targetList,
    int currentIndex,
    int direction,
  ) async {
    int newIndex = currentIndex + direction;
    if (newIndex < 0 || newIndex >= targetList.length) return;

    final itemA = targetList[currentIndex];
    final itemB = targetList[newIndex];

    int rawIdxA = allGroupRaw.indexWhere((h) => h.id == itemA.id);
    int rawIdxB = allGroupRaw.indexWhere((h) => h.id == itemB.id);

    if (rawIdxA != -1 && rawIdxB != -1) {
      final temp = allGroupRaw[rawIdxA];
      allGroupRaw[rawIdxA] = allGroupRaw[rawIdxB];
      allGroupRaw[rawIdxB] = temp;
      notifyListeners();

      try {
        for (int i = 0; i < allGroupRaw.length; i++) {
          final currentGroup = allGroupRaw[i];
          if (currentGroup.id.startsWith("CORRUPTED_")) continue;

          File oldFile = await _storageService.getSpecificGroupFile(
            selectedBaseDir,
            currentGroup.id,
          );

          String cleanId = currentGroup.id;
          if (cleanId.contains('_hub_')) {
            cleanId = cleanId.substring(cleanId.indexOf('hub_'));
          }

          String newId = "${i}_$cleanId";
          currentGroup.id = newId;

          File newFile = await _storageService.getSpecificGroupFile(
            selectedBaseDir,
            newId,
          );

          String jsonString = const JsonEncoder.withIndent(
            '  ',
          ).convert(currentGroup.toJson());

          if (await oldFile.exists()) {
            await newFile.writeAsString(jsonString); // Plain text
            if (oldFile.path != newFile.path) {
              await oldFile.delete();
            }
          } else {
            await newFile.writeAsString(jsonString); // Plain text
          }
        }
      } catch (e) {
        debugPrint("Gagal mengatur ulang urutan file checklist: $e");
      }
      await loadGroupsData();
    }
  }

  Future<void> moveGroupToAnotherSection(
    ChecklistGroup group,
    String targetSection,
  ) async {
    if (group.id.startsWith("CORRUPTED_")) return;
    group.sectionCategory = targetSection.isEmpty ? "Lainnya" : targetSection;
    await saveGroupDataToFile(group);
    await loadGroupsData();
  }

  Future<void> updateMainSectionName(
    String oldSectionName,
    String newSectionName,
  ) async {
    if (_localEmptySections.contains(oldSectionName)) {
      int idx = _localEmptySections.indexOf(oldSectionName);
      _localEmptySections[idx] = newSectionName;
    }

    if (groupedVisibleGroup.containsKey(oldSectionName)) {
      final groups = groupedVisibleGroup.remove(oldSectionName) ?? [];
      for (var group in groups) {
        group.sectionCategory = newSectionName;
      }
      groupedVisibleGroup[newSectionName] = groups;
    }

    for (var group in allGroupRaw) {
      if (group.sectionCategory == oldSectionName) {
        group.sectionCategory = newSectionName;
      }
    }

    for (var group in allGroupRaw) {
      if (group.sectionCategory == newSectionName) {
        await saveGroupDataToFile(group);
      }
    }
    await loadGroupsData();
  }

  Future<void> deleteMainSection(String sectionName) async {
    _localEmptySections.remove(sectionName);
    final listGroupDiSeksiIni = groupedVisibleGroup[sectionName] ?? [];
    try {
      for (var group in listGroupDiSeksiIni) {
        String targetId = group.id;
        if (targetId.startsWith("CORRUPTED_")) {
          targetId = targetId.replaceFirst(RegExp(r'CORRUPTED_\d+_'), '');
        }

        File groupFile = await _storageService.getSpecificGroupFile(
          selectedBaseDir,
          targetId,
        );
        if (await groupFile.exists()) {
          await groupFile.delete();
        }
      }
      groupedVisibleGroup.remove(sectionName);
      allGroupRaw.removeWhere((group) => group.sectionCategory == sectionName);
      await loadGroupsData();
    } catch (e) {
      debugPrint("Gagal menghapus seksi kategori beserta filenya: $e");
    }
  }

  Future<void> moveMainSectionOrder(String sectionName, int direction) async {
    final keys = groupedVisibleGroup.keys.toList();
    int currentIndex = keys.indexOf(sectionName);
    int newIndex = currentIndex + direction;

    if (newIndex < 0 || newIndex >= keys.length) return;

    final tempKey = keys[currentIndex];
    keys[currentIndex] = keys[newIndex];
    keys[newIndex] = tempKey;

    List<ChecklistGroup> reorderedRaw = [];
    for (var key in keys) {
      final groupsInSection = allGroupRaw.where((group) {
        String kategori = group.sectionCategory.trim().isEmpty
            ? "Lainnya"
            : group.sectionCategory;
        return kategori == key;
      }).toList();
      reorderedRaw.addAll(groupsInSection);
    }

    allGroupRaw = reorderedRaw;
    _processGroupsDisplay();

    try {
      for (int i = 0; i < allGroupRaw.length; i++) {
        final currentGroup = allGroupRaw[i];
        if (currentGroup.id.startsWith("CORRUPTED_")) continue;

        File oldFile = await _storageService.getSpecificGroupFile(
          selectedBaseDir,
          currentGroup.id,
        );

        String cleanId = currentGroup.id;
        if (cleanId.contains('_hub_')) {
          cleanId = cleanId.substring(cleanId.indexOf('hub_'));
        }

        String newId = "${i}_$cleanId";
        currentGroup.id = newId;

        File newFile = await _storageService.getSpecificGroupFile(
          selectedBaseDir,
          newId,
        );

        String jsonString = const JsonEncoder.withIndent(
          '  ',
        ).convert(currentGroup.toJson());

        if (await oldFile.exists()) {
          await newFile.writeAsString(jsonString); // Plain text
          if (oldFile.path != newFile.path) {
            await oldFile.delete();
          }
        } else {
          await newFile.writeAsString(jsonString); // Plain text
        }
      }
    } catch (e) {
      debugPrint("Gagal mengamankan urutan seksi baru ke disk: $e");
    }

    await loadGroupsData();
  }
}

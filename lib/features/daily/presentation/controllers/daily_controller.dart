// lib/features/daily/presentation/controllers/daily_controller.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/services/storage_service.dart';
import '../../data/models/daily_model.dart';

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

  // Load Data dari Storage
  Future<void> loadGroupsData() async {
    isLoading = true;
    notifyListeners();

    try {
      selectedBaseDir = await _storageService.getBaseDirSetting();
      List<File> groupFiles = await _storageService.getAllChecklistGroups(
        selectedBaseDir,
      );

      // SOLUSI PERMANEN LINUX: Urutkan file berdasarkan nama file secara alfabetis/numerik.
      groupFiles.sort((a, b) {
        String nameA = a.path.split('/').last;
        String nameB = b.path.split('/').last;
        return nameA.compareTo(nameB);
      });

      List<ChecklistGroup> loadedGroups = [];
      for (var file in groupFiles) {
        String jsonString = await file.readAsString();
        final Map<String, dynamic> parsedMap = jsonDecode(jsonString);
        loadedGroups.add(ChecklistGroup.fromJson(parsedMap));
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
    final visibleList = allGroupRaw.where((group) => !group.isHidden).toList();
    final hiddenList = allGroupRaw.where((group) => group.isHidden).toList();

    groupedVisibleGroup.clear();
    groupedHiddenGroup.clear();

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

  // Tambah Seksi Baru Kosong ke UI lokal
  void addLocalMainSection(String sectionName) {
    groupedVisibleGroup.putIfAbsent(sectionName, () => []);
    notifyListeners();
  }

  // Tambah Group Baru ke File
  Future<void> createGroupAtSection(
    String groupName,
    String icon,
    String targetMainSection,
  ) async {
    int nextIndex = allGroupRaw.length;
    String newId = '${nextIndex}_hub_${DateTime.now().millisecondsSinceEpoch}';

    ChecklistGroup newGroup = ChecklistGroup(
      id: newId,
      groupName: groupName,
      icon: icon,
      sectionCategory: targetMainSection,
      isHidden: false,
      allList: [],
    );

    await saveGroupDataToFile(newGroup);
    await loadGroupsData();
  }

  // Simpan Data Group Tunggal ke File JSON
  Future<void> saveGroupDataToFile(ChecklistGroup group) async {
    File groupFile = await _storageService.getSpecificGroupFile(
      selectedBaseDir,
      group.id,
    );
    final String jsonString = const JsonEncoder.withIndent(
      '  ',
    ).convert(group.toJson());
    await _storageService.saveJsonData(groupFile, jsonString);
  }

  // Toggle Visibilitas Sembunyi/Tampil Group
  Future<void> toggleGroupVisibility(ChecklistGroup group) async {
    group.isHidden = !group.isHidden;
    await saveGroupDataToFile(group);
    _processGroupsDisplay();
  }

  // Update Nama dan Ikon Group
  Future<void> updateGroup(
    ChecklistGroup group,
    String newName,
    String newIcon,
  ) async {
    group.groupName = newName;
    group.icon = newIcon;
    await saveGroupDataToFile(group);
    await loadGroupsData();
  }

  // Hapus Berkas Group Permanen
  Future<void> deleteGroup(ChecklistGroup group) async {
    try {
      File groupFile = await _storageService.getSpecificGroupFile(
        selectedBaseDir,
        group.id,
      );
      if (await groupFile.exists()) {
        await groupFile.delete();
      }
      await loadGroupsData();
    } catch (e) {
      debugPrint("Error deleting group file: $e");
    }
  }

  // Tukar Urutan Posisi Group (dan re-index nama berkas di Linux)
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
          File oldFile = await _storageService.getSpecificGroupFile(
            selectedBaseDir,
            currentGroup.id,
          );

          String cleanId = currentGroup.id;
          if (cleanId.contains('_hub_')) {
            cleanId = cleanId.substring(cleanId.indexOf('hub_'));
          }

          String newId = "${i}_$cleanId";
          File newFile = await _storageService.getSpecificGroupFile(
            selectedBaseDir,
            newId,
          );
          currentGroup.id = newId;

          if (await oldFile.exists()) {
            final String jsonString = const JsonEncoder.withIndent(
              '  ',
            ).convert(currentGroup.toJson());
            await newFile.writeAsString(jsonString);
            if (oldFile.path != newFile.path) {
              await oldFile.delete();
            }
          } else {
            final String jsonString = const JsonEncoder.withIndent(
              '  ',
            ).convert(currentGroup.toJson());
            await newFile.writeAsString(jsonString);
          }
        }
      } catch (e) {
        debugPrint("Gagal mengatur ulang urutan file di Linux: $e");
      }

      _processGroupsDisplay();
    }
  }

  // Pindahkan Group ke Seksi Kategori Lain
  Future<void> moveGroupToAnotherSection(
    ChecklistGroup group,
    String targetSection,
  ) async {
    group.sectionCategory = targetSection.isEmpty ? "Lainnya" : targetSection;
    await saveGroupDataToFile(group);
    await loadGroupsData();
  }

  // Ubah Nama Seksi Utama
  Future<void> updateMainSectionName(
    String oldSectionName,
    String newSectionName,
  ) async {
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

  // Hapus Seksi Utama beserta Isinya
  Future<void> deleteMainSection(String sectionName) async {
    final listGroupDiSeksiIni = groupedVisibleGroup[sectionName] ?? [];
    try {
      for (var group in listGroupDiSeksiIni) {
        File groupFile = await _storageService.getSpecificGroupFile(
          selectedBaseDir,
          group.id,
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

  // Ubah Urutan Tampilan Map Seksi Utama di UI
  void moveMainSectionOrder(String sectionName, int direction) {
    final keys = groupedVisibleGroup.keys.toList();
    int currentIndex = keys.indexOf(sectionName);
    int newIndex = currentIndex + direction;

    if (newIndex < 0 || newIndex >= keys.length) return;

    final tempMap = Map<String, List<ChecklistGroup>>.from(groupedVisibleGroup);
    groupedVisibleGroup.clear();

    final tempKey = keys[currentIndex];
    keys[currentIndex] = keys[newIndex];
    keys[newIndex] = tempKey;

    for (var key in keys) {
      groupedVisibleGroup[key] = tempMap[key] ?? [];
    }
    notifyListeners();
  }
}

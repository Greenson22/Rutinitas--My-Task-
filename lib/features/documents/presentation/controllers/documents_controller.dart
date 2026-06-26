// lib/features/documents/presentation/controllers/documents_controller.dart
import 'package:flutter/material.dart';
import '../../data/models/document_model.dart';

class DocumentsController extends ChangeNotifier {
  bool isLoading = false;
  bool isPageEditMode = false;
  bool isSectionEditMode = false;
  bool showHiddenSection = false;
  String searchQuery = '';

  List<DocumentGroup> allGroupRaw = [];
  Map<String, List<DocumentGroup>> groupedVisibleGroup = {};
  Map<String, List<DocumentGroup>> groupedHiddenGroup = {};

  DocumentsController() {
    // Inisialisasi data awal (Mockup atau muat dari storage nantinya)
    _groupData();
  }

  void _groupData() {
    groupedVisibleGroup.clear();
    groupedHiddenGroup.clear();

    for (var group in allGroupRaw) {
      // Filter Pencarian
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

  void createGroupAtSection(String name, String icon, String section) {
    final newGroup = DocumentGroup(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      groupName: name,
      icon: icon,
      sectionCategory: section,
    );
    allGroupRaw.add(newGroup);
    _groupData();
  }

  void updateGroup(DocumentGroup group, String newName, String newIcon) {
    group.groupName = newName;
    group.icon = newIcon;
    _groupData();
  }

  void deleteGroup(DocumentGroup group) {
    allGroupRaw.removeWhere((g) => g.id == group.id);
    _groupData();
  }

  void toggleGroupVisibility(DocumentGroup group) {
    group.isHidden = !group.isHidden;
    _groupData();
  }

  void moveGroupToAnotherSection(DocumentGroup group, String newSection) {
    group.sectionCategory = newSection;
    _groupData();
  }

  void updateMainSectionName(String oldName, String newName) {
    for (var group in allGroupRaw) {
      if (group.sectionCategory == oldName) {
        group.sectionCategory = newName;
      }
    }
    _groupData();
  }

  void deleteMainSection(String sectionName) {
    allGroupRaw.removeWhere((g) => g.sectionCategory == sectionName);
    _groupData();
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
    // Implementasi perpindahan seksi sesuai urutan map (Opsional untuk saat ini)
    notifyListeners();
  }
}

// lib/features/daily/presentation/controllers/daily_controller.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rutinitasku/core/utils/atomic_write_helper.dart';

import '../../../../../core/services/storage_service.dart';
import '../../../data/models/daily_model.dart';
import '../../../../../core/utils/crypto_helper.dart';

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

  // STATE BARU: Mengontrol visibilitas ikon enkripsi sistem di AppBar lokal (Sama seperti Notes)
  bool isGlobalEncryptionEnabled = false;

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
    loadGroupsData(
      showLoading: false,
    ); // Refresh tanpa loading screen saat mengetik
  }

  // MODIFIKASI: Tambah parameter showLoading agar bisa reload diam-diam di background
  Future<void> loadGroupsData({bool showLoading = true}) async {
    if (showLoading) {
      isLoading = true;
      notifyListeners();
    }

    try {
      // BERIKAN JEDA MIKRO: Menjamin penulisan selesai sepenuhnya di disk storage
      selectedBaseDir = await _storageService.getBaseDirSetting();
      List<File> groupFiles = await _storageService.getAllChecklistGroups(
        selectedBaseDir,
      );

      groupFiles.sort((a, b) {
        String nameA = a.path.split('/').last;
        String nameB = b.path.split('/').last;
        return nameA.compareTo(nameB);
      });

      bool isEncrypted = await _storageService.isEncryptionEnabled();
      String? password = await _storageService.getEncryptionPassword();

      // Sinkronisasikan status enkripsi sistem untuk kontrol UI ikon AppBar
      isGlobalEncryptionEnabled = isEncrypted;

      List<ChecklistGroup> loadedGroups = [];

      for (var file in groupFiles) {
        if (!await file.exists()) continue;

        String jsonString = await file.readAsString();
        final trimmedContent = jsonString.trim();
        bool isRawJson =
            trimmedContent.startsWith('{') || trimmedContent.startsWith('[');
        String fileName = file.path.split('/').last.replaceAll('.json', '');

        try {
          if (!isRawJson) {
            if (password != null && password.isNotEmpty) {
              jsonString = CryptoHelper.decrypt(jsonString, password);
            } else {
              throw Exception("Terkunci: Password sistem tidak tersedia.");
            }
          }

          // PERBAIKAN MUTLAK: Ambil JSON objek dan paksa ID internalnya agar menggunakan `fileName` murni
          final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
          jsonMap['id'] = fileName;
          final ChecklistGroup parsedGroup = ChecklistGroup.fromJson(jsonMap);

          // Status pembacaan fisik (apakah terenkrip atau raw json) mendikte status memorinya secara absolut
          parsedGroup.isEncrypted = !isRawJson;

          loadedGroups.add(parsedGroup);
        } catch (error) {
          debugPrint(
            "Gagal memuat atau mendekripsi berkas checklist ${file.path}: $error",
          );
          // TETAP TAMPILKAN SEBAGAI CARD MOCK UNTUK BERKAS RUSAK
          loadedGroups.add(
            ChecklistGroup(
              id: "CORRUPTED_${DateTime.now().millisecondsSinceEpoch}_$fileName",
              groupName: fileName,
              icon: '⚠️',
              sectionCategory:
                  'Berkas Rusak / Terenkripsi', // Seksi otomatis khusus berkas bermasalah
              isHidden: false,
              allList: [],
            ),
          );
        }
      }

      loadedGroups.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      allGroupRaw = loadedGroups;

      // INTEGRASI LOGIKA FILTER DAN PENGELOMPOKAN TAMPILAN
      final filteredList = allGroupRaw.where((group) {
        if (searchQuery.isEmpty) return true;
        return group.groupName.toLowerCase().contains(searchQuery);
      }).toList();

      final visibleList = filteredList
          .where((group) => !group.isHidden)
          .toList();
      final hiddenList = filteredList.where((group) => group.isHidden).toList();

      groupedVisibleGroup.clear();
      groupedHiddenGroup.clear();

      // Kembalikan struktur seksi kosong lokal terlebih dahulu agar tidak hilang saat re-process
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

      if (showLoading) {
        isLoading = false;
      }
      notifyListeners();
    } catch (e) {
      if (showLoading) {
        isLoading = false;
      }
      notifyListeners();
      debugPrint("Error loading groups: $e");
    }
  }

  // Tambah Seksi Baru Kosong ke UI lokal
  void addLocalMainSection(String sectionName) {
    if (!_localEmptySections.contains(sectionName)) {
      _localEmptySections.add(sectionName);
    }
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
    // Format pembuatan ID awal diselaraskan menggunakan nama berkas fisik ter-indeks
    String newId = "${nextIndex}_hub_${DateTime.now().millisecondsSinceEpoch}";

    ChecklistGroup newGroup = ChecklistGroup(
      id: newId,
      groupName: groupName,
      icon: icon,
      sectionCategory: targetMainSection,
      isHidden: false,
      isEncrypted: false,
      orderIndex: nextIndex,
      allList: [],
    );

    // Jika seksi ini diisi group riil, hapus dari daftar seksi kosong lokal karena sudah ada di file sistem
    _localEmptySections.remove(targetMainSection);

    // Tambahkan 'await' agar penulisan selesai utuh ke disk storage
    await saveGroupDataToFile(newGroup);

    // 3. Lakukan pembacaan sekuensial ulang terhadap seluruh file manifest group checklist
    await loadGroupsData(showLoading: false);
  }

  // MODIFIKASI: Mengamankan Enkripsi Spesifik Sesuai Status Grup
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

      if (group.isEncrypted) {
        String? password = await _storageService.getEncryptionPassword();
        if (password != null && password.isNotEmpty) {
          jsonString = CryptoHelper.encrypt(jsonString, password);
        } else {
          group.isEncrypted = false;
          jsonString = const JsonEncoder.withIndent(
            '  ',
          ).convert(group.toJson());
        }
      }

      // GANTI BLOK ATOMIC WRITE LAMA DENGAN HELPER
      await AtomicWriteHelper.writeSafe(
        targetFile: groupFile,
        content: jsonString,
      );
    } catch (e) {
      debugPrint("Gagal menyimpan berkas grup checklist: $e");
    }
  }

  // METODE BARU: Mengubah Status Enkripsi (Toggle) per Group Checklist
  Future<void> toggleGroupEncryption(ChecklistGroup group) async {
    if (group.id.startsWith("CORRUPTED_")) return;
    String? password = await _storageService.getEncryptionPassword();
    if (password == null || password.isEmpty) {
      throw Exception("NO_PASSWORD");
    }
    group.isEncrypted = !group.isEncrypted;
    await saveGroupDataToFile(group);
    await loadGroupsData(showLoading: false);
  }

  // Toggle Visibilitas Sembunyi/Tampil Group
  Future<void> toggleGroupVisibility(ChecklistGroup group) async {
    if (group.id.startsWith("CORRUPTED_")) return;
    group.isHidden = !group.isHidden;
    await saveGroupDataToFile(group);
    await loadGroupsData(showLoading: false);
  }

  // Update Nama dan Ikon Group
  Future<void> updateGroup(
    ChecklistGroup group,
    String newName,
    String newIcon,
  ) async {
    if (group.id.startsWith("CORRUPTED_")) return;
    group.groupName = newName;
    group.icon = newIcon;
    await saveGroupDataToFile(group);
    await loadGroupsData(showLoading: false);
  }

  // MODIFIKASI: Hapus Berkas Group Permanen (Mendukung pembersihan mock ID berkas rusak)
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
      await loadGroupsData(showLoading: false);
    } catch (e) {
      debugPrint("Error deleting group file: $e");
    }
  }

  // PERBAIKAN: Tukar Urutan Posisi Group Secara Instan (Tanpa Loading Screen)
  Future<void> moveGroupOrder(
    List<ChecklistGroup> targetList,
    int currentIndex,
    int direction,
  ) async {
    int newIndex = currentIndex + direction;
    if (newIndex < 0 || newIndex >= targetList.length) return;

    // 1. Tukar posisi grup di dalam list target (tampilan visual seketika)
    final itemA = targetList[currentIndex];
    final itemB = targetList[newIndex];

    targetList[currentIndex] = itemB;
    targetList[newIndex] = itemA;

    int rawIdxA = allGroupRaw.indexWhere((h) => h.id == itemA.id);
    int rawIdxB = allGroupRaw.indexWhere((h) => h.id == itemB.id);

    if (rawIdxA != -1 && rawIdxB != -1) {
      final temp = allGroupRaw[rawIdxA];
      allGroupRaw[rawIdxA] = allGroupRaw[rawIdxB];
      allGroupRaw[rawIdxB] = temp;
    }

    notifyListeners(); // Perbarui UI seketika tanpa loading

    // 2. ROMBAKAN UTAMA: Update nomor orderIndex secara berurutan
    for (int i = 0; i < allGroupRaw.length; i++) {
      if (allGroupRaw[i].id.startsWith("CORRUPTED_")) continue;
      // Cukup ubah angka urutannya saja, JANGAN ubah nama file/ID-nya
      allGroupRaw[i].orderIndex = i;
      // Tulis perubahan ke storage lewat fungsi yang sudah ada
      await saveGroupDataToFile(allGroupRaw[i]);
    }

    // 3. Muat ulang data agar urutan di memori tersinkronisasi murni di background
    await loadGroupsData(showLoading: false);
  }

  // Pindahkan Group ke Seksi Kategori Lain
  Future<void> moveGroupToAnotherSection(
    ChecklistGroup group,
    String targetSection,
  ) async {
    if (group.id.startsWith("CORRUPTED_")) return;
    group.sectionCategory = targetSection.isEmpty ? "Lainnya" : targetSection;
    await saveGroupDataToFile(group);
    await loadGroupsData(showLoading: false);
  }

  // Ubah Nama Seksi Utama
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
    await loadGroupsData(showLoading: false);
  }

  // Hapus Seksi Utama beserta Isinya
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

      await loadGroupsData(showLoading: false);
    } catch (e) {
      debugPrint("Gagal menghapus seksi kategori beserta filenya: $e");
    }
  }

  // PERBAIKAN: Pindah Urutan Seksi Kategori Secara Instan (Tanpa Loading Screen)
  Future<void> moveMainSectionOrder(int currentIndex, int direction) async {
    final keys = groupedVisibleGroup.keys.toList();
    int newIndex = currentIndex + direction;

    if (newIndex < 0 || newIndex >= keys.length) return;

    // 1. Tukar posisi key seksi
    final temp = keys[currentIndex];
    keys[currentIndex] = keys[newIndex];
    keys[newIndex] = temp;

    // 2. Rebuild Map agar UI langsung bereaksi seketika
    final Map<String, List<ChecklistGroup>> newMap = {};
    for (var key in keys) {
      newMap[key] = groupedVisibleGroup[key]!;
    }
    groupedVisibleGroup.clear();
    groupedVisibleGroup.addAll(newMap);
    notifyListeners(); // Refresh UI langsung

    // 3. Simpan urutan baru ke disk secara persisten menggunakan manipulasi orderIndex
    int globalIndex = 0;

    // Perbarui index untuk grup yang terlihat (visible)
    for (String key in keys) {
      final groupsInSection = groupedVisibleGroup[key] ?? [];
      for (var group in groupsInSection) {
        if (group.id.startsWith("CORRUPTED_")) continue;
        group.orderIndex = globalIndex;
        globalIndex++;
        await saveGroupDataToFile(group);
      }
    }

    // Perbarui index untuk grup tersembunyi agar berada di urutan paling akhir
    for (var group in hiddenGroup) {
      if (group.id.startsWith("CORRUPTED_")) continue;
      group.orderIndex = globalIndex;
      globalIndex++;
      await saveGroupDataToFile(group);
    }

    // 4. Muat ulang keseluruhan data dari storage di background (tanpa memunculkan loading spinner)
    await loadGroupsData(showLoading: false);
  }
}

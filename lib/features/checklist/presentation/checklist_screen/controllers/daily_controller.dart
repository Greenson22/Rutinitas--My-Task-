// lib/features/daily/presentation/controllers/daily_controller.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
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
    _processGroupsDisplay();
  }

  // MODIFIKASI UTAMA: Load Data dari Storage (Menghapus auto-encrypt dan hanya mendekripsi bila dikunci)
  Future<void> loadGroupsData() async {
    isLoading = true;
    notifyListeners();

    try {
      // BERIKAN JEDA MIKRO: Menjamin penulisan selesai sepenuhnya di disk storage
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
    // Jalankan filter pencarian jika query diisi
    final filteredList = allGroupRaw.where((group) {
      if (searchQuery.isEmpty) return true;
      return group.groupName.toLowerCase().contains(searchQuery);
    }).toList();

    final visibleList = filteredList.where((group) => !group.isHidden).toList();
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
    isLoading = false;
    notifyListeners();
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
      allList: [],
    );

    // Jika seksi ini diisi group riil, hapus dari daftar seksi kosong lokal karena sudah ada di file sistem
    _localEmptySections.remove(targetMainSection);

    // Tambahkan 'await' agar penulisan selesai utuh ke disk storage
    await saveGroupDataToFile(newGroup);

    // 2. Tambahkan intervensi asinkron (jeda mikro) untuk memastikan IO penulisan selesai utuh
    await Future.delayed(const Duration(milliseconds: 150));

    // 3. Lakukan pembacaan sekuensial ulang terhadap seluruh file manifest group checklist
    await loadGroupsData();
  }

  // MODIFIKASI: Mengamankan Enkripsi Spesifik Sesuai Status Grup
  Future<void> saveGroupDataToFile(ChecklistGroup group) async {
    // Lewati penyimpanan otomatis jika ini adalah berkas korup buatan/mock card
    if (group.id.startsWith("CORRUPTED_")) return;

    try {
      File groupFile = await _storageService.getSpecificGroupFile(
        selectedBaseDir,
        group.id,
      );

      // Konversi ke format JSON biasa
      String jsonString = const JsonEncoder.withIndent(
        '  ',
      ).convert(group.toJson());

      // Jika properti isEncrypted diaktifkan per-grup, terapkan enkripsi
      if (group.isEncrypted) {
        String? password = await _storageService.getEncryptionPassword();
        if (password != null && password.isNotEmpty) {
          jsonString = CryptoHelper.encrypt(jsonString, password);
        } else {
          // Fallback membatalkan status jika password sistem tidak tersedia
          group.isEncrypted = false;
          jsonString = const JsonEncoder.withIndent(
            '  ',
          ).convert(group.toJson());
        }
      }

      // === SOLUSI ANTI KORUP: Menggunakan Atomic Write dengan Temp File Unik ===
      String tempPath =
          '${groupFile.path}_${DateTime.now().microsecondsSinceEpoch}.tmp';
      File tempFile = File(tempPath);

      // Menggunakan writeAsString menggantikan helper saveJsonData jika string sudah diproses manual
      await tempFile.writeAsString(jsonString);

      if (await tempFile.exists()) {
        if (await groupFile.exists()) {
          await groupFile
              .delete(); // Menghindari permission error saat overwrite di OS tertentu
        }
        await tempFile.rename(groupFile.path); // Rename .tmp ke .json
      }
    } catch (e) {
      debugPrint(
        "Gagal menyimpan berkas grup checklist (Atomic Write Error): $e",
      );
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
    _processGroupsDisplay();
  }

  // Toggle Visibilitas Sembunyi/Tampil Group
  Future<void> toggleGroupVisibility(ChecklistGroup group) async {
    if (group.id.startsWith("CORRUPTED_")) return;
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
    if (group.id.startsWith("CORRUPTED_")) return;
    group.groupName = newName;
    group.icon = newIcon;
    await saveGroupDataToFile(group);
    await loadGroupsData();
  }

  // MODIFIKASI: Hapus Berkas Group Permanen (Mendukung pembersihan mock ID berkas rusak)
  Future<void> deleteGroup(ChecklistGroup group) async {
    try {
      String targetId = group.id;
      // Jika berkas rusak yang dihapus, bersihkan prefix mock ID-nya terlebih dahulu
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

  // Tukar Urutan Posisi Group (Juga menangani penulisan ulang aman enkripsi)
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
        String? password = await _storageService.getEncryptionPassword();
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

          if (currentGroup.isEncrypted &&
              password != null &&
              password.isNotEmpty) {
            jsonString = CryptoHelper.encrypt(jsonString, password);
          } else {
            // Jika gagal memperoleh password, amankan tanpa enkripsi
            currentGroup.isEncrypted = false;
            jsonString = const JsonEncoder.withIndent(
              '  ',
            ).convert(currentGroup.toJson());
          }

          // === ATOMIC WRITE ===
          String tempPath =
              '${newFile.path}_${DateTime.now().microsecondsSinceEpoch}.tmp';
          File tempFile = File(tempPath);
          await tempFile.writeAsString(jsonString);

          if (await tempFile.exists()) {
            if (await newFile.exists()) await newFile.delete();
            await tempFile.rename(newFile.path);

            if (oldFile.path != newFile.path && await oldFile.exists()) {
              await oldFile.delete();
            }
          }
        }
      } catch (e) {
        debugPrint("Gagal mengatur ulang urutan file checklist: $e");
      }

      await loadGroupsData(); // Dipastikan loadData dipanggil asinkron utuh agar daftar ID sinkron
    }
  }

  // Pindahkan Group ke Seksi Kategori Lain
  Future<void> moveGroupToAnotherSection(
    ChecklistGroup group,
    String targetSection,
  ) async {
    if (group.id.startsWith("CORRUPTED_")) return;
    group.sectionCategory = targetSection.isEmpty ? "Lainnya" : targetSection;
    await saveGroupDataToFile(group);
    await loadGroupsData();
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
    await loadGroupsData();
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

      await loadGroupsData();
    } catch (e) {
      debugPrint("Gagal menghapus seksi kategori beserta filenya: $e");
    }
  }

  // Mengubah Urutan Seksi Utama secara Asinkron & Permanen ke Disk
  Future<void> moveMainSectionOrder(String sectionName, int direction) async {
    final keys = groupedVisibleGroup.keys.toList();
    int currentIndex = keys.indexOf(sectionName);
    int newIndex = currentIndex + direction;

    if (newIndex < 0 || newIndex >= keys.length) return;

    // 1. Tukar posisi seksi di list kunci lokal
    final tempKey = keys[currentIndex];
    keys[currentIndex] = keys[newIndex];
    keys[newIndex] = tempKey;

    // 2. Susun ulang `allGroupRaw` berdasarkan urutan seksi yang baru
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

    // 3. Update state di memori lokal secara instan
    allGroupRaw = reorderedRaw;
    _processGroupsDisplay();

    // 4. Sinkronisasikan urutan baru ke penyimpanan fisik
    try {
      String? password = await _storageService.getEncryptionPassword();
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

        if (currentGroup.isEncrypted &&
            password != null &&
            password.isNotEmpty) {
          jsonString = CryptoHelper.encrypt(jsonString, password);
        } else {
          currentGroup.isEncrypted = false;
          jsonString = const JsonEncoder.withIndent(
            '  ',
          ).convert(currentGroup.toJson());
        }

        // === ATOMIC WRITE ===
        String tempPath =
            '${newFile.path}_${DateTime.now().microsecondsSinceEpoch}.tmp';
        File tempFile = File(tempPath);
        await tempFile.writeAsString(jsonString);

        if (await tempFile.exists()) {
          if (await newFile.exists()) await newFile.delete();
          await tempFile.rename(newFile.path);

          if (oldFile.path != newFile.path && await oldFile.exists()) {
            await oldFile.delete();
          }
        }
      }
    } catch (e) {
      debugPrint("Gagal mengamankan urutan seksi baru ke disk: $e");
    }

    // 5. Jalankan pemrosesan akhir
    await loadGroupsData();
  }
}

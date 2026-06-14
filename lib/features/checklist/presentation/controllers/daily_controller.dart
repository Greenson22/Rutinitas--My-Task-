// lib/features/daily/presentation/controllers/daily_controller.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/services/storage_service.dart';
import '../../data/models/daily_model.dart';
import '../../../../core/utils/crypto_helper.dart';

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

  // MODIFIKASI UTAMA: Load Data dari Storage dengan Alur Sinkronisasi & Penanganan Fail-Safe
  Future<void> loadGroupsData() async {
    isLoading = true;
    notifyListeners();

    try {
      // BERIKAN JEDA MIKRO: Menjamin penulisan enkripsi massal selesai sepenuhnya di disk storage (Sama seperti Notes)
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
      List<String> autoEncryptedFiles =
          []; // Penampung nama file yang otomatis terenkripsi balik

      for (var file in groupFiles) {
        if (!await file.exists()) continue;
        String jsonString = await file.readAsString();

        final trimmedContent = jsonString.trim();
        bool isRawJson =
            trimmedContent.startsWith('{') || trimmedContent.startsWith('[');
        String fileName = file.path.split('/').last.replaceAll('.json', '');

        try {
          if (isEncrypted && password != null) {
            if (!isRawJson) {
              // Kondisi Normal: File terenkripsi, lakukan dekripsi seperti biasa
              jsonString = CryptoHelper.decrypt(jsonString, password);
            } else {
              // === FITUR SINKRONISASI: SEKUENS OTOMATIS BERKAS BELUM TERENKRIPSI ===
              // Kondisi khusus: Pengaturan Enkripsi AKTIF, namun ditemukan file JSON mentah/polos.
              // Lakukan enkripsi balik secara otomatis ke lokal storage agar sinkron dengan setelan global.
              try {
                final ChecklistGroup parsedGroup = ChecklistGroup.fromJson(
                  jsonDecode(jsonString),
                );
                final String encryptedContent = CryptoHelper.encrypt(
                  const JsonEncoder.withIndent(
                    '  ',
                  ).convert(parsedGroup.toJson()),
                  password,
                );
                await file.writeAsString(encryptedContent);
                autoEncryptedFiles.add(parsedGroup.groupName);
                debugPrint(
                  "Otomatis mengamankan berkas checklist belum terenkripsi: ${file.path}",
                );
              } catch (autoEncryptError) {
                debugPrint(
                  "Gagal mengamankan otomatis berkas mentah checklist: $autoEncryptError",
                );
              }
            }
          }

          loadedGroups.add(ChecklistGroup.fromJson(jsonDecode(jsonString)));
        } catch (error) {
          debugPrint(
            "Gagal memuat atau mendekripsi berkas checklist ${file.path}: $error",
          );

          // TETAP TAMPILKAN SEBAGAI CARD: Tambahkan mock ChecklistGroup dengan penanda ID khusus
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

      // Catatan: Jika Anda ingin memicu SnackBar otomatis dari "autoEncryptedFiles",
      // lakukan pengecekan list tersebut di callback screen setelah loadGroupsData() dipanggil.
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
    String newId = '${nextIndex}_hub_${DateTime.now().millisecondsSinceEpoch}';

    ChecklistGroup newGroup = ChecklistGroup(
      id: newId,
      groupName: groupName,
      icon: icon,
      sectionCategory: targetMainSection,
      isHidden: false,
      allList: [],
    );

    // Jika seksi ini diisi group riil, hapus dari daftar seksi kosong lokal karena sudah ada di file sistem
    _localEmptySections.remove(targetMainSection);

    await saveGroupDataToFile(newGroup);
    await loadGroupsData();
  }

  // MODIFIKASI: Simpan Data Group Tunggal dengan Integrasi Pengaman Enkripsi Global
  Future<void> saveGroupDataToFile(ChecklistGroup group) async {
    // Lewati penyimpanan otomatis jika ini adalah berkas korup buatan/mock card
    if (group.id.startsWith("CORRUPTED_")) return;

    try {
      File groupFile = await _storageService.getSpecificGroupFile(
        selectedBaseDir,
        group.id,
      );

      bool isEncrypted = await _storageService.isEncryptionEnabled();
      String? password = await _storageService.getEncryptionPassword();

      String jsonString = const JsonEncoder.withIndent(
        '  ',
      ).convert(group.toJson());

      // Jika enkripsi sistem aktif, amankan konten string sebelum ditulis ke disk
      if (isEncrypted && password != null) {
        jsonString = CryptoHelper.encrypt(jsonString, password);
      }

      await _storageService.saveJsonData(groupFile, jsonString);
    } catch (e) {
      debugPrint("Gagal menyimpan berkas grup checklist: $e");
    }
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

  // Tukar Urutan Posisi Group
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
        bool isEncrypted = await _storageService.isEncryptionEnabled();
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
          File newFile = await _storageService.getSpecificGroupFile(
            selectedBaseDir,
            newId,
          );
          currentGroup.id = newId;

          String jsonString = const JsonEncoder.withIndent(
            '  ',
          ).convert(currentGroup.toJson());
          if (isEncrypted && password != null) {
            jsonString = CryptoHelper.encrypt(jsonString, password);
          }

          if (await oldFile.exists()) {
            await newFile.writeAsString(jsonString);
            if (oldFile.path != newFile.path) {
              await oldFile.delete();
            }
          } else {
            await newFile.writeAsString(jsonString);
          }
        }
      } catch (e) {
        debugPrint("Gagal mengatur ulang urutan file checklist: $e");
      }

      _processGroupsDisplay();
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

  // IMPLEMENTASI BARU: Mengubah Urutan Seksi Utama secara Asinkron & Permanen ke Disk
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

    // 3. Update state di memori lokal secara instan agar UI terasa responsif
    allGroupRaw = reorderedRaw;
    _processGroupsDisplay();

    // 4. Sinkronisasikan urutan baru ke penyimpanan fisik dengan memperbarui prefix indeks file
    try {
      bool isEncrypted = await _storageService.isEncryptionEnabled();
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

        // Terapkan indeks numerik 'i' baru ke nama file agar urutan tersimpan secara alfabetis saat di-load kembali
        String newId = "${i}_$cleanId";
        File newFile = await _storageService.getSpecificGroupFile(
          selectedBaseDir,
          newId,
        );
        currentGroup.id = newId;

        String jsonString = const JsonEncoder.withIndent(
          '  ',
        ).convert(currentGroup.toJson());
        if (isEncrypted && password != null) {
          jsonString = CryptoHelper.encrypt(jsonString, password);
        }

        if (await oldFile.exists()) {
          await newFile.writeAsString(jsonString);
          if (oldFile.path != newFile.path) {
            await oldFile.delete();
          }
        } else {
          await newFile.writeAsString(jsonString);
        }
      }
    } catch (e) {
      debugPrint("Gagal mengamankan urutan seksi baru ke disk: $e");
    }

    // 5. Jalankan pemrosesan akhir tampilan untuk memastikan data sinkron
    _processGroupsDisplay();
  }
}

// lib/features/task_master/presentation/controllers/task_master_controller.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:rutinitasku/core/utils/atomic_write_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/task_master_rollout.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/crypto_helper.dart';
import '../../../jurnal_aktivitas/data/models/time_log_model.dart';
import '../../data/models/task_model.dart';

class TaskMasterController {
  final StorageService storageService = StorageService();

  // State variables
  List<TaskCategory> visibleCategories = [];
  List<TaskCategory> hiddenCategories = [];
  List<TaskCategory> allCategoriesRaw = [];
  String selectedBaseDir = 'Documents';
  String fullJsonPath = '';
  bool isLoading = true;
  bool isPageEditMode = false;
  bool showHiddenSection = false;
  bool isFileCorrupted = false;
  bool internalSearchMode = false;
  String searchQuery = '';
  String totalJurnalDurationString = "0j";

  final VoidCallback onUpdate;

  TaskMasterController({required this.onUpdate});

  // UBAH: Mengembalikan string berformat "YYYY-MM-DD HH:mm"
  String getTodayDateString() {
    final now = DateTime.now();
    final String datePart =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final String timePart =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    return "$datePart $timePart";
  }

  // HELPER BARU: Mengambil hanya bagian tanggal "YYYY-MM-DD" saja untuk sinkronisasi antarsistem harian
  String _getJustDateString(String fullDateStr) {
    if (fullDateStr.length >= 10) {
      return fullDateStr.substring(0, 10);
    }
    return fullDateStr;
  }

  void togglePageEditMode() {
    isPageEditMode = !isPageEditMode;
    onUpdate();
  }

  void toggleInternalSearchMode() {
    internalSearchMode = !internalSearchMode;
    if (!internalSearchMode) {
      searchQuery = '';
    }
    processCategoriesDisplay();
  }

  void toggleHiddenSection() {
    showHiddenSection = !showHiddenSection;
    onUpdate();
  }

  void clearSearch() {
    internalSearchMode = false;
    isPageEditMode = false;
    searchQuery = '';
    processCategoriesDisplay();
  }

  Future<void> kalkulasiTotalJurnalHariIni() async {
    try {
      // PERBAIKAN: Menggunakan getJurnalFileForMonth agar membaca berkas bulanan yang aktif saat ini
      File fileJurnal = await storageService.getJurnalFileForMonth(
        selectedBaseDir,
        DateTime.now(),
      );

      if (await fileJurnal.exists()) {
        String jsonString = await fileJurnal.readAsString();

        bool isEncrypted = await storageService.isEncryptionEnabled();
        String? password = await storageService.getEncryptionPassword();
        if (isEncrypted &&
            password != null &&
            !jsonString.trim().startsWith('[')) {
          jsonString = CryptoHelper.decrypt(jsonString, password);
        }

        if (jsonString.trim().isNotEmpty) {
          List<dynamic> decodedJson = jsonDecode(jsonString);
          List<TimeLogEntry> logs = decodedJson
              .map((e) => TimeLogEntry.fromJson(e))
              .toList();

          // PERBAIKAN: Gunakan pembanding substring "YYYY-MM-DD" untuk melacak log jurnal hari ini
          String todayDateOnly = _getJustDateString(getTodayDateString());
          final int todayLogIndex = logs.indexWhere(
            (entry) => _getJustDateString(entry.tanggal) == todayDateOnly,
          );

          if (todayLogIndex != -1) {
            final List<TimeLogTask> todayTasks = logs[todayLogIndex].tasks;
            int totalMenit = todayTasks.fold(
              0,
              (sum, task) => sum + task.durasiMenit,
            );

            int jam = totalMenit ~/ 60;
            int menit = totalMenit % 60;

            totalJurnalDurationString = menit > 0
                ? '${jam}j ${menit}m'
                : '${jam}j';
            onUpdate();
            return;
          }
        }
      }
      totalJurnalDurationString = "0j";
      onUpdate();
    } catch (e) {
      debugPrint("Gagal mengkalkulasi total jurnal hari ini: $e");
    }
  }

  Future<void> initStorageAndLoadData({Function(File)? onCorrupted}) async {
    isLoading = true;
    isFileCorrupted = false;
    onUpdate();

    File? jsonFile;
    try {
      final legacyWritesEnabled = await isTaskMasterLegacyWritesEnabled();
      selectedBaseDir = await storageService.getBaseDirSetting();
      jsonFile = await storageService.getTargetJsonFile(
        selectedBaseDir,
        createDirectory: legacyWritesEnabled,
      );
      fullJsonPath = jsonFile.path;

      String jsonString;
      if (legacyWritesEnabled) {
        jsonString = await storageService.loadOrInitializeJson(jsonFile);
      } else {
        if (!await jsonFile.exists()) {
          throw StateError(
            'File Task Master belum ada. Buka Task Master New untuk membuatnya.',
          );
        }
        jsonString = await jsonFile.readAsString();
      }

      bool isEncrypted = await storageService.isEncryptionEnabled();
      String? password = await storageService.getEncryptionPassword();
      if (isEncrypted &&
          password != null &&
          !jsonString.trim().startsWith('{')) {
        jsonString = CryptoHelper.decrypt(jsonString, password);
      }

      final Map<String, dynamic> parsedMap = jsonDecode(jsonString);
      final List<dynamic> catList = parsedMap['categories'] ?? [];
      List<TaskCategory> loadedCategories = catList
          .map((json) => TaskCategory.fromJson(json))
          .toList();

      // PERBAIKAN: Bandingkan hanya bagian tanggalnya ("YYYY-MM-DD") agar countToday berhasil di-reset saat berganti hari
      String todayDateOnly = _getJustDateString(getTodayDateString());
      bool isDataChanged = false;
      for (var category in loadedCategories) {
        for (var task in category.tasks) {
          if (task.date != null && task.date!.isNotEmpty) {
            String taskDateOnly = _getJustDateString(task.date!);
            if (taskDateOnly != todayDateOnly && task.countToday > 0) {
              task.countToday = 0;
              isDataChanged = true;
            }
          }
        }
      }
      allCategoriesRaw = loadedCategories;
      if (isDataChanged) {
        await saveAllCategoriesToFile(shouldRefresh: false);
      }

      await kalkulasiTotalJurnalHariIni();
      processCategoriesDisplay();
    } catch (e) {
      isLoading = false;
      isFileCorrupted = true;
      onUpdate();
      debugPrint("Error loading data: $e");

      if (jsonFile != null && onCorrupted != null) {
        onCorrupted(jsonFile);
      }
    }
  }

  void handleManualUnlockSuccess(List<TaskCategory> categories) async {
    isFileCorrupted = false;
    allCategoriesRaw = categories;
    await kalkulasiTotalJurnalHariIni();
    processCategoriesDisplay();
  }

  Future<void> forceResetNewFile(File jsonFile) async {
    final legacyWritesEnabled = await isTaskMasterLegacyWritesEnabled();
    if (!legacyWritesEnabled) {
      debugPrint(
        'Task Master lama dalam mode baca-saja; buat file baru dilewati.',
      );
      return;
    }
    isLoading = true;
    isFileCorrupted = false;
    onUpdate();
    try {
      bool isEncrypted = await storageService.isEncryptionEnabled();
      String? password = await storageService.getEncryptionPassword();
      String rawJson = jsonEncode({'categories': []});

      if (isEncrypted && password != null) {
        rawJson = CryptoHelper.encrypt(rawJson, password);
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_encrypted', false);
        await prefs.remove('encryption_password');
      }

      // === UBAH DI SINI: Gunakan Atomic Write Safe ===
      await AtomicWriteHelper.writeSafe(targetFile: jsonFile, content: rawJson);
    } catch (e) {
      debugPrint("Gagal membuat/mengeksekusi file baru: $e");
      isFileCorrupted = true;
    } finally {
      await initStorageAndLoadData();
    }
  }

  void processCategoriesDisplay() {
    final filteredCategories = allCategoriesRaw.where((cat) {
      if (searchQuery.isEmpty) return true;
      return cat.name.toLowerCase().contains(searchQuery);
    }).toList();

    visibleCategories = filteredCategories
        .where((cat) => !cat.isHidden)
        .toList();
    hiddenCategories = filteredCategories.where((cat) => cat.isHidden).toList();
    isLoading = false;
    onUpdate();
  }

  void updateSearchQuery(String query) {
    searchQuery = query.trim().toLowerCase();
    processCategoriesDisplay();
  }

  void moveCategoryOrder(
    List<TaskCategory> targetSubList,
    int currentIndex,
    int direction,
  ) async {
    int newIndex = currentIndex + direction;
    if (newIndex < 0 || newIndex >= targetSubList.length) return;

    final itemA = targetSubList[currentIndex];
    final itemB = targetSubList[newIndex];

    int rawIdxA = allCategoriesRaw.indexWhere((cat) => cat.name == itemA.name);
    int rawIdxB = allCategoriesRaw.indexWhere((cat) => cat.name == itemB.name);

    if (rawIdxA != -1 && rawIdxB != -1) {
      final temp = allCategoriesRaw[rawIdxA];
      allCategoriesRaw[rawIdxA] = allCategoriesRaw[rawIdxB];
      allCategoriesRaw[rawIdxB] = temp;

      await saveAllCategoriesToFile(shouldRefresh: false);
      processCategoriesDisplay();
    }
  }

  Future<void> toggleCategoryVisibility(TaskCategory category) async {
    int index = allCategoriesRaw.indexWhere((cat) => cat.name == category.name);
    if (index != -1) {
      allCategoriesRaw[index].isHidden = !allCategoriesRaw[index].isHidden;
      await saveAllCategoriesToFile(shouldRefresh: false);
      processCategoriesDisplay();
    }
  }

  Future<void> addNewCategory(String name, String icon) async {
    final newCategory = TaskCategory(
      name: name,
      icon: icon,
      isHidden: false,
      tasks: [],
    );
    allCategoriesRaw.add(newCategory);
    await saveAllCategoriesToFile();
  }

  Future<void> updateCategory(
    TaskCategory oldCategory,
    String newName,
    String newIcon,
  ) async {
    int idx = allCategoriesRaw.indexWhere(
      (cat) => cat.name == oldCategory.name,
    );
    if (idx != -1) {
      allCategoriesRaw[idx] = allCategoriesRaw[idx].copyWith(
        name: newName,
        icon: newIcon,
      );
      await saveAllCategoriesToFile();
    }
  }

  Future<void> deleteCategory(TaskCategory category) async {
    allCategoriesRaw.removeWhere((cat) => cat.name == category.name);
    await saveAllCategoriesToFile();
  }

  Future<void> updateUbuntuStorage(String newDir) async {
    await storageService.saveBaseDirSetting(newDir);
    await initStorageAndLoadData();
  }

  // --- HAK CIPTA OPTIMISASI DI SINI ---
  Future<bool> incrementTaskCount(TaskItem task, BuildContext context) async {
    final legacyWritesEnabled = await isTaskMasterLegacyWritesEnabled();
    if (!legacyWritesEnabled) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Task Master lama hanya baca. Gunakan Task Master New untuk mencatat progres.',
            ),
          ),
        );
      }
      return false;
    }
    // 1. UPDATE INSTAN KE MEMORI & REAL-TIME REFRESH UI (Tanpa Lag)
    task.count += 1;
    task.countToday += 1;
    task.date =
        getTodayDateString(); // Otomatis menyimpan tanggal beserta jam & menit baru

    // Perbarui UI lokal secara instan agar efek klik terasa instan
    processCategoriesDisplay();

    // 2. JALANKAN PROSES I/O FILE SECARA BACK-GROUND (TIDAK DITUNGGU DENGAN AWAIT)
    saveAllCategoriesToFile(shouldRefresh: false);

    // Proses pencatatan jurnal dijalankan di background
    _addTimeToJurnal(task.id, context);

    return true;
  }

  Future<bool> _addTimeToJurnal(String myTaskId, BuildContext context) async {
    final legacyWritesEnabled = await isTaskMasterLegacyWritesEnabled();
    if (!legacyWritesEnabled) {
      debugPrint(
        'Task Master lama dalam mode baca-saja; penulisan Jurnal dilewati.',
      );
      return false;
    }
    try {
      int minutesToAdd = 30; // Nilai default fallback

      // 1. BACA PENGATURAN DEFAULT DARI jurnal_template.json
      try {
        final File templateFile = File(
          '$selectedBaseDir/jurnal_aktivitas/jurnal_template.json',
        );
        if (await templateFile.exists()) {
          String tempString = await templateFile.readAsString();
          bool isEncrypted = await storageService.isEncryptionEnabled();
          String? password = await storageService.getEncryptionPassword();

          if (isEncrypted &&
              password != null &&
              !tempString.trim().startsWith('{') &&
              !tempString.trim().startsWith('[')) {
            tempString = CryptoHelper.decrypt(tempString, password);
          }

          final dynamic parsed = jsonDecode(tempString);
          if (parsed is Map<String, dynamic> &&
              parsed['settings'] != null &&
              parsed['settings']['default_increment_minutes'] != null) {
            minutesToAdd =
                parsed['settings']['default_increment_minutes'] as int;
          }
        }
      } catch (e) {
        debugPrint("Gagal membaca setting waktu default jurnal: $e");
      }

      // 2. PROSES PENAMBAHAN WAKTU KE JURNAL BULANAN
      // PERBAIKAN UTAMA: Menggunakan getJurnalFileForMonth agar mengarah ke file bulanan yang sama dengan Jurnal AktivitasScreen
      final File JurnalFile = await storageService.getJurnalFileForMonth(
        selectedBaseDir,
        DateTime.now(),
      );

      // Menggunakan inisialisasi aman bawaan storage
      String jsonString = '[]';
      if (await JurnalFile.exists()) {
        jsonString = await JurnalFile.readAsString();
      }

      bool isEncrypted = await storageService.isEncryptionEnabled();
      String? password = await storageService.getEncryptionPassword();
      if (isEncrypted &&
          password != null &&
          !jsonString.trim().startsWith('[')) {
        jsonString = CryptoHelper.decrypt(jsonString, password);
      }
      List<dynamic> decodedJson = [];
      if (jsonString.trim().isNotEmpty) {
        try {
          decodedJson = jsonDecode(jsonString);
        } catch (e) {
          debugPrint("Format berkas JSON jurnal tidak valid: $e");
        }
      }
      List<TimeLogEntry> loadedLogs = decodedJson
          .map((e) => TimeLogEntry.fromJson(e))
          .toList();

      // Pembersihan string pembanding log jurnal harian agar tetap menggunakan dasar "YYYY-MM-DD" saja
      final String fullTodayStr = getTodayDateString();
      final String todayDateOnly = _getJustDateString(fullTodayStr);

      bool hasTodayLog = loadedLogs.any(
        (entry) => _getJustDateString(entry.tanggal) == todayDateOnly,
      );
      if (!hasTodayLog && loadedLogs.isNotEmpty) {
        final lastLog = loadedLogs.last;
        List<TimeLogTask> copiedTasks = lastLog.tasks.map((task) {
          return TimeLogTask(
            id: task.id,
            nama: task.nama,
            durasiMenit: 0,
            kategori: task.kategori,
            // PERBAIKAN: Safely cast to List<String>
            linkedTaskIds: List<String>.from(task.linkedTaskIds),
          );
        }).toList();
        // Simpan log jurnal baru dengan struktur tanggal murni hari ini
        loadedLogs.add(
          TimeLogEntry(tanggal: todayDateOnly, tasks: copiedTasks),
        );
      } else if (loadedLogs.isEmpty) {
        loadedLogs.add(TimeLogEntry(tanggal: todayDateOnly, tasks: []));
      }

      int todayIndex = loadedLogs.indexWhere(
        (entry) => _getJustDateString(entry.tanggal) == todayDateOnly,
      );
      if (todayIndex != -1) {
        bool isUpdated = false;
        String updatedJurnalTaskName = "";
        for (var logTask in loadedLogs[todayIndex].tasks) {
          // PERBAIKAN PENCARIAN RELASI: Cast ke murni List<String> sebelum menggunakan .contains()
          final List<String> safeLinkedIds = List<String>.from(
            logTask.linkedTaskIds,
          );
          if (safeLinkedIds.contains(myTaskId.toString().trim())) {
            logTask.durasiMenit += minutesToAdd;
            isUpdated = true;
            updatedJurnalTaskName = logTask.nama;
            break;
          }
        }
        if (isUpdated) {
          String updatedJsonContent = jsonEncode(
            loadedLogs.map((e) => e.toJson()).toList(),
          );

          // === Enkripsi konten jurnal jika mode keamanan aktif ===
          if (isEncrypted && password != null && password.isNotEmpty) {
            updatedJsonContent = CryptoHelper.encrypt(
              updatedJsonContent,
              password,
            );
          }

          // === Gunakan Atomic Write Safe untuk file Jurnal ===
          await AtomicWriteHelper.writeSafe(
            targetFile: JurnalFile,
            content: updatedJsonContent,
          );

          // Sinkronisasi total durasi setelah penyimpanan background sukses
          await kalkulasiTotalJurnalHariIni();
          if (context.mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Terhubung! "$updatedJurnalTaskName" di Jurnal +$minutesToAdd mnt.',
                ),
                duration: const Duration(seconds: 1),
                backgroundColor: Colors.teal[800],
              ),
            );
          }
          return true;
        }
      }
      // Jika tugas tidak terhubung ke jurnal
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Progress bertambah! (Tugas tidak terhubung ke jurnal)',
            ),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.blueGrey,
          ),
        );
      }
      return false;
    } catch (e) {
      debugPrint("Error updating linked jurnal data: $e");
      return false;
    }
  }

  Future<void> saveAllCategoriesToFile({bool shouldRefresh = true}) async {
    final legacyWritesEnabled = await isTaskMasterLegacyWritesEnabled();
    if (!legacyWritesEnabled) {
      debugPrint(
        'Task Master lama dalam mode baca-saja; penyimpanan kategori dilewati.',
      );
      return;
    }
    final Map<String, dynamic> updatedMap = {
      'categories': allCategoriesRaw.map((cat) => cat.toJson()).toList(),
    };

    String finalJsonContent = shouldRefresh
        ? const JsonEncoder.withIndent('  ').convert(updatedMap)
        : jsonEncode(updatedMap);

    try {
      File jsonFile = await storageService.getTargetJsonFile(selectedBaseDir);

      // === Periksa status enkripsi global sebelum menulis data ===
      bool isEncrypted = await storageService.isEncryptionEnabled();
      String? password = await storageService.getEncryptionPassword();
      if (isEncrypted && password != null && password.isNotEmpty) {
        finalJsonContent = CryptoHelper.encrypt(finalJsonContent, password);
      }

      // Gunakan Atomic Write Safe
      await AtomicWriteHelper.writeSafe(
        targetFile: jsonFile,
        content: finalJsonContent,
      );

      if (shouldRefresh) {
        await initStorageAndLoadData();
      } else {
        processCategoriesDisplay();
      }
    } catch (e) {
      debugPrint("Error saving categories: $e");
    }
  }
}

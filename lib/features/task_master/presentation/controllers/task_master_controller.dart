// lib/features/task_master/presentation/controllers/task_master_controller.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:rutinitasku/core/utils/atomic_write_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  String getTodayDateString() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
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
      File fileJurnal = await storageService.getJurnalJsonFile(selectedBaseDir);

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

          String todayStr = getTodayDateString();
          final int todayLogIndex = logs.indexWhere(
            (entry) => entry.tanggal == todayStr,
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
      selectedBaseDir = await storageService.getBaseDirSetting();
      jsonFile = await storageService.getTargetJsonFile(selectedBaseDir);
      fullJsonPath = jsonFile.path;
      String jsonString = await storageService.loadOrInitializeJson(jsonFile);

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

      String todayStr = getTodayDateString();
      bool isDataChanged = false;
      for (var category in loadedCategories) {
        for (var task in category.tasks) {
          if (task.date != todayStr && task.countToday > 0) {
            task.countToday = 0;
            isDataChanged = true;
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
      allCategoriesRaw[idx] = TaskCategory(
        name: newName,
        icon: newIcon,
        isHidden: oldCategory.isHidden,
        tasks: oldCategory.tasks,
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
    // 1. UPDATE INSTAN KE MEMORI & REAL-TIME REFRESH UI (Tanpa Lag)
    task.count += 1;
    task.countToday += 1;
    task.date = getTodayDateString();

    // Perbarui UI lokal secara instan agar efek klik terasa instan
    processCategoriesDisplay();

    // 2. JALANKAN PROSES I/O FILE SECARA BACK-GROUND (TIDAK DITUNGGU DENGAN AWAIT)
    saveAllCategoriesToFile(shouldRefresh: false);

    // Proses pencatatan jurnal dijalankan di background
    _add30MinutesToJurnal(task.id, context);

    return true;
  }

  Future<bool> _add30MinutesToJurnal(
    String myTaskId,
    BuildContext context,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int minutesToAdd = prefs.getInt('default_increment_minutes') ?? 30;
      final File JurnalFile = await storageService.getJurnalJsonFile(
        selectedBaseDir,
      );
      String jsonString = await storageService.loadOrInitializeJurnalJson(
        JurnalFile,
      );
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
      final String todayStr = getTodayDateString();
      bool hasTodayLog = loadedLogs.any((entry) => entry.tanggal == todayStr);
      if (!hasTodayLog && loadedLogs.isNotEmpty) {
        final lastLog = loadedLogs.last;
        List<TimeLogTask> copiedTasks = lastLog.tasks.map((task) {
          return TimeLogTask(
            id: task.id,
            nama: task.nama,
            durasiMenit: 0,
            kategori: task.kategori,
            linkedTaskIds: task.linkedTaskIds,
          );
        }).toList();
        loadedLogs.add(TimeLogEntry(tanggal: todayStr, tasks: copiedTasks));
      } else if (loadedLogs.isEmpty) {
        loadedLogs.add(TimeLogEntry(tanggal: todayStr, tasks: []));
      }
      int todayIndex = loadedLogs.indexWhere(
        (entry) => entry.tanggal == todayStr,
      );
      if (todayIndex != -1) {
        bool isUpdated = false;
        String updatedJurnalTaskName = "";
        for (var logTask in loadedLogs[todayIndex].tasks) {
          if (logTask.linkedTaskIds.contains(myTaskId)) {
            logTask.durasiMenit += minutesToAdd;
            isUpdated = true;
            updatedJurnalTaskName = logTask.nama;
            break;
          }
        }
        if (isUpdated) {
          // Ganti variabel finalContent agar bisa dimutasi sebelum ditulis
          String updatedJsonContent = jsonEncode(
            loadedLogs.map((e) => e.toJson()).toList(),
          );

          // === PERBAIKAN: Enkripsi konten jurnal jika mode keamanan aktif ===
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
            ScaffoldMessenger.of(
              context,
            ).hideCurrentSnackBar(); // Hapus snackbar lama agar responsif
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Terhubung! "$updatedJurnalTaskName" di Jurnal +$minutesToAdd mnt.',
                ),
                duration: const Duration(
                  seconds: 1,
                ), // Durasi dipersingkat agar bersih
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
    final Map<String, dynamic> updatedMap = {
      'categories': allCategoriesRaw.map((cat) => cat.toJson()).toList(),
    };

    // Gunakan String penampung sementara
    String finalJsonContent = shouldRefresh
        ? const JsonEncoder.withIndent('  ').convert(updatedMap)
        : jsonEncode(updatedMap);

    try {
      File jsonFile = await storageService.getTargetJsonFile(selectedBaseDir);

      // === PERBAIKAN: Periksa status enkripsi global sebelum menulis data ===
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

// lib/features/jurnal_aktivitas/presentation/controllers/jurnal_aktivitas_controller.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/crypto_helper.dart';
import '../../../../core/utils/atomic_write_helper.dart';
import '../../../task_master/data/models/task_model.dart';
import '../../data/models/time_log_model.dart';

class JurnalAktivitasController {
  final StorageService _storageService = StorageService();

  // State yang diekspos ke UI (Hanya menyimpan log bulan yang sedang aktif / ditampilkan)
  List<TimeLogEntry> logs = [];
  List<TaskCategory> allTaskCategories = [];
  String baseDir = '';

  // Karena sekarang memakai per bulan, kita simpan referensi waktu saat ini
  DateTime currentActiveMonth = DateTime.now();

  bool isLoading = true;
  bool isEditMode = false;
  bool isJurnalFileCorrupted = false;

  int defaultIncrementMinutes = 30;

  String getTodayDateString() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  // File target sekarang dinamis berdasarkan bulan aktif
  Future<File> getJurnalFile() async {
    return await _storageService.getJurnalFileForMonth(
      baseDir,
      currentActiveMonth,
    );
  }

  /// Membaca secara dinamis seluruh file log bulanan yang tercakup dalam rentang waktu tertentu.
  /// Digunakan khusus untuk menyuplai data penuh ke Dialog Analitik/Statistik tanpa mengotori
  /// state utama `logs` yang sedang aktif di UI utama.
  Future<List<TimeLogEntry>> loadAllLogsForRange(
    DateTime start,
    DateTime end,
  ) async {
    List<TimeLogEntry> combinedLogs = [];

    // Cari tahu bulan apa saja yang berada di dalam rentang waktu start s.d end
    List<DateTime> monthsToLoad = [];
    DateTime current = DateTime(start.year, start.month, 1);
    DateTime targetEnd = DateTime(end.year, end.month, 1);

    while (!current.isAfter(targetEnd)) {
      monthsToLoad.add(current);
      current = DateTime(current.year, current.month + 1, 1);
    }

    bool isEncrypted = await _storageService.isEncryptionEnabled();
    String? password = await _storageService.getEncryptionPassword();

    for (DateTime monthDate in monthsToLoad) {
      try {
        File monthFile = await _storageService.getJurnalFileForMonth(
          baseDir,
          monthDate,
        );
        if (await monthFile.exists()) {
          String jsonString = await monthFile.readAsString();

          if (isEncrypted &&
              password != null &&
              !jsonString.trim().startsWith('[')) {
            jsonString = CryptoHelper.decrypt(jsonString, password);
          }

          final List<dynamic> decodedJson = jsonDecode(jsonString);
          List<TimeLogEntry> monthlyLogs = decodedJson
              .map((e) => TimeLogEntry.fromJson(e))
              .toList();
          combinedLogs.addAll(monthlyLogs);
        }
      } catch (e) {
        debugPrint(
          "Gagal memuat potongan log bulan ${monthDate.year}-${monthDate.month} untuk statistik: $e",
        );
      }
    }

    return combinedLogs;
  }

  Future<void> loadData({required VoidCallback onNotify}) async {
    isLoading = true;
    isJurnalFileCorrupted = false;
    onNotify();

    File? jsonFile;
    try {
      final prefs = await SharedPreferences.getInstance();
      defaultIncrementMinutes = prefs.getInt('default_increment_minutes') ?? 30;
      baseDir = await _storageService.getBaseDirSetting();

      // 1. CEK & JALANKAN MIGRASI JIKA PERLU
      File oldMaster = await _storageService.getOldMasterJurnalFile(baseDir);
      if (await oldMaster.exists()) {
        await _migrateOldData(oldMaster);
      }

      // 2. MUAT DATA BULAN INI SAJA
      jsonFile = await getJurnalFile();

      String jsonString = '[]';
      if (await jsonFile.exists()) {
        jsonString = await jsonFile.readAsString();
      } else {
        // Jika file bulan ini belum ada, inisialisasi kosong
        await AtomicWriteHelper.writeSafe(targetFile: jsonFile, content: '[]');
      }

      bool isEncrypted = await _storageService.isEncryptionEnabled();
      String? password = await _storageService.getEncryptionPassword();

      if (isEncrypted &&
          password != null &&
          !jsonString.trim().startsWith('[')) {
        jsonString = CryptoHelper.decrypt(jsonString, password);
      }

      final List<dynamic> decodedJson = jsonDecode(jsonString);
      List<TimeLogEntry> loadedLogs = decodedJson
          .map((e) => TimeLogEntry.fromJson(e))
          .toList();

      // Logika menambahkan hari ini jika belum ada (hanya jika currentActiveMonth adalah bulan ini)
      final DateTime now = DateTime.now();
      if (currentActiveMonth.year == now.year &&
          currentActiveMonth.month == now.month) {
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
              linkedTaskIds: List.from(
                task.linkedTaskIds,
              ), // Pastikan deep copy list
            );
          }).toList();
          loadedLogs.add(TimeLogEntry(tanggal: todayStr, tasks: copiedTasks));
          await _saveLogsToFile(jsonFile, loadedLogs, isEncrypted, password);
        } else if (loadedLogs.isEmpty) {
          // Coba ambil dari bulan lalu jika bulan ini masih kosong total
          await _copyTasksFromLastMonth(loadedLogs, todayStr);
          await _saveLogsToFile(jsonFile, loadedLogs, isEncrypted, password);
        }
      }

      await _loadTaskMasterData();
      logs = loadedLogs;
      isLoading = false;
      isJurnalFileCorrupted = false;
      onNotify();
    } catch (e) {
      isLoading = false;
      isJurnalFileCorrupted = true;
      onNotify();
      debugPrint("Error loading jurnal data: $e");
      if (jsonFile != null) throw jsonFile;
    }
  }

  // Fungsi Helper untuk menyalin tugas bulan lalu jika bulan baru saja dimulai
  Future<void> _copyTasksFromLastMonth(
    List<TimeLogEntry> currentLogs,
    String todayStr,
  ) async {
    DateTime lastMonth = DateTime(
      currentActiveMonth.year,
      currentActiveMonth.month - 1,
      1,
    );
    File lastMonthFile = await _storageService.getJurnalFileForMonth(
      baseDir,
      lastMonth,
    );

    if (await lastMonthFile.exists()) {
      try {
        String jsonString = await lastMonthFile.readAsString();
        bool isEncrypted = await _storageService.isEncryptionEnabled();
        String? password = await _storageService.getEncryptionPassword();
        if (isEncrypted &&
            password != null &&
            !jsonString.trim().startsWith('[')) {
          jsonString = CryptoHelper.decrypt(jsonString, password);
        }
        final List<dynamic> decodedJson = jsonDecode(jsonString);
        List<TimeLogEntry> lastMonthLogs = decodedJson
            .map((e) => TimeLogEntry.fromJson(e))
            .toList();

        if (lastMonthLogs.isNotEmpty) {
          final lastLog = lastMonthLogs.last;
          List<TimeLogTask> copiedTasks = lastLog.tasks.map((task) {
            return TimeLogTask(
              id: task.id,
              nama: task.nama,
              durasiMenit: 0,
              kategori: task.kategori,
              linkedTaskIds: List.from(task.linkedTaskIds),
            );
          }).toList();
          currentLogs.add(TimeLogEntry(tanggal: todayStr, tasks: copiedTasks));
          return;
        }
      } catch (e) {
        debugPrint("Gagal menyalin dari bulan lalu: $e");
      }
    }
    // Jika gagal atau tidak ada bulan lalu, buat kosong
    currentLogs.add(TimeLogEntry(tanggal: todayStr, tasks: []));
  }

  // --- SCRIPT MIGRASI OTOMATIS ---
  Future<void> _migrateOldData(File oldMaster) async {
    debugPrint("Memulai migrasi file jurnal lama ke format bulanan...");
    try {
      String jsonString = await oldMaster.readAsString();
      bool isEncrypted = await _storageService.isEncryptionEnabled();
      String? password = await _storageService.getEncryptionPassword();

      if (isEncrypted &&
          password != null &&
          !jsonString.trim().startsWith('[')) {
        jsonString = CryptoHelper.decrypt(jsonString, password);
      }

      final List<dynamic> decodedJson = jsonDecode(jsonString);
      List<TimeLogEntry> allOldLogs = decodedJson
          .map((e) => TimeLogEntry.fromJson(e))
          .toList();

      // Kelompokkan berdasarkan Tahun-Bulan (YYYY-MM)
      Map<String, List<TimeLogEntry>> groupedByMonth = {};

      for (var log in allOldLogs) {
        try {
          DateTime d = DateTime.parse(log.tanggal);
          String monthKey = "${d.year}-${d.month.toString().padLeft(2, '0')}";

          if (!groupedByMonth.containsKey(monthKey)) {
            groupedByMonth[monthKey] = [];
          }
          groupedByMonth[monthKey]!.add(log);
        } catch (e) {
          debugPrint("Lewati tanggal invalid saat migrasi: ${log.tanggal}");
        }
      }

      // Tulis masing-masing kelompok ke file bulanan
      for (var entry in groupedByMonth.entries) {
        // Parse kembali key YYYY-MM untuk membuat objek DateTime
        List<String> parts = entry.key.split('-');
        DateTime monthDate = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          1,
        );

        File monthFile = await _storageService.getJurnalFileForMonth(
          baseDir,
          monthDate,
        );

        // Simpan data
        await _saveLogsToFile(monthFile, entry.value, isEncrypted, password);
        debugPrint("Berhasil migrasi data untuk bulan: ${entry.key}");
      }

      // Rename file master lama agar tidak dijalankan lagi
      String newName = oldMaster.path.replaceAll('.json', '_backup.json');
      await oldMaster.rename(newName);
      debugPrint("Migrasi Selesai! File lama dicadangkan sebagai $newName");
    } catch (e) {
      debugPrint("MIGRASI GAGAL: $e");
    }
  }

  Future<void> _saveLogsToFile(
    File targetFile,
    List<TimeLogEntry> logsToSave,
    bool isEncrypted,
    String? password,
  ) async {
    String finalContent = jsonEncode(
      logsToSave.map((e) => e.toJson()).toList(),
    );
    if (isEncrypted && password != null && password.isNotEmpty) {
      finalContent = CryptoHelper.encrypt(finalContent, password);
    }
    await AtomicWriteHelper.writeSafe(
      targetFile: targetFile,
      content: finalContent,
    );
  }

  Future<void> saveData() async {
    try {
      final File jsonFile = await getJurnalFile(); // Simpan ke file bulan ini
      bool isEncrypted = await _storageService.isEncryptionEnabled();
      String? password = await _storageService.getEncryptionPassword();
      await _saveLogsToFile(jsonFile, logs, isEncrypted, password);
    } catch (e) {
      debugPrint("Error saving jurnal data: $e");
    }
  }

  // --- Fungsi yang lain di bawah ini tetap sama persis seperti kode Anda sebelumnya ---

  Future<void> _loadTaskMasterData() async {
    try {
      File taskFile = await _storageService.getTargetJsonFile(baseDir);
      if (await taskFile.exists()) {
        String jsonString = await taskFile.readAsString();
        bool isEncrypted = await _storageService.isEncryptionEnabled();
        String? password = await _storageService.getEncryptionPassword();
        if (isEncrypted &&
            password != null &&
            !jsonString.trim().startsWith('{')) {
          jsonString = CryptoHelper.decrypt(jsonString, password);
        }
        final Map<String, dynamic> parsedMap = jsonDecode(jsonString);
        final List<dynamic> catList = parsedMap['categories'] ?? [];
        allTaskCategories = catList
            .map((json) => TaskCategory.fromJson(json))
            .toList();
      }
    } catch (e) {
      debugPrint("Error loading task master components: $e");
    }
  }

  Future<void> updateDefaultIncrement(int newMinutes) async {
    defaultIncrementMinutes = newMinutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('default_increment_minutes', newMinutes);
  }

  Future<void> resetAndCreateNewLog(File jsonFile) async {
    isJurnalFileCorrupted = false;
    try {
      bool isEncrypted = await _storageService.isEncryptionEnabled();
      String? password = await _storageService.getEncryptionPassword();
      String rawJson = jsonEncode([]);
      if (isEncrypted && password != null) {
        rawJson = CryptoHelper.encrypt(rawJson, password);
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_encrypted', false);
        await prefs.remove('encryption_password');
      }
      await AtomicWriteHelper.writeSafe(targetFile: jsonFile, content: rawJson);
    } catch (err) {
      debugPrint("Gagal mereset preferensi enkripsi jurnal: $err");
      isJurnalFileCorrupted = true;
    }
  }

  Future<bool> handleManualUnlock(String decryptedContent) async {
    final parsed = jsonDecode(decryptedContent);
    if (parsed is List) {
      logs = parsed.map((e) => TimeLogEntry.fromJson(e)).toList();
      final String todayStr = getTodayDateString();
      bool hasTodayLog = logs.any((entry) => entry.tanggal == todayStr);
      bool isDataChanged = false;
      if (!hasTodayLog && logs.isNotEmpty) {
        final lastLog = logs.last;
        List<TimeLogTask> copiedTasks = lastLog.tasks.map((task) {
          return TimeLogTask(
            id: task.id,
            nama: task.nama,
            durasiMenit: 0,
            kategori: task.kategori,
            linkedTaskIds: task.linkedTaskIds,
          );
        }).toList();
        logs.add(TimeLogEntry(tanggal: todayStr, tasks: copiedTasks));
        isDataChanged = true;
      } else if (logs.isEmpty) {
        logs.add(TimeLogEntry(tanggal: todayStr, tasks: []));
        isDataChanged = true;
      }
      if (isDataChanged) {
        await saveData();
      }
      _loadTaskMasterData();
      isJurnalFileCorrupted = false;
      isLoading = false;
      return true;
    }
    return false;
  }

  bool isTaskTrulyLinked(TimeLogTask jurnalTask) {
    if (jurnalTask.linkedTaskIds.isEmpty) return false;
    for (var category in allTaskCategories) {
      for (var task in category.tasks) {
        if (jurnalTask.linkedTaskIds.contains(task.id)) {
          return true;
        }
      }
    }
    return false;
  }

  void moveTaskOrder(
    List<TimeLogTask> taskList,
    int currentIndex,
    int direction,
  ) {
    int newIndex = currentIndex + direction;
    if (newIndex < 0 || newIndex >= taskList.length) return;
    final temp = taskList[currentIndex];
    taskList[currentIndex] = taskList[newIndex];
    taskList[newIndex] = temp;
  }

  void updateTaskLink(
    TimeLogTask jurnalTask,
    String taskId,
    List<TimeLogTask> todayTasks,
  ) {
    final bool isLinkedWithThis = jurnalTask.linkedTaskIds.contains(taskId);
    if (isLinkedWithThis) {
      jurnalTask.linkedTaskIds.remove(taskId);
    } else {
      for (var t in todayTasks) {
        if (t.id != jurnalTask.id) {
          t.linkedTaskIds.remove(taskId);
        }
      }
      jurnalTask.linkedTaskIds.clear();
      jurnalTask.linkedTaskIds.add(taskId);
    }
  }

  void addActivityDuration(TimeLogTask task, int minutes) {
    final String todayStr = getTodayDateString();
    int todayIdx = logs.indexWhere((entry) => entry.tanggal == todayStr);
    if (todayIdx != -1) {
      int taskIdx = logs[todayIdx].tasks.indexWhere((t) => t.id == task.id);
      if (taskIdx != -1) {
        logs[todayIdx].tasks[taskIdx].durasiMenit += minutes;
        return;
      }
    }
    for (var logEntry in logs.reversed) {
      int idx = logEntry.tasks.indexWhere((t) => t.id == task.id);
      if (idx != -1) {
        logEntry.tasks[idx].durasiMenit += minutes;
        break;
      }
    }
  }

  void addNewActivity(String activityName) {
    final String = getTodayDateString();
    final int todayLogIndex = logs.indexWhere(
      (entry) => entry.tanggal == String,
    );
    if (todayLogIndex != -1) {
      final randomId = Random().nextInt(999999);
      final newTask = TimeLogTask(
        id: randomId,
        nama: activityName,
        durasiMenit: 0,
        linkedTaskIds: [],
      );
      logs[todayLogIndex].tasks.add(newTask);
    }
  }

  void removeActivity(TimeLogTask task) {
    final String todayStr = getTodayDateString();
    final int todayLogIndex = logs.indexWhere(
      (entry) => entry.tanggal == todayStr,
    );
    if (todayLogIndex != -1) {
      logs[todayLogIndex].tasks.removeWhere((t) => t.id == task.id);
    }
  }
}

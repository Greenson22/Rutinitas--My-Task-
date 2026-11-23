// lib/features/jurnal_aktivitas/presentation/controllers/jurnal_aktivitas_controller.dart

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/crypto_helper.dart';
import '../../../../core/utils/atomic_write_helper.dart';
import '../../../task_master/data/models/task_model.dart';
import '../../data/models/time_log_model.dart';

class JurnalAktivitasController {
  final StorageService _storageService;
  final DateTime Function() _clock;

  JurnalAktivitasController({
    StorageService? storageService,
    DateTime Function()? clock,
  })  : _storageService = storageService ?? StorageService(),
        _clock = clock ?? DateTime.now {
    currentActiveMonth = _clock();
  }

  // State yang diekspos ke UI (Menyimpan log bulan aktif & template tugas hari ini)
  List<TimeLogEntry> logs = [];
  List<TaskCategory> allTaskCategories = [];
  String baseDir = '';

  // Referensi waktu saat ini untuk sistem partisi file bulanan
  late DateTime currentActiveMonth;

  bool isLoading = true;
  bool isEditMode = false;
  bool isJurnalFileCorrupted = false;

  int defaultIncrementMinutes = 30;

  String getTodayDateString() {
    final now = _clock();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  // --- HELPER PATH BERKAS ---

  Future<File> getJurnalFile() async {
    return await _storageService.getJurnalFileForMonth(
      baseDir,
      currentActiveMonth,
    );
  }

  // File baru khusus untuk menyimpan daftar kerangka tugas utama (Template) dan Settings
  Future<File> _getTemplateFile() async {
    final Directory jurnalDir = Directory('$baseDir/jurnal_aktivitas');
    if (!await jurnalDir.exists()) await jurnalDir.create(recursive: true);
    return File('${jurnalDir.path}/jurnal_template.json');
  }

  // --- SISTEM PEMUATAN DATA UTAMA ---

  Future<void> loadData({required VoidCallback onNotify}) async {
    isLoading = true;
    isJurnalFileCorrupted = false;
    currentActiveMonth = _clock();
    onNotify();

    File? jsonFile;
    try {
      baseDir = await _storageService.getBaseDirSetting();

      // 1. Cek & jalankan migrasi file lama jika perlu
      File oldMaster = await _storageService.getOldMasterJurnalFile(baseDir);
      if (await oldMaster.exists()) {
        await _migrateOldData(oldMaster);
      }

      bool isEncrypted = await _storageService.isEncryptionEnabled();
      String? password = await _storageService.getEncryptionPassword();

      // 2. Muat Riwayat Bulan Ini (Hanya berisi aktivitas > 0 menit)
      jsonFile = await getJurnalFile();
      String jsonString = '[]';
      if (await jsonFile.exists()) {
        jsonString = await jsonFile.readAsString();
      } else {
        await AtomicWriteHelper.writeSafe(targetFile: jsonFile, content: '[]');
      }

      if (isEncrypted &&
          password != null &&
          !jsonString.trim().startsWith('[')) {
        jsonString = CryptoHelper.decrypt(jsonString, password);
      }

      final List<dynamic> decodedJson = jsonDecode(jsonString);
      List<TimeLogEntry> loadedLogs = decodedJson
          .map((e) => TimeLogEntry.fromJson(e))
          .toList();

      // 3. Muat Template Tugas & Settings dari jurnal_template.json
      File templateFile = await _getTemplateFile();
      List<TimeLogTask> templateTasks = [];
      if (await templateFile.exists()) {
        String tempString = await templateFile.readAsString();
        if (isEncrypted &&
            password != null &&
            !tempString.trim().startsWith('{') &&
            !tempString.trim().startsWith('[')) {
          tempString = CryptoHelper.decrypt(tempString, password);
        }
        try {
          final dynamic decTemp = jsonDecode(tempString);
          if (decTemp is Map<String, dynamic>) {
            // Membaca konfigurasi default waktu dari key 'settings'
            if (decTemp['settings'] != null &&
                decTemp['settings']['default_increment_minutes'] != null) {
              defaultIncrementMinutes =
                  decTemp['settings']['default_increment_minutes'] as int;
            }
            // Membaca daftar tugas dari key 'tasks'
            if (decTemp['tasks'] != null) {
              templateTasks = (decTemp['tasks'] as List<dynamic>)
                  .map((e) => TimeLogTask.fromJson(e as Map<String, dynamic>))
                  .toList();
            }
          } else if (decTemp is List<dynamic>) {
            // Fallback jika file template lama masih berupa array List
            templateTasks = decTemp
                .map((e) => TimeLogTask.fromJson(e as Map<String, dynamic>))
                .toList();
          }
        } catch (_) {}
      } else {
        // Fallback jika file template belum ada (misal: baru update app)
        if (loadedLogs.isNotEmpty) {
          templateTasks = loadedLogs.last.tasks
              .map(
                (t) => TimeLogTask(
                  id: t.id,
                  nama: t.nama,
                  durasiMenit: 0,
                  kategori: t.kategori,
                  linkedTaskIds: List.from(t.linkedTaskIds),
                ),
              )
              .toList();
        }
      }

      // Pastikan template murni bernilai 0 menit
      for (var t in templateTasks) {
        t.durasiMenit = 0;
      }

      // 4. Gabungkan (Merge) Kerangka Template dengan Riwayat Hari Ini
      final DateTime now = _clock();
      if (currentActiveMonth.year == now.year &&
          currentActiveMonth.month == now.month) {
        final String todayStr = getTodayDateString();
        int todayIdx = loadedLogs.indexWhere(
          (entry) => entry.tanggal == todayStr,
        );

        if (todayIdx != -1) {
          // Jika hari ini sudah ada lognya, padukan durasi tersimpan ke dalam struktur template
          List<TimeLogTask> savedTodayTasks = loadedLogs[todayIdx].tasks;
          List<TimeLogTask> mergedTasks = [];

          for (var tTask in templateTasks) {
            var matched = savedTodayTasks.where((s) => s.id == tTask.id);
            if (matched.isNotEmpty) {
              tTask.durasiMenit =
                  matched.first.durasiMenit; // Masukkan durasi aslinya
            }
            mergedTasks.add(tTask);
          }

          // Antisipasi: kembalikan tugas yg ada di riwayat >0 tapi kebetulan sudah terhapus dari template
          for (var sTask in savedTodayTasks) {
            if (!mergedTasks.any((m) => m.id == sTask.id)) {
              mergedTasks.add(sTask);
            }
          }
          loadedLogs[todayIdx].tasks.clear();
          loadedLogs[todayIdx].tasks.addAll(mergedTasks);
        } else {
          // Hari ini belum ada riwayat, siapkan list baru menggunakan template (0 menit)
          List<TimeLogTask> newTodayTasks = templateTasks
              .map(
                (t) => TimeLogTask(
                  id: t.id,
                  nama: t.nama,
                  durasiMenit: 0,
                  kategori: t.kategori,
                  linkedTaskIds: List.from(t.linkedTaskIds),
                ),
              )
              .toList();
          loadedLogs.add(TimeLogEntry(tanggal: todayStr, tasks: newTodayTasks));
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

  // --- SISTEM PENYIMPANAN DATA UTAMA ---

  Future<void> saveData() async {
    try {
      bool isEncrypted = await _storageService.isEncryptionEnabled();
      String? password = await _storageService.getEncryptionPassword();

      // 1. Simpan full list tugas hari ini & settings default waktu sebagai File Template
      await _saveTemplateTasks(isEncrypted, password);

      // 2. Simpan File Riwayat Bulanan
      final File jsonFile = await getJurnalFile();
      List<TimeLogEntry> filteredLogs = [];

      for (var entry in logs) {
        final bool isToday = entry.tanggal == getTodayDateString();

        // PERBAIKAN LOGIKA: Jangan saring/buang durasi 0 menit khusus untuk tugas hari ini.
        List<TimeLogTask> activeTasks = isToday
            ? entry.tasks
            : entry.tasks.where((t) => t.durasiMenit > 0).toList();

        // Simpan ke riwayat bulanan HANYA jika ada aktivitas, ATAU jika itu objek untuk hari ini
        if (activeTasks.isNotEmpty || isToday) {
          filteredLogs.add(
            TimeLogEntry(tanggal: entry.tanggal, tasks: activeTasks),
          );
        }
      }

      await _saveLogsToFile(jsonFile, filteredLogs, isEncrypted, password);
    } catch (e) {
      debugPrint("Error saving jurnal data: $e");
    }
  }

  Future<void> _saveTemplateTasks(bool isEncrypted, String? password) async {
    final String todayStr = getTodayDateString();
    final int todayIdx = logs.indexWhere((e) => e.tanggal == todayStr);

    List<TimeLogTask> cleanTemplate = [];
    if (todayIdx != -1) {
      List<TimeLogTask> todayTasks = logs[todayIdx].tasks;
      // Bersihkan nilainya jadi 0 sebelum disave ke file template
      cleanTemplate = todayTasks
          .map(
            (t) => TimeLogTask(
              id: t.id,
              nama: t.nama,
              durasiMenit: 0,
              kategori: t.kategori,
              linkedTaskIds: List.from(t.linkedTaskIds),
            ),
          )
          .toList();
    }

    File templateFile = await _getTemplateFile();

    // STRUKTUR BARU MAP: Memisah settings agar tidak dibaca sebagai tugas
    Map<String, dynamic> templateData = {
      'settings': {'default_increment_minutes': defaultIncrementMinutes},
      'tasks': cleanTemplate.map((e) => e.toJson()).toList(),
    };

    String finalContent = jsonEncode(templateData);

    if (isEncrypted && password != null && password.isNotEmpty) {
      finalContent = CryptoHelper.encrypt(finalContent, password);
    }
    await AtomicWriteHelper.writeSafe(
      targetFile: templateFile,
      content: finalContent,
    );
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

  // --- STATISTIK & ANALITIK ---

  Future<List<TimeLogEntry>> loadAllLogsForRange(
    DateTime start,
    DateTime end,
  ) async {
    List<TimeLogEntry> combinedLogs = [];
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
        debugPrint("Gagal memuat potongan log bulan untuk statistik: $e");
      }
    }
    return combinedLogs;
  }

  // --- SCRIPT MIGRASI OTOMATIS (MENDUKUNG FILTERING 0 MENIT) ---

  Future<void> _migrateOldData(File oldMaster) async {
    debugPrint(
      "Memulai migrasi file jurnal lama ke format bulanan dan template...",
    );
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

      // Coba ekstrak data terbaru sebagai inisialisasi Template pertama kalinya
      if (allOldLogs.isNotEmpty) {
        List<TimeLogTask> initialTemplate = allOldLogs.last.tasks
            .map(
              (t) => TimeLogTask(
                id: t.id,
                nama: t.nama,
                durasiMenit: 0,
                kategori: t.kategori,
                linkedTaskIds: List.from(t.linkedTaskIds),
              ),
            )
            .toList();
        File templateFile = await _getTemplateFile();

        // Sesuaikan inisialisasi migrasi dengan objek map baru
        Map<String, dynamic> templateData = {
          'settings': {'default_increment_minutes': defaultIncrementMinutes},
          'tasks': initialTemplate.map((e) => e.toJson()).toList(),
        };

        String tContent = jsonEncode(templateData);
        if (isEncrypted && password != null && password.isNotEmpty) {
          tContent = CryptoHelper.encrypt(tContent, password);
        }
        await AtomicWriteHelper.writeSafe(
          targetFile: templateFile,
          content: tContent,
        );
      }

      Map<String, List<TimeLogEntry>> groupedByMonth = {};
      for (var log in allOldLogs) {
        try {
          // Buang nilai 0 menit pada data lampau untuk menghemat memori
          List<TimeLogTask> filteredTasks = log.tasks
              .where((t) => t.durasiMenit > 0)
              .toList();

          DateTime d = DateTime.parse(log.tanggal);
          String monthKey = "${d.year}-${d.month.toString().padLeft(2, '0')}";

          if (!groupedByMonth.containsKey(monthKey)) {
            groupedByMonth[monthKey] = [];
          }
          groupedByMonth[monthKey]!.add(
            TimeLogEntry(tanggal: log.tanggal, tasks: filteredTasks),
          );
        } catch (e) {
          debugPrint("Lewati tanggal invalid saat migrasi: ${log.tanggal}");
        }
      }

      for (var entry in groupedByMonth.entries) {
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
        await _saveLogsToFile(monthFile, entry.value, isEncrypted, password);
      }

      String newName = oldMaster.path.replaceAll('.json', '_backup.json');
      await oldMaster.rename(newName);
      debugPrint("Migrasi Selesai! File lama dicadangkan sebagai $newName");
    } catch (e) {
      debugPrint("MIGRASI GAGAL: $e");
    }
  }

  // --- LOGIKA UTILITAS LAINNYA ---

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
    // Mengamankan pembaruan langsung ke file lokal
    bool isEncrypted = await _storageService.isEncryptionEnabled();
    String? password = await _storageService.getEncryptionPassword();
    await _saveTemplateTasks(isEncrypted, password);
  }

  Future<void> resetAndCreateNewLog(File jsonFile) async {
    isJurnalFileCorrupted = false;
    try {
      bool isEncrypted = await _storageService.isEncryptionEnabled();
      String? password = await _storageService.getEncryptionPassword();
      String rawJson = jsonEncode([]);
      if (isEncrypted && password != null) {
        rawJson = CryptoHelper.encrypt(rawJson, password);
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
      isJurnalFileCorrupted = false;
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
    final String todayStr = getTodayDateString();
    final int todayLogIndex = logs.indexWhere(
      (entry) => entry.tanggal == todayStr,
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

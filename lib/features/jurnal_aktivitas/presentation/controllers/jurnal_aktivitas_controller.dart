// lib/features/jurnal_aktivitas/presentation/controllers/jurnal_aktivitas_controller.dart

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/crypto_helper.dart';
import '../../../task_master/data/models/task_model.dart';
import '../../data/models/time_log_model.dart';

class JurnalAktivitasController {
  final StorageService _storageService = StorageService();

  // State yang diekspos ke UI
  List<TimeLogEntry> logs = [];
  List<TaskCategory> allTaskCategories = [];
  String baseDir = '';
  String fullJsonPath = '';

  bool isLoading = true;
  bool isEditMode = false;
  bool isJurnalFileCorrupted = false;

  // Pengaturan waktu default dinamis (dalam menit)
  int defaultIncrementMinutes = 30;

  String getTodayDateString() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  Future<File> getJurnalFile() async {
    return await _storageService.getJurnalJsonFile(baseDir);
  }

  Future<void> loadData({required VoidCallback onNotify}) async {
    isLoading = true;
    isJurnalFileCorrupted = false;
    onNotify();

    File? jsonFile;
    try {
      // Muat durasi default yang disimpan user dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      defaultIncrementMinutes = prefs.getInt('default_increment_minutes') ?? 30;

      baseDir = await _storageService.getBaseDirSetting();
      jsonFile = await _storageService.getJurnalJsonFile(baseDir);
      fullJsonPath = jsonFile.path;

      if (!await jsonFile.exists()) {
        await jsonFile.create(recursive: true);
        await jsonFile.writeAsString('[]');
      }

      String jsonString = await jsonFile.readAsString();

      // Fallback: Jika pengguna baru saja mematikan enkripsi tapi file lama masih terkunci
      // dan password masih ada di memori session
      if (!jsonString.trim().startsWith('[')) {
        String? password = await _storageService.getEncryptionPassword();
        if (password != null) {
          try {
            jsonString = CryptoHelper.decrypt(jsonString, password);
          } catch (_) {
            // Akan dilempar ke error (corrupted) jika tetap gagal
          }
        }
      }

      final List<dynamic> decodedJson = jsonDecode(jsonString);
      List<TimeLogEntry> loadedLogs = decodedJson
          .map((e) => TimeLogEntry.fromJson(e))
          .toList();

      final String todayStr = getTodayDateString();
      bool hasTodayLog = loadedLogs.any((entry) => entry.tanggal == todayStr);

      if (!hasTodayLog && loadedLogs.isNotEmpty) {
        final lastLog = loadedLogs.last;
        // Salin tugas dari hari terakhir yang tercatat, reset durasinya ke 0
        List<TimeLogTask> copiedTasks = lastLog.tasks.map((task) {
          return TimeLogTask(
            id: task.id,
            nama: task.nama,
            durasiMenit: 0,
            kategori: task.kategori,
            linkedTaskIds: task.linkedTaskIds,
          );
        }).toList();

        final todayEntry = TimeLogEntry(tanggal: todayStr, tasks: copiedTasks);
        loadedLogs.add(todayEntry);

        final String jsonContent = jsonEncode(
          loadedLogs.map((e) => e.toJson()).toList(),
        );
        // PERBAIKAN: Tulis langsung sebagai plain-text
        await jsonFile.writeAsString(jsonContent);
      } else if (loadedLogs.isEmpty) {
        loadedLogs.add(TimeLogEntry(tanggal: todayStr, tasks: []));
        final String jsonContent = jsonEncode(
          loadedLogs.map((e) => e.toJson()).toList(),
        );
        // PERBAIKAN: Tulis langsung sebagai plain-text
        await jsonFile.writeAsString(jsonContent);
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
      if (jsonFile != null) {
        throw jsonFile; // Lempar file ke screen agar UI bisa menampilkan dialog recovery
      }
    }
  }

  Future<void> _loadTaskMasterData() async {
    try {
      File taskFile = await _storageService.getTargetJsonFile(baseDir);
      if (await taskFile.exists()) {
        String jsonString = await taskFile.readAsString();

        // PERBAIKAN: Task Master sudah menjadi plain text murni, langsung parse
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

  Future<void> saveData() async {
    try {
      final File jsonFile = await _storageService.getJurnalJsonFile(baseDir);
      final String jsonContent = jsonEncode(
        logs.map((e) => e.toJson()).toList(),
      );

      // PERBAIKAN: Bypass proses saveJsonData() yang mengenkripsi, tulis String mentah langsung
      await jsonFile.writeAsString(jsonContent);
    } catch (e) {
      debugPrint("Error saving jurnal data: $e");
    }
  }

  // Menyimpan preferensi durasi penambahan waktu baru dari user
  Future<void> updateDefaultIncrement(int newMinutes) async {
    defaultIncrementMinutes = newMinutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('default_increment_minutes', newMinutes);
  }

  Future<void> resetAndCreateNewLog(File jsonFile) async {
    isJurnalFileCorrupted = false;
    try {
      String rawJson = jsonEncode([]);
      // PERBAIKAN: Tulis reset secara plain-text murni
      await jsonFile.writeAsString(rawJson);
    } catch (err) {
      debugPrint("Gagal mereset jurnal: $err");
      isJurnalFileCorrupted = true;
    }
  }

  bool handleManualUnlock(String decryptedContent) {
    try {
      final parsed = jsonDecode(decryptedContent);
      if (parsed is List) {
        logs = parsed.map((e) => TimeLogEntry.fromJson(e)).toList();

        final String todayStr = getTodayDateString();
        bool hasTodayLog = logs.any((entry) => entry.tanggal == todayStr);

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
        } else if (logs.isEmpty) {
          logs.add(TimeLogEntry(tanggal: todayStr, tasks: []));
        }

        _loadTaskMasterData();

        isJurnalFileCorrupted = false;
        isLoading = false;
        return true;
      }
    } catch (_) {}
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
      // Pastikan task master target hanya terhubung dengan satu jurnal pada hari yang sama
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

    // 1. Coba cari di log hari ini terlebih dahulu agar aman dan akurat
    int todayIdx = logs.indexWhere((entry) => entry.tanggal == todayStr);
    if (todayIdx != -1) {
      int taskIdx = logs[todayIdx].tasks.indexWhere((t) => t.id == task.id);
      if (taskIdx != -1) {
        logs[todayIdx].tasks[taskIdx].durasiMenit += minutes;
        return; // Selesai, langsung keluar dari fungsi
      }
    }

    // 2. Fallback: Jika tidak ketemu di hari ini, cari dari urutan paling baru (reversed)
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

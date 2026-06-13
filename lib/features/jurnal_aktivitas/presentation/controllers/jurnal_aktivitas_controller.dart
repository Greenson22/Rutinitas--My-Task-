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
      baseDir = await _storageService.getBaseDirSetting();
      jsonFile = await _storageService.getJurnalJsonFile(baseDir);
      fullJsonPath = jsonFile.path;

      String jsonString = await _storageService.loadOrInitializeJurnalJson(
        jsonFile,
      );
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
        final todayEntry = TimeLogEntry(tanggal: todayStr, tasks: copiedTasks);
        loadedLogs.add(todayEntry);
        final String jsonContent = jsonEncode(
          loadedLogs.map((e) => e.toJson()).toList(),
        );
        await _storageService.saveJsonData(jsonFile, jsonContent);
      } else if (loadedLogs.isEmpty) {
        loadedLogs.add(TimeLogEntry(tanggal: todayStr, tasks: []));
        final String jsonContent = jsonEncode(
          loadedLogs.map((e) => e.toJson()).toList(),
        );
        await _storageService.saveJsonData(jsonFile, jsonContent);
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
        throw jsonFile; // Lemparkan berkas ke UI untuk memicu dialog error
      }
    }
  }

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

  Future<void> saveData() async {
    try {
      final File jsonFile = await _storageService.getJurnalJsonFile(baseDir);
      final String jsonContent = jsonEncode(
        logs.map((e) => e.toJson()).toList(),
      );
      await _storageService.saveJsonData(jsonFile, jsonContent);
    } catch (e) {
      debugPrint("Error saving jurnal data: $e");
    }
  }

  Future<void> resetAndCreateNewLog(File jsonFile) async {
    isJurnalFileCorrupted = false;
    await jsonFile.writeAsString(jsonEncode([]));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_encrypted', false);
      await prefs.remove('encryption_password');
    } catch (err) {
      debugPrint("Gagal mereset preferensi enkripsi jurnal: $err");
    }
  }

  bool handleManualUnlock(String decryptedContent) {
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

  void addActivityDuration30Minutes(TimeLogTask task) {
    for (var logEntry in logs) {
      int idx = logEntry.tasks.indexWhere((t) => t.id == task.id);
      if (idx != -1) {
        logEntry.tasks[idx].durasiMenit += 30;
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

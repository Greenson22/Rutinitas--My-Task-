// lib/core/services/storage_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/default_json.dart';

class StorageService {
  static const String _keyBaseDir = 'ubuntu_base_dir';

  // MODIFIKASI: Menyesuaikan base directory untuk Android secara otomatis
  Future<String> getBaseDirSetting() async {
    if (!kIsWeb && Platform.isAndroid) {
      // Jika di Android, ambil path internal documents app
      final directory = await getApplicationDocumentsDirectory();
      return directory.path;
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBaseDir) ?? 'Documents';
  }

  Future<void> saveBaseDirSetting(String value) async {
    // Di Android, kita bisa mengunci agar tidak bisa diubah sembarangan jika ingin aman
    if (!kIsWeb && Platform.isAndroid) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBaseDir, value);
  }

  Future<File> getTargetJsonFile(String baseDirSetting) async {
    final Directory myTaskDir = Directory('$baseDirSetting/mytask');

    if (!await myTaskDir.exists()) {
      await myTaskDir.create(recursive: true);
    }

    return File('${myTaskDir.path}/my_tasks.json');
  }

  Future<String> loadOrInitializeJson(File jsonFile) async {
    if (!await jsonFile.exists()) {
      await jsonFile.writeAsString(DefaultJson.content);
    }
    return await jsonFile.readAsString();
  }

  Future<void> saveJsonData(File jsonFile, String jsonContent) async {
    await jsonFile.writeAsString(jsonContent);
  }

  // =========================================================================
  // === CHECKLIST HUB STORAGE ===
  // =========================================================================

  Future<Directory> getChecklistDir(String baseDirSetting) async {
    final Directory checklistDir = Directory('$baseDirSetting/my_checklist');
    if (!await checklistDir.exists()) {
      await checklistDir.create(recursive: true);
    }
    return checklistDir;
  }

  Future<List<File>> getAllChecklistHubs(String baseDirSetting) async {
    final Directory checklistDir = await getChecklistDir(baseDirSetting);
    // Modifikasi listSync() menjadi try-catch aman
    try {
      List<FileSystemEntity> files = checklistDir.listSync();
      return files
          .whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<File> getSpecificHubFile(String baseDirSetting, String hubId) async {
    final Directory checklistDir = await getChecklistDir(baseDirSetting);
    return File('${checklistDir.path}/$hubId.json');
  }

  // =========================================================================
  // === JURNAL AKTIVITAS STORAGE ===
  // =========================================================================

  Future<File> getJurnalJsonFile(String baseDirSetting) async {
    final Directory jurnalDir = Directory('$baseDirSetting/jurnal_aktivitas');

    if (!await jurnalDir.exists()) {
      await jurnalDir.create(recursive: true);
    }

    return File('${jurnalDir.path}/time_log.json');
  }

  Future<String> loadOrInitializeJurnalJson(File jsonFile) async {
    if (!await jsonFile.exists()) {
      const String defaultJurnalContent = '[]';
      await jsonFile.writeAsString(defaultJurnalContent);
    }
    return await jsonFile.readAsString();
  }
}

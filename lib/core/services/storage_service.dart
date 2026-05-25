// lib/core/services/storage_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/default_json.dart';

class StorageService {
  static const String _keyBaseDir = 'ubuntu_base_dir';

  Future<String> getBaseDirSetting() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBaseDir) ?? 'Documents';
  }

  Future<void> saveBaseDirSetting(String value) async {
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
  // === TAMBAHAN UNTUK FITUR DAILY (MENYIMPAN DI SEBELAH FOLDER MYTASK) ===
  // =========================================================================

  Future<File> getDailyJsonFile(String baseDirSetting) async {
    // Membuat folder 'daily' sejajar dengan folder 'mytask'
    final Directory dailyDir = Directory('$baseDirSetting/daily');

    if (!await dailyDir.exists()) {
      await dailyDir.create(recursive: true);
    }

    return File('${dailyDir.path}/my_rutinitas.json');
  }

  Future<String> loadOrInitializeDailyJson(File jsonFile) async {
    if (!await jsonFile.exists()) {
      // Menginisialisasi dengan template JSON kosong/bawaan sesuai struktur user
      const String defaultDailyContent = '''
{
  "topics": "Rutinitas",
  "subjects": []
}
''';
      await jsonFile.writeAsString(defaultDailyContent);
    }
    return await jsonFile.readAsString();
  }
}

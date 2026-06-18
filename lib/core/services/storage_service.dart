// lib/core/services/storage_service.dart

import 'dart:async'; // <-- TAMBAHAN: Dibutuhkan untuk Timer
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // <-- TAMBAHAN: Untuk ValueNotifier
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/default_json.dart';
import '../utils/crypto_helper.dart';

class StorageService {
  static const String _keyBaseDirRelease = 'ubuntu_base_dir';
  static const String _keyBaseDirDebug = 'ubuntu_base_dir_debug';
  static const String _keyIpHistory = 'sharing_ip_history';

  // Key untuk konfigurasi keamanan enkripsi
  static const String _keyIsEncrypted = 'is_encrypted';
  static const String _keyEncryptionPassword = 'encryption_password';
  static const String _keyLastRestoreInfo = 'last_restore_info';

  static const String _keyRememberPassword = 'remember_password';
  static const String _keyPasswordTimeout =
      'password_timeout'; // <-- TAMBAHAN: Key batas waktu sesi

  static String? sessionPassword;

  // --- TAMBAHAN BARU: Timer dan Notifier Kedaluwarsa ---
  static Timer? sessionTimer;
  static final ValueNotifier<String?> sessionExpiredNotifier =
      ValueNotifier<String?>(null);

  String _getBaseDirKey() {
    return kDebugMode ? _keyBaseDirDebug : _keyBaseDirRelease;
  }

  // =========================================================================
  // === HELPER BATAS WAKTU & SESI (TIMER) ===
  // =========================================================================

  Future<int> getPasswordTimeout() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyPasswordTimeout) ?? 1; // Default 1 Menit
  }

  Future<void> setPasswordTimeout(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyPasswordTimeout, minutes);
    await restartSessionTimer();
  }

  Future<void> restartSessionTimer() async {
    sessionTimer?.cancel();

    final prefs = await SharedPreferences.getInstance();
    bool isEncrypted = prefs.getBool(_keyIsEncrypted) ?? false;

    // Jika fitur enkripsi mati, tidak perlu menyalakan timer
    if (!isEncrypted) return;

    int minutes = prefs.getInt(_keyPasswordTimeout) ?? 1;

    // Jika lebih dari 0, berarti bukan Manual. Nyalakan hitung mundur.
    if (minutes > 0) {
      sessionTimer = Timer(Duration(minutes: minutes), () async {
        sessionPassword = null;
        await prefs.remove(_keyEncryptionPassword);
        await prefs.setBool(_keyRememberPassword, false);
        // Picu notifikasi agar PasswordGate mengambil alih layar
        sessionExpiredNotifier.value =
            'Waktu sesi telah habis ($minutes Menit). Silakan masukkan kata sandi kembali.';
      });
    }
  }

  static Future<void> lockManually() async {
    sessionTimer?.cancel();
    sessionPassword = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyEncryptionPassword);
    await prefs.setBool(_keyRememberPassword, false);
    sessionExpiredNotifier.value = 'Aplikasi berhasil dikunci secara manual.';
  }

  Future<bool> isRememberPasswordEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRememberPassword) ?? false;
  }

  Future<void> setRememberPassword(
    bool value, {
    String? currentPassword,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRememberPassword, value);

    if (value) {
      String? pwd =
          currentPassword ??
          sessionPassword ??
          prefs.getString(_keyEncryptionPassword);
      if (pwd != null) {
        await prefs.setString(_keyEncryptionPassword, pwd);
      }
    } else {
      String? existingPwd = prefs.getString(_keyEncryptionPassword);
      if (existingPwd != null) sessionPassword = existingPwd;

      await prefs.remove(_keyEncryptionPassword);
    }
  }

  // =========================================================================
  // === HELPER STATUS RESTORE TERAKHIR (PERSISTEN) ===
  // =========================================================================

  Future<void> saveLastRestoreInfo(String jsonString) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastRestoreInfo, jsonString);
  }

  Future<String?> getLastRestoreInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastRestoreInfo);
  }

  // =========================================================================
  // === HELPER KEAMANAN & STATUS ENKRIPSI ===
  // =========================================================================

  Future<bool> isEncryptionEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsEncrypted) ?? false;
  }

  Future<String?> getEncryptionPassword() async {
    if (sessionPassword != null) return sessionPassword;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEncryptionPassword);
  }

  Future<String> getBaseDirSetting() async {
    if (!kIsWeb && Platform.isAndroid) {
      final directory = await getApplicationDocumentsDirectory();
      return directory.path;
    }
    final prefs = await SharedPreferences.getInstance();
    String defaultFolder = kDebugMode ? 'Documents_Debug' : 'Documents';
    return prefs.getString(_getBaseDirKey()) ?? defaultFolder;
  }

  Future<void> saveBaseDirSetting(String value) async {
    if (!kIsWeb && Platform.isAndroid) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_getBaseDirKey(), value);
  }

  // =========================================================================
  // === TASK MASTER STORAGE (Mendukung Dekripsi Otomatis) ===
  // =========================================================================

  Future<File> getTargetJsonFile(String baseDirSetting) async {
    final Directory myTaskDir = Directory('$baseDirSetting/mytask');
    if (!await myTaskDir.exists()) await myTaskDir.create(recursive: true);
    return File('${myTaskDir.path}/my_tasks.json');
  }

  Future<String> loadOrInitializeJson(File jsonFile) async {
    if (!await jsonFile.exists()) {
      await jsonFile.writeAsString(DefaultJson.content);
    }
    String content = await jsonFile.readAsString();
    bool isEncrypted = await isEncryptionEnabled();
    String? password = await getEncryptionPassword();
    if (isEncrypted && password != null && content.contains(':')) {
      content = CryptoHelper.decrypt(content, password);
    }
    return content;
  }

  Future<void> saveJsonData(File jsonFile, String jsonContent) async {
    String dataToSave = jsonContent;
    bool isEncrypted = await isEncryptionEnabled();
    String? password = await getEncryptionPassword();
    if (isEncrypted && password != null && password.isNotEmpty) {
      dataToSave = CryptoHelper.encrypt(jsonContent, password);
    }
    await jsonFile.writeAsString(dataToSave);
  }

  Future<String> getChecklistDirPath(String baseDirSetting) async {
    final Directory checklistDir = Directory('$baseDirSetting/my_checklist');
    return checklistDir.path;
  }

  // =========================================================================
  // === CHECKLIST HUB STORAGE ===
  // =========================================================================

  Future<Directory> getChecklistDir(String baseDirSetting) async {
    final Directory checklistDir = Directory('$baseDirSetting/my_checklist');
    if (!await checklistDir.exists())
      await checklistDir.create(recursive: true);
    return checklistDir;
  }

  Future<List<File>> getAllChecklistGroups(String baseDirSetting) async {
    final Directory checklistDir = await getChecklistDir(baseDirSetting);
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

  Future<File> getSpecificGroupFile(String baseDirSetting, String hubId) async {
    final Directory checklistDir = await getChecklistDir(baseDirSetting);
    return File('${checklistDir.path}/$hubId.json');
  }

  // =========================================================================
  // === JURNAL AKTIVITAS STORAGE (Mendukung Dekripsi Otomatis) ===
  // =========================================================================

  Future<File> getJurnalJsonFile(String baseDirSetting) async {
    final Directory jurnalDir = Directory('$baseDirSetting/jurnal_aktivitas');
    if (!await jurnalDir.exists()) await jurnalDir.create(recursive: true);
    return File('${jurnalDir.path}/time_log.json');
  }

  Future<String> loadOrInitializeJurnalJson(File jsonFile) async {
    if (!await jsonFile.exists()) {
      const String defaultJurnalContent = '[]';
      await jsonFile.writeAsString(defaultJurnalContent);
    }
    String content = await jsonFile.readAsString();
    bool isEncrypted = await isEncryptionEnabled();
    String? password = await getEncryptionPassword();
    if (isEncrypted && password != null && content.contains(':')) {
      content = CryptoHelper.decrypt(content, password);
    }
    return content;
  }

  // =========================================================================
  // === STORAGE BACKUP FROM SERVER (ZIP VERSION) ===
  // =========================================================================

  Future<File> getBackupZipFile(
    String baseDirSetting,
    String namaZipDinamis,
  ) async {
    final Directory backupDir = Directory(
      '$baseDirSetting/storage/backup_from_server',
    );
    if (!await backupDir.exists()) await backupDir.create(recursive: true);
    return File('${backupDir.path}/$namaZipDinamis');
  }

  Future<File> getLocalBackupZipFile(
    String baseDirSetting,
    String namaZipDinamis,
  ) async {
    final Directory backupDir = Directory('$baseDirSetting/storage/backup');
    if (!await backupDir.exists()) await backupDir.create(recursive: true);
    return File('${backupDir.path}/$namaZipDinamis');
  }

  Future<List<File>> getAllLocalBackupFiles(String baseDirSetting) async {
    final Directory backupDir = Directory('$baseDirSetting/storage/backup');
    if (!await backupDir.exists()) return [];
    try {
      List<FileSystemEntity> entities = backupDir.listSync();
      return entities
          .whereType<File>()
          .where((file) => file.path.endsWith('.zip'))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> getIpHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyIpHistory) ?? [];
  }

  Future<void> saveIpToHistory(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> currentHistory = prefs.getStringList(_keyIpHistory) ?? [];
    currentHistory.remove(ip);
    currentHistory.insert(0, ip);
    if (currentHistory.length > 5)
      currentHistory = currentHistory.sublist(0, 5);
    await prefs.setStringList(_keyIpHistory, currentHistory);
  }

  Future<void> deleteIpFromHistory(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> currentHistory = prefs.getStringList(_keyIpHistory) ?? [];
    currentHistory.remove(ip);
    await prefs.setStringList(_keyIpHistory, currentHistory);
  }

  Future<List<File>> getAllServerBackupFiles(String baseDirSetting) async {
    final Directory backupDir = Directory(
      '$baseDirSetting/storage/backup_from_server',
    );
    if (!await backupDir.exists()) return [];
    try {
      List<FileSystemEntity> entities = backupDir.listSync();
      return entities
          .whereType<File>()
          .where((file) => file.path.endsWith('.zip'))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // =========================================================================
  // === PROMPT HUB STORAGE (Mendukung Enkripsi Otomatis) ===
  // =========================================================================

  Future<Directory> getPromptDir(String baseDirSetting) async {
    final Directory promptDir = Directory('$baseDirSetting/prompts');
    if (!await promptDir.exists()) await promptDir.create(recursive: true);
    return promptDir;
  }

  Future<List<File>> getAllPromptGroups(String baseDirSetting) async {
    final Directory promptDir = await getPromptDir(baseDirSetting);
    try {
      List<FileSystemEntity> files = promptDir.listSync();
      return files
          .whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<File> getSpecificPromptFile(String baseDirSetting, String id) async {
    final Directory promptDir = await getPromptDir(baseDirSetting);
    return File('${promptDir.path}/$id.json');
  }

  Future<void> savePromptGroup(
    String baseDirSetting,
    String id,
    String jsonContent,
  ) async {
    final file = await getSpecificPromptFile(baseDirSetting, id);
    String dataToSave = jsonContent;
    bool isEncrypted = await isEncryptionEnabled();
    String? password = await getEncryptionPassword();

    if (isEncrypted && password != null && password.isNotEmpty) {
      dataToSave = CryptoHelper.encrypt(jsonContent, password);
    }
    await file.writeAsString(dataToSave);
  }

  Future<void> deletePromptGroup(String baseDir, String id) async {
    final file = File('$baseDir/prompts/$id.json');
    if (await file.exists()) await file.delete();
  }

  String formatJsonPretty(dynamic jsonObject) {
    return const JsonEncoder.withIndent('  ').convert(jsonObject);
  }

  // =========================================================================
  // === NOTES STORAGE (Mendukung Enkripsi & Dekripsi Otomatis) ===
  // =========================================================================

  Future<Directory> getNotesDir(String baseDirSetting) async {
    final Directory notesDir = Directory('$baseDirSetting/notes');
    if (!await notesDir.exists()) await notesDir.create(recursive: true);
    return notesDir;
  }

  Future<List<File>> getAllNoteGroups(String baseDirSetting) async {
    final Directory notesDir = await getNotesDir(baseDirSetting);
    try {
      List<FileSystemEntity> files = notesDir.listSync();
      return files
          .whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<File> getSpecificNoteFile(String baseDirSetting, String id) async {
    final Directory notesDir = await getNotesDir(baseDirSetting);
    return File('${notesDir.path}/$id.json');
  }

  Future<void> saveNoteGroup(
    String baseDirSetting,
    String id,
    String jsonContent,
  ) async {
    final file = await getSpecificNoteFile(baseDirSetting, id);
    String dataToSave = jsonContent;
    bool isEncrypted = await isEncryptionEnabled();
    String? password = await getEncryptionPassword();

    if (isEncrypted && password != null && password.isNotEmpty) {
      dataToSave = CryptoHelper.encrypt(jsonContent, password);
    }
    await file.writeAsString(dataToSave);
  }

  Future<void> deleteNoteGroup(String baseDirSetting, String id) async {
    final file = await getSpecificNoteFile(baseDirSetting, id);
    if (await file.exists()) await file.delete();
  }

  // =========================================================================
  // === MODIFIKASI MIGRASI MASSAL ===
  // =========================================================================

  Future<void> migrateFilesEncryption(
    bool turnOn,
    String password, {
    bool remember = false,
  }) async {
    final baseDir = await getBaseDirSetting();
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_keyIsEncrypted, turnOn);
    await prefs.setBool(_keyRememberPassword, remember);

    if (turnOn) {
      sessionPassword = password;
      if (remember) {
        await prefs.setString(_keyEncryptionPassword, password);
      } else {
        await prefs.remove(_keyEncryptionPassword);
      }
      // Mulai timer otomatis jika enkripsi berhasil
      await restartSessionTimer();
    } else {
      sessionTimer?.cancel(); // Matikan timer
      sessionPassword = null;
      await prefs.remove(_keyEncryptionPassword);
      await prefs.setBool(_keyRememberPassword, false);
    }

    List<File> allTargetFiles = [];
    allTargetFiles.add(await getTargetJsonFile(baseDir));
    allTargetFiles.add(await getJurnalJsonFile(baseDir));
    allTargetFiles.addAll(await getAllChecklistGroups(baseDir));
    allTargetFiles.addAll(await getAllPromptGroups(baseDir));
    allTargetFiles.addAll(await getAllNoteGroups(baseDir));

    for (var file in allTargetFiles) {
      if (!await file.exists()) continue;
      String content = await file.readAsString();
      final trimmedContent = content.trim();

      bool isRawJson =
          trimmedContent.startsWith('{') || trimmedContent.startsWith('[');

      if (turnOn) {
        if (isRawJson) {
          String encrypted = CryptoHelper.encrypt(content, password);
          await file.writeAsString(encrypted, flush: true);
        }
      } else {
        if (!isRawJson) {
          try {
            String decrypted = CryptoHelper.decrypt(content, password);
            await file.writeAsString(decrypted, flush: true);
          } catch (e) {
            debugPrint(
              "Gagal mendekripsi file saat migrasi: ${file.path}, error: $e",
            );
          }
        }
      }
    }
  }
}

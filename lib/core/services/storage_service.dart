// lib/core/services/storage_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/default_json.dart';
import '../utils/crypto_helper.dart'; // Pastikan import CryptoHelper sudah benar

class StorageService {
  // 1. Definisikan key preferensi penyimpanan
  static const String _keyBaseDirRelease = 'ubuntu_base_dir';
  static const String _keyBaseDirDebug = 'ubuntu_base_dir_debug';
  static const String _keyIpHistory = 'sharing_ip_history';

  // BARU: Key untuk konfigurasi keamanan enkripsi
  static const String _keyIsEncrypted = 'is_encrypted';
  static const String _keyEncryptionPassword = 'encryption_password';

  // Helper untuk mendapatkan key yang sesuai secara otomatis berdasarkan build mode
  String _getBaseDirKey() {
    return kDebugMode ? _keyBaseDirDebug : _keyBaseDirRelease;
  }

  // =========================================================================
  // === HELPER KEAMANAN & STATUS ENKRIPSI ===
  // =========================================================================

  /// Mengambil status aktif/nonaktif enkripsi saat ini
  Future<bool> isEncryptionEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsEncrypted) ?? false;
  }

  /// Mengambil kunci/kata sandi enkripsi terkonfigurasi
  Future<String?> getEncryptionPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEncryptionPassword);
  }

  // 2. Perbarui fungsi mengambil pengaturan path
  Future<String> getBaseDirSetting() async {
    if (!kIsWeb && Platform.isAndroid) {
      final directory = await getApplicationDocumentsDirectory();
      return directory.path;
    }

    final prefs = await SharedPreferences.getInstance();
    String defaultFolder = kDebugMode ? 'Documents_Debug' : 'Documents';

    return prefs.getString(_getBaseDirKey()) ?? defaultFolder;
  }

  // 3. Perbarui juga fungsi menyimpan pengaturan path
  Future<void> saveBaseDirSetting(String value) async {
    if (!kIsWeb && Platform.isAndroid) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_getBaseDirKey(), value);
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

  Future<String> getChecklistDirPath(String baseDirSetting) async {
    final Directory checklistDir = Directory('$baseDirSetting/my_checklist');
    return checklistDir.path;
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
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    return File('${backupDir.path}/$namaZipDinamis');
  }

  Future<File> getLocalBackupZipFile(
    String baseDirSetting,
    String namaZipDinamis,
  ) async {
    final Directory backupDir = Directory('$baseDirSetting/storage/backup');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
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

    if (currentHistory.length > 5) {
      currentHistory = currentHistory.sublist(0, 5);
    }

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
    if (!await promptDir.exists()) {
      await promptDir.create(recursive: true);
    }
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

    // Cek jika fitur enkripsi aktif, lakukan enkripsi konten JSON sebelum ditulis
    bool isEncrypted = await isEncryptionEnabled();
    String? password = await getEncryptionPassword();

    if (isEncrypted && password != null && password.isNotEmpty) {
      dataToSave = CryptoHelper.encrypt(jsonContent, password);
    }

    await file.writeAsString(dataToSave);
  }

  Future<void> deletePromptGroup(String baseDir, String id) async {
    final file = File('$baseDir/prompts/$id.json');
    if (await file.exists()) {
      await file.delete();
    }
  }

  String formatJsonPretty(dynamic jsonObject) {
    return const JsonEncoder.withIndent('  ').convert(jsonObject);
  }

  // =========================================================================
  // === NOTES STORAGE (Mendukung Enkripsi Otomatis) ===
  // =========================================================================

  Future<Directory> getNotesDir(String baseDirSetting) async {
    final Directory notesDir = Directory('$baseDirSetting/notes');
    if (!await notesDir.exists()) {
      await notesDir.create(recursive: true);
    }
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

    // Cek jika fitur enkripsi aktif, lakukan enkripsi konten JSON sebelum ditulis
    bool isEncrypted = await isEncryptionEnabled();
    String? password = await getEncryptionPassword();

    if (isEncrypted && password != null && password.isNotEmpty) {
      dataToSave = CryptoHelper.encrypt(jsonContent, password);
    }

    await file.writeAsString(dataToSave);
  }

  Future<void> deleteNoteGroup(String baseDirSetting, String id) async {
    final file = await getSpecificNoteFile(baseDirSetting, id);
    if (await file.exists()) {
      await file.delete();
    }
  }

  // =========================================================================
  // === FITUR UTAMA BARU: MIGRASI MASSAL SAAT AMANKAN/DEKRIPSI DATA ===
  // =========================================================================

  /// Melakukan migrasi massal seluruh data file .json (Notes & Prompts)
  /// jika fitur enkripsi diaktifkan atau dinonaktifkan.
  Future<void> migrateFilesEncryption(bool turnOn, String password) async {
    final baseDir = await getBaseDirSetting();

    // Ambil daftar berkas dari folder Notes dan Prompts
    final List<File> notesFiles = await getAllNoteGroups(baseDir);
    final List<File> promptFiles = await getAllPromptGroups(baseDir);

    final List<File> allTargetFiles = [...notesFiles, ...promptFiles];

    for (var file in allTargetFiles) {
      if (!await file.exists()) continue;
      String content = await file.readAsString();

      if (turnOn) {
        // PROSES AKTIVASI: Enkripsi data JSON jika belum terenkripsi sebelumnya
        if (!content.contains(':')) {
          String encrypted = CryptoHelper.encrypt(content, password);
          await file.writeAsString(encrypted);
        }
      } else {
        // PROSES DEAKTIVASI: Dekripsi data kembali ke JSON murni
        if (content.contains(':')) {
          String decrypted = CryptoHelper.decrypt(content, password);
          await file.writeAsString(decrypted);
        }
      }
    }

    // Perbarui status preferensi sistem secara persisten
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsEncrypted, turnOn);

    if (turnOn) {
      await prefs.setString(_keyEncryptionPassword, password);
    } else {
      await prefs.remove(_keyEncryptionPassword);
    }
  }
}

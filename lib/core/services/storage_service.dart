// lib/core/services/storage_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/default_json.dart';

class StorageService {
  static const String _keyBaseDir = 'ubuntu_base_dir';
  static const String _keyIpHistory = 'sharing_ip_history';

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

  // Fungsi ini sebenarnya sudah ada di kode Anda, pastikan bisa digunakan untuk menimpa data lama
  Future<void> saveJsonData(File jsonFile, String jsonContent) async {
    await jsonFile.writeAsString(jsonContent);
  }

  // Tambahkan helper ini untuk memudahkan pengecekan struktur folder my_checklist saat eksport/import massal
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

  // =========================================================================
  // === STORAGE BACKUP FROM SERVER (ZIP VERSION) ===
  // =========================================================================

  /// Fungsi untuk menyiapkan folder induk backup dan mengembalikan file target ZIP
  Future<File> getBackupZipFile(
    String baseDirSetting,
    String namaZipDinamis,
  ) async {
    // Buat folder induk 'storage/backup_from_server' jika belum ada
    final Directory backupDir = Directory(
      '$baseDirSetting/storage/backup_from_server',
    );
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    // Kembalikan objek file ZIP di dalam folder tersebut
    return File('${backupDir.path}/$namaZipDinamis');
  }

  // === TAMBAHAN UNTUK BACKUP LOKAL (ZIP) ===

  /// Fungsi untuk menyiapkan folder 'storage/backup' dan mengembalikan file target ZIP
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

  /// Fungsi untuk mengambil daftar semua file ZIP yang ada di folder 'storage/backup'
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

  // 1. Fungsi Ambil Riwayat IP (IP terakhir akan berada di urutan pertama)
  Future<List<String>> getIpHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyIpHistory) ?? [];
  }

  // 2. Fungsi Simpan IP Baru ke dalam Riwayat
  Future<void> saveIpToHistory(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> currentHistory = prefs.getStringList(_keyIpHistory) ?? [];

    // Hapus jika IP sudah ada sebelumnya agar tidak duplikat
    currentHistory.remove(ip);

    // Masukkan IP baru di posisi paling depan (index 0) agar menjadi IP terakhir yang digunakan
    currentHistory.insert(0, ip);

    // Batasi riwayat misalnya maksimal hanya menyimpan 5 IP terakhir
    if (currentHistory.length > 5) {
      currentHistory = currentHistory.sublist(0, 5);
    }

    await prefs.setStringList(_keyIpHistory, currentHistory);
  }

  // 3. Fungsi Hapus IP tertentu dari Riwayat
  Future<void> deleteIpFromHistory(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> currentHistory = prefs.getStringList(_keyIpHistory) ?? [];
    currentHistory.remove(ip);
    await prefs.setStringList(_keyIpHistory, currentHistory);
  }

  // TAMBAHKAN fungsi ini di dalam kelas StorageService
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
}

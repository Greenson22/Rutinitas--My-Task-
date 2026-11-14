import 'dart:async';
import 'dart:io';

import 'package:rutinitasku/core/services/storage_service.dart';
import 'package:rutinitasku/core/utils/atomic_write_helper.dart';
import 'package:rutinitasku/core/utils/crypto_helper.dart';

import '../exceptions/task_master_exceptions.dart';

/// Isi file Task Master setelah dekripsi.
class TaskFileSnapshot {
  const TaskFileSnapshot({
    required this.rawContent,
    required this.content,
    required this.wasEncrypted,
  });

  /// Bytes/teks asli di disk, dipakai untuk backup tanpa mengubah bentuknya.
  final String rawContent;

  /// JSON yang sudah didekripsi.
  final String content;
  final bool wasEncrypted;
}

class TaskBackupInfo {
  const TaskBackupInfo({required this.path, required this.createdAt});

  final String path;
  final DateTime createdAt;
}

/// Seam penyimpanan tingkat rendah untuk contract test.
abstract interface class TaskLocalDataSource {
  /// Mengembalikan `null` bila file belum ada.
  Future<TaskFileSnapshot?> read();

  /// Menulis dengan atomic write dan enkripsi sesuai pengaturan aktif.
  Future<void> write(String content);

  /// Membuat backup berisi konten asli sebelum migrasi.
  Future<TaskBackupInfo> createBackup(TaskFileSnapshot snapshot);

  Future<List<TaskBackupInfo>> listBackups();
}

/// Implementasi file system untuk `<baseDir>/mytask/my_tasks.json`.
class FileTaskLocalDataSource implements TaskLocalDataSource {
  FileTaskLocalDataSource({
    required StorageService storageService,
    required Future<String> Function() baseDirProvider,
    Future<bool> Function()? encryptionEnabledProvider,
    Future<String?> Function()? passwordProvider,
    DateTime Function()? clock,
  }) : _storageService = storageService,
       _baseDirProvider = baseDirProvider,
       _encryptionEnabledProvider =
           encryptionEnabledProvider ?? storageService.isEncryptionEnabled,
       _passwordProvider =
           passwordProvider ?? storageService.getEncryptionPassword,
       _clock = clock ?? DateTime.now;

  final StorageService _storageService;
  final Future<String> Function() _baseDirProvider;
  final Future<bool> Function() _encryptionEnabledProvider;
  final Future<String?> Function() _passwordProvider;
  final DateTime Function() _clock;

  Future<void> _writeQueue = Future<void>.value();

  Future<File> _resolveFile() async {
    final baseDir = await _baseDirProvider();
    return _storageService.getTargetJsonFile(baseDir);
  }

  @override
  Future<TaskFileSnapshot?> read() async {
    final file = await _resolveFile();
    if (!await file.exists()) return null;

    final rawContent = await file.readAsString();
    if (_looksLikePlainJson(rawContent)) {
      return TaskFileSnapshot(
        rawContent: rawContent,
        content: rawContent,
        wasEncrypted: false,
      );
    }

    final encryptionEnabled = await _encryptionEnabledProvider();
    if (!encryptionEnabled) {
      throw TaskDecryptionException(
        'File Task Master tidak dapat dibaca sebagai JSON dan enkripsi '
        'sedang nonaktif. Periksa file atau pulihkan backup.',
      );
    }

    final password = await _passwordProvider();
    if (password == null || password.isEmpty) {
      throw TaskLockedException(
        'File Task Master terenkripsi. Masukkan PIN/kata sandi melalui '
        'pengaturan keamanan untuk membuka data.',
      );
    }

    try {
      final content = CryptoHelper.decrypt(rawContent, password);
      return TaskFileSnapshot(
        rawContent: rawContent,
        content: content,
        wasEncrypted: true,
      );
    } catch (error) {
      throw TaskDecryptionException(
        'Kata sandi salah atau file Task Master korup. Data tidak diubah.',
        cause: error,
      );
    }
  }

  @override
  Future<void> write(String content) {
    final previous = _writeQueue;
    final next = () async {
      try {
        await previous;
      } catch (_) {
        // Penulisan sebelumnya gagal; antrean harus tetap bisa dipakai.
      }
      await _writeNow(content);
    }();

    _writeQueue = next.catchError((_) {});
    return next;
  }

  Future<void> _writeNow(String content) async {
    final file = await _resolveFile();

    var dataToWrite = content;
    final encryptionEnabled = await _encryptionEnabledProvider();
    if (encryptionEnabled) {
      final password = await _passwordProvider();
      if (password == null || password.isEmpty) {
        throw TaskLockedException(
          'Enkripsi aktif tetapi kata sandi tidak tersedia. '
          'Perubahan tidak disimpan agar data tidak bocor.',
        );
      }
      dataToWrite = CryptoHelper.encrypt(content, password);
    }

    final success = await AtomicWriteHelper.writeSafe(
      targetFile: file,
      content: dataToWrite,
    );
    if (!success) {
      throw TaskDataSourceException(
        'Gagal menulis file Task Master secara aman. '
        'Data lama tetap dipertahankan; silakan coba lagi.',
      );
    }
  }

  @override
  Future<TaskBackupInfo> createBackup(TaskFileSnapshot snapshot) async {
    final file = await _resolveFile();
    final backupDir = Directory('${file.parent.path}/backup');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final now = _clock();
    final baseName = 'my_tasks_${_timestamp(now)}';
    var backupFile = File('${backupDir.path}/$baseName.json');
    var suffix = 1;
    while (await backupFile.exists()) {
      backupFile = File('${backupDir.path}/${baseName}_$suffix.json');
      suffix++;
    }

    final success = await AtomicWriteHelper.writeSafe(
      targetFile: backupFile,
      content: snapshot.rawContent,
    );
    if (!success) {
      throw TaskDataSourceException(
        'Gagal membuat backup sebelum migrasi. '
        'File asli tidak diubah; silakan coba lagi.',
      );
    }

    return TaskBackupInfo(path: backupFile.path, createdAt: now);
  }

  @override
  Future<List<TaskBackupInfo>> listBackups() async {
    final file = await _resolveFile();
    final backupDir = Directory('${file.parent.path}/backup');
    if (!await backupDir.exists()) return const [];

    final backups = <TaskBackupInfo>[];
    await for (final entity in backupDir.list()) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      final stat = await entity.stat();
      backups.add(TaskBackupInfo(path: entity.path, createdAt: stat.modified));
    }
    backups.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return backups;
  }

  bool _looksLikePlainJson(String content) {
    final trimmed = content.trimLeft();
    return trimmed.startsWith('{') || trimmed.startsWith('[');
  }

  String _timestamp(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${time.year}${two(time.month)}${two(time.day)}_'
        '${two(time.hour)}${two(time.minute)}${two(time.second)}';
  }
}

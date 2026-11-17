import 'dart:async';
import 'dart:io';

import 'package:rutinitasku/core/services/storage_service.dart';
import 'package:rutinitasku/core/utils/atomic_write_helper.dart';

import '../exceptions/task_master_exceptions.dart';
import '../services/background_codec.dart';

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
  ///
  /// [password] dapat diberikan saat pengguna memasukkan PIN pemulihan. Bila
  /// berhasil, kata sandi itu dipakai untuk penulisan berikutnya.
  Future<TaskFileSnapshot?> read({String? password});

  /// Menulis dengan atomic write dan enkripsi sesuai pengaturan aktif.
  Future<void> write(String content);

  /// Menyiapkan konten file eksternal (misalnya hasil ekspor Data Center)
  /// sebelum diimpor.
  ///
  /// JSON biasa dikembalikan apa adanya. Konten terenkripsi didekripsi dengan
  /// kata sandi sesi agar file lama hasil ekspor tetap dapat dipulihkan.
  Future<String> decodeExternalContent(String rawContent);

  /// Membuat backup berisi konten asli sebelum migrasi.
  Future<TaskBackupInfo> createBackup(TaskFileSnapshot snapshot);

  /// Mem-backup file saat ini tanpa perlu mendekripsinya.
  ///
  /// Mengembalikan `null` bila file belum ada.
  Future<TaskBackupInfo?> backupCurrentFile();

  Future<List<TaskBackupInfo>> listBackups();

  /// Menyalin isi backup kembali ke file utama dengan atomic write.
  Future<void> restoreBackup(String backupPath);
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

  /// Kata sandi hasil PIN pemulihan. Menimpa password dari pengaturan agar
  /// penulisan berikutnya tetap terenkripsi dengan PIN yang benar.
  String? _sessionPasswordOverride;

  Future<File> _resolveFile() async {
    final baseDir = await _baseDirProvider();
    return _storageService.getTargetJsonFile(baseDir);
  }

  @override
  Future<TaskFileSnapshot?> read({String? password}) async {
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

    final effectivePassword =
        password ?? _sessionPasswordOverride ?? await _passwordProvider();
    if (effectivePassword == null || effectivePassword.isEmpty) {
      throw TaskLockedException(
        'File Task Master terenkripsi. Masukkan PIN/kata sandi melalui '
        'pengaturan keamanan untuk membuka data.',
      );
    }

    try {
      final content = await BackgroundCrypto.decrypt(
        rawContent,
        effectivePassword,
      );
      if (password != null && password.isNotEmpty) {
        _sessionPasswordOverride = password;
      }
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
  Future<String> decodeExternalContent(String rawContent) async {
    if (_looksLikePlainJson(rawContent)) return rawContent;

    final password = _sessionPasswordOverride ?? await _passwordProvider();
    if (password == null || password.isEmpty) {
      throw TaskLockedException(
        'File yang diimpor terenkripsi. Masukkan PIN/kata sandi lebih dulu '
        'agar file dapat dibaca. Data saat ini tidak diubah.',
      );
    }

    try {
      return await BackgroundCrypto.decrypt(rawContent, password);
    } catch (error) {
      throw TaskDecryptionException(
        'File yang diimpor tidak dapat didekripsi dengan PIN/kata sandi saat '
        'ini. Data saat ini tidak diubah.',
        cause: error,
      );
    }
  }

  @override
  Future<void> write(String content) {
    return _serialize(() => _writeNow(content));
  }

  /// Menjalankan operasi tulis satu per satu agar tidak ada dua penulisan
  /// yang berjalan bersamaan. Kegagalan satu operasi tidak memutus antrean.
  Future<T> _serialize<T>(Future<T> Function() action) {
    final previous = _writeQueue;
    final completer = Completer<T>();
    _writeQueue = completer.future.then<void>((_) {}, onError: (_) {});
    unawaited(() async {
      try {
        await previous;
      } catch (_) {
        // Operasi sebelumnya gagal; antrean harus tetap bisa dipakai.
      }
      try {
        completer.complete(await action());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    }());
    return completer.future;
  }

  Future<void> _writeNow(String content) async {
    final file = await _resolveFile();

    var dataToWrite = content;
    final encryptionEnabled = await _encryptionEnabledProvider();
    if (encryptionEnabled) {
      final password = _sessionPasswordOverride ?? await _passwordProvider();
      if (password == null || password.isEmpty) {
        throw TaskLockedException(
          'Enkripsi aktif tetapi kata sandi tidak tersedia. '
          'Perubahan tidak disimpan agar data tidak bocor.',
        );
      }
      dataToWrite = await BackgroundCrypto.encrypt(content, password);
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
  Future<TaskBackupInfo> createBackup(TaskFileSnapshot snapshot) {
    return _serialize(() => _createBackupNow(snapshot));
  }

  Future<TaskBackupInfo> _createBackupNow(TaskFileSnapshot snapshot) async {
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
  Future<TaskBackupInfo?> backupCurrentFile() async {
    final file = await _resolveFile();
    if (!await file.exists()) return null;
    final rawContent = await file.readAsString();
    return createBackup(
      TaskFileSnapshot(
        rawContent: rawContent,
        content: '',
        wasEncrypted: !_looksLikePlainJson(rawContent),
      ),
    );
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

  @override
  Future<void> restoreBackup(String backupPath) {
    return _serialize(() => _restoreBackupNow(backupPath));
  }

  Future<void> _restoreBackupNow(String backupPath) async {
    final backupFile = File(backupPath);
    if (!await backupFile.exists()) {
      throw TaskDataSourceException(
        'File backup tidak ditemukan. Data saat ini tidak diubah.',
      );
    }

    final rawContent = await backupFile.readAsString();
    final targetFile = await _resolveFile();
    final success = await AtomicWriteHelper.writeSafe(
      targetFile: targetFile,
      content: rawContent,
    );
    if (!success) {
      throw TaskDataSourceException(
        'Gagal memulihkan backup secara aman. Data saat ini dipertahankan; '
        'silakan coba lagi.',
      );
    }
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

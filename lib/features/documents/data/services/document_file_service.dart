// lib/features/documents/data/services/document_file_service.dart

import 'dart:io';

/// Pilihan penanganan ketika berkas yang diimpor sudah ada di direktori tujuan.
enum DocumentNameConflictPolicy {
  /// Lewati berkas yang bentrok.
  cancel,

  /// Simpan berkas baru dengan akhiran `(1)`, `(2)`, dan seterusnya.
  keepBoth,

  /// Timpa berkas yang sudah ada.
  overwrite,
}

/// Layanan filesystem untuk berkas-berkas di dalam sebuah group My Documents.
///
/// Layanan ini sengaja tidak membaca konfigurasi global apa pun. Base directory
/// harus diberikan lewat konstruktor agar seluruh operasi dapat diuji tanpa
/// membangun widget maupun menyentuh direktori produksi.
///
/// Struktur direktori tetap sama seperti sebelumnya:
/// `<baseDir>/my_documents/<groupId>/<nama berkas>`.
class DocumentFileService {
  final String baseDir;

  DocumentFileService({required this.baseDir});

  /// Direktori induk seluruh group dokumen.
  Directory get documentsDirectory => Directory('$baseDir/my_documents');

  /// Direktori fisik milik satu group dokumen.
  Directory groupDirectory(String groupId) =>
      Directory('${documentsDirectory.path}$_separator$groupId');

  /// Memastikan direktori group ada.
  Future<Directory> ensureGroupDirectory(String groupId) async {
    final dir = groupDirectory(groupId);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Membaca isi langsung direktori group (non-rekursif).
  ///
  /// Berkas JSON metadata disembunyikan dari daftar. Daftar yang dikembalikan
  /// hanya berisi berkas, bukan direktori.
  Future<List<File>> listFiles(String groupId) async {
    final dir = await ensureGroupDirectory(groupId);
    final entities = dir.listSync();
    return entities
        .whereType<File>()
        .where((file) => !_isMetadataFile(file))
        .toList();
  }

  /// Menghitung jumlah berkas langsung di dalam direktori group.
  ///
  /// Berbeda dari [listFiles], metode ini tidak membuat direktori group bila
  /// belum ada, sehingga aman dipakai saat sekadar menghitung ringkasan.
  Future<int> countFiles(String groupId) async {
    final dir = groupDirectory(groupId);
    if (!await dir.exists()) return 0;
    final entities = dir.listSync();
    return entities
        .whereType<File>()
        .where((file) => !_isMetadataFile(file))
        .length;
  }

  /// Nama berkas tanpa direktori.
  String fileName(File file) => _baseName(file.path);

  /// Path relatif berkas terhadap direktori group, selalu memakai pemisah `/`.
  ///
  /// Jika berkas berada di luar direktori group, path absolutnya dikembalikan
  /// apa adanya agar pemanggil bisa mendeteksi ketidakcocokan.
  String relativePath(String groupId, File file) {
    final root = _normalize(ensureDirectoryPath(groupId));
    final target = _normalize(file.path);
    if (target == root) return '';
    final prefix = root.endsWith('/') ? root : '$root/';
    if (target.startsWith(prefix)) {
      return target.substring(prefix.length);
    }
    return file.path;
  }

  /// Mengubah path relatif terhadap group menjadi [File] absolut.
  File resolveRelativePath(String groupId, String relativePath) {
    final normalized = relativePath.replaceAll('\\', '/');
    final segments = normalized
        .split('/')
        .where((segment) => segment.isNotEmpty && segment != '.')
        .toList();
    return File([groupDirectory(groupId).path, ...segments].join(_separator));
  }

  /// Mengubah path (relatif maupun absolut) menjadi [File] absolut.
  File resolvePath(String groupId, String path) {
    final asFile = File(path);
    if (asFile.isAbsolute) return asFile;
    return resolveRelativePath(groupId, path);
  }

  /// Apakah berkas dengan nama ini sudah ada di root group.
  Future<bool> fileExistsInGroup(String groupId, String fileName) async {
    final dir = groupDirectory(groupId);
    return File('${dir.path}$_separator$fileName').exists();
  }

  /// Mengimpor satu berkas ke dalam group.
  ///
  /// [sourceFile] adalah berkas asal di luar direktori aplikasi.
  /// [fileName] adalah nama tujuan. Waktu modifikasi asli dipertahankan.
  ///
  /// Mengembalikan berkas tujuan, atau `null` bila impor dilewati karena
  /// kebijakan [DocumentNameConflictPolicy.cancel].
  Future<File?> importFile({
    required String groupId,
    required File sourceFile,
    required String fileName,
    DocumentNameConflictPolicy conflictPolicy =
        DocumentNameConflictPolicy.keepBoth,
  }) async {
    final dir = await ensureGroupDirectory(groupId);
    File targetFile = File('${dir.path}$_separator$fileName');

    if (await targetFile.exists()) {
      switch (conflictPolicy) {
        case DocumentNameConflictPolicy.cancel:
          return null;
        case DocumentNameConflictPolicy.overwrite:
          break;
        case DocumentNameConflictPolicy.keepBoth:
          targetFile = await _firstAvailableKeepBothPath(targetFile);
          break;
      }
    }

    final DateTime originalLastModified = await sourceFile.lastModified();
    await sourceFile.copy(targetFile.path);
    await targetFile.setLastModified(originalLastModified);
    return targetFile;
  }

  /// Mengubah nama berkas di dalam group.
  ///
  /// [newFileName] adalah nama lengkap tujuan (termasuk ekstensi). Nama yang
  /// sudah dipakai berkas lain tidak ditimpa; metode mengembalikan `null` agar
  /// perilaku lama tetap terjaga.
  Future<File?> renameFile({
    required String groupId,
    required File file,
    required String newFileName,
  }) async {
    final dir = await ensureGroupDirectory(groupId);
    final targetFile = File('${dir.path}$_separator$newFileName');
    if (await targetFile.exists()) return null;
    await file.rename(targetFile.path);
    return targetFile;
  }

  /// Memindahkan satu berkas ke root group lain.
  ///
  /// Bila nama bentrok di tujuan, berkas diberi akhiran berbasis waktu seperti
  /// perilaku lama, sehingga tidak ada berkas yang tertimpa.
  Future<File?> moveFile({
    required File file,
    required String targetGroupId,
  }) async {
    final targetDir = await ensureGroupDirectory(targetGroupId);
    if (!await file.exists()) return null;

    final originalName = _baseName(file.path);
    File targetFile = File('${targetDir.path}$_separator$originalName');
    if (await targetFile.exists()) {
      targetFile = await _firstAvailableTimestampPath(targetFile);
    }

    await file.rename(targetFile.path);
    return targetFile;
  }

  /// Menghapus satu berkas bila ada.
  Future<bool> deleteFile(File file) async {
    if (!await file.exists()) return false;
    await file.delete();
    return true;
  }

  /// Menghapus beberapa berkas. Mengembalikan jumlah berkas yang terhapus.
  Future<int> deleteFiles(List<File> files) async {
    int deleted = 0;
    for (final file in files) {
      if (await deleteFile(file)) deleted++;
    }
    return deleted;
  }

  /// Menghapus direktori fisik milik group beserta seluruh isinya.
  Future<void> deleteGroupDirectory(String groupId) async {
    final dir = groupDirectory(groupId);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  /// Membersihkan nama folder dari karakter path terlarang.
  String sanitizeFolderName(String rawName) {
    final replaced = rawName
        .replaceAll(RegExp(r'[/\\:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (replaced.isEmpty || replaced == '.' || replaced == '..') {
      return '';
    }
    return replaced;
  }

  /// Mengembalikan [Directory] untuk [relativePath] di dalam [groupId].
  Directory resolveDirectory(String groupId, {String relativePath = ''}) {
    final normalized = relativePath.replaceAll('\\', '/');
    final segments = normalized
        .split('/')
        .where((s) => s.isNotEmpty && s != '.')
        .toList();
    if (segments.isEmpty) return groupDirectory(groupId);
    return Directory([groupDirectory(groupId).path, ...segments].join(_separator));
  }

  /// Memastikan direktori untuk [relativePath] di dalam [groupId] ada.
  Future<Directory> ensureDirectory(
    String groupId, {
    String relativePath = '',
  }) async {
    final dir = resolveDirectory(groupId, relativePath: relativePath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Membaca isi langsung direktori (non-rekursif), memisahkan subfolder dan berkas.
  ///
  /// Berkas JSON metadata disembunyikan pada level root group.
  Future<({List<Directory> directories, List<File> files})> listDirectory(
    String groupId, {
    String relativePath = '',
  }) async {
    final dir = await ensureDirectory(groupId, relativePath: relativePath);
    final entities = dir.listSync();
    final isRoot = relativePath.trim().isEmpty;
    final directories = entities.whereType<Directory>().toList();
    final files = entities
        .whereType<File>()
        .where((file) => !isRoot || !_isMetadataFile(file))
        .toList();
    return (directories: directories, files: files);
  }

  /// Menghitung jumlah subfolder dan berkas langsung di dalam [relativePath]
  /// tanpa membuat direktori bila belum ada.
  Future<({int folderCount, int fileCount})> countDirectoryEntries(
    String groupId, {
    String relativePath = '',
  }) async {
    final dir = resolveDirectory(groupId, relativePath: relativePath);
    if (!await dir.exists()) return (folderCount: 0, fileCount: 0);
    final entities = dir.listSync();
    final isRoot = relativePath.trim().isEmpty;
    final folderCount = entities.whereType<Directory>().length;
    final fileCount = entities
        .whereType<File>()
        .where((file) => !isRoot || !_isMetadataFile(file))
        .length;
    return (folderCount: folderCount, fileCount: fileCount);
  }

  /// Membuat direktori fisik folder baru.
  Future<Directory> createFolderDirectory(
    String groupId,
    String relativePath,
  ) async {
    return ensureDirectory(groupId, relativePath: relativePath);
  }

  /// Mengganti nama/lokasi direktori fisik folder.
  Future<Directory> renameFolderDirectory(
    String groupId,
    String oldRelativePath,
    String newRelativePath,
  ) async {
    final oldDir = resolveDirectory(groupId, relativePath: oldRelativePath);
    final newDir = resolveDirectory(groupId, relativePath: newRelativePath);
    if (!await newDir.parent.exists()) {
      await newDir.parent.create(recursive: true);
    }
    if (await oldDir.exists()) {
      return oldDir.rename(newDir.path);
    }
    await newDir.create(recursive: true);
    return newDir;
  }

  /// Memindahkan direktori fisik folder ke lokasi baru.
  Future<Directory> moveFolderDirectory(
    String groupId,
    String oldRelativePath,
    String newRelativePath,
  ) async {
    return renameFolderDirectory(groupId, oldRelativePath, newRelativePath);
  }

  /// Menghapus direktori fisik folder beserta seluruh isinya secara rekursif.
  Future<void> deleteFolderDirectory(
    String groupId,
    String relativePath,
  ) async {
    final dir = resolveDirectory(groupId, relativePath: relativePath);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  /// Path direktori group tanpa menyentuh filesystem.
  String ensureDirectoryPath(String groupId) => groupDirectory(groupId).path;

  bool _isMetadataFile(File file) => file.path.toLowerCase().endsWith('.json');

  Future<File> _firstAvailableKeepBothPath(File target) async {
    final nameParts = _splitFileName(_baseName(target.path));
    final String parent = target.parent.path;

    int counter = 1;
    File candidate = File(
      '$parent$_separator${nameParts.stem} ($counter)${nameParts.extension}',
    );
    while (await candidate.exists()) {
      counter++;
      candidate = File(
        '$parent$_separator${nameParts.stem} ($counter)${nameParts.extension}',
      );
    }
    return candidate;
  }

  Future<File> _firstAvailableTimestampPath(File target) async {
    final nameParts = _splitFileName(_baseName(target.path));
    final String parent = target.parent.path;
    final String timestamp = DateTime.now().millisecondsSinceEpoch
        .toString()
        .substring(8);

    File candidate = File(
      '$parent$_separator${nameParts.stem}_$timestamp${nameParts.extension}',
    );
    int counter = 1;
    while (await candidate.exists()) {
      candidate = File(
        '$parent$_separator${nameParts.stem}_${timestamp}_$counter${nameParts.extension}',
      );
      counter++;
    }
    return candidate;
  }

  ({String stem, String extension}) _splitFileName(String name) {
    final int lastDot = name.lastIndexOf('.');
    return (
      stem: lastDot != -1 ? name.substring(0, lastDot) : name,
      extension: lastDot != -1 ? name.substring(lastDot) : '',
    );
  }

  String _baseName(String path) => path.split(RegExp(r'[/\\]')).last;

  String _normalize(String path) => path.replaceAll('\\', '/');

  String get _separator => Platform.pathSeparator;
}

/// Kesalahan yang bisa ditampilkan dengan aman kepada pengguna.
class TaskMasterException implements Exception {
  TaskMasterException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

/// File memakai versi skema yang belum dikenal aplikasi ini.
class UnsupportedSchemaVersionException extends TaskMasterException {
  UnsupportedSchemaVersionException(this.detectedVersion)
    : super(
        'Versi skema data ($detectedVersion) tidak dikenali. '
        'Data tidak diubah. Perbarui aplikasi ke versi yang lebih baru.',
      );

  final int detectedVersion;
}

/// Migrasi gagal. File asli tidak diubah.
class TaskMigrationException extends TaskMasterException {
  TaskMigrationException(super.message, {this.backupPath, super.cause});

  final String? backupPath;
}

/// Isi file bukan JSON Task Master yang valid.
class TaskDataCorruptedException extends TaskMasterException {
  TaskDataCorruptedException(super.message, {super.cause});
}

/// File terenkripsi tetapi kata sandi sesi tidak tersedia.
class TaskLockedException extends TaskMasterException {
  TaskLockedException(super.message, {super.cause});
}

/// Kata sandi salah atau ciphertext rusak.
class TaskDecryptionException extends TaskMasterException {
  TaskDecryptionException(super.message, {super.cause});
}

/// Kegagalan baca/tulis pada penyimpanan lokal.
class TaskDataSourceException extends TaskMasterException {
  TaskDataSourceException(super.message, {super.cause});
}

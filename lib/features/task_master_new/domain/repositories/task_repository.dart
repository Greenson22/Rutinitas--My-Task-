import '../entities/task_master_data.dart';

/// Seam utama antara presentasi dan penyimpanan Task Master.
///
/// Controller dan widget hanya bergantung pada kontrak ini. Implementasi
/// konkret menangani file system, enkripsi, backup, dan migrasi.
abstract interface class TaskRepository {
  /// Memuat data dan menjalankan migrasi otomatis bila file masih legacy.
  Future<TaskMasterData> load();

  /// Menyimpan seluruh data dengan skema v2.
  Future<void> save(TaskMasterData data);
}

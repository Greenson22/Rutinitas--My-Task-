import '../entities/task_kind.dart';
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

  /// Menambah kategori baru, menyimpan, lalu mengembalikan data terbaru.
  Future<TaskMasterData> addCategory({
    required String name,
    required String icon,
  });

  /// Mengubah nama dan ikon kategori tanpa mengubah `id` atau tugas di dalamnya.
  Future<TaskMasterData> updateCategory({
    required String categoryId,
    required String name,
    required String icon,
  });

  /// Menyembunyikan atau menampilkan kembali kategori.
  Future<TaskMasterData> setCategoryHidden({
    required String categoryId,
    required bool isHidden,
  });

  /// Menghapus kategori beserta tugas di dalamnya.
  Future<TaskMasterData> deleteCategory(String categoryId);

  /// Menambah tugas baru pada kategori, menyimpan, lalu mengembalikan data.
  Future<TaskMasterData> addTask({
    required String categoryId,
    required String name,
    required TaskKind kind,
    required int targetDaily,
    required int targetTotal,
    required bool isActive,
  });

  /// Mengubah field tugas tanpa mengubah `id`, riwayat, atau hitungan total.
  Future<TaskMasterData> updateTask({
    required String categoryId,
    required String taskId,
    required String name,
    required TaskKind kind,
    required int targetDaily,
    required int targetTotal,
    required bool isActive,
  });

  /// Mengaktifkan atau menonaktifkan tugas tanpa menghapus riwayatnya.
  Future<TaskMasterData> setTaskActive({
    required String categoryId,
    required String taskId,
    required bool isActive,
  });

  /// Menghapus satu tugas dari kategori.
  Future<TaskMasterData> deleteTask({
    required String categoryId,
    required String taskId,
  });
}

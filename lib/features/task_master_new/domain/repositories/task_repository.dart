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
}

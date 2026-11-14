import '../entities/category.dart';
import '../entities/task_master_data.dart';

/// Batas panjang nama kategori sesuai spesifikasi.
const int maxCategoryNameLength = 60;

/// Emoji bawaan ketika pengguna tidak memilih ikon.
const String defaultCategoryIcon = '📌';

/// Kesalahan validasi yang aman ditampilkan pada form kategori.
class CategoryValidationException implements Exception {
  CategoryValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Memvalidasi nama kategori.
///
/// Mengembalikan pesan kesalahan, atau `null` bila nama valid. Pemeriksaan
/// duplikat bersifat case-insensitive dan mengabaikan kategori yang sedang
/// diedit melalui [exceptId].
String? validateCategoryName(
  String rawName, {
  required Iterable<Category> existingCategories,
  String? exceptId,
}) {
  final name = rawName.trim();
  if (name.isEmpty) return 'Nama kategori tidak boleh kosong';
  if (name.length > maxCategoryNameLength) {
    return 'Nama kategori maksimal $maxCategoryNameLength karakter';
  }

  final normalized = name.toLowerCase();
  for (final category in existingCategories) {
    if (category.id == exceptId) continue;
    if (category.name.trim().toLowerCase() == normalized) {
      return 'Nama kategori "$name" sudah digunakan';
    }
  }
  return null;
}

/// Menambah kategori baru di urutan paling akhir.
///
/// Melempar [CategoryValidationException] bila nama tidak valid atau duplikat.
TaskMasterData addCategoryTo(
  TaskMasterData data, {
  required String id,
  required String name,
  required String icon,
}) {
  final error = validateCategoryName(name, existingCategories: data.categories);
  if (error != null) throw CategoryValidationException(error);

  final trimmedName = name.trim();
  final trimmedIcon = icon.trim();
  final nextSortOrder = data.categories.isEmpty
      ? 0
      : data.categories
                .map((category) => category.sortOrder)
                .reduce((a, b) => a > b ? a : b) +
            1;

  final category = Category(
    id: id,
    name: trimmedName,
    icon: trimmedIcon.isEmpty ? defaultCategoryIcon : trimmedIcon,
    isHidden: false,
    sortOrder: nextSortOrder,
  );

  return data.copyWith(categories: [...data.categories, category]);
}

/// Mengubah nama dan ikon kategori tanpa mengubah [Category.id].
///
/// Semua tugas di dalam kategori ikut dipertahankan.
TaskMasterData updateCategoryIn(
  TaskMasterData data, {
  required String categoryId,
  required String name,
  required String icon,
}) {
  final error = validateCategoryName(
    name,
    existingCategories: data.categories,
    exceptId: categoryId,
  );
  if (error != null) throw CategoryValidationException(error);

  return _replaceCategory(
    data,
    categoryId: categoryId,
    update: (existing) {
      final trimmedIcon = icon.trim();
      return existing.copyWith(
        name: name.trim(),
        icon: trimmedIcon.isEmpty ? existing.icon : trimmedIcon,
      );
    },
  );
}

/// Menyembunyikan atau menampilkan kembali kategori.
TaskMasterData setCategoryHiddenIn(
  TaskMasterData data, {
  required String categoryId,
  required bool isHidden,
}) {
  return _replaceCategory(
    data,
    categoryId: categoryId,
    update: (existing) => existing.copyWith(isHidden: isHidden),
  );
}

TaskMasterData _replaceCategory(
  TaskMasterData data, {
  required String categoryId,
  required Category Function(Category existing) update,
}) {
  final index = data.categories.indexWhere(
    (category) => category.id == categoryId,
  );
  if (index == -1) {
    throw CategoryValidationException('Kategori tidak ditemukan');
  }

  final categories = [...data.categories];
  categories[index] = update(categories[index]);
  return data.copyWith(categories: categories);
}

/// Menghapus kategori beserta tugas di dalamnya.
TaskMasterData deleteCategoryFrom(
  TaskMasterData data, {
  required String categoryId,
}) {
  final remaining = data.categories
      .where((category) => category.id != categoryId)
      .toList();
  if (remaining.length == data.categories.length) {
    throw CategoryValidationException('Kategori tidak ditemukan');
  }
  return data.copyWith(categories: remaining);
}

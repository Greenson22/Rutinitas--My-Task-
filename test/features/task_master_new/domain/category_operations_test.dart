import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/category.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/daily_progress.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_kind.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_master_data.dart';
import 'package:rutinitasku/features/task_master_new/domain/operations/category_operations.dart';

void main() {
  final now = DateTime(2026, 11, 14, 12);

  Task task(String id, {String categoryId = 'cat_1'}) {
    return Task(
      id: id,
      categoryId: categoryId,
      name: 'Tugas $id',
      kind: TaskKind.counter,
      isActive: true,
      sortOrder: 0,
      targetDaily: 0,
      targetTotal: 0,
      totalCount: 7,
      createdAt: now,
      updatedAt: now,
      history: {
        DailyProgress.dateKey(now): DailyProgress(
          date: DailyProgress.dateKey(now),
          count: 2,
          updatedAt: now,
        ),
      },
    );
  }

  TaskMasterData sampleData() {
    return TaskMasterData(
      schemaVersion: 2,
      categories: [
        Category(
          id: 'cat_1',
          name: 'Olahraga',
          icon: '🏃',
          isHidden: false,
          sortOrder: 0,
          tasks: [task('task_1')],
        ),
      ],
    );
  }

  group('validasi nama kategori', () {
    test('nama kosong ditolak', () {
      final error = validateCategoryName(
        '   ',
        existingCategories: const [],
      );

      expect(error, isNotNull);
    });

    test('nama lebih dari 60 karakter ditolak', () {
      final error = validateCategoryName(
        'a' * (maxCategoryNameLength + 1),
        existingCategories: const [],
      );

      expect(error, contains('60'));
    });

    test('duplikat bersifat case-insensitive', () {
      final error = validateCategoryName(
        '  olahraga ',
        existingCategories: sampleData().categories,
      );

      expect(error, contains('sudah digunakan'));
    });

    test('nama sendiri saat edit tidak dianggap duplikat', () {
      final error = validateCategoryName(
        'Olahraga',
        existingCategories: sampleData().categories,
        exceptId: 'cat_1',
      );

      expect(error, isNull);
    });
  });

  group('operasi kategori', () {
    test('tambah kategori menaruh di urutan terakhir', () {
      final updated = addCategoryTo(
        sampleData(),
        id: 'cat_2',
        name: 'Belajar',
        icon: '📚',
      );

      expect(updated.categories, hasLength(2));
      expect(updated.categories.last.id, 'cat_2');
      expect(updated.categories.last.sortOrder, 1);
      expect(updated.categories.last.icon, '📚');
      expect(updated.categories.last.isHidden, isFalse);
    });

    test('tambah kategori duplikat melempar validasi', () {
      expect(
        () => addCategoryTo(
          sampleData(),
          id: 'cat_2',
          name: 'Olahraga',
          icon: '📚',
        ),
        throwsA(isA<CategoryValidationException>()),
      );
    });

    test('rename mempertahankan id dan semua tugas', () {
      final updated = updateCategoryIn(
        sampleData(),
        categoryId: 'cat_1',
        name: 'Kebugaran',
        icon: '💪',
      );

      final category = updated.categories.single;
      expect(category.id, 'cat_1');
      expect(category.name, 'Kebugaran');
      expect(category.icon, '💪');
      expect(category.tasks.single.id, 'task_1');
      expect(category.tasks.single.categoryId, 'cat_1');
      expect(category.tasks.single.totalCount, 7);
    });

    test('sembunyikan dan tampilkan kembali kategori', () {
      final hidden = setCategoryHiddenIn(
        sampleData(),
        categoryId: 'cat_1',
        isHidden: true,
      );
      expect(hidden.categories.single.isHidden, isTrue);
      expect(hidden.activeCategoryCount, 0);

      final shown = setCategoryHiddenIn(
        hidden,
        categoryId: 'cat_1',
        isHidden: false,
      );
      expect(shown.categories.single.isHidden, isFalse);
      expect(shown.activeCategoryCount, 1);
    });

    test('hapus kategori ikut menghapus tugas di dalamnya', () {
      final updated = deleteCategoryFrom(sampleData(), categoryId: 'cat_1');

      expect(updated.categories, isEmpty);
      expect(updated.allTasks, isEmpty);
    });
  });
}

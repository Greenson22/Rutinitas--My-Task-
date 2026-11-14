import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/core/services/storage_service.dart';
import 'package:rutinitasku/features/task_master_new/data/datasources/task_local_data_source.dart';
import 'package:rutinitasku/features/task_master_new/data/mappers/task_master_mapper.dart';
import 'package:rutinitasku/features/task_master_new/data/repositories/task_repository_impl.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/category.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/daily_progress.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_kind.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_master_data.dart';
import 'package:rutinitasku/features/task_master_new/domain/operations/category_operations.dart';

import '../support/fake_task_local_data_source.dart';

void main() {
  final now = DateTime(2026, 11, 14, 12);

  TaskMasterData sampleData() {
    final today = DailyProgress.dateKey(now);
    return TaskMasterData(
      schemaVersion: 2,
      categories: [
        Category(
          id: 'cat_1',
          name: 'Olahraga',
          icon: '🏃',
          isHidden: false,
          sortOrder: 0,
          tasks: [
            Task(
              id: 'task_1',
              categoryId: 'cat_1',
              name: 'Push up',
              kind: TaskKind.habit,
              isActive: true,
              sortOrder: 0,
              targetDaily: 20,
              targetTotal: 0,
              totalCount: 120,
              createdAt: now,
              updatedAt: now,
              history: {
                today: DailyProgress(date: today, count: 15, updatedAt: now),
              },
            ),
          ],
        ),
      ],
    );
  }

  FakeTaskLocalDataSource sourceWith(TaskMasterData data) {
    final mapper = TaskMasterMapper(clock: () => now);
    final raw = jsonEncode(mapper.toJson(data, today: now));
    return FakeTaskLocalDataSource(
      snapshot: TaskFileSnapshot(
        rawContent: raw,
        content: raw,
        wasEncrypted: false,
      ),
    );
  }

  TaskRepositoryImpl buildRepository(FakeTaskLocalDataSource source) {
    return TaskRepositoryImpl(
      localDataSource: source,
      mapper: TaskMasterMapper(clock: () => now),
      categoryIdGenerator: () => 'cat_new',
    );
  }

  group('TaskRepository kategori', () {
    test('tambah kategori bertahan setelah repository dibuat ulang', () async {
      final source = FakeTaskLocalDataSource();
      final repository = buildRepository(source);

      final added = await repository.addCategory(
        name: 'Belajar',
        icon: '📚',
      );
      expect(added.categories.single.id, 'cat_new');

      final reopened = buildRepository(source);
      final loaded = await reopened.load();

      expect(loaded.categories.single.name, 'Belajar');
      expect(loaded.categories.single.icon, '📚');
      expect(loaded.categories.single.id, 'cat_new');
      expect(source.writeCount, 1);
    });

    test('rename mempertahankan id dan seluruh tugas', () async {
      final source = sourceWith(sampleData());
      final repository = buildRepository(source);

      final updated = await repository.updateCategory(
        categoryId: 'cat_1',
        name: 'Kebugaran',
        icon: '💪',
      );

      final category = updated.categories.single;
      expect(category.id, 'cat_1');
      expect(category.name, 'Kebugaran');
      expect(category.tasks.single.id, 'task_1');
      expect(category.tasks.single.categoryId, 'cat_1');
      expect(category.tasks.single.countOn(DailyProgress.dateKey(now)), 15);

      final reopened = buildRepository(source);
      final loaded = await reopened.load();
      expect(loaded.categories.single.id, 'cat_1');
      expect(loaded.categories.single.name, 'Kebugaran');
      expect(loaded.categories.single.tasks.single.id, 'task_1');
    });

    test('nama duplikat ditolak tanpa menulis file', () async {
      final source = sourceWith(sampleData());
      final repository = buildRepository(source);

      await expectLater(
        repository.addCategory(name: 'olahraga', icon: '📚'),
        throwsA(isA<CategoryValidationException>()),
      );

      expect(source.writeCount, 0);
      final loaded = await repository.load();
      expect(loaded.categories, hasLength(1));
    });

    test('status sembunyi bertahan setelah reload', () async {
      final source = sourceWith(sampleData());
      final repository = buildRepository(source);

      await repository.setCategoryHidden(
        categoryId: 'cat_1',
        isHidden: true,
      );

      final reopened = buildRepository(source);
      final loaded = await reopened.load();
      expect(loaded.categories.single.isHidden, isTrue);
      expect(loaded.activeCategoryCount, 0);
    });

    test('hapus kategori tersimpan dan tidak muncul setelah reload', () async {
      final source = sourceWith(sampleData());
      final repository = buildRepository(source);

      await repository.deleteCategory('cat_1');

      final reopened = buildRepository(source);
      final loaded = await reopened.load();
      expect(loaded.categories, isEmpty);
    });

    test('tambah kategori bertahan pada file nyata di direktori sementara', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'task_master_category_',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      TaskLocalDataSource dataSource() => FileTaskLocalDataSource(
        storageService: StorageService(),
        baseDirProvider: () async => tempDir.path,
        encryptionEnabledProvider: () async => false,
        clock: () => now,
      );

      final repository = TaskRepositoryImpl(
        localDataSource: dataSource(),
        mapper: TaskMasterMapper(clock: () => now),
        categoryIdGenerator: () => 'cat_file',
      );
      await repository.addCategory(name: 'Belajar', icon: '📚');

      final file = File('${tempDir.path}/mytask/my_tasks.json');
      expect(await file.exists(), isTrue);

      final reopened = TaskRepositoryImpl(
        localDataSource: dataSource(),
        mapper: TaskMasterMapper(clock: () => now),
        categoryIdGenerator: () => 'cat_other',
      );
      final loaded = await reopened.load();

      expect(loaded.categories.single.id, 'cat_file');
      expect(loaded.categories.single.name, 'Belajar');
      expect(loaded.categories.single.icon, '📚');
    });
  });
}

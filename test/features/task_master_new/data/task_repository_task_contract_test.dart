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
import 'package:rutinitasku/features/task_master_new/domain/operations/task_operations.dart';

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
      taskIdGenerator: () => 'task_new',
      clock: () => now,
    );
  }

  group('TaskRepository tugas', () {
    test('tambah tugas bertahan setelah repository dibuat ulang', () async {
      final source = sourceWith(sampleData());
      final repository = buildRepository(source);

      final updated = await repository.addTask(
        categoryId: 'cat_1',
        name: 'Sit up',
        kind: TaskKind.progress,
        targetDaily: 10,
        targetTotal: 100,
        isActive: true,
      );

      expect(updated.categories.single.tasks, hasLength(2));
      final added = updated.categories.single.tasks.last;
      expect(added.id, 'task_new');
      expect(added.kind, TaskKind.progress);
      expect(added.targetDaily, 10);
      expect(added.targetTotal, 100);

      final reopened = buildRepository(source);
      final loaded = await reopened.load();
      final loadedTask = loaded.categories.single.tasks.last;
      expect(loadedTask.id, 'task_new');
      expect(loadedTask.name, 'Sit up');
      expect(loadedTask.kind, TaskKind.progress);
      expect(loadedTask.targetTotal, 100);
      expect(loadedTask.isActive, isTrue);
    });

    test('target progress nol ditolak tanpa menulis file', () async {
      final source = sourceWith(sampleData());
      final repository = buildRepository(source);

      await expectLater(
        repository.addTask(
          categoryId: 'cat_1',
          name: 'Sit up',
          kind: TaskKind.progress,
          targetDaily: 0,
          targetTotal: 0,
          isActive: true,
        ),
        throwsA(isA<TaskValidationException>()),
      );

      expect(source.writeCount, 0);
    });

    test('edit mempertahankan id, hitungan, dan riwayat', () async {
      final source = sourceWith(sampleData());
      final repository = buildRepository(source);

      final updated = await repository.updateTask(
        categoryId: 'cat_1',
        taskId: 'task_1',
        name: 'Push up pagi',
        kind: TaskKind.progress,
        targetDaily: 30,
        targetTotal: 500,
        isActive: false,
      );

      final task = updated.categories.single.tasks.single;
      expect(task.id, 'task_1');
      expect(task.name, 'Push up pagi');
      expect(task.kind, TaskKind.progress);
      expect(task.targetDaily, 30);
      expect(task.targetTotal, 500);
      expect(task.isActive, isFalse);
      expect(task.totalCount, 120);
      expect(task.countOn(DailyProgress.dateKey(now)), 15);

      final reopened = buildRepository(source);
      final loaded = await reopened.load();
      final loadedTask = loaded.categories.single.tasks.single;
      expect(loadedTask.id, 'task_1');
      expect(loadedTask.totalCount, 120);
      expect(loadedTask.countOn(DailyProgress.dateKey(now)), 15);
      expect(loadedTask.targetTotal, 500);
    });

    test('nonaktifkan dan aktifkan kembali bertahan setelah reload', () async {
      final source = sourceWith(sampleData());
      final repository = buildRepository(source);

      await repository.setTaskActive(
        categoryId: 'cat_1',
        taskId: 'task_1',
        isActive: false,
      );
      expect(
        (await repository.load()).categories.single.tasks.single.isActive,
        isFalse,
      );

      final reopened = buildRepository(source);
      expect(
        (await reopened.load()).categories.single.tasks.single.isActive,
        isFalse,
      );

      await reopened.setTaskActive(
        categoryId: 'cat_1',
        taskId: 'task_1',
        isActive: true,
      );
      expect(
        (await reopened.load()).categories.single.tasks.single.isActive,
        isTrue,
      );
    });

    test('hapus tugas tersimpan dan tidak muncul setelah reload', () async {
      final source = sourceWith(sampleData());
      final repository = buildRepository(source);

      await repository.deleteTask(categoryId: 'cat_1', taskId: 'task_1');

      final reopened = buildRepository(source);
      final loaded = await reopened.load();
      expect(loaded.categories.single.tasks, isEmpty);
    });

    test('tugas tersimpan pada file nyata di direktori sementara', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'task_master_task_',
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
        taskIdGenerator: () => 'task_file',
        clock: () => now,
      );
      await repository.addCategory(name: 'Belajar', icon: '📚');
      await repository.addTask(
        categoryId: 'cat_file',
        name: 'Membaca',
        kind: TaskKind.progress,
        targetDaily: 5,
        targetTotal: 50,
        isActive: true,
      );

      final file = File('${tempDir.path}/mytask/my_tasks.json');
      expect(await file.exists(), isTrue);

      final reopened = TaskRepositoryImpl(
        localDataSource: dataSource(),
        mapper: TaskMasterMapper(clock: () => now),
        categoryIdGenerator: () => 'cat_other',
        taskIdGenerator: () => 'task_other',
        clock: () => now,
      );
      final loaded = await reopened.load();
      final task = loaded.categories.single.tasks.single;

      expect(task.id, 'task_file');
      expect(task.name, 'Membaca');
      expect(task.kind, TaskKind.progress);
      expect(task.targetDaily, 5);
      expect(task.targetTotal, 50);
    });
  });
}

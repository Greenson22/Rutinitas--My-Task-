import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/features/task_master_new/data/datasources/task_local_data_source.dart';
import 'package:rutinitasku/features/task_master_new/data/mappers/task_master_mapper.dart';
import 'package:rutinitasku/features/task_master_new/data/repositories/task_repository_impl.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/category.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/daily_progress.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_kind.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_master_data.dart';

import '../support/fake_task_local_data_source.dart';

void main() {
  final now = DateTime(2026, 11, 14, 12);
  final today = DailyProgress.dateKey(now);

  Task task({
    required String id,
    required String categoryId,
    required String name,
    required int sortOrder,
  }) {
    return Task(
      id: id,
      categoryId: categoryId,
      name: name,
      kind: TaskKind.habit,
      isActive: true,
      sortOrder: sortOrder,
      targetDaily: 10,
      targetTotal: 0,
      totalCount: 7,
      createdAt: now,
      updatedAt: now,
      history: {today: DailyProgress(date: today, count: 2, updatedAt: now)},
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
          tasks: [
            task(
              id: 'task_1',
              categoryId: 'cat_1',
              name: 'Push up',
              sortOrder: 0,
            ),
            task(
              id: 'task_2',
              categoryId: 'cat_1',
              name: 'Sit up',
              sortOrder: 1,
            ),
          ],
        ),
        Category(
          id: 'cat_2',
          name: 'Belajar',
          icon: '📚',
          isHidden: false,
          sortOrder: 1,
          tasks: [
            task(
              id: 'task_3',
              categoryId: 'cat_2',
              name: 'Baca buku',
              sortOrder: 0,
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
      clock: () => now,
    );
  }

  group('TaskRepository reorder dan aksi massal', () {
    test('urutan kategori bertahan setelah repository dibuat ulang', () async {
      final source = sourceWith(sampleData());
      final repository = buildRepository(source);

      await repository.reorderCategory(categoryId: 'cat_1', newIndex: 1);

      final reopened = buildRepository(source);
      final loaded = await reopened.load();
      final ordered = [...loaded.categories]
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      expect(ordered.map((category) => category.id), ['cat_2', 'cat_1']);
      expect(ordered.map((category) => category.sortOrder), [0, 1]);
    });

    test('urutan tugas dan sortOrder bertahan setelah reload', () async {
      final source = sourceWith(sampleData());
      final repository = buildRepository(source);

      await repository.reorderTask(
        categoryId: 'cat_1',
        taskId: 'task_1',
        newIndex: 1,
      );

      final reopened = buildRepository(source);
      final loaded = await reopened.load();
      final ordered = [...loaded.categoryById('cat_1')!.tasks]
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      expect(ordered.map((item) => item.id), ['task_2', 'task_1']);
      expect(ordered.map((item) => item.sortOrder), [0, 1]);
    });

    test('pindah kategori mempertahankan id, total, dan riwayat', () async {
      final source = sourceWith(sampleData());
      final repository = buildRepository(source);

      await repository.moveTask(
        fromCategoryId: 'cat_1',
        taskId: 'task_1',
        toCategoryId: 'cat_2',
      );

      final reopened = buildRepository(source);
      final loaded = await reopened.load();
      expect(loaded.categoryById('cat_1')!.tasks.map((item) => item.id), [
        'task_2',
      ]);
      final moved = loaded.categoryById('cat_2')!.tasks.last;
      expect(moved.id, 'task_1');
      expect(moved.categoryId, 'cat_2');
      expect(moved.totalCount, 7);
      expect(moved.countOn(today), 2);
    });

    test('aksi aktif dan hapus massal bertahan setelah reload', () async {
      final source = sourceWith(sampleData());
      final repository = buildRepository(source);

      await repository.setTasksActive(
        categoryId: 'cat_1',
        taskIds: ['task_1', 'task_2'],
        isActive: false,
      );
      await repository.deleteTasks(categoryId: 'cat_1', taskIds: ['task_2']);

      final reopened = buildRepository(source);
      final loaded = await reopened.load();
      final tasks = loaded.categoryById('cat_1')!.tasks;
      expect(tasks.map((item) => item.id), ['task_1']);
      expect(tasks.single.isActive, isFalse);
      expect(tasks.single.totalCount, 7);
      expect(tasks.single.countOn(today), 2);
    });
  });
}

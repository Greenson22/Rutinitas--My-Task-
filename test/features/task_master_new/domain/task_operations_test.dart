import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/category.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/daily_progress.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_kind.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_master_data.dart';
import 'package:rutinitasku/features/task_master_new/domain/operations/task_operations.dart';

void main() {
  final now = DateTime(2026, 11, 14, 12);
  final today = DailyProgress.dateKey(now);

  Task existingTask({
    String id = 'task_1',
    String categoryId = 'cat_1',
    TaskKind kind = TaskKind.habit,
  }) {
    return Task(
      id: id,
      categoryId: categoryId,
      name: 'Push up',
      kind: kind,
      isActive: true,
      sortOrder: 0,
      targetDaily: 20,
      targetTotal: 0,
      totalCount: 120,
      createdAt: now.subtract(const Duration(days: 4)),
      updatedAt: now,
      history: {today: DailyProgress(date: today, count: 15, updatedAt: now)},
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
          tasks: [existingTask()],
        ),
      ],
    );
  }

  group('validasi nama tugas', () {
    test('nama kosong ditolak', () {
      expect(validateTaskName('   '), isNotNull);
    });

    test('nama maksimal 120 karakter', () {
      expect(validateTaskName('a' * maxTaskNameLength), isNull);
      expect(validateTaskName('a' * (maxTaskNameLength + 1)), contains('120'));
    });
  });

  group('validasi target tugas', () {
    test('target harian negatif ditolak', () {
      expect(
        validateTaskTargets(
          kind: TaskKind.habit,
          targetDaily: -1,
          targetTotal: 0,
        ),
        contains('harian'),
      );
    });

    test('progress wajib memiliki target total lebih dari nol', () {
      expect(
        validateTaskTargets(
          kind: TaskKind.progress,
          targetDaily: 0,
          targetTotal: 0,
        ),
        contains('lebih dari 0'),
      );
      expect(
        validateTaskTargets(
          kind: TaskKind.progress,
          targetDaily: 1,
          targetTotal: 10,
        ),
        isNull,
      );
    });

    test('habit dan counter boleh tanpa target total', () {
      for (final kind in [TaskKind.habit, TaskKind.counter]) {
        expect(
          validateTaskTargets(kind: kind, targetDaily: 0, targetTotal: 0),
          isNull,
        );
      }
    });
  });

  group('operasi tugas', () {
    test('tambah tugas menaruh di urutan terakhir tanpa hitungan awal', () {
      final updated = addTaskTo(
        sampleData(),
        id: 'task_2',
        categoryId: 'cat_1',
        name: '  Sit up  ',
        kind: TaskKind.progress,
        targetDaily: 10,
        targetTotal: 100,
        isActive: true,
        now: now,
      );

      final task = updated.categories.single.tasks.last;
      expect(task.id, 'task_2');
      expect(task.name, 'Sit up');
      expect(task.kind, TaskKind.progress);
      expect(task.sortOrder, 1);
      expect(task.targetDaily, 10);
      expect(task.targetTotal, 100);
      expect(task.totalCount, 0);
      expect(task.createdAt, now);
      expect(task.updatedAt, now);
    });

    test('tambah tugas dengan target progress nol ditolak', () {
      expect(
        () => addTaskTo(
          sampleData(),
          id: 'task_2',
          categoryId: 'cat_1',
          name: 'Sit up',
          kind: TaskKind.progress,
          targetDaily: 0,
          targetTotal: 0,
          isActive: true,
          now: now,
        ),
        throwsA(isA<TaskValidationException>()),
      );
    });

    test('edit mempertahankan id, riwayat, hitungan, dan urutan', () {
      final updated = updateTaskIn(
        sampleData(),
        categoryId: 'cat_1',
        taskId: 'task_1',
        name: 'Push up pagi',
        kind: TaskKind.counter,
        targetDaily: 0,
        targetTotal: 0,
        isActive: false,
        now: now.add(const Duration(minutes: 5)),
      );

      final task = updated.categories.single.tasks.single;
      expect(task.id, 'task_1');
      expect(task.name, 'Push up pagi');
      expect(task.kind, TaskKind.counter);
      expect(task.isActive, isFalse);
      expect(task.sortOrder, 0);
      expect(task.totalCount, 120);
      expect(task.countOn(today), 15);
      expect(task.updatedAt, now.add(const Duration(minutes: 5)));
      expect(task.createdAt, now.subtract(const Duration(days: 4)));
    });

    test('nonaktifkan lalu aktifkan kembali mempertahankan data', () {
      final inactive = setTaskActiveIn(
        sampleData(),
        categoryId: 'cat_1',
        taskId: 'task_1',
        isActive: false,
        now: now,
      );
      expect(inactive.categories.single.tasks.single.isActive, isFalse);
      expect(inactive.categories.single.tasks.single.totalCount, 120);

      final active = setTaskActiveIn(
        inactive,
        categoryId: 'cat_1',
        taskId: 'task_1',
        isActive: true,
        now: now,
      );
      expect(active.categories.single.tasks.single.isActive, isTrue);
      expect(active.categories.single.tasks.single.countOn(today), 15);
    });

    test('increment menambah total, hitungan hari ini, dan riwayat', () {
      final result = incrementTaskIn(
        sampleData(),
        categoryId: 'cat_1',
        taskId: 'task_1',
        now: now.add(const Duration(minutes: 1)),
      );

      final task = result.data.categories.single.tasks.single;
      expect(task.totalCount, 121);
      expect(task.countOn(today), 16);
      expect(
        task.history[today]!.updatedAt,
        now.add(const Duration(minutes: 1)),
      );
      expect(task.updatedAt, now.add(const Duration(minutes: 1)));
      expect(result.increment.categoryId, 'cat_1');
      expect(result.increment.taskId, 'task_1');
      expect(result.increment.dateKey, today);
      expect(task.sortOrder, 0);
      expect(task.name, 'Push up');
    });

    test('increment membuat entri riwayat bila hari ini belum ada', () {
      final data = sampleData();
      final task = data.categories.single.tasks.single;
      final withoutToday = data.copyWith(
        categories: [
          data.categories.single.copyWith(
            tasks: [task.copyWith(history: const {})],
          ),
        ],
      );

      final result = incrementTaskIn(
        withoutToday,
        categoryId: 'cat_1',
        taskId: 'task_1',
        now: now,
      );

      final updated = result.data.categories.single.tasks.single;
      expect(updated.totalCount, 121);
      expect(updated.countOn(today), 1);
      expect(updated.history[today]!.count, 1);
    });

    test('undo mengembalikan total, hitungan, dan riwayat hari ini', () {
      final incremented = incrementTaskIn(
        sampleData(),
        categoryId: 'cat_1',
        taskId: 'task_1',
        now: now,
      );

      final reverted = undoIncrementIn(
        incremented.data,
        increment: incremented.increment,
        now: now.add(const Duration(seconds: 2)),
      );

      final task = reverted.categories.single.tasks.single;
      expect(task.totalCount, 120);
      expect(task.countOn(today), 15);
      expect(task.history[today]!.count, 15);
    });

    test('undo menghapus riwayat hari ini bila hitungan menjadi nol', () {
      final data = sampleData();
      final task = data.categories.single.tasks.single;
      final withoutToday = data.copyWith(
        categories: [
          data.categories.single.copyWith(
            tasks: [task.copyWith(history: const {})],
          ),
        ],
      );
      final incremented = incrementTaskIn(
        withoutToday,
        categoryId: 'cat_1',
        taskId: 'task_1',
        now: now,
      );

      final reverted = undoIncrementIn(
        incremented.data,
        increment: incremented.increment,
        now: now,
      );

      final updated = reverted.categories.single.tasks.single;
      expect(updated.totalCount, 120);
      expect(updated.countOn(today), 0);
      expect(updated.history.containsKey(today), isFalse);
    });

    test('undo tanpa entri riwayat tidak mengubah total', () {
      final data = sampleData();
      final task = data.categories.single.tasks.single;
      final withoutHistory = data.copyWith(
        categories: [
          data.categories.single.copyWith(
            tasks: [task.copyWith(history: const {})],
          ),
        ],
      );

      final reverted = undoIncrementIn(
        withoutHistory,
        increment: TaskIncrement(
          categoryId: 'cat_1',
          taskId: 'task_1',
          dateKey: today,
        ),
        now: now,
      );

      final updated = reverted.categories.single.tasks.single;
      expect(updated.totalCount, 120);
      expect(updated.history, isEmpty);
    });

    test('hapus tugas hanya menghapus tugas yang dipilih', () {
      final data = addTaskTo(
        sampleData(),
        id: 'task_2',
        categoryId: 'cat_1',
        name: 'Sit up',
        kind: TaskKind.counter,
        targetDaily: 0,
        targetTotal: 0,
        isActive: true,
        now: now,
      );

      final updated = deleteTaskFrom(
        data,
        categoryId: 'cat_1',
        taskId: 'task_1',
      );

      expect(updated.categories.single.tasks.single.id, 'task_2');
    });
  });
}

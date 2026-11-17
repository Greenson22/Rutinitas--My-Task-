import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/features/task_master_new/data/exceptions/task_master_exceptions.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/category.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/daily_progress.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_kind.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_master_data.dart';
import 'package:rutinitasku/features/task_master_new/presentation/controllers/task_master_controller.dart';

import '../support/fake_task_repository.dart';

void main() {
  var now = DateTime(2026, 11, 14, 12);
  late String today;

  setUp(() {
    now = DateTime(2026, 11, 14, 12);
  });

  TaskMasterData sampleData() {
    today = DailyProgress.dateKey(now);
    Task task(String id, String name, TaskKind kind, int total, int daily) {
      return Task(
        id: id,
        categoryId: 'cat_1',
        name: name,
        kind: kind,
        isActive: true,
        sortOrder: id == 'task_1' ? 0 : 1,
        targetDaily: daily,
        targetTotal: 0,
        totalCount: total,
        createdAt: now,
        updatedAt: now,
        history: {
          today: DailyProgress(date: today, count: daily, updatedAt: now),
        },
      );
    }

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
            task('task_1', 'Push up', TaskKind.habit, 120, 15),
            task('task_2', 'Baca buku', TaskKind.progress, 40, 3),
          ],
        ),
      ],
    );
  }

  TaskMasterNewController buildController(FakeTaskRepository repository) {
    final controller = TaskMasterNewController(
      repository: repository,
      clock: () => now,
      saveDebounce: const Duration(hours: 1),
    );
    addTearDown(controller.dispose);
    return controller;
  }

  test('increment mengubah state seketika tanpa menunggu simpan', () async {
    final repository = FakeTaskRepository(data: sampleData());
    final controller = buildController(repository);
    await controller.load();

    final applied = controller.incrementTask(
      categoryId: 'cat_1',
      taskId: 'task_1',
    );

    expect(applied, isTrue);
    final task = controller.state.data!.allTasks.first;
    expect(task.totalCount, 121);
    expect(task.countOn(today), 16);
    expect(controller.state.lastIncrement?.taskId, 'task_1');
    expect(repository.saveCount, 0);
  });

  test('increment tersimpan setelah debounce diselesaikan', () async {
    final repository = FakeTaskRepository(data: sampleData());
    final controller = buildController(repository);
    await controller.load();

    controller.incrementTask(categoryId: 'cat_1', taskId: 'task_1');
    await controller.flushPendingSave();

    final saved = repository.data!.allTasks.first;
    expect(repository.saveCount, 1);
    expect(saved.totalCount, 121);
    expect(saved.countOn(today), 16);
  });

  test(
    'undo mengembalikan total, hitungan, dan riwayat lalu tersimpan',
    () async {
      final repository = FakeTaskRepository(data: sampleData());
      final controller = buildController(repository);
      await controller.load();

      controller.incrementTask(categoryId: 'cat_1', taskId: 'task_1');
      final undone = controller.undoLastIncrement();

      expect(undone, isTrue);
      final task = controller.state.data!.allTasks.first;
      expect(task.totalCount, 120);
      expect(task.countOn(today), 15);
      expect(controller.state.lastIncrement, isNull);

      await controller.flushPendingSave();
      expect(repository.data!.allTasks.first.totalCount, 120);
      expect(repository.data!.allTasks.first.countOn(today), 15);
    },
  );

  test('hanya increment terakhir yang dapat di-undo', () async {
    final repository = FakeTaskRepository(data: sampleData());
    final controller = buildController(repository);
    await controller.load();

    controller.incrementTask(categoryId: 'cat_1', taskId: 'task_1');
    now = now.add(const Duration(seconds: 1));
    controller.incrementTask(categoryId: 'cat_1', taskId: 'task_2');

    expect(controller.state.lastIncrement?.taskId, 'task_2');
    controller.undoLastIncrement();

    final first = controller.state.data!.allTasks.first;
    final second = controller.state.data!.allTasks.last;
    expect(first.totalCount, 121);
    expect(first.countOn(today), 16);
    expect(second.totalCount, 40);
    expect(second.countOn(today), 3);
  });

  test('double tap dalam jendela singkat tidak menambah dua kali', () async {
    final repository = FakeTaskRepository(data: sampleData());
    final controller = buildController(repository);
    await controller.load();

    final first = controller.incrementTask(
      categoryId: 'cat_1',
      taskId: 'task_1',
    );
    final second = controller.incrementTask(
      categoryId: 'cat_1',
      taskId: 'task_1',
    );

    expect(first, isTrue);
    expect(second, isFalse);
    expect(controller.state.data!.allTasks.first.totalCount, 121);
  });

  test('increment cepat pada tugas berbeda tetap dihitung semua', () async {
    final repository = FakeTaskRepository(data: sampleData());
    final controller = buildController(repository);
    await controller.load();

    expect(
      controller.incrementTask(categoryId: 'cat_1', taskId: 'task_1'),
      isTrue,
    );
    expect(
      controller.incrementTask(categoryId: 'cat_1', taskId: 'task_2'),
      isTrue,
    );

    final first = controller.state.data!.allTasks.first;
    final second = controller.state.data!.allTasks.last;
    expect(first.totalCount, 121);
    expect(second.totalCount, 41);
    expect(controller.state.lastIncrement?.taskId, 'task_2');
  });

  test(
    'increment tugas yang sama setelah jendela double tap dihitung',
    () async {
      final repository = FakeTaskRepository(data: sampleData());
      final controller = buildController(repository);
      await controller.load();

      expect(
        controller.incrementTask(categoryId: 'cat_1', taskId: 'task_1'),
        isTrue,
      );
      now = now.add(incrementDoubleTapWindow + const Duration(milliseconds: 1));
      expect(
        controller.incrementTask(categoryId: 'cat_1', taskId: 'task_1'),
        isTrue,
      );

      expect(controller.state.data!.allTasks.first.totalCount, 122);
      expect(controller.state.data!.allTasks.first.countOn(today), 17);
    },
  );

  test('kegagalan menyimpan menampilkan banner dan bisa dicoba lagi', () async {
    final repository = FakeTaskRepository(data: sampleData());
    repository.saveError = TaskDataSourceException('Penyimpanan penuh.');
    final controller = buildController(repository);
    await controller.load();

    controller.incrementTask(categoryId: 'cat_1', taskId: 'task_1');
    await controller.flushPendingSave();

    expect(
      controller.state.actionMessage,
      startsWith('Perubahan belum tersimpan.'),
    );
    expect(controller.state.actionMessage, contains('Penyimpanan penuh.'));
    expect(controller.state.actionRetryable, isTrue);
    expect(repository.data!.allTasks.first.totalCount, 120);

    repository.saveError = null;
    await controller.retryLastAction();

    expect(controller.state.actionMessage, isNull);
    expect(repository.data!.allTasks.first.totalCount, 121);
    expect(repository.data!.allTasks.first.countOn(today), 16);
  });
}

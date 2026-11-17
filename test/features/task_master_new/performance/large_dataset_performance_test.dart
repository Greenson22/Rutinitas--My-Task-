import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/core/services/storage_service.dart';
import 'package:rutinitasku/features/task_master_new/data/datasources/task_local_data_source.dart';
import 'package:rutinitasku/features/task_master_new/data/repositories/task_repository_impl.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/category.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/daily_progress.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_kind.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_master_data.dart';
import 'package:rutinitasku/features/task_master_new/domain/operations/dashboard_summary.dart';
import 'package:rutinitasku/features/task_master_new/presentation/controllers/task_master_controller.dart';

import '../support/fake_task_repository.dart';

/// Batas target performa dari SPEC.
const int loadTargetMilliseconds = 500;
const int searchTargetMilliseconds = 100;
const int incrementTargetMilliseconds = 100;

const int categoryCount = 20;
const int tasksPerCategory = 50;

DateTime _baseTime() => DateTime(2026, 11, 14, 12);

/// Membangun 1.000 tugas dengan riwayat sparse satu minggu terakhir,
/// ukuran yang realistis untuk pengguna berat Task Master.
TaskMasterData buildLargeDataset({int historyDaysPerTask = 7}) {
  final now = _baseTime();
  final categories = <Category>[];

  for (var categoryIndex = 0; categoryIndex < categoryCount; categoryIndex++) {
    final tasks = <Task>[];
    for (var taskIndex = 0; taskIndex < tasksPerCategory; taskIndex++) {
      final globalIndex = categoryIndex * tasksPerCategory + taskIndex;
      final id = 'task_$globalIndex';
      final history = <String, DailyProgress>{};
      for (var day = 0; day < historyDaysPerTask; day++) {
        final date = now.subtract(Duration(days: day));
        final dateKey = DailyProgress.dateKey(date);
        history[dateKey] = DailyProgress(
          date: dateKey,
          count: (globalIndex + day) % 4,
          updatedAt: date,
        );
      }

      tasks.add(
        Task(
          id: id,
          categoryId: 'cat_$categoryIndex',
          name: 'Tugas ${globalIndex + 1}',
          kind: TaskKind.values[globalIndex % TaskKind.values.length],
          isActive: globalIndex % 10 != 0,
          sortOrder: taskIndex,
          targetDaily: globalIndex % 3,
          targetTotal: globalIndex % 3 == 0 ? 100 : 0,
          totalCount: globalIndex % 60,
          createdAt: now,
          updatedAt: now,
          history: history,
        ),
      );
    }

    categories.add(
      Category(
        id: 'cat_$categoryIndex',
        name: 'Kategori ${categoryIndex + 1}',
        icon: '📁',
        isHidden: categoryIndex % 10 == 9,
        sortOrder: categoryIndex,
        tasks: tasks,
      ),
    );
  }

  return TaskMasterData(
    schemaVersion: TaskMasterData.currentSchemaVersion,
    categories: categories,
  );
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('task_master_perf_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  FileTaskLocalDataSource buildDataSource() {
    return FileTaskLocalDataSource(
      storageService: StorageService(),
      baseDirProvider: () async => tempDir.path,
      encryptionEnabledProvider: () async => false,
      passwordProvider: () async => null,
      clock: _baseTime,
    );
  }

  test('1.000 tugas dimuat di bawah 500 ms', () async {
    final repository = TaskRepositoryImpl(
      localDataSource: buildDataSource(),
      clock: _baseTime,
    );
    await repository.save(buildLargeDataset());

    // Pemuatan pertama memuat biaya satu kali pembuatan isolate dan pemanasan
    // JIT. Ukur keduanya agar bukti performa jujur, lalu tegakkan target pada
    // pemuatan hangat yang mewakili pemakaian sehari-hari.
    final coldWatch = Stopwatch()..start();
    final coldLoaded = await repository.load();
    coldWatch.stop();

    final stopwatch = Stopwatch()..start();
    final loaded = await repository.load();
    stopwatch.stop();

    expect(coldLoaded.allTasks.length, categoryCount * tasksPerCategory);
    expect(loaded.allTasks.length, categoryCount * tasksPerCategory);
    expect(
      stopwatch.elapsedMilliseconds,
      lessThan(loadTargetMilliseconds),
      reason:
          'Pemuatan 1.000 tugas memakan ${stopwatch.elapsedMilliseconds} ms, '
          'melebihi target $loadTargetMilliseconds ms.',
    );
    // ignore: avoid_print
    print(
      'PERF load: ${stopwatch.elapsedMilliseconds} ms hangat, '
      '${coldWatch.elapsedMilliseconds} ms dingin '
      '(${loaded.allTasks.length} tugas)',
    );
  });

  test('pencarian 1.000 tugas selesai di bawah 100 ms', () async {
    final data = buildLargeDataset();
    final repository = FakeTaskRepository(data: data);
    final controller = TaskMasterNewController(
      repository: repository,
      clock: _baseTime,
      saveDebounce: const Duration(hours: 1),
    );
    addTearDown(controller.dispose);
    await controller.load();

    final stopwatch = Stopwatch()..start();
    controller.setSearchQuery('tugas 1');
    final groups = controller.searchGroups();
    stopwatch.stop();

    expect(groups, isNotEmpty);
    expect(
      stopwatch.elapsedMilliseconds,
      lessThan(searchTargetMilliseconds),
      reason:
          'Pencarian memakan ${stopwatch.elapsedMilliseconds} ms, '
          'melebihi target $searchTargetMilliseconds ms.',
    );
    // ignore: avoid_print
    print(
      'PERF search: ${stopwatch.elapsedMilliseconds} ms '
      '(${groups.fold<int>(0, (sum, group) => sum + group.tasks.length)} hasil)',
    );
  });

  test('ringkasan dashboard 1.000 tugas tetap di bawah 100 ms', () async {
    final data = buildLargeDataset();
    final today = DailyProgress.dateKey(_baseTime());

    final stopwatch = Stopwatch()..start();
    final todayTasks = collectTodayTasks(data, today);
    final completed = completedTargetCount(todayTasks, today);
    stopwatch.stop();

    expect(todayTasks, isNotEmpty);
    expect(completed, greaterThanOrEqualTo(0));
    expect(stopwatch.elapsedMilliseconds, lessThan(searchTargetMilliseconds));
    // ignore: avoid_print
    print(
      'PERF dashboard summary: ${stopwatch.elapsedMilliseconds} ms '
      '(${todayTasks.length} tugas hari ini)',
    );
  });

  test('perubahan state setelah increment selesai di bawah 100 ms', () async {
    final data = buildLargeDataset();
    final repository = FakeTaskRepository(data: data);
    final controller = TaskMasterNewController(
      repository: repository,
      clock: _baseTime,
      saveDebounce: const Duration(hours: 1),
    );
    addTearDown(controller.dispose);
    await controller.load();

    final targetTask = data.categories.first.tasks.first;
    final stopwatch = Stopwatch()..start();
    final applied = controller.incrementTask(
      categoryId: targetTask.categoryId,
      taskId: targetTask.id,
    );
    // Memaksa pembacaan state yang sama seperti yang dilakukan widget.
    final updated = controller.state.data!
        .categoryById(targetTask.categoryId)!
        .tasks
        .first;
    stopwatch.stop();

    expect(applied, isTrue);
    expect(updated.totalCount, targetTask.totalCount + 1);
    expect(
      stopwatch.elapsedMilliseconds,
      lessThan(incrementTargetMilliseconds),
      reason:
          'Increment memakan ${stopwatch.elapsedMilliseconds} ms, '
          'melebihi target $incrementTargetMilliseconds ms.',
    );
    // ignore: avoid_print
    print('PERF increment: ${stopwatch.elapsedMilliseconds} ms');
    await controller.flushPendingSave();
  });

  test('penulisan data besar tidak memblokir event loop', () async {
    final repository = TaskRepositoryImpl(
      localDataSource: buildDataSource(),
      clock: _baseTime,
    );
    final data = buildLargeDataset();

    var ticks = 0;
    final timer = Timer.periodic(const Duration(milliseconds: 1), (_) {
      ticks++;
    });
    await repository.save(data);
    timer.cancel();

    expect(
      ticks,
      greaterThan(0),
      reason:
          'Event loop tidak sempat berjalan selama penyimpanan, berarti '
          'penulisan memblokir frame render.',
    );
    // ignore: avoid_print
    print('PERF save: event loop berjalan $ticks kali selama penyimpanan');
  });

  test('penulisan bersamaan diserialisasi dan hasil akhir benar', () async {
    final repository = TaskRepositoryImpl(
      localDataSource: buildDataSource(),
      clock: _baseTime,
    );
    final firstData = buildLargeDataset(historyDaysPerTask: 1);
    final secondBase = buildLargeDataset(historyDaysPerTask: 2);
    final secondData = secondBase.copyWith(
      categories: [
        for (final category in secondBase.categories)
          category.copyWith(
            name: '${category.name} v2',
            tasks: [
              for (final task in category.tasks)
                task.copyWith(name: '${task.name} v2'),
            ],
          ),
      ],
    );

    await Future.wait([
      repository.save(firstData),
      repository.save(secondData),
    ]);

    final reloaded = await repository.load();
    expect(reloaded.categories.first.name, endsWith('v2'));
    expect(reloaded.categories.first.tasks.first.name, endsWith('v2'));
  });
}

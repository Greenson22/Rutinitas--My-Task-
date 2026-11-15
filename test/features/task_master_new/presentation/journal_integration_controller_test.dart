import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/category.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/daily_progress.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_kind.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_master_data.dart';
import 'package:rutinitasku/features/task_master_new/domain/repositories/journal_gateway.dart';
import 'package:rutinitasku/features/task_master_new/presentation/controllers/task_master_controller.dart';
import 'package:rutinitasku/features/task_master_new/presentation/controllers/task_master_state.dart';

import '../support/fake_journal_gateway.dart';
import '../support/fake_task_repository.dart';

void main() {
  var now = DateTime(2026, 11, 14, 12);
  late String today;

  setUp(() {
    now = DateTime(2026, 11, 14, 12);
  });

  TaskMasterData sampleData() {
    today = DailyProgress.dateKey(now);
    Task task(String id, String name, int total) {
      return Task(
        id: id,
        categoryId: 'cat_1',
        name: name,
        kind: TaskKind.habit,
        isActive: true,
        sortOrder: id == 'task_1' ? 0 : 1,
        targetDaily: 20,
        targetTotal: 0,
        totalCount: total,
        createdAt: now,
        updatedAt: now,
        history: {today: DailyProgress(date: today, count: 15, updatedAt: now)},
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
            task('task_1', 'Push up', 120),
            task('task_2', 'Baca buku', 40),
          ],
        ),
      ],
    );
  }

  TaskMasterNewController buildController(
    FakeTaskRepository repository, {
    FakeJournalGateway? journalGateway,
  }) {
    final controller = TaskMasterNewController(
      repository: repository,
      journalGateway: journalGateway,
      clock: () => now,
      saveDebounce: const Duration(hours: 1),
    );
    addTearDown(controller.dispose);
    return controller;
  }

  FakeJournalGateway linkedGateway({int minutes = 45}) {
    return FakeJournalGateway(
      linkState: JournalLinkState(
        linkedTaskIds: const {'task_1'},
        incrementMinutes: minutes,
      ),
    );
  }

  test('memuat relasi Jurnal tanpa menyalinnya ke data Task Master', () async {
    final repository = FakeTaskRepository(data: sampleData());
    final journal = linkedGateway();
    final controller = buildController(repository, journalGateway: journal);
    await controller.load();

    expect(controller.isTaskLinkedToJournal('task_1'), isTrue);
    expect(controller.isTaskLinkedToJournal('task_2'), isFalse);
    expect(controller.journalIncrementMinutes, 45);

    final tasks = controller.state.data!.allTasks.toList();
    expect(tasks.map((task) => task.id), ['task_1', 'task_2']);
    // Hanya dua field data tugas yang ada; relasi Jurnal tidak disalin.
    expect(controller.state.data!.allTasks, hasLength(2));
  });

  test('gagal membaca relasi Jurnal memberi peringatan yang jelas', () async {
    final repository = FakeTaskRepository(data: sampleData());
    final journal = linkedGateway()
      ..loadError = JournalGatewayException('Jurnal tidak dapat dibaca.');
    final controller = buildController(repository, journalGateway: journal);

    await controller.load();

    expect(controller.state.status, TaskMasterNewStatus.ready);
    expect(controller.state.data, isNotNull);
    expect(controller.state.actionMessage, contains('Relasi Jurnal'));
    expect(controller.state.actionRetryable, isFalse);
  });

  test('increment tugas tertaut menambah durasi Jurnal', () async {
    final repository = FakeTaskRepository(data: sampleData());
    final journal = linkedGateway();
    final controller = buildController(repository, journalGateway: journal);
    await controller.load();

    controller.incrementTask(categoryId: 'cat_1', taskId: 'task_1');
    await pumpEventQueue();

    expect(journal.addCalls, ['task_1']);
    expect(journal.addDates.single, now);
  });

  test('increment tugas tidak tertaut tidak menyentuh Jurnal', () async {
    final repository = FakeTaskRepository(data: sampleData());
    final journal = linkedGateway();
    final controller = buildController(repository, journalGateway: journal);
    await controller.load();

    controller.incrementTask(categoryId: 'cat_1', taskId: 'task_2');
    await pumpEventQueue();

    expect(journal.addCalls, isEmpty);
    expect(controller.state.data!.allTasks.last.totalCount, 41);
  });

  test('undo mengurangi durasi Jurnal yang sama', () async {
    final repository = FakeTaskRepository(data: sampleData());
    final journal = linkedGateway();
    final controller = buildController(repository, journalGateway: journal);
    await controller.load();

    controller.incrementTask(categoryId: 'cat_1', taskId: 'task_1');
    await pumpEventQueue();
    expect(journal.addCalls, ['task_1']);

    controller.undoLastIncrement();
    await pumpEventQueue();

    expect(journal.subtractCalls, hasLength(1));
    expect(journal.subtractCalls.single.journalTaskId, 'jurnal_task_1');
    expect(journal.subtractCalls.single.minutes, 45);
    expect(controller.state.data!.allTasks.first.totalCount, 120);
  });

  test('undo melewati tengah malam memakai tanggal increment', () async {
    final repository = FakeTaskRepository(data: sampleData());
    final journal = linkedGateway();
    final controller = buildController(repository, journalGateway: journal);
    await controller.load();

    now = DateTime(2026, 11, 14, 23, 59);
    controller.incrementTask(categoryId: 'cat_1', taskId: 'task_1');
    await pumpEventQueue();
    final incrementAt = now;

    now = DateTime(2026, 11, 15, 0, 1);
    controller.undoLastIncrement();
    await pumpEventQueue();

    expect(journal.subtractDates.single, incrementAt);
  });

  test('undo menunggu penambahan Jurnal selesai sebelum mengurangi', () async {
    final repository = FakeTaskRepository(data: sampleData());
    final journal = linkedGateway();
    final completer = Completer<JournalAdjustment?>();
    journal.addCompleter = completer;
    final controller = buildController(repository, journalGateway: journal);
    await controller.load();

    controller.incrementTask(categoryId: 'cat_1', taskId: 'task_1');
    expect(controller.undoLastIncrement(), isTrue);

    // Task Master sudah kembali meski Jurnal belum selesai.
    expect(controller.state.data!.allTasks.first.totalCount, 120);
    expect(journal.subtractCalls, isEmpty);

    completer.complete(
      const JournalAdjustment(journalTaskId: 'jurnal_task_1', minutes: 45),
    );
    await pumpEventQueue();

    expect(journal.subtractCalls, hasLength(1));
    expect(journal.subtractCalls.single.minutes, 45);
  });

  test('gagal menambah durasi Jurnal tetap menaikkan hitungan', () async {
    final repository = FakeTaskRepository(data: sampleData());
    final journal = linkedGateway()
      ..addError = JournalGatewayException('Jurnal tidak dapat ditulis.');
    final controller = buildController(repository, journalGateway: journal);
    await controller.load();

    controller.incrementTask(categoryId: 'cat_1', taskId: 'task_1');
    await pumpEventQueue();

    expect(controller.state.data!.allTasks.first.totalCount, 121);
    expect(controller.state.actionMessage, contains('Jurnal'));

    controller.undoLastIncrement();
    await pumpEventQueue();
    expect(journal.subtractCalls, isEmpty);
  });

  test(
    'rollback Jurnal gagal tidak membatalkan rollback Task Master',
    () async {
      final repository = FakeTaskRepository(data: sampleData());
      final journal = linkedGateway()
        ..subtractError = JournalGatewayException(
          'Aktivitas Jurnal tidak ditemukan.',
        );
      final controller = buildController(repository, journalGateway: journal);
      await controller.load();

      controller.incrementTask(categoryId: 'cat_1', taskId: 'task_1');
      await pumpEventQueue();
      controller.undoLastIncrement();
      await pumpEventQueue();

      final task = controller.state.data!.allTasks.first;
      expect(task.totalCount, 120);
      expect(task.countOn(today), 15);
      expect(controller.state.lastIncrement, isNull);
      expect(controller.state.actionMessage, contains('Jurnal'));
      expect(controller.state.actionMessage, contains('dikurangi'));
    },
  );
}

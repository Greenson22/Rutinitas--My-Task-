import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/features/task_master_new/data/exceptions/task_master_exceptions.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/category.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/daily_progress.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_kind.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_master_data.dart';
import 'package:rutinitasku/features/task_master_new/presentation/screens/task_master_screen.dart';

import '../support/fake_task_repository.dart';

void main() {
  final now = DateTime(2026, 11, 14, 12);
  final today = DailyProgress.dateKey(now);

  TaskFixtures taskBuilder() => TaskFixtures(now, today);

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
          tasks: [taskBuilder().habit(), taskBuilder().progress()],
        ),
      ],
    );
  }

  Widget app(FakeTaskRepository repository) {
    return MaterialApp(
      home: TaskMasterNewScreen(repository: repository, clock: () => now),
    );
  }

  Future<void> openDetail(WidgetTester tester) async {
    final finder = find.byKey(const Key('manageTasks_cat_1'));
    await tester.scrollUntilVisible(
      finder,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> openTaskMenu(WidgetTester tester, String taskId) async {
    await tester.tap(find.byKey(Key('taskMenu_$taskId')));
    await tester.pumpAndSettle();
  }

  Future<void> selectKind(WidgetTester tester, String label) async {
    await tester.tap(find.byKey(const Key('taskKindField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  group('daftar tugas', () {
    testWidgets('menampilkan badge jenis, status, hitungan, dan progress bar', (
      tester,
    ) async {
      final repository = FakeTaskRepository(data: sampleData());
      await tester.pumpWidget(app(repository));
      await tester.pumpAndSettle();
      await openDetail(tester);

      expect(find.text('Push up'), findsOneWidget);
      expect(find.text('Baca buku'), findsOneWidget);
      expect(find.text('Kebiasaan'), findsOneWidget);
      expect(find.text('Progres'), findsOneWidget);
      expect(find.text('Aktif'), findsNWidgets(2));
      expect(find.textContaining('Hari ini 15 / 20'), findsOneWidget);
      expect(find.textContaining('Hari ini 3'), findsOneWidget);
      expect(find.text('40 / 100'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('empty state mengajak menambah tugas pertama', (tester) async {
      final data = sampleData();
      final empty = TaskMasterData(
        schemaVersion: 2,
        categories: [data.categories.single.copyWith(tasks: const [])],
      );
      final repository = FakeTaskRepository(data: empty);

      await tester.pumpWidget(app(repository));
      await tester.pumpAndSettle();
      await openDetail(tester);

      expect(find.text('Belum ada tugas'), findsOneWidget);
      expect(find.byKey(const Key('emptyAddTaskButton')), findsOneWidget);
    });
  });

  group('form tugas', () {
    testWidgets('pengguna dapat menambah tugas baru ke kategori', (
      tester,
    ) async {
      final repository = FakeTaskRepository(data: sampleData());
      await tester.pumpWidget(app(repository));
      await tester.pumpAndSettle();
      await openDetail(tester);

      await tester.tap(find.byKey(const Key('addTaskButton')));
      await tester.pumpAndSettle();

      expect(find.text('Tambah Tugas Baru'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('taskNameField')), 'Sit up');
      await tester.enterText(
        find.byKey(const Key('taskTargetDailyField')),
        '25',
      );
      await tester.tap(find.byKey(const Key('taskSaveButton')));
      await tester.pumpAndSettle();

      expect(find.text('Tambah Tugas Baru'), findsNothing);
      expect(find.text('Sit up'), findsOneWidget);

      final created = repository.data!.categories.single.tasks.last;
      expect(created.name, 'Sit up');
      expect(created.kind, TaskKind.habit);
      expect(created.targetDaily, 25);
      expect(created.isActive, isTrue);
    });

    testWidgets('Progress mewajibkan target total lebih dari nol', (
      tester,
    ) async {
      final repository = FakeTaskRepository(data: sampleData());
      await tester.pumpWidget(app(repository));
      await tester.pumpAndSettle();
      await openDetail(tester);

      await tester.tap(find.byKey(const Key('addTaskButton')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('taskNameField')),
        'Lari 10 km',
      );
      await selectKind(tester, 'Progres');
      await tester.tap(find.byKey(const Key('taskSaveButton')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Target total wajib lebih dari 0'),
        findsOneWidget,
      );
      expect(find.text('Tambah Tugas Baru'), findsOneWidget);
      expect(repository.data!.categories.single.tasks, hasLength(2));

      await tester.enterText(
        find.byKey(const Key('taskTargetTotalField')),
        '10',
      );
      await tester.tap(find.byKey(const Key('taskSaveButton')));
      await tester.pumpAndSettle();

      expect(find.text('Tambah Tugas Baru'), findsNothing);
      final created = repository.data!.categories.single.tasks.last;
      expect(created.kind, TaskKind.progress);
      expect(created.targetTotal, 10);
    });

    testWidgets('target harian negatif ditolak', (tester) async {
      final repository = FakeTaskRepository(data: sampleData());
      await tester.pumpWidget(app(repository));
      await tester.pumpAndSettle();
      await openDetail(tester);

      await tester.tap(find.byKey(const Key('addTaskButton')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('taskNameField')), 'Sit up');
      await tester.enterText(
        find.byKey(const Key('taskTargetDailyField')),
        '-2',
      );
      await tester.tap(find.byKey(const Key('taskSaveButton')));
      await tester.pumpAndSettle();

      expect(find.text('Target harian tidak boleh negatif'), findsOneWidget);
      expect(repository.data!.categories.single.tasks, hasLength(2));
    });

    testWidgets('kegagalan menyimpan menampilkan pesan dan bisa dicoba lagi', (
      tester,
    ) async {
      final repository = FakeTaskRepository(data: sampleData());
      repository.taskActionError = TaskDataSourceException(
        'Gagal menulis file Task Master.',
      );
      await tester.pumpWidget(app(repository));
      await tester.pumpAndSettle();
      await openDetail(tester);

      await tester.tap(find.byKey(const Key('addTaskButton')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('taskNameField')), 'Sit up');
      await tester.tap(find.byKey(const Key('taskSaveButton')));
      await tester.pumpAndSettle();

      expect(find.text('Gagal menulis file Task Master.'), findsWidgets);
      await tester.tap(find.byKey(const Key('taskCancelButton')));
      await tester.pumpAndSettle();

      expect(find.text('Gagal menulis file Task Master.'), findsOneWidget);
      expect(find.byKey(const Key('retryActionButton')), findsOneWidget);

      repository.taskActionError = null;
      await tester.tap(find.byKey(const Key('retryActionButton')));
      await tester.pumpAndSettle();

      expect(find.text('Sit up'), findsOneWidget);
      expect(find.byKey(const Key('retryActionButton')), findsNothing);
    });

    testWidgets('pengguna dapat mengedit semua field tanpa kehilangan id', (
      tester,
    ) async {
      final repository = FakeTaskRepository(data: sampleData());
      await tester.pumpWidget(app(repository));
      await tester.pumpAndSettle();
      await openDetail(tester);

      await openTaskMenu(tester, 'task_1');
      await tester.tap(find.text('Ubah'));
      await tester.pumpAndSettle();

      expect(find.text('Ubah Tugas'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('taskNameField')),
        'Push up pagi',
      );
      await selectKind(tester, 'Progres');
      await tester.enterText(
        find.byKey(const Key('taskTargetDailyField')),
        '30',
      );
      await tester.enterText(
        find.byKey(const Key('taskTargetTotalField')),
        '500',
      );
      final switchFinder = find.byKey(const Key('taskActiveSwitch'));
      await tester.scrollUntilVisible(
        switchFinder,
        100,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('taskSaveButton')));
      await tester.pumpAndSettle();

      expect(find.text('Ubah Tugas'), findsNothing);
      final edited = repository.data!.categories.single.tasks.first;
      expect(edited.id, 'task_1');
      expect(edited.name, 'Push up pagi');
      expect(edited.kind, TaskKind.progress);
      expect(edited.targetDaily, 30);
      expect(edited.targetTotal, 500);
      expect(edited.isActive, isFalse);
      expect(edited.totalCount, 120);
      expect(edited.countOn(today), 15);

      expect(find.text('Push up pagi'), findsOneWidget);
      expect(find.text('Nonaktif'), findsOneWidget);
    });
  });

  group('status dan hapus tugas', () {
    testWidgets('pengguna dapat menonaktifkan dan mengaktifkan kembali', (
      tester,
    ) async {
      final repository = FakeTaskRepository(data: sampleData());
      await tester.pumpWidget(app(repository));
      await tester.pumpAndSettle();
      await openDetail(tester);

      await openTaskMenu(tester, 'task_1');
      await tester.tap(find.text('Nonaktifkan'));
      await tester.pumpAndSettle();

      expect(repository.data!.categories.single.tasks.first.isActive, isFalse);
      expect(find.text('Nonaktif'), findsOneWidget);

      await openTaskMenu(tester, 'task_1');
      await tester.tap(find.text('Aktifkan'));
      await tester.pumpAndSettle();

      expect(repository.data!.categories.single.tasks.first.isActive, isTrue);
      expect(find.text('Nonaktif'), findsNothing);
    });

    testWidgets('hapus tugas meminta konfirmasi', (tester) async {
      final repository = FakeTaskRepository(data: sampleData());
      await tester.pumpWidget(app(repository));
      await tester.pumpAndSettle();
      await openDetail(tester);

      await openTaskMenu(tester, 'task_1');
      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();

      expect(find.text('Hapus tugas?'), findsOneWidget);
      expect(find.textContaining('Push up'), findsWidgets);
      await tester.tap(find.byKey(const Key('deleteTaskCancelButton')));
      await tester.pumpAndSettle();
      expect(repository.data!.categories.single.tasks, hasLength(2));

      await openTaskMenu(tester, 'task_1');
      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('deleteTaskConfirmButton')));
      await tester.pumpAndSettle();

      expect(repository.data!.categories.single.tasks, hasLength(1));
      expect(find.text('Push up'), findsNothing);
    });

    testWidgets('perubahan tugas bertahan setelah layar dibuka ulang', (
      tester,
    ) async {
      final repository = FakeTaskRepository(data: sampleData());
      await tester.pumpWidget(app(repository));
      await tester.pumpAndSettle();
      await openDetail(tester);

      await tester.tap(find.byKey(const Key('addTaskButton')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('taskNameField')), 'Sit up');
      await tester.enterText(
        find.byKey(const Key('taskTargetDailyField')),
        '25',
      );
      await tester.tap(find.byKey(const Key('taskSaveButton')));
      await tester.pumpAndSettle();

      // Simulasikan aplikasi ditutup lalu dibuka kembali.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app(repository));
      await tester.pumpAndSettle();
      await openDetail(tester);

      expect(find.text('Sit up'), findsOneWidget);
      expect(find.textContaining('Hari ini 0 / 25'), findsOneWidget);
    });
  });
}

class TaskFixtures {
  TaskFixtures(this.now, this.today);

  final DateTime now;
  final String today;

  Task habit() {
    return Task(
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
      history: {today: DailyProgress(date: today, count: 15, updatedAt: now)},
    );
  }

  Task progress() {
    return Task(
      id: 'task_2',
      categoryId: 'cat_1',
      name: 'Baca buku',
      kind: TaskKind.progress,
      isActive: true,
      sortOrder: 1,
      targetDaily: 1,
      targetTotal: 100,
      totalCount: 40,
      createdAt: now,
      updatedAt: now,
      history: {today: DailyProgress(date: today, count: 3, updatedAt: now)},
    );
  }
}

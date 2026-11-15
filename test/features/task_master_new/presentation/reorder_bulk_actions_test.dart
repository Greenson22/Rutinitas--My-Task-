import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

  Task task({
    required String id,
    required String categoryId,
    required String name,
    required int sortOrder,
    int totalCount = 10,
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
      totalCount: totalCount,
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
            task(
              id: 'task_3',
              categoryId: 'cat_1',
              name: 'Plank',
              sortOrder: 2,
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
              id: 'task_4',
              categoryId: 'cat_2',
              name: 'Baca buku',
              sortOrder: 0,
            ),
          ],
        ),
      ],
    );
  }

  Widget app(FakeTaskRepository repository) {
    return MaterialApp(
      home: TaskMasterNewScreen(repository: repository, clock: () => now),
    );
  }

  Future<void> openDetail(
    WidgetTester tester, {
    String categoryId = 'cat_1',
  }) async {
    final finder = find.byKey(Key('manageTasks_$categoryId'));
    await tester.scrollUntilVisible(
      finder,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> reopenApp(
    WidgetTester tester,
    FakeTaskRepository repository,
  ) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();
  }

  List<Task> orderedTasks(FakeTaskRepository repository, String categoryId) {
    return [...repository.data!.categoryById(categoryId)!.tasks]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  group('reorder tugas', () {
    testWidgets('tombol panah mengubah urutan dan bertahan setelah reload', (
      tester,
    ) async {
      final repository = FakeTaskRepository(data: sampleData());
      await tester.pumpWidget(app(repository));
      await tester.pumpAndSettle();
      await openDetail(tester);

      await tester.tap(find.byKey(const Key('reorderTasksButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('reorderTaskHandle_task_1')), findsOneWidget);
      await tester.tap(find.byKey(const Key('moveTaskDown_task_1')));
      await tester.pumpAndSettle();

      expect(orderedTasks(repository, 'cat_1').map((item) => item.id), [
        'task_2',
        'task_1',
        'task_3',
      ]);
      expect(orderedTasks(repository, 'cat_1').map((item) => item.sortOrder), [
        0,
        1,
        2,
      ]);

      await reopenApp(tester, repository);
      await openDetail(tester);

      final first = tester.getTopLeft(find.text('Sit up')).dy;
      final second = tester.getTopLeft(find.text('Push up')).dy;
      expect(first, lessThan(second));
    });

    testWidgets('drag handle mengubah urutan tugas', (tester) async {
      final repository = FakeTaskRepository(data: sampleData());
      await tester.pumpWidget(app(repository));
      await tester.pumpAndSettle();
      await openDetail(tester);

      await tester.tap(find.byKey(const Key('reorderTasksButton')));
      await tester.pumpAndSettle();

      await tester.drag(
        find.byKey(const Key('reorderTaskHandle_task_1')),
        const Offset(0, 120),
      );
      await tester.pumpAndSettle();

      expect(orderedTasks(repository, 'cat_1').first.id, isNot('task_1'));
    });

    testWidgets('mode urutkan keluar dengan tombol Selesai', (tester) async {
      final repository = FakeTaskRepository(data: sampleData());
      await tester.pumpWidget(app(repository));
      await tester.pumpAndSettle();
      await openDetail(tester);

      await tester.tap(find.byKey(const Key('reorderTasksButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('finishReorderButton')), findsOneWidget);

      await tester.tap(find.byKey(const Key('finishReorderButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('finishReorderButton')), findsNothing);
      expect(find.byKey(const Key('addTaskButton')), findsOneWidget);
    });
  });

  group('pindah kategori', () {
    testWidgets(
      'tugas pindah tanpa kehilangan id dan bertahan setelah reload',
      (tester) async {
        final repository = FakeTaskRepository(data: sampleData());
        await tester.pumpWidget(app(repository));
        await tester.pumpAndSettle();
        await openDetail(tester);

        await tester.tap(find.byKey(const Key('taskMenu_task_1')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Pindahkan'));
        await tester.pumpAndSettle();

        expect(find.text('Pindahkan tugas'), findsOneWidget);
        await tester.tap(find.byKey(const Key('moveTaskOption_cat_2')));
        await tester.pumpAndSettle();

        expect(
          repository.data!.categoryById('cat_1')!.tasks.map((item) => item.id),
          isNot(contains('task_1')),
        );
        final moved = repository.data!.categoryById('cat_2')!.tasks.last;
        expect(moved.id, 'task_1');
        expect(moved.categoryId, 'cat_2');
        expect(moved.name, 'Push up');
        expect(moved.totalCount, 10);

        await reopenApp(tester, repository);
        await openDetail(tester, categoryId: 'cat_2');
        expect(find.text('Push up'), findsOneWidget);
        expect(find.text('Baca buku'), findsOneWidget);
      },
    );

    testWidgets('kategori saat ini tidak muncul sebagai tujuan', (
      tester,
    ) async {
      final repository = FakeTaskRepository(data: sampleData());
      await tester.pumpWidget(app(repository));
      await tester.pumpAndSettle();
      await openDetail(tester);

      await tester.tap(find.byKey(const Key('taskMenu_task_1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pindahkan'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('moveTaskOption_cat_2')), findsOneWidget);
      expect(find.byKey(const Key('moveTaskOption_cat_1')), findsNothing);
    });
  });

  group('aksi massal', () {
    testWidgets(
      'long press masuk mode seleksi dan nonaktif massal keluar mode',
      (tester) async {
        final repository = FakeTaskRepository(data: sampleData());
        await tester.pumpWidget(app(repository));
        await tester.pumpAndSettle();
        await openDetail(tester);

        await tester.longPress(find.byKey(const Key('taskTile_task_1')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('exitSelectionButton')), findsOneWidget);
        expect(find.text('1 tugas dipilih'), findsOneWidget);

        await tester.tap(find.byKey(const Key('taskTile_task_2')));
        await tester.pumpAndSettle();
        expect(find.text('2 tugas dipilih'), findsOneWidget);

        await tester.tap(find.byKey(const Key('bulkDeactivateButton')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('exitSelectionButton')), findsNothing);
        final tasks = repository.data!.categoryById('cat_1')!.tasks;
        expect(tasks[0].isActive, isFalse);
        expect(tasks[1].isActive, isFalse);
        expect(tasks[2].isActive, isTrue);
      },
    );

    testWidgets('aktif massal mengaktifkan kembali tugas terpilih', (
      tester,
    ) async {
      final data = sampleData();
      final inactive = data.copyWith(
        categories: [
          data.categories.first.copyWith(
            tasks: [
              for (final item in data.categories.first.tasks)
                item.copyWith(isActive: false),
            ],
          ),
          data.categories.last,
        ],
      );
      final repository = FakeTaskRepository(data: inactive);
      await tester.pumpWidget(app(repository));
      await tester.pumpAndSettle();
      await openDetail(tester);

      await tester.longPress(find.byKey(const Key('taskTile_task_1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('bulkActivateButton')));
      await tester.pumpAndSettle();

      final tasks = repository.data!.categoryById('cat_1')!.tasks;
      expect(tasks.first.isActive, isTrue);
      expect(tasks[1].isActive, isFalse);
      expect(find.byKey(const Key('exitSelectionButton')), findsNothing);
    });

    testWidgets('hapus massal meminta konfirmasi dan menghapus terpilih', (
      tester,
    ) async {
      final repository = FakeTaskRepository(data: sampleData());
      await tester.pumpWidget(app(repository));
      await tester.pumpAndSettle();
      await openDetail(tester);

      await tester.longPress(find.byKey(const Key('taskTile_task_1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('taskTile_task_2')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bulkDeleteButton')));
      await tester.pumpAndSettle();

      expect(find.text('Hapus 2 tugas?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('bulkDeleteCancelButton')));
      await tester.pumpAndSettle();
      expect(repository.data!.categoryById('cat_1')!.tasks, hasLength(3));

      await tester.tap(find.byKey(const Key('bulkDeleteButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('bulkDeleteConfirmButton')));
      await tester.pumpAndSettle();

      expect(
        repository.data!.categoryById('cat_1')!.tasks.map((item) => item.id),
        ['task_3'],
      );
      expect(find.byKey(const Key('exitSelectionButton')), findsNothing);
    });

    testWidgets('tombol tutup keluar dari mode seleksi tanpa mengubah data', (
      tester,
    ) async {
      final repository = FakeTaskRepository(data: sampleData());
      await tester.pumpWidget(app(repository));
      await tester.pumpAndSettle();
      await openDetail(tester);

      await tester.longPress(find.byKey(const Key('taskTile_task_1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('exitSelectionButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('exitSelectionButton')), findsNothing);
      expect(repository.data!.categoryById('cat_1')!.tasks, hasLength(3));
    });
  });

  group('reorder kategori', () {
    testWidgets('tombol panah mengubah urutan dan bertahan setelah reload', (
      tester,
    ) async {
      final repository = FakeTaskRepository(data: sampleData());
      await tester.pumpWidget(app(repository));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('reorderCategoriesButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('categoryReorderSheet')), findsOneWidget);
      expect(find.byKey(const Key('categoryDragHandle_cat_1')), findsOneWidget);

      await tester.tap(find.byKey(const Key('moveCategoryDown_cat_1')));
      await tester.pumpAndSettle();

      final ordered = [...repository.data!.categories]
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      expect(ordered.map((category) => category.id), ['cat_2', 'cat_1']);
      expect(ordered.map((category) => category.sortOrder), [0, 1]);

      await tester.tap(find.byKey(const Key('closeCategoryReorderButton')));
      await tester.pumpAndSettle();
      await reopenApp(tester, repository);

      await tester.tap(find.byKey(const Key('reorderCategoriesButton')));
      await tester.pumpAndSettle();
      final belajar = tester
          .getTopLeft(find.byKey(const ValueKey('reorderCategory_cat_2')))
          .dy;
      final olahraga = tester
          .getTopLeft(find.byKey(const ValueKey('reorderCategory_cat_1')))
          .dy;
      expect(belajar, lessThan(olahraga));
    });

    testWidgets('drag handle mengubah urutan kategori', (tester) async {
      final repository = FakeTaskRepository(data: sampleData());
      await tester.pumpWidget(app(repository));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('reorderCategoriesButton')));
      await tester.pumpAndSettle();

      await tester.timedDrag(
        find.byKey(const Key('categoryDragHandle_cat_1')),
        const Offset(0, 200),
        const Duration(seconds: 1),
      );
      await tester.pumpAndSettle();

      final ordered = [...repository.data!.categories]
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      expect(ordered.first.id, 'cat_2');
    });
  });
}

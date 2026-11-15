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
    required TaskKind kind,
    required int targetDaily,
    required int targetTotal,
    required int totalCount,
    required int countToday,
    bool isActive = true,
    int sortOrder = 0,
  }) {
    return Task(
      id: id,
      categoryId: categoryId,
      name: name,
      kind: kind,
      isActive: isActive,
      sortOrder: sortOrder,
      targetDaily: targetDaily,
      targetTotal: targetTotal,
      totalCount: totalCount,
      createdAt: now,
      updatedAt: now,
      history: countToday == 0
          ? const {}
          : {
              today: DailyProgress(
                date: today,
                count: countToday,
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
          tasks: [
            task(
              id: 'task_1',
              categoryId: 'cat_1',
              name: 'Push up',
              kind: TaskKind.habit,
              targetDaily: 20,
              targetTotal: 0,
              totalCount: 120,
              countToday: 15,
              sortOrder: 0,
            ),
            task(
              id: 'task_2',
              categoryId: 'cat_1',
              name: 'Sit up',
              kind: TaskKind.habit,
              targetDaily: 10,
              targetTotal: 0,
              totalCount: 40,
              countToday: 0,
              isActive: false,
              sortOrder: 1,
            ),
            task(
              id: 'task_3',
              categoryId: 'cat_1',
              name: 'Lari pagi',
              kind: TaskKind.counter,
              targetDaily: 0,
              targetTotal: 0,
              totalCount: 3,
              countToday: 0,
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
              kind: TaskKind.progress,
              targetDaily: 1,
              targetTotal: 100,
              totalCount: 40,
              countToday: 1,
              sortOrder: 0,
            ),
            task(
              id: 'task_5',
              categoryId: 'cat_2',
              name: 'Menulis catatan',
              kind: TaskKind.habit,
              targetDaily: 0,
              targetTotal: 0,
              totalCount: 2,
              countToday: 0,
              sortOrder: 1,
            ),
          ],
        ),
        Category(
          id: 'cat_hidden',
          name: 'Kesehatan',
          icon: '💊',
          isHidden: true,
          sortOrder: 2,
          tasks: [
            task(
              id: 'task_hidden',
              categoryId: 'cat_hidden',
              name: 'Minum air',
              kind: TaskKind.habit,
              targetDaily: 5,
              targetTotal: 0,
              totalCount: 30,
              countToday: 5,
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

  Future<void> pumpReady(
    WidgetTester tester,
    FakeTaskRepository repository,
  ) async {
    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();
  }

  Future<void> openSearch(WidgetTester tester) async {
    if (find.byKey(const Key('taskSearchField')).evaluate().isEmpty) {
      await tester.tap(find.byKey(const Key('openSearchButton')));
      await tester.pumpAndSettle();
    }
  }

  Future<void> search(WidgetTester tester, String query) async {
    await openSearch(tester);
    await tester.enterText(find.byKey(const Key('taskSearchField')), query);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();
  }

  Future<void> selectFilter(WidgetTester tester, String name) async {
    await openSearch(tester);
    await tester.tap(find.byKey(Key('taskFilter_$name')));
    await tester.pumpAndSettle();
  }

  Finder inactiveBadge(String taskId) {
    return find.descendant(
      of: find.byKey(Key('taskTile_$taskId')),
      matching: find.text('Nonaktif'),
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

  group('pencarian', () {
    testWidgets('menemukan tugas lintas kategori dan mengelompokkannya', (
      tester,
    ) async {
      final repository = FakeTaskRepository(data: sampleData());
      await pumpReady(tester, repository);

      await search(tester, 'buku');

      expect(find.text('Hasil pencarian'), findsOneWidget);
      expect(find.byKey(const Key('searchGroup_cat_2')), findsOneWidget);
      expect(find.text('Baca buku'), findsOneWidget);
      expect(find.text('Belajar'), findsOneWidget);
      expect(find.byKey(const Key('searchGroup_cat_1')), findsNothing);
      expect(find.text('Push up'), findsNothing);
      expect(find.byKey(const Key('summaryActiveCategories')), findsNothing);
    });

    testWidgets('menemukan kategori berdasarkan nama dan peka huruf kecil', (
      tester,
    ) async {
      final repository = FakeTaskRepository(data: sampleData());
      await pumpReady(tester, repository);

      await search(tester, 'olahraga');

      expect(find.byKey(const Key('searchGroup_cat_1')), findsOneWidget);
      expect(find.text('Push up'), findsOneWidget);
      expect(find.text('Sit up'), findsOneWidget);
      expect(find.text('Lari pagi'), findsOneWidget);
      expect(inactiveBadge('task_2'), findsOneWidget);
      expect(find.byKey(const Key('searchGroup_cat_2')), findsNothing);
      expect(find.text('Minum air'), findsNothing);
    });

    testWidgets('hasil baru muncul setelah debounce 250 ms', (tester) async {
      final repository = FakeTaskRepository(data: sampleData());
      await pumpReady(tester, repository);
      await openSearch(tester);

      await tester.enterText(find.byKey(const Key('taskSearchField')), 'buku');
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Hasil pencarian'), findsNothing);

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.text('Hasil pencarian'), findsOneWidget);
      expect(find.text('Baca buku'), findsOneWidget);
    });
  });

  group('filter', () {
    testWidgets('filter aktif hanya menampilkan tugas aktif', (tester) async {
      final repository = FakeTaskRepository(data: sampleData());
      await pumpReady(tester, repository);

      await selectFilter(tester, 'active');

      expect(find.text('Hasil filter'), findsOneWidget);
      expect(find.text('Push up'), findsOneWidget);
      expect(find.text('Lari pagi'), findsOneWidget);
      expect(find.text('Baca buku'), findsOneWidget);
      expect(find.text('Sit up'), findsNothing);
      expect(find.text('Minum air'), findsNothing);
    });

    testWidgets('filter nonaktif menampilkan badge nonaktif', (tester) async {
      final repository = FakeTaskRepository(data: sampleData());
      await pumpReady(tester, repository);

      await selectFilter(tester, 'inactive');

      expect(find.text('Sit up'), findsOneWidget);
      expect(inactiveBadge('task_2'), findsOneWidget);
      expect(find.text('Push up'), findsNothing);
      expect(find.byKey(const Key('searchGroup_cat_2')), findsNothing);
    });

    testWidgets('filter punya target hari ini menyaring tugas tanpa target', (
      tester,
    ) async {
      final repository = FakeTaskRepository(data: sampleData());
      await pumpReady(tester, repository);

      await selectFilter(tester, 'hasTargetToday');

      expect(find.text('Push up'), findsOneWidget);
      expect(find.text('Baca buku'), findsOneWidget);
      expect(find.text('Lari pagi'), findsNothing);
      expect(find.text('Menulis catatan'), findsNothing);
      // Filter target hari ini tidak menyiratkan status aktif.
      expect(find.text('Sit up'), findsOneWidget);
    });

    testWidgets('pencarian dan filter dapat dipakai bersamaan', (tester) async {
      final repository = FakeTaskRepository(data: sampleData());
      await pumpReady(tester, repository);

      await search(tester, 'up');
      expect(find.text('Push up'), findsOneWidget);
      expect(find.text('Sit up'), findsOneWidget);

      await selectFilter(tester, 'inactive');

      expect(find.text('Sit up'), findsOneWidget);
      expect(find.text('Push up'), findsNothing);
      expect(inactiveBadge('task_2'), findsOneWidget);
    });
  });

  group('empty state pencarian', () {
    testWidgets('menampilkan aksi untuk menghapus pencarian dan filter', (
      tester,
    ) async {
      final repository = FakeTaskRepository(data: sampleData());
      await pumpReady(tester, repository);

      await search(tester, 'tidak ada');
      await selectFilter(tester, 'inactive');

      expect(find.byKey(const Key('searchEmptyState')), findsOneWidget);
      expect(find.text('Tidak ada hasil'), findsOneWidget);
      expect(find.text('Push up'), findsNothing);

      await tester.tap(find.byKey(const Key('clearSearchFiltersButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('searchEmptyState')), findsNothing);
      expect(find.byKey(const Key('summaryActiveCategories')), findsOneWidget);
      expect(find.text('Push up'), findsOneWidget);
      expect(find.byKey(const Key('taskSearchField')), findsNothing);
    });

    testWidgets('tombol hapus di kolom pencarian mengosongkan query', (
      tester,
    ) async {
      final repository = FakeTaskRepository(data: sampleData());
      await pumpReady(tester, repository);

      await search(tester, 'buku');
      expect(find.text('Baca buku'), findsOneWidget);

      await tester.tap(find.byKey(const Key('taskSearchClearButton')));
      await tester.pumpAndSettle();

      expect(find.text('Hasil pencarian'), findsNothing);
      expect(find.text('Baca buku'), findsOneWidget);
    });
  });

  group('detail kategori', () {
    testWidgets('pencarian, filter, dan empty state bekerja di detail', (
      tester,
    ) async {
      final repository = FakeTaskRepository(data: sampleData());
      await pumpReady(tester, repository);
      await openDetail(tester);

      await tester.enterText(find.byKey(const Key('taskSearchField')), 'push');
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      expect(find.text('Push up'), findsOneWidget);
      expect(find.text('Sit up'), findsNothing);
      expect(find.text('1 dari 3 tugas'), findsOneWidget);

      await tester.tap(find.byKey(const Key('taskSearchClearButton')));
      await tester.pumpAndSettle();
      await selectFilter(tester, 'inactive');

      expect(find.text('Sit up'), findsOneWidget);
      expect(inactiveBadge('task_2'), findsOneWidget);
      expect(find.text('Push up'), findsNothing);

      await search(tester, 'tidak ada');

      expect(find.byKey(const Key('searchEmptyState')), findsOneWidget);
      await tester.tap(find.byKey(const Key('clearSearchFiltersButton')));
      await tester.pumpAndSettle();

      expect(find.text('Push up'), findsOneWidget);
      expect(find.text('Sit up'), findsOneWidget);
      expect(find.text('Lari pagi'), findsOneWidget);
    });
  });
}

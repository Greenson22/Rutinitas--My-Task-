import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/category.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/daily_progress.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_kind.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_master_data.dart';
import 'package:rutinitasku/features/task_master_new/domain/repositories/journal_gateway.dart';
import 'package:rutinitasku/features/task_master_new/presentation/screens/task_master_screen.dart';

import '../support/fake_journal_gateway.dart';
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
              name: 'Baca buku',
              kind: TaskKind.progress,
              targetDaily: 1,
              targetTotal: 100,
              totalCount: 100,
              countToday: 1,
              sortOrder: 1,
            ),
          ],
        ),
        Category(
          id: 'cat_hidden',
          name: 'Kesehatan',
          icon: '💊',
          isHidden: true,
          sortOrder: 1,
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
        Category(
          id: 'cat_2',
          name: 'Belajar',
          icon: '📚',
          isHidden: false,
          sortOrder: 2,
          tasks: [
            task(
              id: 'task_4',
              categoryId: 'cat_2',
              name: 'Catatan harian',
              kind: TaskKind.counter,
              targetDaily: 0,
              targetTotal: 0,
              totalCount: 3,
              countToday: 0,
            ),
          ],
        ),
      ],
    );
  }

  Widget app(
    FakeTaskRepository repository, {
    FakeJournalGateway? journal,
    DateTime Function()? clock,
  }) {
    return MaterialApp(
      home: TaskMasterNewScreen(
        repository: repository,
        journalGateway: journal,
        clock: clock ?? () => now,
      ),
    );
  }

  String summaryValue(WidgetTester tester, String key) {
    final finder = find.descendant(
      of: find.byKey(Key(key)),
      matching: find.byType(Text),
    );
    return tester.widget<Text>(finder.first).data!;
  }

  testWidgets('dashboard menampilkan loading state', (tester) async {
    final repository = FakeTaskRepository(data: sampleData())
      ..loadCompleter = Completer<TaskMasterData>();

    await tester.pumpWidget(app(repository));

    expect(find.text('Memuat data Task Master...'), findsOneWidget);

    repository.loadCompleter!.complete(sampleData());
    await tester.pumpAndSettle();
  });

  testWidgets('dashboard siap menampilkan ringkasan, Hari Ini, dan kategori', (
    tester,
  ) async {
    final repository = FakeTaskRepository(data: sampleData());
    final journal = FakeJournalGateway(
      linkState: const JournalLinkState(
        linkedTaskIds: {'task_1'},
        incrementMinutes: 45,
        todayMinutes: 75,
      ),
    );

    await tester.pumpWidget(app(repository, journal: journal));
    await tester.pumpAndSettle();

    // Empat kartu ringkasan akurat dan mengabaikan kategori tersembunyi.
    expect(summaryValue(tester, 'summaryActiveCategories'), '2');
    expect(summaryValue(tester, 'summaryActiveTasks'), '3');
    expect(summaryValue(tester, 'summaryCompletedTargets'), '1');
    expect(summaryValue(tester, 'summaryJournalMinutes'), '1 jam 15 mnt');

    // Daftar "Hari Ini" hanya memuat tugas bertarget atau beraktivitas.
    expect(find.text('Hari Ini'), findsOneWidget);
    expect(find.text('Push up'), findsOneWidget);
    expect(find.text('Baca buku'), findsOneWidget);
    expect(find.byKey(const Key('todayTask_task_4')), findsNothing);
    expect(find.text('Minum air'), findsNothing);

    // Setiap baris menampilkan kategori, progres harian, dan status target.
    expect(find.text('🏃 Olahraga'), findsNWidgets(2));
    expect(find.textContaining('Hari ini 15 / 20'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('taskTargetStatus_task_2')),
        matching: find.text('Target tercapai'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('taskTargetStatus_task_1')),
        matching: find.text('Belum tercapai'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('journalLinkBadge_task_1')), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('manageTasks_cat_2')),
      250,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.byKey(const Key('categoryCard_cat_1')), findsOneWidget);
    expect(find.byKey(const Key('categoryCard_cat_2')), findsOneWidget);
    expect(find.byKey(const Key('categoryCard_cat_hidden')), findsNothing);
    expect(find.text('2 tugas aktif'), findsOneWidget);
    expect(find.text('Hari ini 1 / 2 target'), findsOneWidget);
    expect(find.text('Belum ada target hari ini'), findsOneWidget);
  });

  testWidgets('empty state mengarahkan pengguna membuat kategori pertama', (
    tester,
  ) async {
    final repository = FakeTaskRepository(data: TaskMasterData.empty());

    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada kategori'), findsOneWidget);
    expect(find.byKey(const Key('emptyCreateCategoryButton')), findsOneWidget);

    await tester.tap(find.byKey(const Key('emptyCreateCategoryButton')));
    await tester.pumpAndSettle();

    expect(find.text('Tambah Kategori Baru'), findsOneWidget);
  });

  testWidgets('empty state ringan tampil saat belum ada tugas hari ini', (
    tester,
  ) async {
    final repository = FakeTaskRepository(
      data: TaskMasterData(
        schemaVersion: 2,
        categories: [
          Category(
            id: 'cat_1',
            name: 'Catatan',
            icon: '📝',
            isHidden: false,
            sortOrder: 0,
            tasks: [
              task(
                id: 'task_counter',
                categoryId: 'cat_1',
                name: 'Coret-coret',
                kind: TaskKind.counter,
                targetDaily: 0,
                targetTotal: 0,
                totalCount: 0,
                countToday: 0,
              ),
            ],
          ),
        ],
      ),
    );

    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('emptyTodayTasks')), findsOneWidget);
    expect(find.text('Belum ada tugas hari ini'), findsOneWidget);
    expect(summaryValue(tester, 'summaryCompletedTargets'), '0');
  });

  testWidgets('mode tampilkan tersembunyi menampilkan kategori tersembunyi', (
    tester,
  ) async {
    final repository = FakeTaskRepository(data: sampleData());

    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();

    expect(summaryValue(tester, 'summaryActiveCategories'), '2');
    expect(summaryValue(tester, 'summaryActiveTasks'), '3');

    final toggle = find.byKey(const Key('showHiddenToggle'));
    await tester.scrollUntilVisible(
      toggle,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('manageTasks_cat_hidden')),
      250,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.byKey(const Key('categoryCard_cat_hidden')), findsOneWidget);
    expect(find.text('Disembunyikan'), findsOneWidget);
  });

  testWidgets('increment dari dashboard memakai alur Undo yang sama', (
    tester,
  ) async {
    final repository = FakeTaskRepository(data: sampleData());
    final journal = FakeJournalGateway(
      linkState: const JournalLinkState(
        linkedTaskIds: {'task_1'},
        incrementMinutes: 45,
        todayMinutes: 75,
      ),
    );

    await tester.pumpWidget(app(repository, journal: journal));
    await tester.pumpAndSettle();

    expect(find.textContaining('Hari ini 15 / 20'), findsOneWidget);

    await tester.tap(find.byKey(const Key('dashboardIncrement_task_1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.textContaining('Hari ini 16 / 20'), findsOneWidget);
    expect(find.byKey(const Key('incrementSnackBar')), findsOneWidget);
    expect(find.textContaining('Jurnal +45 menit'), findsOneWidget);
    expect(summaryValue(tester, 'summaryJournalMinutes'), '2 jam');

    await tester.tap(find.byKey(const Key('undoIncrementAction')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Hari ini 15 / 20'), findsOneWidget);
    expect(summaryValue(tester, 'summaryJournalMinutes'), '1 jam 15 mnt');
    expect(repository.data!.allTasks.first.totalCount, 120);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}

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

  TaskMasterData sampleData() {
    Task task(String id, String name, int sortOrder) {
      return Task(
        id: id,
        categoryId: 'cat_1',
        name: name,
        kind: TaskKind.habit,
        isActive: true,
        sortOrder: sortOrder,
        targetDaily: 20,
        targetTotal: 0,
        totalCount: 120,
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
          tasks: [task('task_1', 'Push up', 0), task('task_2', 'Baca buku', 1)],
        ),
      ],
    );
  }

  Widget app(FakeTaskRepository repository, FakeJournalGateway journal) {
    return MaterialApp(
      home: TaskMasterNewScreen(
        repository: repository,
        journalGateway: journal,
        clock: () => now,
      ),
    );
  }

  Future<void> openDetail(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('manageTasks_cat_1')));
    await tester.pumpAndSettle();
  }

  testWidgets('dashboard menampilkan indikator Jurnal pada tugas tertaut', (
    tester,
  ) async {
    final repository = FakeTaskRepository(data: sampleData());
    final journal = FakeJournalGateway(
      linkState: const JournalLinkState(
        linkedTaskIds: {'task_1'},
        incrementMinutes: 45,
      ),
    );

    await tester.pumpWidget(app(repository, journal));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('journalLinkBadge_task_1')), findsOneWidget);
    expect(find.byKey(const Key('journalLinkBadge_task_2')), findsNothing);
  });

  testWidgets('tugas tertaut Jurnal menampilkan indikator', (tester) async {
    final repository = FakeTaskRepository(data: sampleData());
    final journal = FakeJournalGateway(
      linkState: const JournalLinkState(
        linkedTaskIds: {'task_1'},
        incrementMinutes: 45,
      ),
    );

    await tester.pumpWidget(app(repository, journal));
    await tester.pumpAndSettle();
    await openDetail(tester);

    expect(find.byKey(const Key('journalLinkBadge_task_1')), findsOneWidget);
    expect(find.byKey(const Key('journalLinkBadge_task_2')), findsNothing);
    expect(find.text('Jurnal'), findsOneWidget);
  });

  testWidgets(
    'increment tertaut menampilkan durasi Jurnal dan undo mengurangi',
    (tester) async {
      final repository = FakeTaskRepository(data: sampleData());
      final journal = FakeJournalGateway(
        linkState: const JournalLinkState(
          linkedTaskIds: {'task_1'},
          incrementMinutes: 45,
        ),
      );

      await tester.pumpWidget(app(repository, journal));
      await tester.pumpAndSettle();
      await openDetail(tester);

      await tester.tap(find.byKey(const Key('incrementTask_task_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('Jurnal +45 menit'), findsOneWidget);

      await tester.tap(find.byKey(const Key('undoIncrementAction')));
      await tester.pumpAndSettle();

      expect(journal.subtractCalls, hasLength(1));
      expect(journal.subtractCalls.single.minutes, 45);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('increment tidak tertaut memberi pesan jelas', (tester) async {
    final repository = FakeTaskRepository(data: sampleData());
    final journal = FakeJournalGateway();

    await tester.pumpWidget(app(repository, journal));
    await tester.pumpAndSettle();
    await openDetail(tester);

    await tester.tap(find.byKey(const Key('incrementTask_task_2')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('Jurnal tidak tertaut'), findsOneWidget);
    expect(journal.addCalls, isEmpty);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}

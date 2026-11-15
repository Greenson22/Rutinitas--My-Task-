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

  String key(int daysAgo) {
    return DailyProgress.dateKey(
      DateTime(now.year, now.month, now.day - daysAgo),
    );
  }

  DailyProgress progress(int daysAgo, int count) {
    return DailyProgress(date: key(daysAgo), count: count, updatedAt: now);
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
            Task(
              id: 'task_1',
              categoryId: 'cat_1',
              name: 'Push up',
              kind: TaskKind.habit,
              isActive: true,
              sortOrder: 0,
              targetDaily: 20,
              targetTotal: 0,
              totalCount: 120,
              createdAt: now.subtract(const Duration(days: 30)),
              updatedAt: now,
              history: {
                key(1): progress(1, 25),
                key(2): progress(2, 20),
                key(3): progress(3, 10),
                key(0): progress(0, 15),
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget app(FakeTaskRepository repository, {DateTime Function()? clock}) {
    return MaterialApp(
      home: TaskMasterNewScreen(
        repository: repository,
        clock: clock ?? () => now,
      ),
    );
  }

  Future<void> openDetail(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('manageTasks_cat_1')));
    await tester.pumpAndSettle();
  }

  testWidgets('menampilkan streak dan riwayat harian sparse', (tester) async {
    final repository = FakeTaskRepository(data: sampleData());
    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('taskStreak_task_1')), findsOneWidget);
    expect(find.text('🔥 2 hari'), findsOneWidget);

    await openDetail(tester);
    await tester.tap(find.byKey(const Key('taskHistory_task_1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('taskHistoryScreen')), findsOneWidget);
    expect(find.text('Riwayat Push up'), findsOneWidget);
    expect(find.text('Streak 2 hari'), findsOneWidget);

    // Empat entri sparse terlihat, termasuk hari ini.
    expect(find.byKey(Key('taskHistoryEntry_${key(0)}')), findsOneWidget);
    expect(find.byKey(Key('taskHistoryEntry_${key(1)}')), findsOneWidget);
    expect(find.byKey(Key('taskHistoryEntry_${key(2)}')), findsOneWidget);
    expect(find.byKey(Key('taskHistoryEntry_${key(3)}')), findsOneWidget);
    expect(find.text('Target harian tercapai • 25×'), findsOneWidget);
    expect(find.text('Di bawah target • 10×'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
  });

  testWidgets('riwayat tetap ada setelah layar dibuka kembali', (tester) async {
    final repository = FakeTaskRepository(data: sampleData());
    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();
    await openDetail(tester);

    await tester.tap(find.byKey(const Key('taskHistory_task_1')));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Simulasikan aplikasi ditutup lalu dibuka kembali.
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();
    await openDetail(tester);

    await tester.tap(find.byKey(const Key('taskHistory_task_1')));
    await tester.pumpAndSettle();

    expect(find.byKey(Key('taskHistoryEntry_${key(1)}')), findsOneWidget);
    expect(find.text('Target harian tercapai • 25×'), findsOneWidget);
  });

  testWidgets('pergantian hari membuat hitungan hari ini nol', (tester) async {
    var clockNow = now;
    final repository = FakeTaskRepository(data: sampleData());
    await tester.pumpWidget(app(repository, clock: () => clockNow));
    await tester.pumpAndSettle();
    await openDetail(tester);

    expect(find.textContaining('Hari ini 15 / 20'), findsOneWidget);

    clockNow = DateTime(2026, 11, 15, 8);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await tester.pumpWidget(app(repository, clock: () => clockNow));
    await tester.pumpAndSettle();
    await openDetail(tester);

    expect(find.textContaining('Hari ini 0 / 20'), findsOneWidget);
    // Riwayat lama tetap ada.
    expect(repository.data!.allTasks.single.countOn(key(0)), 15);

    await tester.tap(find.byKey(const Key('taskHistory_task_1')));
    await tester.pumpAndSettle();
    expect(find.byKey(Key('taskHistoryEntry_${key(0)}')), findsOneWidget);
  });
}

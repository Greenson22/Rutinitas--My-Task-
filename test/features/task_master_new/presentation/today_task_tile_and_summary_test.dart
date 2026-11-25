import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/category.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/daily_progress.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_kind.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/today_visibility.dart';
import 'package:rutinitasku/features/task_master_new/domain/operations/dashboard_summary.dart';
import 'package:rutinitasku/features/task_master_new/presentation/widgets/dashboard_summary_cards.dart';
import 'package:rutinitasku/features/task_master_new/presentation/widgets/today_task_tile.dart';

void main() {
  const todayKey = '2026-11-25';
  final now = DateTime(2026, 11, 25);
  final category = Category(
    id: 'cat1',
    name: 'Umum',
    icon: '📌',
    isHidden: false,
    sortOrder: 0,
  );

  TodayTaskEntry makeEntry(Task task) =>
      TodayTaskEntry(category: category, task: task);

  group('TodayTaskTile — Pewarnaan Tile Selesai', () {
    testWidgets('targetMet == true memiliki latar belakang Color(0xFFE8F5E9)', (
      tester,
    ) async {
      final task = Task(
        id: 't1',
        categoryId: 'cat1',
        name: 'Minum Air',
        kind: TaskKind.habit,
        targetDaily: 2,
        targetTotal: 0,
        totalCount: 0,
        isActive: true,
        sortOrder: 0,
        createdAt: now,
        updatedAt: now,
        history: {todayKey: DailyProgress(date: todayKey, count: 2, updatedAt: now)},
        todayVisibility: TodayVisibility.auto,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TodayTaskTile(
              entry: makeEntry(task),
              todayKey: todayKey,
              onIncrement: () {},
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.byKey(const Key('todayTask_t1')),
      );
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.color, const Color(0xFFE8F5E9));
    });

    testWidgets('targetMet == false memiliki latar belakang transparan', (
      tester,
    ) async {
      final task = Task(
        id: 't2',
        categoryId: 'cat1',
        name: 'Olahraga',
        kind: TaskKind.habit,
        targetDaily: 2,
        targetTotal: 0,
        totalCount: 0,
        isActive: true,
        sortOrder: 0,
        createdAt: now,
        updatedAt: now,
        history: {todayKey: DailyProgress(date: todayKey, count: 1, updatedAt: now)},
        todayVisibility: TodayVisibility.auto,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TodayTaskTile(
              entry: makeEntry(task),
              todayKey: todayKey,
              onIncrement: () {},
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.byKey(const Key('todayTask_t2')),
      );
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.color, Colors.transparent);
    });

    testWidgets(
      'TaskKind.counter tanpa target memiliki latar belakang transparan',
      (tester) async {
        final task = Task(
          id: 't3',
          categoryId: 'cat1',
          name: 'Kopi',
          kind: TaskKind.counter,
          targetDaily: 0,
          targetTotal: 0,
          totalCount: 0,
          isActive: true,
          sortOrder: 0,
          createdAt: now,
          updatedAt: now,
          history: {todayKey: DailyProgress(date: todayKey, count: 3, updatedAt: now)},
          todayVisibility: TodayVisibility.auto,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TodayTaskTile(
                entry: makeEntry(task),
                todayKey: todayKey,
                onIncrement: () {},
              ),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.byKey(const Key('todayTask_t3')),
        );
        final decoration = container.decoration as BoxDecoration?;
        expect(decoration?.color, Colors.transparent);
      },
    );
  });

  group('DashboardSummaryCards — Kartu Target Tercapai X/Y', () {
    testWidgets('semua tugas tercapai menampilkan "X / Y" dengan warna hijau', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DashboardSummaryCards(
              activeCategoryCount: 1,
              activeTaskCount: 3,
              completedTargetsToday: 3,
              todayTasksTotalCount: 3,
              journalMinutesToday: 10,
            ),
          ),
        ),
      );

      expect(find.text('3 / 3'), findsOneWidget);
      final flagIcon = tester.widget<Icon>(find.byIcon(Icons.flag_rounded));
      expect(flagIcon.color, Colors.green[700]);
    });

    testWidgets(
      'sebagian tugas tercapai menampilkan "X / Y" dengan warna oranye',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DashboardSummaryCards(
                activeCategoryCount: 1,
                activeTaskCount: 3,
                completedTargetsToday: 1,
                todayTasksTotalCount: 3,
                journalMinutesToday: 10,
              ),
            ),
          ),
        );

        expect(find.text('1 / 3'), findsOneWidget);
        final flagIcon = tester.widget<Icon>(find.byIcon(Icons.flag_rounded));
        expect(flagIcon.color, Colors.orange[800]);
      },
    );

    testWidgets('tanpa tugas hari ini menampilkan "0 / 0" dengan warna oranye', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DashboardSummaryCards(
              activeCategoryCount: 1,
              activeTaskCount: 0,
              completedTargetsToday: 0,
              todayTasksTotalCount: 0,
              journalMinutesToday: 0,
            ),
          ),
        ),
      );

      expect(find.text('0 / 0'), findsOneWidget);
      final flagIcon = tester.widget<Icon>(find.byIcon(Icons.flag_rounded));
      expect(flagIcon.color, Colors.orange[800]);
    });
  });
}

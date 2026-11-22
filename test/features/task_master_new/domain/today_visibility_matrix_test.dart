import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/category.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/daily_progress.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_kind.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_master_data.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/today_visibility.dart';
import 'package:rutinitasku/features/task_master_new/domain/operations/dashboard_summary.dart';

void main() {
  const todayKey = '2026-11-22';
  final todayDate = DateTime.parse(todayKey);

  group('collectTodayTasks domain matrix', () {
    // Matriks:
    // 3 visibilitas: auto, always, never
    // 4 kondisi tugas:
    //   1. target harian (habit targetDaily > 0)
    //   2. tanpa target (counter tanpa target & tanpa hitungan hari ini)
    //   3. ada aktivitas (counter tanpa target tapi ada countToday > 0)
    //   4. progress dengan target total (progress targetTotal > 0, targetDaily = 0)
    // 2 status aktif: isActive = true / false
    // 2 visibilitas kategori: isHidden = false / true

    for (final visibility in TodayVisibility.values) {
      for (final condition in ['dailyTarget', 'noTarget', 'hasActivity', 'progressTotal']) {
        for (final isActive in [true, false]) {
          for (final categoryHidden in [false, true]) {
            test(
              'visibilitas=$visibility, kondisi=$condition, active=$isActive, catHidden=$categoryHidden',
              () {
                final TaskKind kind;
                final int targetDaily;
                final int targetTotal;
                final Map<String, DailyProgress> history;

                switch (condition) {
                  case 'dailyTarget':
                    kind = TaskKind.habit;
                    targetDaily = 5;
                    targetTotal = 0;
                    history = const {};
                    break;
                  case 'noTarget':
                    kind = TaskKind.counter;
                    targetDaily = 0;
                    targetTotal = 0;
                    history = const {};
                    break;
                  case 'hasActivity':
                    kind = TaskKind.counter;
                    targetDaily = 0;
                    targetTotal = 0;
                    history = {
                      todayKey: DailyProgress(
                        date: todayKey,
                        count: 2,
                        updatedAt: todayDate,
                      ),
                    };
                    break;
                  case 'progressTotal':
                    kind = TaskKind.progress;
                    targetDaily = 0;
                    targetTotal = 100;
                    history = const {};
                    break;
                  default:
                    throw StateError('Unknown condition');
                }

                final task = Task(
                  id: 't1',
                  categoryId: 'c1',
                  name: 'Test Task',
                  kind: kind,
                  isActive: isActive,
                  sortOrder: 0,
                  targetDaily: targetDaily,
                  targetTotal: targetTotal,
                  totalCount: 0,
                  createdAt: todayDate,
                  updatedAt: todayDate,
                  todayVisibility: visibility,
                  history: history,
                );

                final category = Category(
                  id: 'c1',
                  name: 'Test Cat',
                  icon: '📌',
                  isHidden: categoryHidden,
                  sortOrder: 0,
                  tasks: [task],
                );

                final data = TaskMasterData(
                  schemaVersion: 2,
                  categories: [category],
                );

                final entries = collectTodayTasks(data, todayKey);

                final bool expectedVisible;
                if (!isActive || categoryHidden) {
                  expectedVisible = false;
                } else {
                  switch (visibility) {
                    case TodayVisibility.never:
                      expectedVisible = false;
                      break;
                    case TodayVisibility.always:
                      expectedVisible = true;
                      break;
                    case TodayVisibility.auto:
                      expectedVisible = condition == 'dailyTarget' ||
                          condition == 'hasActivity' ||
                          condition == 'progressTotal';
                      break;
                  }
                }

                if (expectedVisible) {
                  expect(entries.map((e) => e.task.id), contains('t1'));
                } else {
                  expect(entries.map((e) => e.task.id), isNot(contains('t1')));
                }
              },
            );
          }
        }
      }
    }
  });

  group('ringkasan dashboard dan urutan sortOrder', () {
    test('tugas always tanpa target menyumbang nol pada hitungan target tercapai', () {
      final taskAlwaysNoTarget = Task(
        id: 't_always',
        categoryId: 'c1',
        name: 'Always No Target',
        kind: TaskKind.counter,
        isActive: true,
        sortOrder: 1,
        targetDaily: 0,
        targetTotal: 0,
        totalCount: 5,
        createdAt: todayDate,
        updatedAt: todayDate,
        todayVisibility: TodayVisibility.always,
      );

      final taskWithTargetMet = Task(
        id: 't_target',
        categoryId: 'c1',
        name: 'Target Met',
        kind: TaskKind.habit,
        isActive: true,
        sortOrder: 0,
        targetDaily: 3,
        targetTotal: 0,
        totalCount: 3,
        createdAt: todayDate,
        updatedAt: todayDate,
        todayVisibility: TodayVisibility.auto,
        history: {
          todayKey: DailyProgress(date: todayKey, count: 3, updatedAt: todayDate),
        },
      );

      final category = Category(
        id: 'c1',
        name: 'Test Cat',
        icon: '📌',
        isHidden: false,
        sortOrder: 0,
        tasks: [taskAlwaysNoTarget, taskWithTargetMet],
      );

      final data = TaskMasterData(schemaVersion: 2, categories: [category]);
      final todayTasks = collectTodayTasks(data, todayKey);

      expect(todayTasks.length, 2);
      // Urutan stabil sesuai sortOrder
      expect(todayTasks[0].task.id, 't_target');
      expect(todayTasks[1].task.id, 't_always');

      final completed = completedTargetCount(todayTasks, todayKey);
      expect(completed, 1);
    });
  });
}

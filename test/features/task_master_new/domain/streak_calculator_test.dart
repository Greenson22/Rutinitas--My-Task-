import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/daily_progress.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_kind.dart';
import 'package:rutinitasku/features/task_master_new/domain/operations/streak_calculator.dart';

void main() {
  final today = DateTime(2026, 11, 14, 12);

  String key(int daysAgo) {
    final date = DateTime(today.year, today.month, today.day - daysAgo);
    return DailyProgress.dateKey(date);
  }

  Task taskWith({
    TaskKind kind = TaskKind.habit,
    int targetDaily = 1,
    int targetTotal = 0,
    int totalCount = 0,
    Map<String, int> history = const {},
  }) {
    return Task(
      id: 'task_1',
      categoryId: 'cat_1',
      name: 'Push up',
      kind: kind,
      isActive: true,
      sortOrder: 0,
      targetDaily: targetDaily,
      targetTotal: targetTotal,
      totalCount: totalCount,
      createdAt: today.subtract(const Duration(days: 30)),
      updatedAt: today,
      history: {
        for (final entry in history.entries)
          entry.key: DailyProgress(
            date: entry.key,
            count: entry.value,
            updatedAt: today,
          ),
      },
    );
  }

  group('streak', () {
    test('menghitung hari berhasil berturut-turut dari kemarin', () {
      final task = taskWith(
        targetDaily: 20,
        history: {key(1): 20, key(2): 25, key(3): 20, key(5): 20},
      );

      expect(calculateStreak(task, today), 3);
    });

    test('hari yang tidak mencapai target memutus streak', () {
      final task = taskWith(
        targetDaily: 20,
        history: {key(1): 20, key(2): 19, key(3): 20},
      );

      expect(calculateStreak(task, today), 1);
    });

    test('tanpa target harian, aktivitas dihitung sebagai hari berhasil', () {
      final task = taskWith(
        targetDaily: 0,
        history: {key(1): 1, key(2): 3, key(3): 1},
      );

      expect(calculateStreak(task, today), 3);
    });

    test('hari tanpa aktivitas memutus streak saat target harian nol', () {
      final task = taskWith(targetDaily: 0, history: {key(1): 1, key(3): 1});

      expect(calculateStreak(task, today), 1);
    });

    test('hari ini yang belum dikerjakan tidak memutus streak', () {
      final task = taskWith(targetDaily: 1, history: {key(1): 1, key(2): 1});

      expect(task.countOn(key(0)), 0);
      expect(calculateStreak(task, today), 2);
    });

    test('streak tidak menghitung hari ini meski target sudah tercapai', () {
      final task = taskWith(
        targetDaily: 1,
        history: {key(0): 1, key(1): 1, key(2): 1},
      );

      expect(calculateStreak(task, today), 2);
    });

    test('streak kosong bila kemarin tidak berhasil', () {
      final task = taskWith(targetDaily: 1, history: {key(2): 1, key(3): 1});

      expect(calculateStreak(task, today), 0);
    });

    test('streak tidak melebihi batas retensi 365 hari', () {
      final history = {for (var day = 1; day <= 400; day++) key(day): 1};
      final task = taskWith(targetDaily: 1, history: history);

      expect(calculateStreak(task, today), historyRetentionDays);
    });
  });

  group('definisi selesai', () {
    test('habit selesai hanya bila target harian tercapai', () {
      final task = taskWith(targetDaily: 20, history: {key(0): 20});
      final short = taskWith(targetDaily: 20, history: {key(0): 19});

      expect(task.isCompleteOn(key(0)), isTrue);
      expect(short.isCompleteOn(key(0)), isFalse);
    });

    test('counter tidak memiliki status selesai', () {
      final task = taskWith(
        kind: TaskKind.counter,
        targetDaily: 0,
        history: {key(0): 5},
      );

      expect(task.isCompleteOn(key(0)), isFalse);
    });

    test('progress selesai bila total mencapai target total', () {
      final done = taskWith(
        kind: TaskKind.progress,
        targetDaily: 1,
        targetTotal: 100,
        totalCount: 100,
      );
      final unfinished = taskWith(
        kind: TaskKind.progress,
        targetDaily: 1,
        targetTotal: 100,
        totalCount: 99,
      );

      expect(done.isCompleteOn(key(0)), isTrue);
      expect(unfinished.isCompleteOn(key(0)), isFalse);
    });
  });

  group('pemangkasan riwayat', () {
    test('mempertahankan 365 hari terakhir dan membuang yang lebih lama', () {
      final history = {
        for (var day = 0; day < 365; day++)
          key(day): DailyProgress(date: key(day), count: 1, updatedAt: today),
        key(365): DailyProgress(date: key(365), count: 1, updatedAt: today),
      };

      final pruned = pruneHistory(history, today: today);

      expect(pruned, hasLength(365));
      expect(pruned.containsKey(key(0)), isTrue);
      expect(pruned.containsKey(key(364)), isTrue);
      expect(pruned.containsKey(key(365)), isFalse);
    });

    test('membuang hitungan nol tanpa membuang tanggal lain', () {
      final tomorrow = DailyProgress.dateKey(
        DateTime(today.year, today.month, today.day + 1),
      );
      final history = {
        key(1): DailyProgress(date: key(1), count: 2, updatedAt: today),
        key(0): DailyProgress(date: key(0), count: 0, updatedAt: today),
        tomorrow: DailyProgress(date: tomorrow, count: 3, updatedAt: today),
      };

      final pruned = pruneHistory(history, today: today);

      expect(pruned.keys, [key(1), tomorrow]);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/category.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/daily_progress.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_kind.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_master_data.dart';

void main() {
  final now = DateTime(2026, 11, 14, 12);

  Task task(String id, {required bool isActive}) {
    return Task(
      id: id,
      categoryId: 'cat',
      name: id,
      kind: TaskKind.counter,
      isActive: isActive,
      sortOrder: 0,
      targetDaily: 0,
      targetTotal: 0,
      totalCount: 0,
      createdAt: now,
      updatedAt: now,
      history: {
        DailyProgress.dateKey(now): DailyProgress(
          date: DailyProgress.dateKey(now),
          count: 1,
          updatedAt: now,
        ),
      },
    );
  }

  test(
    'ringkasan tidak menghitung kategori tersembunyi dan tugas nonaktif',
    () {
      final data = TaskMasterData(
        schemaVersion: 2,
        categories: [
          Category(
            id: 'cat_1',
            name: 'Terlihat',
            icon: '👀',
            isHidden: false,
            sortOrder: 0,
            tasks: [
              task('aktif', isActive: true),
              task('nonaktif', isActive: false),
            ],
          ),
          Category(
            id: 'cat_2',
            name: 'Tersembunyi',
            icon: '🙈',
            isHidden: true,
            sortOrder: 1,
            tasks: [task('hidden-aktif', isActive: true)],
          ),
        ],
      );

      expect(data.activeCategoryCount, 1);
      expect(data.activeTaskCount, 1);
      expect(data.allTasks.length, 3);
    },
  );
}

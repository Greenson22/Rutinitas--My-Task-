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

/// Ketahanan penyimpanan Task Master New: perubahan tetap tampil di layar,
/// banner “Perubahan belum tersimpan” muncul, dan aksi dapat dicoba ulang.
void main() {
  final now = DateTime(2026, 11, 14, 12);
  final today = DailyProgress.dateKey(now);

  TaskMasterData sampleData() {
    return TaskMasterData(
      schemaVersion: TaskMasterData.currentSchemaVersion,
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
              createdAt: now,
              updatedAt: now,
              history: {
                today: DailyProgress(date: today, count: 15, updatedAt: now),
              },
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

  testWidgets(
    'penyimpanan gagal mempertahankan state dan banner bisa dicoba lagi',
    (tester) async {
      final repository = FakeTaskRepository(data: sampleData());
      await tester.pumpWidget(app(repository));
      await tester.pumpAndSettle();

      expect(find.textContaining('Hari ini 15 / 20'), findsOneWidget);

      repository.saveError = TaskDataSourceException('Penyimpanan penuh.');
      await tester.tap(find.byKey(const Key('dashboardIncrement_task_1')));
      // Lewati jendela debounce penyimpanan agar kegagalan benar-benar terjadi.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // State tetap di layar walau file belum tersimpan.
      expect(find.textContaining('Hari ini 16 / 20'), findsOneWidget);
      expect(find.textContaining('Perubahan belum tersimpan'), findsOneWidget);
      expect(find.textContaining('Penyimpanan penuh.'), findsOneWidget);
      expect(find.byKey(const Key('retryActionButton')), findsOneWidget);
      expect(repository.data!.allTasks.first.totalCount, 120);

      repository.saveError = null;
      await tester.tap(find.byKey(const Key('retryActionButton')));
      await tester.pumpAndSettle();

      expect(find.textContaining('belum tersimpan'), findsNothing);
      expect(find.byKey(const Key('retryActionButton')), findsNothing);
      expect(find.textContaining('Hari ini 16 / 20'), findsOneWidget);
      expect(repository.data!.allTasks.first.totalCount, 121);
      expect(repository.data!.allTasks.first.countOn(today), 16);
    },
  );
}

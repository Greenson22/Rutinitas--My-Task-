import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/category.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/daily_progress.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_kind.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_master_data.dart';
import 'package:rutinitasku/features/task_master_new/presentation/controllers/task_master_controller.dart';
import 'package:rutinitasku/features/task_master_new/presentation/screens/category_detail_screen.dart';
import '../support/fake_task_repository.dart';

void main() {
  Widget buildCategoryScreen(TaskMasterNewController controller, String categoryId) {
    return MaterialApp(
      home: CategoryDetailScreen(
        controller: controller,
        categoryId: categoryId,
      ),
    );
  }

  group('TaskFormDialog — Ticket 03 (Edit Hitungan Hari Ini)', () {
    testWidgets(
      '(a) field muncul di mode edit dengan nilai awal, (b) tidak muncul di mode tambah, (c) perubahan nilai tersimpan dengan delta totalCount yang benar, (d) validasi menolak nilai negatif',
      (tester) async {
        final now = DateTime.now();
        final key = DailyProgress.dateKey(now);
        final repo = FakeTaskRepository(
          data: TaskMasterData(
            schemaVersion: 2,
            categories: [
              Category(
                id: 'cat-1',
                name: 'Olahraga',
                icon: '🏃',
                isHidden: false,
                sortOrder: 0,
                tasks: [
                  Task(
                    id: 'task-1',
                    categoryId: 'cat-1',
                    name: 'Push Up',
                    kind: TaskKind.habit,
                    targetDaily: 20,
                    targetTotal: 0,
                    totalCount: 50,
                    isActive: true,
                    sortOrder: 0,
                    createdAt: now,
                    updatedAt: now,
                    history: {
                      key: DailyProgress(
                        date: key,
                        count: 5,
                        updatedAt: now,
                      ),
                    },
                  ),
                ],
              ),
            ],
          ),
        );

        final controller = TaskMasterNewController(repository: repo);
        await controller.load();

        await tester.pumpWidget(buildCategoryScreen(controller, 'cat-1'));
        await tester.pumpAndSettle();

        // (b) Mode tambah baru: field Hitungan Hari Ini tidak muncul
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('taskCountTodayField')), findsNothing);
        await tester.tap(find.byKey(const Key('taskCancelButton')));
        await tester.pumpAndSettle();

        // (a) Mode edit: buka menu ⋮ -> Ubah
        await tester.tap(find.byIcon(Icons.more_vert).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Ubah'));
        await tester.pumpAndSettle();

        final countFieldFinder = find.byKey(const Key('taskCountTodayField'));
        expect(countFieldFinder, findsOneWidget);
        final fieldWidget = tester.widget<TextFormField>(countFieldFinder);
        expect(fieldWidget.controller?.text, '5');

        // (d) Validasi menolak nilai negatif
        await tester.enterText(countFieldFinder, '-3');
        await tester.tap(find.byKey(const Key('taskSaveButton')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('taskCountTodayField')), findsOneWidget);

        // (c) Ubah nilai dari 5 menjadi 20 -> totalCount harus menjadi 50 - 5 + 20 = 65
        await tester.enterText(countFieldFinder, '20');
        await tester.tap(find.byKey(const Key('taskSaveButton')));
        await tester.pumpAndSettle();

        final updatedTask = repo.data!.categories.first.tasks.first;
        expect(updatedTask.countOn(key), 20);
        expect(updatedTask.totalCount, 65);
      },
    );
  });
}

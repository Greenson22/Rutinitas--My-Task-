import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/category.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/daily_progress.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_kind.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_master_data.dart';
import 'package:rutinitasku/features/task_master_new/presentation/models/today_task_sort_mode.dart';
import 'package:rutinitasku/features/task_master_new/presentation/screens/task_master_screen.dart';

import '../support/fake_task_repository.dart';

void main() {
  final now = DateTime(2026, 11, 14, 12);
  final today = DailyProgress.dateKey(now);

  Task createTask({
    required String id,
    required String categoryId,
    required String name,
    required int countToday,
    required int targetDaily,
    int sortOrder = 0,
  }) {
    return Task(
      id: id,
      categoryId: categoryId,
      name: name,
      kind: TaskKind.habit,
      isActive: true,
      sortOrder: sortOrder,
      targetDaily: targetDaily,
      targetTotal: 0,
      totalCount: 10,
      createdAt: now,
      updatedAt: now,
      history: {
        today: DailyProgress(date: today, count: countToday, updatedAt: now),
      },
    );
  }

  TaskMasterData sampleData() {
    return TaskMasterData(
      schemaVersion: 2,
      categories: [
        Category(
          id: 'cat_olahraga',
          name: 'Olahraga',
          icon: '🏃',
          isHidden: false,
          sortOrder: 0,
          tasks: [
            createTask(
              id: 'task_pushup',
              categoryId: 'cat_olahraga',
              name: 'Push up',
              countToday: 20,
              targetDaily: 20, // Met
              sortOrder: 0,
            ),
            createTask(
              id: 'task_situp',
              categoryId: 'cat_olahraga',
              name: 'Sit up',
              countToday: 5,
              targetDaily: 20, // Not met
              sortOrder: 1,
            ),
          ],
        ),
        Category(
          id: 'cat_belajar',
          name: 'Belajar',
          icon: '📚',
          isHidden: false,
          sortOrder: 1,
          tasks: [
            createTask(
              id: 'task_baca',
              categoryId: 'cat_belajar',
              name: 'Baca Buku',
              countToday: 1,
              targetDaily: 2, // Not met
              sortOrder: 0,
            ),
          ],
        ),
      ],
    );
  }

  Widget createTestWidget(FakeTaskRepository repository) {
    return MaterialApp(
      home: TaskMasterNewScreen(
        repository: repository,
        clock: () => now,
      ),
    );
  }

  group('TaskMasterNewScreen Hari Ini Sorting & Refresh tests', () {
    testWidgets('tombol refresh di kanan atas AppBar sudah dihilangkan', (tester) async {
      final repository = FakeTaskRepository(data: sampleData());
      await tester.pumpWidget(createTestWidget(repository));
      await tester.pumpAndSettle();

      // Cek tombol refresh tidak ada di AppBar
      expect(find.byTooltip('Muat ulang data'), findsNothing);
      expect(find.byIcon(Icons.refresh), findsNothing);
    });

    testWidgets('dapat mengurutkan tugas Hari Ini dengan mode sortir otomatis (A-Z, Belum tercapai, dll)', (tester) async {
      final repository = FakeTaskRepository(data: sampleData());
      await tester.pumpWidget(createTestWidget(repository));
      await tester.pumpAndSettle();

      // Default order: Push up, Sit up, Baca Buku (cat_olahraga, lalu cat_belajar)
      expect(find.text('Push up'), findsOneWidget);
      expect(find.text('Sit up'), findsOneWidget);
      expect(find.text('Baca Buku'), findsOneWidget);

      // Buka menu sortir
      final sortButton = find.byKey(const Key('todaySortMenuButton'));
      expect(sortButton, findsOneWidget);
      await tester.tap(sortButton);
      await tester.pumpAndSettle();

      // Pilih Nama tugas (A-Z)
      await tester.tap(find.text('Nama tugas (A-Z)'));
      await tester.pumpAndSettle();

      final posBaca = tester.getTopLeft(find.text('Baca Buku')).dy;
      final posPush = tester.getTopLeft(find.text('Push up')).dy;
      final posSit = tester.getTopLeft(find.text('Sit up')).dy;

      expect(posBaca, lessThan(posPush));
      expect(posPush, lessThan(posSit));

      // Buka menu sortir lagi, pilih Belum tercapai di atas
      await tester.tap(sortButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Belum tercapai di atas'));
      await tester.pumpAndSettle();

      final posPush2 = tester.getTopLeft(find.text('Push up')).dy;
      final posSit2 = tester.getTopLeft(find.text('Sit up')).dy;
      // Push up met (target tercapai), Sit up not met -> Sit up harus lebih atas dari Push up
      expect(posSit2, lessThan(posPush2));
    });

    testWidgets('dapat mengurutkan tugas Hari Ini secara manual (reorder mode & move buttons)', (tester) async {
      final repository = FakeTaskRepository(data: sampleData());
      await tester.pumpWidget(createTestWidget(repository));
      await tester.pumpAndSettle();

      // Klik tombol atur urutan manual
      final reorderButton = find.byKey(const Key('todayReorderButton'));
      expect(reorderButton, findsOneWidget);
      await tester.tap(reorderButton);
      await tester.pumpAndSettle();

      // Di mode reorder, tombol panah naik/turun muncul
      final downButton = find.byKey(const Key('moveTodayTaskDown_task_pushup'));
      expect(downButton, findsOneWidget);

      final initialPushDy = tester.getTopLeft(find.text('Push up')).dy;
      final initialSitDy = tester.getTopLeft(find.text('Sit up')).dy;
      expect(initialPushDy, lessThan(initialSitDy));

      // Tekan tombol turunkan Push up
      await tester.tap(downButton);
      await tester.pumpAndSettle();

      final newPushDy = tester.getTopLeft(find.text('Push up')).dy;
      final newSitDy = tester.getTopLeft(find.text('Sit up')).dy;
      // Sekarang Push up berada di bawah Sit up
      expect(newSitDy, lessThan(newPushDy));

      // Tutup mode reorder
      await tester.tap(reorderButton);
      await tester.pumpAndSettle();

      // Urutan kustom tetap dipertahankan
      final finalPushDy = tester.getTopLeft(find.text('Push up')).dy;
      final finalSitDy = tester.getTopLeft(find.text('Sit up')).dy;
      expect(finalSitDy, lessThan(finalPushDy));
    });
  });
}

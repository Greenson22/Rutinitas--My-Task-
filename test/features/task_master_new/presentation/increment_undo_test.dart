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
  final today = DailyProgress.dateKey(now);

  TaskMasterData sampleData() {
    Task task({
      required String id,
      required String name,
      required TaskKind kind,
      required int total,
      required int daily,
      required int historyCount,
      required int sortOrder,
    }) {
      return Task(
        id: id,
        categoryId: 'cat_1',
        name: name,
        kind: kind,
        isActive: true,
        sortOrder: sortOrder,
        targetDaily: daily,
        targetTotal: 0,
        totalCount: total,
        createdAt: now,
        updatedAt: now,
        history: {
          today: DailyProgress(
            date: today,
            count: historyCount,
            updatedAt: now,
          ),
        },
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
          tasks: [
            task(
              id: 'task_1',
              name: 'Push up',
              kind: TaskKind.habit,
              total: 120,
              daily: 20,
              historyCount: 15,
              sortOrder: 0,
            ),
            task(
              id: 'task_2',
              name: 'Baca buku',
              kind: TaskKind.progress,
              total: 40,
              daily: 1,
              historyCount: 3,
              sortOrder: 1,
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

  Future<void> increment(WidgetTester tester, String taskId) async {
    await tester.tap(find.byKey(Key('incrementTask_$taskId')));
    // Selesaikan animasi SnackBar agar tombol Undo bisa diketuk.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets(
    'increment langsung memperbarui UI dan menampilkan Undo 5 detik',
    (tester) async {
      final repository = FakeTaskRepository(data: sampleData());
      await tester.pumpWidget(app(repository));
      await tester.pumpAndSettle();
      await openDetail(tester);

      expect(find.textContaining('Hari ini 15 / 20'), findsOneWidget);
      await increment(tester, 'task_1');

      // UI berubah tanpa dialog konfirmasi.
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.textContaining('Hari ini 16 / 20'), findsOneWidget);
      expect(find.textContaining('Total 121'), findsOneWidget);
      expect(find.byKey(const Key('undoIncrementAction')), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      final snackBar = tester.widget<SnackBar>(
        find.byKey(const Key('incrementSnackBar')),
      );
      expect(snackBar.duration, const Duration(seconds: 5));

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('Undo mengembalikan total, hitungan, dan riwayat hari ini', (
    tester,
  ) async {
    final repository = FakeTaskRepository(data: sampleData());
    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();
    await openDetail(tester);

    await increment(tester, 'task_1');
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Hari ini 15 / 20'), findsOneWidget);
    expect(find.textContaining('Total 120'), findsOneWidget);

    final task = repository.data!.allTasks.first;
    expect(task.totalCount, 120);
    expect(task.countOn(today), 15);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('double tap cepat hanya menambah satu hitungan', (tester) async {
    final repository = FakeTaskRepository(data: sampleData());
    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();
    await openDetail(tester);

    await increment(tester, 'task_1');
    await increment(tester, 'task_1');

    expect(find.textContaining('Hari ini 16 / 20'), findsOneWidget);
    expect(find.textContaining('Total 121'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('hanya increment terakhir yang bisa di-undo', (tester) async {
    var clockNow = now;
    final repository = FakeTaskRepository(data: sampleData());
    await tester.pumpWidget(app(repository, clock: () => clockNow));
    await tester.pumpAndSettle();
    await openDetail(tester);

    await increment(tester, 'task_1');
    // Lewati jendela double tap agar increment berikutnya diterima.
    clockNow = now.add(const Duration(seconds: 1));
    await increment(tester, 'task_2');

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Hari ini 16 / 20'), findsOneWidget);
    expect(find.textContaining('Total 121'), findsOneWidget);
    expect(find.textContaining('Hari ini 3 • Total 40'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('menutup aplikasi sebelum debounce tetap menyimpan increment', (
    tester,
  ) async {
    final repository = FakeTaskRepository(data: sampleData());
    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();
    await openDetail(tester);

    await tester.tap(find.byKey(const Key('incrementTask_task_1')));
    await tester.pump();

    // Tutup sebelum timer debounce 300 ms sempat berjalan.
    await tester.pumpWidget(const SizedBox());
    await tester.pump();

    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();
    await openDetail(tester);

    expect(find.textContaining('Hari ini 16 / 20'), findsOneWidget);
    expect(find.textContaining('Total 121'), findsOneWidget);
  });

  testWidgets('increment tetap tersimpan setelah aplikasi dibuka ulang', (
    tester,
  ) async {
    final repository = FakeTaskRepository(data: sampleData());
    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();
    await openDetail(tester);

    await increment(tester, 'task_1');
    await tester.pump(const Duration(milliseconds: 350));

    // Simulasikan aplikasi ditutup lalu dibuka kembali.
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();
    await openDetail(tester);

    expect(find.textContaining('Hari ini 16 / 20'), findsOneWidget);
    expect(find.textContaining('Total 121'), findsOneWidget);
  });
}

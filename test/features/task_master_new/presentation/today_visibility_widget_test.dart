import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/category.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_kind.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_master_data.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/today_visibility.dart';
import 'package:rutinitasku/features/task_master_new/presentation/screens/task_master_screen.dart';

import '../support/fake_task_repository.dart';

void main() {
  final now = DateTime(2026, 11, 22, 10);

  TaskMasterData createSampleData() {
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
              kind: TaskKind.counter,
              isActive: true,
              sortOrder: 0,
              targetDaily: 0,
              targetTotal: 0,
              totalCount: 0,
              createdAt: now,
              updatedAt: now,
              todayVisibility: TodayVisibility.auto,
            ),
            Task(
              id: 'task_2',
              categoryId: 'cat_1',
              name: 'Sit up',
              kind: TaskKind.habit,
              isActive: true,
              sortOrder: 1,
              targetDaily: 20,
              targetTotal: 0,
              totalCount: 0,
              createdAt: now,
              updatedAt: now,
              todayVisibility: TodayVisibility.auto,
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

  testWidgets('form tugas dapat menyimpan tiga opsi visibilitas', (tester) async {
    final repository = FakeTaskRepository(data: createSampleData());
    await tester.pumpWidget(createTestWidget(repository));
    await tester.pumpAndSettle();

    // Buka detail kategori
    final manageFinder = find.byKey(const Key('manageTasks_cat_1'));
    await tester.scrollUntilVisible(
      manageFinder,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(manageFinder);
    await tester.pumpAndSettle();

    // Tambah tugas baru
    await tester.tap(find.byKey(const Key('addTaskButton')));
    await tester.pumpAndSettle();

    // Default adalah Otomatis
    expect(find.text('Otomatis'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('taskNameField')), 'Plank');
    // Pilih Selalu
    await tester.tap(find.byKey(const Key('taskTodayVisibilityField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Selalu').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('taskSaveButton')));
    await tester.pumpAndSettle();

    final addedTask = repository.data!.categories.first.tasks.firstWhere(
      (t) => t.name == 'Plank',
    );
    expect(addedTask.todayVisibility, TodayVisibility.always);
  });

  testWidgets('menu baris di detail kategori mengubah visibilitas dan daftar Hari Ini langsung bereaksi', (tester) async {
    final repository = FakeTaskRepository(data: createSampleData());
    await tester.pumpWidget(createTestWidget(repository));
    await tester.pumpAndSettle();

    // Di dashboard awal: task_1 (counter tanpa target & tanpa hitungan) tidak muncul di Hari Ini
    expect(find.byKey(const Key('todayTask_task_1')), findsNothing);
    expect(find.byKey(const Key('todayTask_task_2')), findsOneWidget);

    // Buka kategori
    final manageFinder = find.byKey(const Key('manageTasks_cat_1'));
    await tester.scrollUntilVisible(
      manageFinder,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(manageFinder);
    await tester.pumpAndSettle();

    // Ubah visibilitas task_1 jadi Selalu
    await tester.tap(find.byKey(const Key('taskMenu_task_1')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tampil di Hari Ini'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('visibilityOption_always_task_1')));
    await tester.pumpAndSettle();

    // Kembali ke dashboard
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Sekarang task_1 muncul di daftar Hari Ini langsung!
    expect(find.byKey(const Key('todayTask_task_1')), findsOneWidget);
    expect(find.text('Tanpa target'), findsOneWidget);
  });

  testWidgets('menu baris di daftar Hari Ini mengubah visibilitas dan langsung menghilang bila never', (tester) async {
    final repository = FakeTaskRepository(data: createSampleData());
    await tester.pumpWidget(createTestWidget(repository));
    await tester.pumpAndSettle();

    // task_2 awalnya ada di Hari Ini
    expect(find.byKey(const Key('todayTask_task_2')), findsOneWidget);

    // Buka menu di TodayTaskTile
    await tester.tap(find.byKey(const Key('todayTaskMenu_task_2')));
    await tester.pumpAndSettle();

    // Pilih Sembunyikan
    await tester.tap(find.byKey(const Key('todayVisibilityOption_never_task_2')));
    await tester.pumpAndSettle();

    // task_2 langsung hilang dari daftar Hari Ini tanpa reload
    expect(find.byKey(const Key('todayTask_task_2')), findsNothing);
    final task2 = repository.data!.categories.first.tasks.firstWhere((t) => t.id == 'task_2');
    expect(task2.todayVisibility, TodayVisibility.never);
  });

  testWidgets('aksi massal Visibilitas Hari Ini menerapkan nilai terpilih ke semua tugas', (tester) async {
    final repository = FakeTaskRepository(data: createSampleData());
    await tester.pumpWidget(createTestWidget(repository));
    await tester.pumpAndSettle();

    // Buka kategori
    final manageFinder = find.byKey(const Key('manageTasks_cat_1'));
    await tester.scrollUntilVisible(
      manageFinder,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(manageFinder);
    await tester.pumpAndSettle();

    // Long press task_1 untuk masuk selection mode
    await tester.longPress(find.byKey(const Key('taskTile_task_1')));
    await tester.pumpAndSettle();

    // Tap task_2 untuk memilih keduanya
    await tester.tap(find.byKey(const Key('taskTile_task_2')));
    await tester.pumpAndSettle();

    // Buka menu bulk visibility
    await tester.tap(find.byKey(const Key('bulkVisibilityButton')));
    await tester.pumpAndSettle();

    // Pilih Selalu
    await tester.tap(find.text('Selalu'));
    await tester.pumpAndSettle();

    final tasks = repository.data!.categories.first.tasks;
    expect(tasks[0].todayVisibility, TodayVisibility.always);
    expect(tasks[1].todayVisibility, TodayVisibility.always);
    // Status aktif tidak disentuh
    expect(tasks[0].isActive, isTrue);
    expect(tasks[1].isActive, isTrue);
  });

  testWidgets('empty state Hari Ini menampilkan bantuan pengaturan visibilitas', (tester) async {
    final emptyData = TaskMasterData(
      schemaVersion: 2,
      categories: [
        Category(
          id: 'cat_empty',
          name: 'Kosong',
          icon: '📁',
          isHidden: false,
          sortOrder: 0,
          tasks: [],
        ),
      ],
    );
    final repository = FakeTaskRepository(data: emptyData);
    await tester.pumpWidget(createTestWidget(repository));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('emptyTodayTasks')), findsOneWidget);
    expect(find.textContaining('Tampil di Hari Ini'), findsOneWidget);
  });
}

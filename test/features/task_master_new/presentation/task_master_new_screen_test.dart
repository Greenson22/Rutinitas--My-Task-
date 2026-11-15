import 'dart:async';

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

void main() {
  final now = DateTime(2026, 11, 14, 12);

  TaskMasterData sampleData() {
    final today = DailyProgress.dateKey(now);
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
              createdAt: now,
              updatedAt: now,
              history: {
                today: DailyProgress(date: today, count: 15, updatedAt: now),
              },
            ),
            Task(
              id: 'task_2',
              categoryId: 'cat_1',
              name: 'Buku',
              kind: TaskKind.progress,
              isActive: true,
              sortOrder: 1,
              targetDaily: 1,
              targetTotal: 100,
              totalCount: 40,
              createdAt: now,
              updatedAt: now,
              history: const {},
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

  testWidgets('menampilkan loading lalu data hasil migrasi', (tester) async {
    final repository = FakeTaskRepository(data: sampleData())
      ..loadCompleter = Completer<TaskMasterData>();

    await tester.pumpWidget(app(repository));
    expect(find.text('Memuat data Task Master...'), findsOneWidget);

    repository.loadCompleter!.complete(sampleData());
    await tester.pumpAndSettle();

    expect(find.text('Task Master New'), findsOneWidget);
    expect(find.text('Olahraga'), findsOneWidget);
    expect(find.text('Push up'), findsOneWidget);
    expect(find.text('Buku'), findsOneWidget);
    expect(find.text('Kebiasaan'), findsOneWidget);
    expect(find.text('Progres'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsAtLeastNWidgets(1));
    expect(find.textContaining('Hari ini 15 / 20'), findsOneWidget);
  });

  testWidgets('menampilkan empty state yang jelas', (tester) async {
    final repository = FakeTaskRepository(data: TaskMasterData.empty());

    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada kategori'), findsOneWidget);
    expect(find.text('Muat Ulang'), findsOneWidget);
  });

  testWidgets('menampilkan error state yang dapat ditindaklanjuti', (
    tester,
  ) async {
    final repository = FakeTaskRepository(
      error: UnsupportedSchemaVersionException(99),
    );

    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();

    expect(find.text('Versi data tidak didukung'), findsOneWidget);
    expect(find.textContaining('Data tidak diubah'), findsOneWidget);
    expect(find.text('Coba Lagi'), findsOneWidget);

    repository.error = null;
    repository.data = sampleData();
    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();

    expect(find.text('Olahraga'), findsOneWidget);
    expect(repository.loadCount, 2);
  });
}

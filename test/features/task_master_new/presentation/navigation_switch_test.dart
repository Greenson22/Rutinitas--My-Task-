import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/core/presentation/widgets/drawer_menu.dart';
import 'package:rutinitasku/core/presentation/widgets/task_master_entry.dart';
import 'package:rutinitasku/features/task_master/presentation/controllers/task_master_controller.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_master_data.dart';
import 'package:rutinitasku/features/task_master_new/presentation/screens/task_master_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_journal_gateway.dart';
import '../support/fake_task_repository.dart';

void main() {
  final now = DateTime(2026, 11, 18, 9);

  group('switch navigasi Task Master', () {
    testWidgets('TaskMasterEntry membuka Task Master New', (tester) async {
      final repository = FakeTaskRepository(data: TaskMasterData.empty());

      await tester.pumpWidget(
        MaterialApp(
          home: TaskMasterEntry(
            repository: repository,
            journalGateway: FakeJournalGateway(),
            clock: () => now,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TaskMasterNewScreen), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Task Master'),
        ),
        findsOneWidget,
      );
      expect(repository.loadCount, 1);
    });

    testWidgets('drawer hanya punya satu pintu masuk Task Master', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: DrawerMenu())),
      );

      expect(find.text('Task Master'), findsOneWidget);
      expect(find.text('Task Master New'), findsNothing);
    });

    testWidgets('menu Task Master membuka modul baru', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: null,
            drawer: DrawerMenu(),
            body: SizedBox.shrink(),
          ),
        ),
      );

      final scaffoldState = tester.firstState<ScaffoldState>(
        find.byType(Scaffold),
      );
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Task Master'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(TaskMasterNewScreen), findsOneWidget);
    });
  });

  group('modul lama baca-saja setelah switch', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('task_master_legacy_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('saveAllCategoriesToFile tidak membuat file', () async {
      final controller = TaskMasterController(onUpdate: () {})
        ..selectedBaseDir = tempDir.path;

      await controller.saveAllCategoriesToFile();

      expect(tempDir.listSync(), isEmpty);
    });

    test('memuat saat file belum ada tidak membuat folder atau file', () async {
      SharedPreferences.setMockInitialValues({
        'ubuntu_base_dir_debug': tempDir.path,
      });
      final controller = TaskMasterController(onUpdate: () {});

      await controller.initStorageAndLoadData();

      expect(controller.isFileCorrupted, isTrue);
      expect(Directory('${tempDir.path}/mytask').existsSync(), isFalse);
    });

    test('forceResetNewFile tidak membuat file baru', () async {
      final controller = TaskMasterController(onUpdate: () {});
      final target = File('${tempDir.path}/my_tasks.json');

      await controller.forceResetNewFile(target);

      expect(await target.exists(), isFalse);
    });
  });
}

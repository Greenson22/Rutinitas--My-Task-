import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/features/task_master_new/data/exceptions/task_master_exceptions.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/category.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_backup.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_kind.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_master_data.dart';
import 'package:rutinitasku/features/task_master_new/presentation/screens/task_master_screen.dart';

import '../support/fake_task_repository.dart';

void main() {
  final now = DateTime(2026, 11, 14, 12);

  TaskMasterData sampleData() {
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

  testWidgets('file terkunci menampilkan PIN dan PIN benar membuka data', (
    tester,
  ) async {
    final repository = FakeTaskRepository(data: sampleData())
      ..error = TaskLockedException('File terenkripsi.')
      ..expectedPassword = '1234';

    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();

    expect(find.text('Data terkunci'), findsOneWidget);
    expect(find.byKey(const Key('unlockWithPinButton')), findsOneWidget);

    await tester.tap(find.byKey(const Key('unlockWithPinButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pinField')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('pinField')), 'salah');
    await tester.tap(find.byKey(const Key('pinConfirmButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pinError')), findsOneWidget);
    expect(find.text('PIN tidak cocok'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('pinField')), '1234');
    await tester.tap(find.byKey(const Key('pinConfirmButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pinField')), findsNothing);
    expect(find.text('Olahraga'), findsOneWidget);
    expect(find.text('Push up'), findsOneWidget);
  });

  testWidgets('file gagal didekripsi dapat dipulihkan dari backup', (
    tester,
  ) async {
    final repository = FakeTaskRepository(data: sampleData())
      ..error = TaskDecryptionException('Kata sandi salah atau file korup.')
      ..restoredData = sampleData()
      ..backups = [TaskBackup(path: '/tmp/backup_1.json', createdAt: now)];

    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();

    expect(find.text('Gagal membuka data'), findsOneWidget);
    expect(find.byKey(const Key('restoreBackupButton')), findsOneWidget);
    expect(find.byKey(const Key('createNewFileButton')), findsOneWidget);

    await tester.tap(find.byKey(const Key('restoreBackupButton')));
    await tester.pumpAndSettle();
    expect(find.text('Pulihkan backup'), findsWidgets);

    await tester.tap(find.byKey(const Key('restoreBackup_0')));
    await tester.pumpAndSettle();
    expect(find.text('Pulihkan backup ini?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirmRestoreBackupButton')));
    await tester.pumpAndSettle();

    expect(repository.restoreBackupCount, 1);
    expect(find.text('Olahraga'), findsOneWidget);
  });

  testWidgets('buat file baru meminta konfirmasi destruktif', (tester) async {
    final repository = FakeTaskRepository(data: sampleData())
      ..error = TaskDataCorruptedException('JSON korup.');

    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('createNewFileButton')));
    await tester.pumpAndSettle();
    expect(find.text('Buat file baru?'), findsOneWidget);
    expect(find.textContaining('akan dibackup'), findsOneWidget);
    expect(repository.createNewFileCount, 0);

    await tester.tap(find.byKey(const Key('confirmCreateNewFileButton')));
    await tester.pumpAndSettle();

    expect(repository.createNewFileCount, 1);
    expect(find.text('Belum ada kategori'), findsOneWidget);
  });

  testWidgets('editor JSON Advanced memvalidasi sebelum menyimpan', (
    tester,
  ) async {
    final repository = FakeTaskRepository(data: sampleData())
      ..rawJson = '{"schemaVersion":2,"categories":[]}';

    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('advancedButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('taskMasterAdvancedSheet')), findsOneWidget);
    expect(find.byKey(const Key('openRawJsonEditorTile')), findsOneWidget);
    expect(find.byKey(const Key('openSettingsTile')), findsNothing);

    await tester.tap(find.byKey(const Key('openRawJsonEditorTile')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('rawJsonEditorField')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('rawJsonEditorField')),
      '{ bukan json',
    );
    await tester.tap(find.byKey(const Key('rawJsonSaveButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('rawJsonValidationError')), findsOneWidget);
    expect(repository.rawSaveCount, 0);

    const valid = '{"schemaVersion":2,"categories":[]}';
    await tester.enterText(find.byKey(const Key('rawJsonEditorField')), valid);
    await tester.tap(find.byKey(const Key('rawJsonSaveButton')));
    await tester.pumpAndSettle();

    expect(repository.rawSaveCount, 1);
    expect(repository.lastRawSavedContent, valid);
    expect(find.byKey(const Key('rawJsonEditorField')), findsNothing);
    expect(find.textContaining('JSON berhasil disimpan'), findsOneWidget);
  });

  testWidgets('editor JSON menolak akar yang bukan objek', (tester) async {
    final repository = FakeTaskRepository(data: sampleData());

    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('advancedButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('openRawJsonEditorTile')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('rawJsonEditorField')),
      '[1,2,3]',
    );
    await tester.tap(find.byKey(const Key('rawJsonSaveButton')));
    await tester.pumpAndSettle();

    expect(find.text('Akar JSON harus berupa objek.'), findsOneWidget);
    expect(repository.rawSaveCount, 0);
  });

  testWidgets(
    'sheet Advanced hanya memiliki satu tile (Editor JSON mentah) dan tidak ada jalur Settings di Task Master New',
    (tester) async {
      final repository = FakeTaskRepository(data: sampleData());

      await tester.pumpWidget(app(repository));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('advancedButton')));
      await tester.pumpAndSettle();

      final sheet = find.byKey(const Key('taskMasterAdvancedSheet'));
      expect(sheet, findsOneWidget);

      final listTiles = find.descendant(
        of: sheet,
        matching: find.byType(ListTile),
      );
      expect(listTiles, findsOneWidget);
      expect(find.byKey(const Key('openRawJsonEditorTile')), findsOneWidget);
      expect(find.byKey(const Key('openSettingsTile')), findsNothing);
      expect(find.text('Pengaturan folder & enkripsi'), findsNothing);
    },
  );
}

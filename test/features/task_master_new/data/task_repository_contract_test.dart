import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/core/services/storage_service.dart';
import 'package:rutinitasku/features/task_master_new/data/datasources/task_local_data_source.dart';
import 'package:rutinitasku/features/task_master_new/data/exceptions/task_master_exceptions.dart';
import 'package:rutinitasku/features/task_master_new/data/mappers/task_master_mapper.dart';
import 'package:rutinitasku/features/task_master_new/data/repositories/task_repository_impl.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_kind.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_master_data.dart';

import '../support/fake_task_local_data_source.dart';

void main() {
  final now = DateTime(2026, 11, 14, 12);

  TaskRepositoryImpl buildRepository(FakeTaskLocalDataSource source) {
    return TaskRepositoryImpl(
      localDataSource: source,
      mapper: TaskMasterMapper(
        clock: () => now,
        idGenerator: () => 'generated',
      ),
    );
  }

  String legacyJson() {
    return jsonEncode({
      'categories': [
        {
          'name': 'Kesehatan',
          'icon': '💚',
          'isHidden': false,
          'tasks': [
            {
              'id': 'task-1',
              'name': 'Jalan kaki',
              'count': 12,
              'date': '2026-11-13 07:00',
              'countToday': 4,
              'lastUpdated': '2026-11-13 07:00',
              'targetCountToday': 10,
              'type': 0,
              'targetCount': 0,
              'isActive': true,
            },
          ],
        },
      ],
    });
  }

  TaskFileSnapshot legacySnapshot() {
    final raw = legacyJson();
    return TaskFileSnapshot(rawContent: raw, content: raw, wasEncrypted: false);
  }

  group('TaskRepository contract', () {
    test('file tidak ada menghasilkan data kosong tanpa menulis', () async {
      final source = FakeTaskLocalDataSource();
      final repository = buildRepository(source);

      final data = await repository.load();

      expect(data.categories, isEmpty);
      expect(source.writeCount, 0);
      expect(source.backupCount, 0);
    });

    test('migrasi legacy membuat backup sebelum menulis v2', () async {
      final source = FakeTaskLocalDataSource(snapshot: legacySnapshot());
      final repository = buildRepository(source);

      final data = await repository.load();

      expect(source.backupCount, 1);
      expect(source.writeCount, 1);
      expect(source.backups.single.rawContent, legacyJson());
      expect(data.categories.single.name, 'Kesehatan');
      expect(data.categories.single.tasks.single.id, 'task-1');
      expect(data.categories.single.tasks.single.kind, TaskKind.habit);
      expect(data.categories.single.tasks.single.countOn('2026-11-13'), 4);

      final written = jsonDecode(source.writes.single) as Map<String, dynamic>;
      expect(written['schemaVersion'], 2);
    });

    test(
      'migrasi kedua idempoten: tidak menulis atau membuat backup lagi',
      () async {
        final source = FakeTaskLocalDataSource(snapshot: legacySnapshot());
        final repository = buildRepository(source);

        await repository.load();
        final second = await repository.load();

        expect(source.backupCount, 1);
        expect(source.writeCount, 1);
        expect(second.categories.single.tasks.single.id, 'task-1');
      },
    );

    test('versi skema tidak dikenal ditolak tanpa mengubah file', () async {
      final raw = jsonEncode({'schemaVersion': 99, 'categories': <dynamic>[]});
      final source = FakeTaskLocalDataSource(
        snapshot: TaskFileSnapshot(
          rawContent: raw,
          content: raw,
          wasEncrypted: false,
        ),
      );
      final repository = buildRepository(source);

      await expectLater(
        repository.load(),
        throwsA(isA<UnsupportedSchemaVersionException>()),
      );

      expect(source.writeCount, 0);
      expect(source.backupCount, 0);
      expect(source.snapshot!.rawContent, raw);
    });

    test(
      'kegagalan menulis tidak mengubah file asli dan menyebut backup',
      () async {
        final original = legacySnapshot();
        final source = FakeTaskLocalDataSource(snapshot: original)
          ..writeError = TaskDataSourceException('disk penuh');
        final repository = buildRepository(source);

        await expectLater(
          repository.load(),
          throwsA(
            isA<TaskMigrationException>().having(
              (error) => error.backupPath,
              'backupPath',
              isNotNull,
            ),
          ),
        );

        expect(source.snapshot!.rawContent, original.rawContent);
        expect(source.backupCount, 1);
        expect(source.writeCount, 0);
      },
    );

    test('JSON korup gagal sebelum backup dan tidak menimpa file', () async {
      const raw = '{ bukan json';
      final source = FakeTaskLocalDataSource(
        snapshot: const TaskFileSnapshot(
          rawContent: raw,
          content: raw,
          wasEncrypted: false,
        ),
      );
      final repository = buildRepository(source);

      await expectLater(
        repository.load(),
        throwsA(isA<TaskDataCorruptedException>()),
      );

      expect(source.backupCount, 0);
      expect(source.writeCount, 0);
      expect(source.snapshot!.rawContent, raw);
    });

    test('save menulis skema v2', () async {
      final source = FakeTaskLocalDataSource();
      final repository = buildRepository(source);

      await repository.save(TaskMasterData.empty());

      expect(source.writeCount, 1);
      final written = jsonDecode(source.writes.single) as Map<String, dynamic>;
      expect(written['schemaVersion'], 2);
    });
  });

  group('migrasi file terenkripsi end-to-end', () {
    test(
      'membaca, memigrasikan, dan menulis ulang secara terenkripsi',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'task_master_encrypted_',
        );
        addTearDown(() async {
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        });

        final dataSource = FileTaskLocalDataSource(
          storageService: StorageService(),
          baseDirProvider: () async => tempDir.path,
          encryptionEnabledProvider: () async => true,
          passwordProvider: () async => 'pin-rahasia',
          clock: () => now,
        );
        await dataSource.write(legacyJson());

        final file = File('${tempDir.path}/mytask/my_tasks.json');
        final rawBefore = await file.readAsString();
        expect(rawBefore.trimLeft().startsWith('{'), isFalse);

        final repository = TaskRepositoryImpl(
          localDataSource: dataSource,
          mapper: TaskMasterMapper(
            clock: () => now,
            idGenerator: () => 'generated',
          ),
        );

        final data = await repository.load();
        expect(data.categories.single.tasks.single.id, 'task-1');
        expect(data.categories.single.tasks.single.kind, TaskKind.habit);

        final rawAfter = await file.readAsString();
        expect(rawAfter.trimLeft().startsWith('{'), isFalse);
        expect(rawAfter, isNot(rawBefore));

        final snapshot = await dataSource.read();
        final migrated = jsonDecode(snapshot!.content) as Map<String, dynamic>;
        expect(migrated['schemaVersion'], 2);

        final backups = await dataSource.listBackups();
        expect(backups, hasLength(1));
        expect(await File(backups.single.path).readAsString(), rawBefore);
      },
    );
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/core/services/storage_service.dart';
import 'package:rutinitasku/features/task_master_new/data/datasources/task_local_data_source.dart';
import 'package:rutinitasku/features/task_master_new/data/exceptions/task_master_exceptions.dart';
import 'package:rutinitasku/features/task_master_new/data/mappers/task_master_mapper.dart';
import 'package:rutinitasku/features/task_master_new/data/repositories/task_repository_impl.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_backup.dart';
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
      expect(written['schemaVersion'], 3);
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
      expect(written['schemaVersion'], 3);
    });

    test('readRawJson mengembalikan JSON terformat', () async {
      final source = FakeTaskLocalDataSource(snapshot: legacySnapshot());
      final repository = buildRepository(source);

      final raw = await repository.readRawJson();

      expect(raw, contains('"Kesehatan"'));
      expect(raw, contains('\n'));
    });

    test('saveRawJson menolak JSON tidak valid tanpa menulis', () async {
      final source = FakeTaskLocalDataSource();
      final repository = buildRepository(source);

      await expectLater(
        repository.saveRawJson('{ bukan json'),
        throwsA(isA<TaskDataCorruptedException>()),
      );
      await expectLater(
        repository.saveRawJson('{"categories":"bukan-list"}'),
        throwsA(isA<TaskDataCorruptedException>()),
      );
      await expectLater(
        repository.saveRawJson('{"schemaVersion":99,"categories":[]}'),
        throwsA(isA<UnsupportedSchemaVersionException>()),
      );

      expect(source.writeCount, 0);
    });

    test('saveRawJson memvalidasi, menormalkan v2, dan atomic write', () async {
      final source = FakeTaskLocalDataSource();
      final repository = buildRepository(source);
      final raw = jsonEncode({
        'schemaVersion': 2,
        'fieldTambahan': 'dipertahankan',
        'categories': [
          {
            'id': 'cat_1',
            'name': 'Fokus',
            'icon': '🎯',
            'tasks': [
              {
                'id': 'task_1',
                'name': 'Deep work',
                'kind': 'habit',
                'targetDaily': 2,
              },
            ],
          },
        ],
      });

      final data = await repository.saveRawJson(raw);

      expect(data.categories.single.name, 'Fokus');
      expect(source.writeCount, 1);
      final written = jsonDecode(source.writes.single) as Map<String, dynamic>;
      expect(written['schemaVersion'], 3);
      expect(written['fieldTambahan'], 'dipertahankan');
      expect(written['categories'][0]['tasks'][0]['id'], 'task_1');
    });

    test(
      'createNewFile membackup file lama lalu menulis data kosong',
      () async {
        final source = FakeTaskLocalDataSource(snapshot: legacySnapshot());
        final repository = buildRepository(source);

        final data = await repository.createNewFile();

        expect(data.categories, isEmpty);
        expect(source.backupCount, 1);
        expect(source.backups.single.rawContent, legacyJson());
        expect(source.writeCount, 1);
        final written =
            jsonDecode(source.writes.single) as Map<String, dynamic>;
        expect(written['schemaVersion'], 3);
        expect(written['categories'], isEmpty);
      },
    );

    test('restoreBackup menyalin backup lalu memuat ulang data', () async {
      final source = FakeTaskLocalDataSource(snapshot: legacySnapshot());
      final repository = buildRepository(source);
      final backup = await source.backupCurrentFile();

      final restored = await repository.restoreBackup(
        TaskBackup(path: backup!.path, createdAt: backup.createdAt),
      );

      expect(source.restoreCount, 1);
      expect(restored.categories.single.name, 'Kesehatan');
      expect(restored.categories.single.tasks.single.id, 'task-1');
    });

    test('listBackups mengurutkan backup terbaru lebih dulu', () async {
      final source = FakeTaskLocalDataSource();
      await source.createBackup(legacySnapshot());
      await source.createBackup(legacySnapshot());
      final repository = buildRepository(source);

      final backups = await repository.listBackups();

      expect(backups, hasLength(2));
      expect(backups.first.createdAt.isAfter(backups.last.createdAt), isTrue);
    });
  });

  group('kompatibilitas Data Center', () {
    String v2Json() {
      return jsonEncode({
        'schemaVersion': 2,
        'fieldTambahan': 'dipertahankan',
        'categories': [
          {
            'id': 'cat_sehat',
            'name': 'Kesehatan',
            'icon': '💚',
            'isHidden': false,
            'sortOrder': 0,
            'tasks': [
              {
                'id': 'task-lari',
                'name': 'Lari pagi',
                'kind': 'habit',
                'isActive': true,
                'sortOrder': 0,
                'targetDaily': 2,
                'targetTotal': 0,
                'count': 8,
                'createdAt': '2026-11-01T07:00:00.000',
                'updatedAt': '2026-11-14T08:00:00.000',
                'history': {
                  '2026-11-13': {
                    'count': 2,
                    'updatedAt': '2026-11-13T08:00:00.000',
                  },
                  '2026-11-14': {
                    'count': 1,
                    'updatedAt': '2026-11-14T08:00:00.000',
                  },
                },
              },
            ],
          },
        ],
      });
    }

    test(
      'import v2 memulihkan kategori, tugas, target, status, dan riwayat',
      () async {
        final source = FakeTaskLocalDataSource(snapshot: legacySnapshot());
        final repository = buildRepository(source);

        final imported = await repository.importJson(v2Json());

        expect(imported.categories.single.id, 'cat_sehat');
        final task = imported.categories.single.tasks.single;
        expect(task.id, 'task-lari');
        expect(task.kind, TaskKind.habit);
        expect(task.targetDaily, 2);
        expect(task.isActive, isTrue);
        expect(task.history, hasLength(2));
        expect(task.countOn('2026-11-13'), 2);

        expect(source.backupCount, 1);
        expect(source.writeCount, 1);

        final loaded = await repository.load();
        final reloaded = loaded.categories.single.tasks.single;
        expect(reloaded.id, 'task-lari');
        expect(reloaded.targetDaily, 2);
        expect(reloaded.totalCount, 8);
        expect(reloaded.isActive, isTrue);
        expect(reloaded.countOn('2026-11-13'), 2);
      },
    );

    test('import legacy dimigrasikan saat data dibuka', () async {
      final source = FakeTaskLocalDataSource();
      final repository = buildRepository(source);

      await repository.importJson(legacyJson());
      expect(source.writeCount, 1);
      final written = jsonDecode(source.writes.single) as Map<String, dynamic>;
      expect(
        written['schemaVersion'],
        isNull,
        reason: 'legacy ditulis apa adanya',
      );

      final data = await repository.load();

      expect(data.categories.single.name, 'Kesehatan');
      expect(data.categories.single.tasks.single.id, 'task-1');
      expect(data.categories.single.tasks.single.kind, TaskKind.habit);
      expect(data.categories.single.tasks.single.countOn('2026-11-13'), 4);
      expect(source.writeCount, 2, reason: 'migrasi menulis ulang v2');
      expect(source.backupCount, 1, reason: 'backup dibuat saat migrasi');
    });

    test('import tidak valid tidak mengubah data lama', () async {
      final original = legacySnapshot();
      final source = FakeTaskLocalDataSource(snapshot: original);
      final repository = buildRepository(source);

      await expectLater(
        repository.importJson('{ bukan json'),
        throwsA(isA<TaskDataCorruptedException>()),
      );
      await expectLater(
        repository.importJson('{"categories":"bukan-list"}'),
        throwsA(isA<TaskDataCorruptedException>()),
      );
      await expectLater(
        repository.importJson('{"schemaVersion":99,"categories":[]}'),
        throwsA(isA<UnsupportedSchemaVersionException>()),
      );

      expect(source.writeCount, 0);
      expect(source.backupCount, 0);
      expect(source.snapshot!.rawContent, original.rawContent);
    });

    test('export lalu import round-trip menghasilkan data setara', () async {
      final sourceA = FakeTaskLocalDataSource();
      final mapper = TaskMasterMapper(
        clock: () => now,
        idGenerator: () => 'generated',
      );
      final repoA = TaskRepositoryImpl(
        localDataSource: sourceA,
        mapper: mapper,
      );
      // saveRawJson menormalkan ke v2 sekaligus mempertahankan field tak
      // dikenal dan menulis field legacy untuk kompatibilitas.
      await repoA.saveRawJson(v2Json());
      final dataA = await repoA.load();

      final exported = await repoA.exportJson();
      expect(exported.trimLeft().startsWith('{'), isTrue);

      final sourceB = FakeTaskLocalDataSource();
      final repoB = buildRepository(sourceB);
      await repoB.importJson(exported);
      final dataB = await repoB.load();

      expect(dataB.categories.length, dataA.categories.length);
      final categoryA = dataA.categories.single;
      final categoryB = dataB.categories.single;
      expect(categoryB.id, categoryA.id);
      expect(categoryB.name, categoryA.name);
      expect(categoryB.icon, categoryA.icon);
      expect(categoryB.isHidden, categoryA.isHidden);
      expect(categoryB.sortOrder, categoryA.sortOrder);

      final taskA = categoryA.tasks.single;
      final taskB = categoryB.tasks.single;
      expect(taskB.id, taskA.id);
      expect(taskB.name, taskA.name);
      expect(taskB.kind, taskA.kind);
      expect(taskB.isActive, taskA.isActive);
      expect(taskB.sortOrder, taskA.sortOrder);
      expect(taskB.targetDaily, taskA.targetDaily);
      expect(taskB.targetTotal, taskA.targetTotal);
      expect(taskB.totalCount, taskA.totalCount);
      expect(taskB.createdAt, taskA.createdAt);
      expect(taskB.updatedAt, taskA.updatedAt);
      expect(taskB.history, taskA.history);

      final importedJson =
          jsonDecode(sourceB.writes.single) as Map<String, dynamic>;
      expect(importedJson['fieldTambahan'], 'dipertahankan');
      expect(importedJson['schemaVersion'], 3);
      final importedTask =
          importedJson['categories'][0]['tasks'][0] as Map<String, dynamic>;
      expect(importedTask['type'], 0);
      expect(importedTask['countToday'], 1);
    });

    test('validateImportJson tidak menulis atau membuat backup', () async {
      final original = legacySnapshot();
      final source = FakeTaskLocalDataSource(snapshot: original);
      final repository = buildRepository(source);

      final preview = await repository.validateImportJson(v2Json());

      expect(preview.categories.single.name, 'Kesehatan');
      expect(source.writeCount, 0);
      expect(source.backupCount, 0);
      expect(source.snapshot!.rawContent, original.rawContent);
    });
  });

  group('migrasi file terenkripsi end-to-end', () {
    test(
      'ekspor mentah terenkripsi dapat diimpor kembali dengan PIN sesi',
      () async {
        final tempDirA = await Directory.systemTemp.createTemp(
          'task_master_export_a_',
        );
        final tempDirB = await Directory.systemTemp.createTemp(
          'task_master_export_b_',
        );
        addTearDown(() async {
          if (await tempDirA.exists()) await tempDirA.delete(recursive: true);
          if (await tempDirB.exists()) await tempDirB.delete(recursive: true);
        });

        const v2 =
            '{"schemaVersion":2,"categories":[{"id":"cat_x","name":"Fokus",'
            '"icon":"🎯","isHidden":false,"sortOrder":0,"tasks":[{"id":'
            '"task_x","name":"Latihan","kind":"habit","isActive":true,'
            '"sortOrder":0,"targetDaily":1,"targetTotal":0,"count":3,'
            '"history":{"2026-11-14":{"count":1,"updatedAt":'
            '"2026-11-14T08:00:00.000"}}}]}]}';

        FileTaskLocalDataSource buildSource(String path) {
          return FileTaskLocalDataSource(
            storageService: StorageService(),
            baseDirProvider: () async => path,
            encryptionEnabledProvider: () async => true,
            passwordProvider: () async => 'pin-rahasia',
            clock: () => now,
          );
        }

        final sourceA = buildSource(tempDirA.path);
        final repoA = TaskRepositoryImpl(
          localDataSource: sourceA,
          mapper: TaskMasterMapper(clock: () => now),
        );
        await repoA.saveRawJson(v2);

        final exported = await repoA.exportJson();
        expect(exported.trimLeft().startsWith('{'), isFalse);

        final sourceB = buildSource(tempDirB.path);
        final repoB = TaskRepositoryImpl(
          localDataSource: sourceB,
          mapper: TaskMasterMapper(clock: () => now),
        );
        await repoB.importJson(exported);
        final data = await repoB.load();

        final task = data.categories.single.tasks.single;
        expect(task.id, 'task_x');
        expect(task.targetDaily, 1);
        expect(task.totalCount, 3);
        expect(task.countOn('2026-11-14'), 1);

        final rawB = await File(
          '${tempDirB.path}/mytask/my_tasks.json',
        ).readAsString();
        expect(rawB.trimLeft().startsWith('{'), isFalse);
      },
    );

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
        expect(migrated['schemaVersion'], 3);

        final backups = await dataSource.listBackups();
        expect(backups, hasLength(1));
        expect(await File(backups.single.path).readAsString(), rawBefore);
      },
    );
  });
}

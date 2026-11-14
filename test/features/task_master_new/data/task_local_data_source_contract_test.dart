import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/core/services/storage_service.dart';
import 'package:rutinitasku/features/task_master_new/data/datasources/task_local_data_source.dart';
import 'package:rutinitasku/features/task_master_new/data/exceptions/task_master_exceptions.dart';

void main() {
  late Directory tempDir;
  late FileTaskLocalDataSource dataSource;
  late bool encryptionEnabled;
  String? password;

  File taskFile() => File('${tempDir.path}/mytask/my_tasks.json');

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('task_master_new_test_');
    encryptionEnabled = false;
    password = null;
    dataSource = FileTaskLocalDataSource(
      storageService: StorageService(),
      baseDirProvider: () async => tempDir.path,
      encryptionEnabledProvider: () async => encryptionEnabled,
      passwordProvider: () async => password,
      clock: () => DateTime(2026, 11, 14, 12, 34, 56),
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('TaskLocalDataSource contract', () {
    test('file belum ada mengembalikan null', () async {
      expect(await dataSource.read(), isNull);
    });

    test('tulis dan baca plain JSON memakai lokasi file lama', () async {
      const content = '{"schemaVersion":2,"categories":[]}';

      await dataSource.write(content);

      expect(await taskFile().exists(), isTrue);
      final snapshot = await dataSource.read();
      expect(snapshot, isNotNull);
      expect(snapshot!.content, content);
      expect(snapshot.rawContent, content);
      expect(snapshot.wasEncrypted, isFalse);

      final leftovers = tempDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.tmp'));
      expect(
        leftovers,
        isEmpty,
        reason: 'atomic write harus membersihkan .tmp',
      );
    });

    test('round-trip file terenkripsi', () async {
      encryptionEnabled = true;
      password = 'pin-rahasia';
      const content = '{"schemaVersion":2,"categories":[{"id":"cat_1"}]}';

      await dataSource.write(content);

      final raw = await taskFile().readAsString();
      expect(raw.trimLeft().startsWith('{'), isFalse);
      expect(raw, contains(':'));

      final snapshot = await dataSource.read();
      expect(snapshot, isNotNull);
      expect(snapshot!.content, content);
      expect(snapshot.wasEncrypted, isTrue);
      expect(snapshot.rawContent, raw);
    });

    test('kata sandi salah menghasilkan TaskDecryptionException', () async {
      encryptionEnabled = true;
      password = 'benar';
      await dataSource.write('{"schemaVersion":2,"categories":[]}');

      password = 'salah';
      await expectLater(
        dataSource.read(),
        throwsA(isA<TaskDecryptionException>()),
      );
    });

    test(
      'file terenkripsi tanpa kata sandi menghasilkan TaskLockedException',
      () async {
        encryptionEnabled = true;
        password = 'benar';
        await dataSource.write('{"schemaVersion":2,"categories":[]}');

        password = null;
        await expectLater(
          dataSource.read(),
          throwsA(isA<TaskLockedException>()),
        );
      },
    );

    test('backup memakai konten asli dan mengikuti status enkripsi', () async {
      encryptionEnabled = true;
      password = 'pin-rahasia';
      await dataSource.write('{"schemaVersion":2,"categories":[]}');

      final snapshot = await dataSource.read();
      final backup = await dataSource.createBackup(snapshot!);

      final backupFile = File(backup.path);
      expect(await backupFile.exists(), isTrue);
      expect(await backupFile.readAsString(), snapshot.rawContent);
      expect(backup.path, contains('/mytask/backup/my_tasks_20261114_123456'));
      expect(backup.createdAt, DateTime(2026, 11, 14, 12, 34, 56));

      final listed = await dataSource.listBackups();
      expect(listed, hasLength(1));
      expect(listed.single.path, backup.path);
    });

    test('penulisan diserialisasi mengikuti urutan pemanggilan', () async {
      final first = dataSource.write('{"schemaVersion":2,"categories":[1]}');
      final second = dataSource.write('{"schemaVersion":2,"categories":[2]}');

      await Future.wait([first, second]);

      final snapshot = await dataSource.read();
      expect(
        jsonDecode(snapshot!.content)['categories'],
        [2],
        reason: 'penulisan terakhir harus menjadi isi akhir',
      );
    });
  });
}

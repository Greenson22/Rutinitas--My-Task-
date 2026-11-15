import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/core/services/storage_service.dart';
import 'package:rutinitasku/core/utils/crypto_helper.dart';
import 'package:rutinitasku/features/task_master_new/data/gateways/file_journal_gateway.dart';
import 'package:rutinitasku/features/task_master_new/domain/repositories/journal_gateway.dart';

void main() {
  final now = DateTime(2026, 11, 14, 12);
  late Directory tempDir;
  late bool encryptionEnabled;
  String? password;
  late FileJournalGateway gateway;

  File journalFile(String name) =>
      File('${tempDir.path}/jurnal_aktivitas/$name');

  Directory journalDirectory() => Directory('${tempDir.path}/jurnal_aktivitas');

  File templateFile() => journalFile('jurnal_template.json');
  File monthFile() => journalFile('jurnal_2026_11.json');
  File oldMasterFile() => journalFile('time_log.json');

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('journal_gateway_test_');
    encryptionEnabled = false;
    password = null;
    gateway = FileJournalGateway(
      storageService: StorageService(),
      baseDirProvider: () async => tempDir.path,
      encryptionEnabledProvider: () async => encryptionEnabled,
      passwordProvider: () async => password,
      clock: () => now,
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<void> writeTemplate({
    required int? incrementMinutes,
    Object? linkedTaskIds = const ['task_1'],
    String taskId = '7',
  }) async {
    await journalDirectory().create(recursive: true);
    final settings = incrementMinutes == null
        ? <String, dynamic>{}
        : <String, dynamic>{'default_increment_minutes': incrementMinutes};
    final content = jsonEncode({
      'settings': settings,
      'tasks': [
        {
          'id': taskId,
          'nama': 'Belajar',
          'durasi_menit': 0,
          'kategori': null,
          'linkedTaskIds': linkedTaskIds,
        },
      ],
    });
    await templateFile().writeAsString(
      encryptionEnabled ? CryptoHelper.encrypt(content, password!) : content,
    );
  }

  Future<Object?> readJournalFile(File file) async {
    final raw = await file.readAsString();
    final content =
        raw.trimLeft().startsWith('[') || raw.trimLeft().startsWith('{')
        ? raw
        : CryptoHelper.decrypt(raw, password!);
    return jsonDecode(content);
  }

  group('JournalGateway contract', () {
    test('menambah durasi sesuai pengaturan template', () async {
      await writeTemplate(incrementMinutes: 45);

      final links = await gateway.loadLinks();
      expect(links.linkedTaskIds, {'task_1'});
      expect(links.incrementMinutes, 45);
      expect(links.isLinked('task_2'), isFalse);

      final adjustment = await gateway.addDuration(taskId: 'task_1', at: now);
      expect(adjustment, isNotNull);
      expect(adjustment!.journalTaskId, '7');
      expect(adjustment.minutes, 45);

      final logs = await readJournalFile(monthFile()) as List<dynamic>;
      final todayEntry = logs.single as Map<String, dynamic>;
      expect(todayEntry['tanggal'], '2026-11-14');
      final task =
          (todayEntry['tasks'] as List<dynamic>).single as Map<String, dynamic>;
      expect(task['id'], '7');
      expect(task['durasi_menit'], 45);
      expect(task['linkedTaskIds'], ['task_1']);
    });

    test('melaporkan total durasi Jurnal hari ini', () async {
      await writeTemplate(incrementMinutes: 45);

      expect((await gateway.loadLinks()).todayMinutes, 0);

      await gateway.addDuration(taskId: 'task_1', at: now);
      expect((await gateway.loadLinks()).todayMinutes, 45);

      await gateway.addDuration(taskId: 'task_1', at: now);
      expect((await gateway.loadLinks()).todayMinutes, 90);
    });

    test('mengurangi durasi yang sama saat undo', () async {
      await writeTemplate(incrementMinutes: 45);
      final adjustment = await gateway.addDuration(taskId: 'task_1', at: now);

      await gateway.subtractDuration(adjustment: adjustment!, at: now);

      final logs = await readJournalFile(monthFile()) as List<dynamic>;
      final task =
          (((logs.single as Map)['tasks'] as List<dynamic>).single as Map);
      expect(task['durasi_menit'], 0);
    });

    test('pengaturan tidak tersedia memakai fallback 30 menit', () async {
      await writeTemplate(incrementMinutes: null);

      final links = await gateway.loadLinks();
      expect(links.incrementMinutes, defaultJournalIncrementMinutes);

      final adjustment = await gateway.addDuration(taskId: 'task_1', at: now);
      expect(adjustment!.minutes, 30);
      expect(defaultJournalIncrementMinutes, 30);
    });

    test('pengaturan tidak valid memakai fallback 30 menit', () async {
      await writeTemplate(incrementMinutes: 0);
      final adjustment = await gateway.addDuration(taskId: 'task_1', at: now);
      expect(adjustment!.minutes, 30);

      final content = jsonEncode({
        'settings': {'default_increment_minutes': 'tidak-valid'},
        'tasks': <dynamic>[],
      });
      await templateFile().writeAsString(content);
      expect((await gateway.loadLinks()).incrementMinutes, 30);
    });

    test('tugas tidak tertaut tidak mengubah Jurnal', () async {
      await writeTemplate(incrementMinutes: 45);

      final adjustment = await gateway.addDuration(
        taskId: 'task_lain',
        at: now,
      );

      expect(adjustment, isNull);
      expect(await monthFile().exists(), isFalse);
    });

    test('membaca dan menulis file Jurnal terenkripsi', () async {
      encryptionEnabled = true;
      password = 'pin-jurnal';
      await writeTemplate(incrementMinutes: 60);

      final links = await gateway.loadLinks();
      expect(links.linkedTaskIds, {'task_1'});
      expect(links.incrementMinutes, 60);

      final adjustment = await gateway.addDuration(taskId: 'task_1', at: now);
      expect(adjustment!.minutes, 60);

      final raw = await monthFile().readAsString();
      expect(raw.trimLeft().startsWith('['), isFalse);
      expect(raw, contains(':'));

      final logs = await readJournalFile(monthFile()) as List<dynamic>;
      final task =
          (((logs.single as Map)['tasks'] as List<dynamic>).single as Map);
      expect(task['durasi_menit'], 60);

      await gateway.subtractDuration(adjustment: adjustment, at: now);
      final afterUndo = await readJournalFile(monthFile()) as List<dynamic>;
      final afterTask =
          (((afterUndo.single as Map)['tasks'] as List<dynamic>).single as Map);
      expect(afterTask['durasi_menit'], 0);
    });

    test('kata sandi salah menghasilkan kegagalan yang jelas', () async {
      encryptionEnabled = true;
      password = 'benar';
      await writeTemplate(incrementMinutes: 45);

      password = 'salah';
      await expectLater(
        gateway.addDuration(taskId: 'task_1', at: now),
        throwsA(isA<JournalGatewayException>()),
      );
    });

    test('mengurangi aktivitas yang tidak ditemukan gagal', () async {
      await writeTemplate(incrementMinutes: 45);

      await expectLater(
        gateway.subtractDuration(
          adjustment: const JournalAdjustment(
            journalTaskId: 'tidak_ada',
            minutes: 30,
          ),
          at: now,
        ),
        throwsA(isA<JournalGatewayException>()),
      );
    });

    test('menggabungkan tautan dari template dan log hari ini', () async {
      await writeTemplate(
        incrementMinutes: 45,
        linkedTaskIds: const <String>[],
      );
      await monthFile().writeAsString(
        jsonEncode([
          {
            'tanggal': '2026-11-14',
            'tasks': [
              {
                'id': 7,
                'nama': 'Belajar',
                'durasi_menit': 0,
                'kategori': null,
                'linkedTaskIds': ['task_1'],
              },
            ],
          },
        ]),
      );

      final links = await gateway.loadLinks();
      expect(links.linkedTaskIds, {'task_1'});
      expect(links.incrementMinutes, 45);
    });

    test(
      'tautan dari hari sebelumnya tidak dianggap tertaut hari ini',
      () async {
        await writeTemplate(
          incrementMinutes: 45,
          linkedTaskIds: const <String>[],
        );
        await monthFile().writeAsString(
          jsonEncode([
            {
              'tanggal': '2026-11-13',
              'tasks': [
                {
                  'id': 7,
                  'nama': 'Belajar',
                  'durasi_menit': 0,
                  'kategori': null,
                  'linkedTaskIds': ['task_1'],
                },
              ],
            },
          ]),
        );

        final links = await gateway.loadLinks();
        expect(links.linkedTaskIds, isEmpty);
      },
    );

    test(
      'mengurangi lebih banyak dari durasi tersedia menulis nol dan gagal',
      () async {
        await writeTemplate(incrementMinutes: 45);
        final adjustment = await gateway.addDuration(taskId: 'task_1', at: now);
        expect(adjustment!.minutes, 45);

        await expectLater(
          gateway.subtractDuration(
            adjustment: const JournalAdjustment(
              journalTaskId: '7',
              minutes: 60,
            ),
            at: now,
          ),
          throwsA(isA<JournalGatewayException>()),
        );

        final logs = await readJournalFile(monthFile()) as List<dynamic>;
        final task =
            (((logs.single as Map)['tasks'] as List<dynamic>).single as Map);
        expect(task['durasi_menit'], 0);
      },
    );

    test('tetap membaca dan menulis master Jurnal lama', () async {
      await journalDirectory().create(recursive: true);
      await oldMasterFile().writeAsString(
        jsonEncode([
          {
            'tanggal': '2026-11-14',
            'tasks': [
              {
                'id': 3,
                'nama': 'Menulis',
                'durasi_menit': 10,
                'kategori': null,
                'linkedTaskIds': ['task_1'],
              },
            ],
          },
        ]),
      );

      final links = await gateway.loadLinks();
      expect(links.linkedTaskIds, {'task_1'});

      final adjustment = await gateway.addDuration(taskId: 'task_1', at: now);
      expect(adjustment!.journalTaskId, '3');
      expect(adjustment.minutes, 30);
      expect(await monthFile().exists(), isFalse);

      final logs = await readJournalFile(oldMasterFile()) as List<dynamic>;
      final task =
          (((logs.single as Map)['tasks'] as List<dynamic>).single as Map);
      expect(task['durasi_menit'], 40);
    });
  });
}

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/features/task_master_new/data/mappers/task_master_mapper.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/daily_progress.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_kind.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_master_data.dart';

void main() {
  final now = DateTime(2026, 11, 14, 12);
  late TaskMasterMapper mapper;
  var generatedId = 0;

  setUp(() {
    generatedId = 0;
    mapper = TaskMasterMapper(
      clock: () => now,
      idGenerator: () => 'generated_${++generatedId}',
    );
  });

  group('migrasi legacy', () {
    Map<String, dynamic> legacyFixture() {
      return {
        'categories': [
          {
            'name': 'Olahraga',
            'icon': '🏃',
            'isHidden': false,
            'unknownCategoryField': 'dipertahankan',
            'tasks': [
              {
                'id': 't1',
                'name': 'Push up',
                'count': 100,
                'date': '2026-11-13 20:00',
                'countToday': 5,
                'lastUpdated': '2026-11-13 20:00',
                'targetCountToday': 20,
                'type': 0,
                'targetCount': 0,
                'isActive': true,
                'unknownTaskField': 'aman',
              },
              {
                'id': '',
                'name': 'Minum kopi',
                'count': 3,
                'date': '2026-11-14 09:00',
                'countToday': 2,
                'lastUpdated': '2026-11-14 09:00',
                'targetCountToday': 0,
                'type': 0,
              },
              {
                'id': 't3',
                'name': 'Buku',
                'count': 10,
                'date': '2026-11-14 09:00',
                'countToday': 0,
                'lastUpdated': '2026-11-14 09:00',
                'targetCountToday': 1,
                'type': 1,
                'targetCount': 100,
              },
            ],
          },
          {'name': 'Olahraga', 'icon': '💪', 'tasks': []},
        ],
      };
    }

    test('memetakan id, kind, dan menyimpan field tidak dikenal', () {
      final original = legacyFixture();
      final data = mapper.fromJson(original);

      expect(data.schemaVersion, TaskMasterData.currentSchemaVersion);
      expect(data.categories, hasLength(2));

      final first = data.categories.first;
      expect(first.id, startsWith('cat_'));
      expect(first.icon, '🏃');
      expect(first.tasks, hasLength(3));

      final pushUp = first.tasks[0];
      expect(pushUp.id, 't1', reason: 'id tugas lama harus dipertahankan');
      expect(pushUp.kind, TaskKind.habit);
      expect(pushUp.targetDaily, 20);
      expect(pushUp.totalCount, 100);

      final coffee = first.tasks[1];
      expect(coffee.id, 'generated_1');
      expect(coffee.kind, TaskKind.counter);

      final book = first.tasks[2];
      expect(book.kind, TaskKind.progress);
      expect(book.targetTotal, 100);

      expect(data.categories[1].id, isNot(first.id));
      expect(data.categories[1].id, startsWith('${first.id}_'));

      final json = mapper.toJson(data, original: original);
      final categories = json['categories'] as List;
      final migratedFirst = categories.first as Map<String, dynamic>;
      expect(migratedFirst['unknownCategoryField'], 'dipertahankan');
      final migratedTasks = migratedFirst['tasks'] as List;
      final migratedPushUp = migratedTasks.first as Map<String, dynamic>;
      expect(migratedPushUp['unknownTaskField'], 'aman');
      expect(
        migratedPushUp['date'],
        '2026-11-13 20:00',
        reason: 'field date legacy dipertahankan',
      );
    });

    test('countToday pada tanggal lampau dipindahkan ke history', () {
      final data = mapper.fromJson(legacyFixture());
      final pushUp = data.categories.first.tasks[0];

      expect(pushUp.countOn('2026-11-13'), 5);
      expect(pushUp.countOn('2026-11-14'), 0);
    });

    test('countToday hari ini tetap dapat diproyeksikan dari history', () {
      final data = mapper.fromJson(legacyFixture());
      final coffee = data.categories.first.tasks[1];

      expect(coffee.countOn(DailyProgress.dateKey(now)), 2);
      expect(coffee.countTodayFor(now), 2);

      final json = mapper.toJson(data, original: legacyFixture(), today: now);
      final taskJson =
          ((json['categories'] as List).first['tasks'] as List)[1]
              as Map<String, dynamic>;
      expect(taskJson['countToday'], 2);
      expect((taskJson['history'] as Map)['2026-11-14']['count'], 2);
    });

    test(
      'idempoten: memetakan ulang hasil migrasi tidak menggandakan data',
      () {
        final first = mapper.fromJson(legacyFixture());
        final migratedJson = mapper.toJson(
          first,
          original: legacyFixture(),
          today: now,
        );

        final second = mapper.fromJson(migratedJson);
        expect(second.categories, hasLength(first.categories.length));
        expect(second.categories.first.tasks, hasLength(3));
        expect(second.categories.first.id, first.categories.first.id);
        expect(second.categories.first.tasks[0].id, 't1');
        expect(second.categories.first.tasks[0].countOn('2026-11-13'), 5);
      },
    );
  });

  group('skema v2', () {
    test('mempertahankan history dan kind yang tersimpan', () {
      final json = {
        'schemaVersion': 2,
        'categories': [
          {
            'id': 'cat_abc',
            'name': 'Belajar',
            'icon': '📚',
            'isHidden': true,
            'sortOrder': 3,
            'tasks': [
              {
                'id': 't9',
                'name': 'Baca',
                'kind': 'habit',
                'isActive': false,
                'sortOrder': 4,
                'targetCountToday': 30,
                'targetCount': 0,
                'count': 90,
                'countToday': 999,
                'createdAt': '2026-01-01T08:00:00.000',
                'updatedAt': '2026-11-14T08:30:00.000',
                'history': {
                  '2026-11-14': {
                    'count': 12,
                    'updatedAt': '2026-11-14T08:30:00.000',
                  },
                  '2026-11-13': {
                    'count': 30,
                    'updatedAt': '2026-11-13T19:00:00.000',
                  },
                },
              },
            ],
          },
        ],
      };

      final data = mapper.fromJson(json);
      final category = data.categories.single;
      final task = category.tasks.single;

      expect(category.id, 'cat_abc');
      expect(category.isHidden, isTrue);
      expect(category.sortOrder, 3);
      expect(task.kind, TaskKind.habit);
      expect(task.isActive, isFalse);
      expect(task.countOn('2026-11-14'), 12);
      expect(task.countOn('2026-11-13'), 30);

      final written = mapper.toJson(data, today: now);
      final writtenTask =
          ((written['categories'] as List).single['tasks'] as List).single
              as Map<String, dynamic>;
      expect(writtenTask['countToday'], 12);
      expect(writtenTask['type'], 0);
      expect(jsonEncode(written), contains('"schemaVersion":2'));
    });

    test('riwayat lebih dari 365 hari dipangkas saat menulis', () {
      final json = {
        'schemaVersion': 2,
        'categories': [
          {
            'id': 'cat_1',
            'name': 'Belajar',
            'tasks': [
              {
                'id': 't1',
                'name': 'Baca',
                'kind': 'habit',
                'history': {
                  '2024-01-01': {
                    'count': 5,
                    'updatedAt': '2024-01-01T08:00:00.000',
                  },
                  '2026-11-14': {
                    'count': 2,
                    'updatedAt': '2026-11-14T08:00:00.000',
                  },
                },
              },
            ],
          },
        ],
      };

      final data = mapper.fromJson(json);
      final written = mapper.toJson(data, today: now);
      final history =
          (((written['categories'] as List).single['tasks'] as List).single
                  as Map<String, dynamic>)['history']
              as Map<String, dynamic>;

      expect(history.containsKey('2024-01-01'), isFalse);
      expect(history['2026-11-14']['count'], 2);
    });
  });
}

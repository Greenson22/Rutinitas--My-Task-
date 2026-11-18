import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/features/task_master/data/models/task_model.dart';

void main() {
  Map<String, dynamic> taskJson({bool withUnknownFields = true}) {
    return {
      'id': 't1',
      'name': 'Push up',
      'count': 100,
      'date': '2026-11-13 20:00',
      'checked': false,
      'countToday': 5,
      'lastUpdated': '2026-11-13 20:00',
      'targetCountToday': 20,
      'type': 0,
      'targetCount': 0,
      'isActive': true,
      if (withUnknownFields) ...{
        'history': {
          '2026-11-13': 5,
          '2026-11-12': 3,
        },
        'kind': 'progress',
        'sortOrder': 2,
        'todayVisibility': 'always',
        'showInToday': true,
        'unknownTaskField': 'aman',
      },
    };
  }

  Map<String, dynamic> categoryJson({bool withUnknownFields = true}) {
    return {
      'name': 'Olahraga',
      'icon': '🏃',
      'isHidden': false,
      if (withUnknownFields) 'unknownCategoryField': 'dipertahankan',
      'tasks': [taskJson(withUnknownFields: withUnknownFields)],
    };
  }

  group('TaskCategory passthrough', () {
    test('round-trip mempertahankan seluruh key yang tidak dikenal', () {
      final source = categoryJson();

      final result = TaskCategory.fromJson(source).toJson();

      expect(result, equals(source));
      expect(jsonDecode(jsonEncode(result)), equals(source));
    });

    test('round-trip berulang kategori tetap mempertahankan key tak dikenal',
        () {
      var json = categoryJson();

      for (var i = 0; i < 3; i++) {
        json = TaskCategory.fromJson(json).toJson();
      }

      expect(json, equals(categoryJson()));
    });

    test('mengubah field yang dikenali tidak menghapus key tak dikenal', () {
      final category = TaskCategory.fromJson(categoryJson());

      final updated = category.copyWith(name: 'Kebugaran');

      final result = updated.toJson();
      expect(result['name'], 'Kebugaran');
      expect(result['unknownCategoryField'], 'dipertahankan');
      expect(result['tasks'], hasLength(1));
    });

    test('key tak dikenal kategori tidak bocor ke tugas', () {
      final category = TaskCategory.fromJson(categoryJson());

      final task = category.toJson()['tasks'][0] as Map<String, dynamic>;
      expect(task.containsKey('unknownCategoryField'), isFalse);
    });
  });

  group('TaskItem passthrough', () {
    test('round-trip mempertahankan field tambahan setelah simpan-muat-simpan',
        () {
      var json = taskJson();

      for (var i = 0; i < 3; i++) {
        json = TaskItem.fromJson(json).toJson();
      }

      expect(json['history'], {
        '2026-11-13': 5,
        '2026-11-12': 3,
      });
      expect(json['kind'], 'progress');
      expect(json['sortOrder'], 2);
      expect(json['todayVisibility'], 'always');
      expect(json['showInToday'], true);
      expect(json['unknownTaskField'], 'aman');
    });

    test('mengubah field yang dikenali tidak menghapus key tak dikenal', () {
      final task = TaskItem.fromJson(taskJson());

      task
        ..name = 'Push up pagi'
        ..count = 120;

      final result = task.toJson();
      expect(result['name'], 'Push up pagi');
      expect(result['count'], 120);
      expect(result['unknownTaskField'], 'aman');
      expect(result['history'], isNotNull);
    });

    test('key tak dikenal tugas tidak bocor ke kategori', () {
      final categoryJsonWithTaskExtras = categoryJson();
      final category = TaskCategory.fromJson(categoryJsonWithTaskExtras);

      final result = category.toJson();
      expect(result.containsKey('unknownTaskField'), isFalse);
      expect(result.containsKey('history'), isFalse);
    });
  });

  group('kompatibilitas file lama', () {
    test('file lama tanpa field tambahan tetap menghasilkan JSON setara', () {
      final source = categoryJson(withUnknownFields: false);

      final result = TaskCategory.fromJson(source).toJson();

      expect(result, equals(source));
    });
  });
}

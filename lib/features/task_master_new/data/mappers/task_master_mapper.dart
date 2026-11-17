import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/daily_progress.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_kind.dart';
import '../../domain/entities/task_master_data.dart';
import '../../domain/operations/streak_calculator.dart';
import '../exceptions/task_master_exceptions.dart';

/// Satu-satunya jalur konversi antara JSON dan entity domain Task Master New.
class TaskMasterMapper {
  TaskMasterMapper({DateTime Function()? clock, String Function()? idGenerator})
    : _clock = clock ?? DateTime.now,
      _idGenerator = idGenerator ?? _generateTaskId;

  final DateTime Function() _clock;
  final String Function() _idGenerator;

  int detectSchemaVersion(Map<String, dynamic> json) {
    final raw = json['schemaVersion'];
    if (raw == null) return 1;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) {
      final parsed = int.tryParse(raw);
      if (parsed != null) return parsed;
    }
    throw TaskDataCorruptedException(
      'Field schemaVersion tidak valid. Data tidak diubah.',
    );
  }

  TaskMasterData fromJson(Map<String, dynamic> json) {
    final version = detectSchemaVersion(json);
    switch (version) {
      case 1:
        return _fromJson(json, isLegacy: true);
      case TaskMasterData.currentSchemaVersion:
        return _fromJson(json, isLegacy: false);
      default:
        throw UnsupportedSchemaVersionException(version);
    }
  }

  TaskMasterData _fromJson(
    Map<String, dynamic> json, {
    required bool isLegacy,
  }) {
    final rawCategories = json['categories'];
    if (rawCategories != null && rawCategories is! List) {
      throw TaskDataCorruptedException(
        'Daftar kategori tidak valid. Data tidak diubah.',
      );
    }

    final usedCategoryIds = <String>{};
    final categories = <Category>[];
    final categoryList = (rawCategories as List?) ?? const [];

    for (
      var categoryIndex = 0;
      categoryIndex < categoryList.length;
      categoryIndex++
    ) {
      final rawCategory = _asMap(categoryList[categoryIndex]);
      if (rawCategory == null) {
        throw TaskDataCorruptedException(
          'Salah satu kategori bukan objek JSON yang valid.',
        );
      }

      final name = _asString(rawCategory['name'], fallback: 'Tanpa Nama');
      final rawId = _asString(rawCategory['id']);
      final baseId = rawId.isEmpty ? _categoryIdFromName(name) : rawId;
      final id = _uniqueId(baseId, usedCategoryIds);

      final rawTasks = rawCategory['tasks'];
      if (rawTasks != null && rawTasks is! List) {
        throw TaskDataCorruptedException(
          'Daftar tugas pada kategori "$name" tidak valid.',
        );
      }

      final tasks = <Task>[];
      final taskList = (rawTasks as List?) ?? const [];
      final usedTaskIds = <String>{};
      for (var taskIndex = 0; taskIndex < taskList.length; taskIndex++) {
        final rawTask = _asMap(taskList[taskIndex]);
        if (rawTask == null) {
          throw TaskDataCorruptedException(
            'Salah satu tugas pada kategori "$name" bukan objek JSON yang valid.',
          );
        }
        tasks.add(
          _taskFromJson(
            rawTask,
            categoryId: id,
            fallbackSortOrder: taskIndex,
            isLegacy: isLegacy,
            usedIds: usedTaskIds,
          ),
        );
      }

      categories.add(
        Category(
          id: id,
          name: name,
          icon: _asString(rawCategory['icon'], fallback: '📌'),
          isHidden: _asBool(rawCategory['isHidden']),
          sortOrder: _asInt(rawCategory['sortOrder'], fallback: categoryIndex),
          tasks: tasks,
        ),
      );
    }

    return TaskMasterData(
      schemaVersion: TaskMasterData.currentSchemaVersion,
      categories: categories,
    );
  }

  Task _taskFromJson(
    Map<String, dynamic> json, {
    required String categoryId,
    required int fallbackSortOrder,
    required bool isLegacy,
    required Set<String> usedIds,
  }) {
    final name = _asString(json['name'], fallback: 'Tanpa Nama');
    final rawId = _asString(json['id']);
    final id = _uniqueId(rawId.isEmpty ? _idGenerator() : rawId, usedIds);

    final targetDaily = _asInt(json['targetCountToday'] ?? json['targetDaily']);
    final targetTotal = _asInt(json['targetCount'] ?? json['targetTotal']);

    final explicitKind = TaskKind.tryParse(json['kind']);
    final legacyType = _asInt(json['type']);
    final kind =
        explicitKind ??
        (legacyType == 1
            ? TaskKind.progress
            : (targetDaily > 0 ? TaskKind.habit : TaskKind.counter));

    final now = _clock();
    final legacyUpdated = _parseDateTime(
      json['updatedAt'] ?? json['lastUpdated'] ?? json['date'],
    );
    final updatedAt = legacyUpdated ?? now;
    final createdAt = _parseDateTime(json['createdAt']) ?? updatedAt;

    final history = _parseHistory(
      json['history'],
      fallbackUpdatedAt: updatedAt,
    );

    if (isLegacy) {
      final legacyCountToday = _asInt(json['countToday']);
      if (legacyCountToday > 0) {
        final legacyDateKey =
            _dateKeyFromValue(json['date']) ?? DailyProgress.dateKey(now);
        final existing = history[legacyDateKey]?.count ?? 0;
        if (legacyCountToday > existing) {
          history[legacyDateKey] = DailyProgress(
            date: legacyDateKey,
            count: legacyCountToday,
            updatedAt: updatedAt,
          );
        }
      }
    }

    return Task(
      id: id,
      categoryId: categoryId,
      name: name,
      kind: kind,
      isActive: _asBool(json['isActive'], fallback: true),
      sortOrder: _asInt(json['sortOrder'], fallback: fallbackSortOrder),
      targetDaily: targetDaily,
      targetTotal: targetTotal,
      totalCount: _asInt(json['count'] ?? json['totalCount']),
      createdAt: createdAt,
      updatedAt: updatedAt,
      history: history,
    );
  }

  Map<String, DailyProgress> _parseHistory(
    Object? raw, {
    required DateTime fallbackUpdatedAt,
  }) {
    if (raw is! Map) return <String, DailyProgress>{};

    final history = <String, DailyProgress>{};
    for (final entry in raw.entries) {
      final dateKey = entry.key.toString();
      if (!_isDateKey(dateKey)) continue;

      final value = entry.value;
      final int count;
      final DateTime updatedAt;
      if (value is Map) {
        count = _asInt(value['count']);
        updatedAt = _parseDateTime(value['updatedAt']) ?? fallbackUpdatedAt;
      } else {
        count = _asInt(value);
        updatedAt = fallbackUpdatedAt;
      }
      if (count <= 0) continue;
      history[dateKey] = DailyProgress(
        date: dateKey,
        count: count,
        updatedAt: updatedAt,
      );
    }
    return history;
  }

  /// Menulis skema v2. Bila [original] diberikan, field yang tidak dikenal
  /// dipertahankan selama masih memungkinkan.
  Map<String, dynamic> toJson(
    TaskMasterData data, {
    Map<String, dynamic>? original,
    DateTime? today,
  }) {
    final todayKey = DailyProgress.dateKey(today ?? _clock());
    final result = <String, dynamic>{...?original};
    result['schemaVersion'] = TaskMasterData.currentSchemaVersion;

    final originalCategories = original?['categories'];
    final originalCategoryList = originalCategories is List
        ? originalCategories
        : const [];

    result['categories'] = data.categories.map((category) {
      final originalCategory = _findOriginalCategory(
        originalCategoryList,
        category,
      );
      final categoryJson = <String, dynamic>{...?originalCategory};
      categoryJson['id'] = category.id;
      categoryJson['name'] = category.name;
      categoryJson['icon'] = category.icon;
      categoryJson['isHidden'] = category.isHidden;
      categoryJson['sortOrder'] = category.sortOrder;

      final originalTasks = originalCategory?['tasks'];
      final originalTaskList = originalTasks is List ? originalTasks : const [];

      categoryJson['tasks'] = category.tasks.map((task) {
        final originalTask = _findOriginalTask(originalTaskList, task);
        final taskJson = <String, dynamic>{...?originalTask};
        taskJson.addAll(
          _taskToJson(task, todayKey, originalTask: originalTask),
        );
        return taskJson;
      }).toList();

      return categoryJson;
    }).toList();

    return result;
  }

  Map<String, dynamic> _taskToJson(
    Task task,
    String todayKey, {
    Map<String, dynamic>? originalTask,
  }) {
    final countToday = task.countOn(todayKey);
    final updatedIso = task.updatedAt.toIso8601String();
    final originalDate = originalTask?['date'];
    final legacyDate = originalDate is String && originalDate.trim().isNotEmpty
        ? originalDate
        : _formatLegacyDate(task.updatedAt);
    final prunedHistory = pruneHistory(
      task.history,
      today: DateTime.parse('${todayKey}T00:00:00'),
    );

    return {
      'id': task.id,
      'name': task.name,
      'kind': task.kind.jsonValue,
      'type': task.kind == TaskKind.progress ? 1 : 0,
      'isActive': task.isActive,
      'sortOrder': task.sortOrder,
      'count': task.totalCount,
      'countToday': countToday,
      'targetCountToday': task.targetDaily,
      'targetCount': task.targetTotal,
      'date': legacyDate,
      'lastUpdated': legacyDate,
      'checked': task.isCompleteOn(todayKey),
      'createdAt': task.createdAt.toIso8601String(),
      'updatedAt': updatedIso,
      'history': {
        for (final entry in prunedHistory.entries)
          entry.key: {
            'count': entry.value.count,
            'updatedAt': entry.value.updatedAt.toIso8601String(),
          },
      },
    };
  }

  Map<String, dynamic>? _findOriginalCategory(
    List<dynamic> originalCategories,
    Category category,
  ) {
    for (final raw in originalCategories) {
      final map = _asMap(raw);
      if (map == null) continue;
      if (_asString(map['id']) == category.id) return map;
    }
    for (final raw in originalCategories) {
      final map = _asMap(raw);
      if (map == null) continue;
      if (_asString(map['name']) == category.name) return map;
    }
    return null;
  }

  Map<String, dynamic>? _findOriginalTask(
    List<dynamic> originalTasks,
    Task task,
  ) {
    for (final raw in originalTasks) {
      final map = _asMap(raw);
      if (map == null) continue;
      if (_asString(map['id']) == task.id) return map;
    }
    for (final raw in originalTasks) {
      final map = _asMap(raw);
      if (map == null) continue;
      if (_asString(map['name']) == task.name) return map;
    }
    return null;
  }

  String _categoryIdFromName(String name) {
    final normalized = name.trim().toLowerCase();
    final source = normalized.isEmpty ? 'tanpa-nama' : normalized;
    final digest = sha256.convert(utf8.encode(source)).toString();
    return 'cat_${digest.substring(0, 8)}';
  }

  String _uniqueId(String base, Set<String> used) {
    final sanitized = base.trim().isEmpty ? _idGenerator() : base.trim();
    var candidate = sanitized;
    var counter = 2;
    while (used.contains(candidate)) {
      candidate = '${sanitized}_$counter';
      counter++;
    }
    used.add(candidate);
    return candidate;
  }

  /// Pemeriksaan cepat `YYYY-MM-DD` tanpa RegExp, karena dipanggil untuk
  /// setiap entri riwayat dan bisa mencapai puluhan ribu kali pada data besar.
  static bool _isDateKey(String value) {
    if (value.length != 10) return false;
    for (var index = 0; index < value.length; index++) {
      if (index == 4 || index == 7) {
        if (value.codeUnitAt(index) != 0x2D) return false;
        continue;
      }
      final code = value.codeUnitAt(index);
      if (code < 0x30 || code > 0x39) return false;
    }
    return true;
  }

  String? _dateKeyFromValue(Object? raw) {
    if (raw is! String) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.length >= 10 && _isDateKey(trimmed.substring(0, 10))) {
      return trimmed.substring(0, 10);
    }
    final parsed = _parseDateTime(trimmed);
    return parsed == null ? null : DailyProgress.dateKey(parsed);
  }

  DateTime? _parseDateTime(Object? raw) {
    if (raw is DateTime) return raw;
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw);
    }
    if (raw is! String) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final normalized = trimmed.contains(' ')
        ? trimmed.replaceFirst(' ', 'T')
        : trimmed;
    return DateTime.tryParse(normalized);
  }

  String _formatLegacyDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)} '
        '${two(date.hour)}:${two(date.minute)}';
  }

  Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  String _asString(Object? value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  int _asInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? fallback;
    return fallback;
  }

  bool _asBool(Object? value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return fallback;
  }

  static String _generateTaskId() {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }
}

// lib/features/task_master/data/models/task_model.dart

import 'dart:math';

const _knownCategoryKeys = {'name', 'icon', 'isHidden', 'tasks'};
const _knownTaskKeys = {
  'id',
  'name',
  'count',
  'date',
  'checked',
  'countToday',
  'lastUpdated',
  'targetCountToday',
  'type',
  'targetCount',
  'isActive',
};

/// Menyalin key JSON di luar [knownKeys] apa adanya agar tidak hilang saat
/// modul lama menyimpan ulang file.
Map<String, dynamic> _unknownFieldsOf(
  Map<String, dynamic> json,
  Set<String> knownKeys,
) {
  return {
    for (final entry in json.entries)
      if (!knownKeys.contains(entry.key)) entry.key: entry.value,
  };
}

class TaskCategory {
  final String name;
  final String icon;
  bool isHidden;
  final List<TaskItem> tasks;

  /// Key JSON yang tidak dikenali model ini, disimpan apa adanya agar tidak
  /// hilang saat modul lama menyimpan ulang file.
  final Map<String, dynamic> unknownFields;

  TaskCategory({
    required this.name,
    required this.icon,
    required this.isHidden,
    required this.tasks,
    this.unknownFields = const {},
  });

  factory TaskCategory.fromJson(Map<String, dynamic> json) {
    var list = json['tasks'] as List? ?? [];
    List<TaskItem> taskList = list.map((i) => TaskItem.fromJson(i)).toList();

    return TaskCategory(
      name: json['name'] ?? '',
      icon: json['icon'] ?? '📌',
      isHidden: json['isHidden'] ?? false,
      tasks: taskList,
      unknownFields: _unknownFieldsOf(json, _knownCategoryKeys),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ...unknownFields,
      'name': name,
      'icon': icon,
      'isHidden': isHidden,
      'tasks': tasks.map((e) => e.toJson()).toList(),
    };
  }

  TaskCategory copyWith({String? name, String? icon}) {
    return TaskCategory(
      name: name ?? this.name,
      icon: icon ?? this.icon,
      isHidden: isHidden,
      tasks: tasks,
      unknownFields: unknownFields,
    );
  }
}

class TaskItem {
  final String id;
  String name;
  int count;
  String? date;
  final bool checked;
  int countToday;
  final String lastUpdated;
  int targetCountToday;
  int type; // <--- PERBAIKAN: Hapus kata kunci 'final' agar tidak imutabel
  int targetCount;
  bool isActive;

  /// Key JSON yang tidak dikenali model ini, disimpan apa adanya agar tidak
  /// hilang saat modul lama menyimpan ulang file.
  final Map<String, dynamic> unknownFields;

  TaskItem({
    required this.id,
    required this.name,
    required this.count,
    this.date,
    required this.checked,
    required this.countToday,
    required this.lastUpdated,
    required this.targetCountToday,
    required this.type,
    required this.targetCount,
    this.isActive = true,
    this.unknownFields = const {},
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] ?? generateRandomId(),
      name: json['name'] ?? '',
      count: json['count'] ?? 0,
      date: json['date'],
      checked: json['checked'] ?? false,
      countToday: json['countToday'] ?? 0,
      lastUpdated: json['lastUpdated'] ?? '',
      targetCountToday: json['targetCountToday'] ?? 0,
      type: json['type'] ?? 0,
      targetCount: json['targetCount'] ?? 0,
      isActive: json['isActive'] ?? true,
      unknownFields: _unknownFieldsOf(json, _knownTaskKeys),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ...unknownFields,
      'id': id,
      'name': name,
      'count': count,
      'date': date,
      'checked': checked,
      'countToday': countToday,
      'lastUpdated': lastUpdated,
      'targetCountToday': targetCountToday,
      'type': type,
      'targetCount': targetCount,
      'isActive': isActive,
    };
  }

  static String generateRandomId() {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(
      8,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }
}

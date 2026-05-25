import 'dart:math';

class TaskCategory {
  final String name;
  final String icon;
  final bool isHidden;
  final List<TaskItem> tasks;

  TaskCategory({
    required this.name,
    required this.icon,
    required this.isHidden,
    required this.tasks,
  });

  factory TaskCategory.fromJson(Map<String, dynamic> json) {
    var list = json['tasks'] as List? ?? [];
    List<TaskItem> taskList = list.map((i) => TaskItem.fromJson(i)).toList();

    return TaskCategory(
      name: json['name'] ?? '',
      icon: json['icon'] ?? '📌',
      isHidden: json['isHidden'] ?? false,
      tasks: taskList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon': icon,
      'isHidden': isHidden,
      'tasks': tasks.map((e) => e.toJson()).toList(),
    };
  }
}

class TaskItem {
  final String id; // Tetap final karena ID tidak perlu diubah
  String name; // <--- HAPUS FINAL DI SINI
  int count;
  String? date;
  final bool checked;
  int countToday;
  final String lastUpdated;
  int targetCountToday;
  final int type;
  int targetCount; // <--- HAPUS FINAL DI SINI

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
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
    };
  }

  // Fungsi statis untuk membuat ID acak unik numerik/string pendek jika tidak pakai package uuid
  static String generateRandomId() {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(
      8,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }
}

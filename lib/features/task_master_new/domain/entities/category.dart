import 'task.dart';

/// Kategori dengan identitas stabil yang tidak bergantung pada nama.
class Category {
  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.isHidden,
    required this.sortOrder,
    List<Task> tasks = const [],
  }) : tasks = List.unmodifiable(tasks);

  final String id;
  final String name;
  final String icon;
  final bool isHidden;
  final int sortOrder;
  final List<Task> tasks;

  Category copyWith({
    String? id,
    String? name,
    String? icon,
    bool? isHidden,
    int? sortOrder,
    List<Task>? tasks,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      isHidden: isHidden ?? this.isHidden,
      sortOrder: sortOrder ?? this.sortOrder,
      tasks: tasks ?? this.tasks,
    );
  }
}

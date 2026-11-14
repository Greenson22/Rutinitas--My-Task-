import 'category.dart';
import 'task.dart';

/// Seluruh data Task Master yang sudah menggunakan skema v2.
class TaskMasterData {
  TaskMasterData({
    required this.schemaVersion,
    List<Category> categories = const [],
  }) : categories = List.unmodifiable(categories);

  static const int currentSchemaVersion = 2;

  final int schemaVersion;
  final List<Category> categories;

  Iterable<Task> get allTasks =>
      categories.expand((category) => category.tasks);

  int get activeTaskCount => categories
      .where((category) => !category.isHidden)
      .expand((category) => category.tasks)
      .where((task) => task.isActive)
      .length;

  int get activeCategoryCount =>
      categories.where((category) => !category.isHidden).length;

  TaskMasterData copyWith({int? schemaVersion, List<Category>? categories}) {
    return TaskMasterData(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      categories: categories ?? this.categories,
    );
  }

  factory TaskMasterData.empty() {
    return TaskMasterData(schemaVersion: currentSchemaVersion);
  }
}

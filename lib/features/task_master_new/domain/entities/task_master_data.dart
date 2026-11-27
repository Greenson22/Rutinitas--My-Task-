import 'category.dart';
import 'task.dart';
import 'today_task_sort_mode.dart';

/// Seluruh data Task Master yang sudah menggunakan skema v3.
class TaskMasterData {
  TaskMasterData({
    required this.schemaVersion,
    List<Category> categories = const [],
    this.todaySortMode = TodayTaskSortMode.defaultOrder,
    List<String> todayOrder = const [],
  }) : categories = List.unmodifiable(categories),
       todayOrder = List.unmodifiable(todayOrder);

  static const int currentSchemaVersion = 3;

  final int schemaVersion;
  final List<Category> categories;
  final TodayTaskSortMode todaySortMode;
  final List<String> todayOrder;

  Iterable<Task> get allTasks =>
      categories.expand((category) => category.tasks);

  /// Mencari kategori berdasarkan `id`, atau `null` bila tidak ada.
  Category? categoryById(String categoryId) {
    for (final category in categories) {
      if (category.id == categoryId) return category;
    }
    return null;
  }

  int get activeTaskCount => categories
      .where((category) => !category.isHidden)
      .expand((category) => category.tasks)
      .where((task) => task.isActive)
      .length;

  int get activeCategoryCount =>
      categories.where((category) => !category.isHidden).length;

  TaskMasterData copyWith({
    int? schemaVersion,
    List<Category>? categories,
    TodayTaskSortMode? todaySortMode,
    List<String>? todayOrder,
  }) {
    return TaskMasterData(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      categories: categories ?? this.categories,
      todaySortMode: todaySortMode ?? this.todaySortMode,
      todayOrder: todayOrder ?? this.todayOrder,
    );
  }

  factory TaskMasterData.empty() {
    return TaskMasterData(schemaVersion: currentSchemaVersion);
  }
}

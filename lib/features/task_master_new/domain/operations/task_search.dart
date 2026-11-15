import '../entities/category.dart';
import '../entities/task.dart';
import '../entities/task_master_data.dart';
import 'dashboard_summary.dart';

/// Jeda input sebelum pencarian diterapkan, agar pengetikan tidak memicu
/// penyaringan ulang pada setiap karakter.
const Duration taskSearchDebounce = Duration(milliseconds: 250);

/// Filter tugas yang dapat digabung dengan pencarian.
enum TaskFilter {
  /// Semua tugas, tanpa memandang status atau target.
  all,

  /// Hanya tugas yang sedang aktif.
  active,

  /// Hanya tugas yang sedang nonaktif.
  inactive,

  /// Hanya tugas yang punya target hari ini.
  hasTargetToday,
}

String taskFilterLabel(TaskFilter filter) {
  return switch (filter) {
    TaskFilter.all => 'Semua',
    TaskFilter.active => 'Tugas aktif',
    TaskFilter.inactive => 'Tugas nonaktif',
    TaskFilter.hasTargetToday => 'Punya target hari ini',
  };
}

bool taskMatchesFilter(Task task, TaskFilter filter) {
  return switch (filter) {
    TaskFilter.all => true,
    TaskFilter.active => task.isActive,
    TaskFilter.inactive => !task.isActive,
    TaskFilter.hasTargetToday => taskHasTargetToday(task),
  };
}

/// Satu kelompok hasil pencarian beserta konteks kategorinya.
class TaskSearchGroup {
  const TaskSearchGroup({
    required this.category,
    required this.tasks,
    required this.categoryNameMatches,
  });

  final Category category;
  final List<Task> tasks;

  /// `true` bila yang cocok adalah nama kategori, bukan hanya nama tugas.
  final bool categoryNameMatches;
}

/// Menyaring tugas di dalam satu kategori berdasarkan [query] dan [filter].
///
/// Pencarian tidak peka huruf besar/kecil. Bila nama kategori cocok, seluruh
/// tugas di kategori tersebut ikut ditampilkan (setelah difilter). Bila hanya
/// nama tugas yang cocok, hanya tugas yang cocok yang ditampilkan.
List<Task> filterTasksInCategory(
  Category category, {
  String query = '',
  TaskFilter filter = TaskFilter.all,
}) {
  final normalized = query.trim().toLowerCase();
  final categoryMatches =
      normalized.isNotEmpty && category.name.toLowerCase().contains(normalized);

  final tasks = [...category.tasks]
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  return tasks
      .where((task) {
        if (!taskMatchesFilter(task, filter)) return false;
        if (normalized.isEmpty || categoryMatches) return true;
        return task.name.toLowerCase().contains(normalized);
      })
      .toList(growable: false);
}

/// Mengelompokkan hasil pencarian per kategori.
///
/// Hanya kategori dengan setidaknya satu tugas yang lolos filter yang
/// dikembalikan. Urutan kategori dan tugas mengikuti `sortOrder` agar stabil.
List<TaskSearchGroup> searchTaskGroups(
  TaskMasterData data, {
  String query = '',
  TaskFilter filter = TaskFilter.all,
  bool includeHidden = false,
}) {
  final normalized = query.trim().toLowerCase();
  final groups = <TaskSearchGroup>[];

  for (final category in visibleCategories(
    data,
    includeHidden: includeHidden,
  )) {
    final tasks = filterTasksInCategory(category, query: query, filter: filter);
    if (tasks.isEmpty) continue;

    groups.add(
      TaskSearchGroup(
        category: category,
        tasks: tasks,
        categoryNameMatches:
            normalized.isNotEmpty &&
            category.name.toLowerCase().contains(normalized),
      ),
    );
  }

  return groups;
}

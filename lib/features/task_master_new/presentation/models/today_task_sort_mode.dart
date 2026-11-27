import '../../domain/entities/today_task_sort_mode.dart';
import '../../domain/operations/dashboard_summary.dart';

export '../../domain/entities/today_task_sort_mode.dart';

/// Helper fungsi untuk mengurutkan daftar [TodayTaskEntry] pada dashboard Hari Ini.
List<TodayTaskEntry> sortTodayTasks(
  List<TodayTaskEntry> tasks, {
  required TodayTaskSortMode mode,
  required String todayKey,
  List<String> customOrder = const [],
}) {
  if (tasks.isEmpty) return tasks;
  final result = List<TodayTaskEntry>.from(tasks);

  switch (mode) {
    case TodayTaskSortMode.defaultOrder:
      return result;

    case TodayTaskSortMode.nameAsc:
      result.sort((a, b) => a.task.name.toLowerCase().compareTo(b.task.name.toLowerCase()));
      return result;

    case TodayTaskSortMode.nameDesc:
      result.sort((a, b) => b.task.name.toLowerCase().compareTo(a.task.name.toLowerCase()));
      return result;

    case TodayTaskSortMode.incompleteFirst:
      result.sort((a, b) {
        final aMet = isTaskTargetMetToday(a.task, todayKey);
        final bMet = isTaskTargetMetToday(b.task, todayKey);
        if (aMet != bMet) {
          return aMet ? 1 : -1; // belum tercapai (false) di atas
        }
        return 0;
      });
      return result;

    case TodayTaskSortMode.completedFirst:
      result.sort((a, b) {
        final aMet = isTaskTargetMetToday(a.task, todayKey);
        final bMet = isTaskTargetMetToday(b.task, todayKey);
        if (aMet != bMet) {
          return aMet ? -1 : 1; // tercapai (true) di atas
        }
        return 0;
      });
      return result;

    case TodayTaskSortMode.categoryAsc:
      result.sort((a, b) {
        final catCompare = a.category.name.toLowerCase().compareTo(b.category.name.toLowerCase());
        if (catCompare != 0) return catCompare;
        return a.task.name.toLowerCase().compareTo(b.task.name.toLowerCase());
      });
      return result;

    case TodayTaskSortMode.custom:
      if (customOrder.isEmpty) return result;
      final indexMap = <String, int>{};
      for (var i = 0; i < customOrder.length; i++) {
        indexMap[customOrder[i]] = i;
      }
      result.sort((a, b) {
        final indexA = indexMap[a.task.id] ?? 999999;
        final indexB = indexMap[b.task.id] ?? 999999;
        return indexA.compareTo(indexB);
      });
      return result;
  }
}

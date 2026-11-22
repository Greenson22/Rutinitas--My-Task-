import '../entities/category.dart';
import '../entities/task.dart';
import '../entities/task_kind.dart';
import '../entities/task_master_data.dart';
import '../entities/today_visibility.dart';

/// Satu tugas yang relevan untuk daftar "Hari Ini" pada dashboard.
class TodayTaskEntry {
  const TodayTaskEntry({required this.category, required this.task});

  final Category category;
  final Task task;
}

/// Kategori yang boleh tampil di dashboard sesuai mode "Tampilkan tersembunyi".
List<Category> visibleCategories(
  TaskMasterData data, {
  bool includeHidden = false,
}) {
  final categories =
      data.categories
          .where((category) => includeHidden || !category.isHidden)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return categories;
}

/// Tugas dianggap punya target hari ini bila punya target harian, atau
/// merupakan tugas `progress` yang punya target total.
bool taskHasTargetToday(Task task) {
  if (task.targetDaily > 0) return true;
  return task.kind == TaskKind.progress && task.targetTotal > 0;
}

/// Apakah target tugas sudah tercapai untuk [todayKey].
///
/// Tugas dengan target harian mengikuti target harian. Tugas `progress` tanpa
/// target harian dianggap tercapai ketika total mencapai target total. Tugas
/// tanpa target, seperti `counter`, tidak pernah dihitung sebagai target.
bool isTaskTargetMetToday(Task task, String todayKey) {
  if (task.targetDaily > 0) return task.countOn(todayKey) >= task.targetDaily;
  return task.isProgressComplete;
}

/// Mengumpulkan tugas aktif yang tampil di daftar "Hari Ini" sesuai aturan visibilitas.
///
/// Aturan:
/// - Tugas nonaktif selalu dikecualikan.
/// - Kategori tersembunyi tetap dikecualikan kecuali [includeHidden] aktif.
/// - `never` selalu dikecualikan.
/// - `always` selalu disertakan.
/// - `auto` memakai aturan lama (target harian > 0, progress dengan target total > 0, atau countToday > 0).
/// Urutan mengikuti `sortOrder` kategori lalu tugas agar stabil antar-build.
List<TodayTaskEntry> collectTodayTasks(
  TaskMasterData data,
  String todayKey, {
  bool includeHidden = false,
}) {
  final entries = <TodayTaskEntry>[];
  for (final category in visibleCategories(
    data,
    includeHidden: includeHidden,
  )) {
    final tasks = [...category.tasks]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    for (final task in tasks) {
      if (!task.isActive) continue;
      final shouldShow = switch (task.todayVisibility) {
        TodayVisibility.never => false,
        TodayVisibility.always => true,
        TodayVisibility.auto =>
          taskHasTargetToday(task) || task.countOn(todayKey) > 0,
      };
      if (shouldShow) {
        entries.add(TodayTaskEntry(category: category, task: task));
      }
    }
  }
  return entries;
}

/// Jumlah target yang sudah tercapai dari daftar tugas "Hari Ini".
int completedTargetCount(Iterable<TodayTaskEntry> entries, String todayKey) {
  return entries
      .where((entry) => isTaskTargetMetToday(entry.task, todayKey))
      .length;
}

/// Jumlah tugas aktif di dalam satu kategori.
int categoryActiveTaskCount(Category category) {
  return category.tasks.where((task) => task.isActive).length;
}

/// Jumlah tugas aktif di kategori yang punya target hari ini.
int categoryTargetTaskCount(Category category) {
  return category.tasks
      .where((task) => task.isActive && taskHasTargetToday(task))
      .length;
}

/// Jumlah target tercapai hari ini di dalam satu kategori.
int categoryCompletedTargetCount(Category category, String todayKey) {
  return category.tasks
      .where((task) => task.isActive && isTaskTargetMetToday(task, todayKey))
      .length;
}

/// Jumlah tugas aktif yang sudah punya aktivitas hari ini di satu kategori.
int categoryActiveTodayCount(Category category, String todayKey) {
  return category.tasks
      .where((task) => task.isActive && task.countOn(todayKey) > 0)
      .length;
}

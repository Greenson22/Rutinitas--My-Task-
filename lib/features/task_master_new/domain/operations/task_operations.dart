import '../entities/daily_progress.dart';
import '../entities/task.dart';
import '../entities/task_kind.dart';
import '../entities/task_master_data.dart';
import '../entities/today_visibility.dart';

/// Batas panjang nama tugas sesuai spesifikasi.
const int maxTaskNameLength = 120;

/// Kesalahan validasi yang aman ditampilkan pada form tugas.
class TaskValidationException implements Exception {
  TaskValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Memvalidasi nama tugas.
///
/// Mengembalikan pesan kesalahan, atau `null` bila nama valid. Nama tugas
/// boleh sama dengan tugas lain; yang penting tidak kosong dan tidak melebihi
/// batas panjang.
String? validateTaskName(String rawName) {
  final name = rawName.trim();
  if (name.isEmpty) return 'Nama tugas tidak boleh kosong';
  if (name.length > maxTaskNameLength) {
    return 'Nama tugas maksimal $maxTaskNameLength karakter';
  }
  return null;
}

/// Memvalidasi target sesuai jenis tugas.
///
/// Target harian tidak boleh negatif. Tugas [TaskKind.progress] wajib memiliki
/// target total lebih dari nol. Target total negatif juga ditolak agar data
/// tidak setengah jadi.
String? validateTaskTargets({
  required TaskKind kind,
  required int targetDaily,
  required int targetTotal,
}) {
  return validateTaskDailyTarget(targetDaily) ??
      validateTaskTotalTarget(kind: kind, targetTotal: targetTotal);
}

/// Memvalidasi target harian saja.
String? validateTaskDailyTarget(int targetDaily) {
  if (targetDaily < 0) return 'Target harian tidak boleh negatif';
  return null;
}

/// Memvalidasi target total sesuai jenis tugas.
String? validateTaskTotalTarget({
  required TaskKind kind,
  required int targetTotal,
}) {
  if (targetTotal < 0) return 'Target total tidak boleh negatif';
  if (kind == TaskKind.progress && targetTotal <= 0) {
    return 'Target total wajib lebih dari 0 untuk tugas Progres';
  }
  return null;
}

/// Menambah tugas baru di urutan paling akhir pada kategori [categoryId].
///
/// Melempar [TaskValidationException] bila nama, target, atau kategori tidak
/// valid.
TaskMasterData addTaskTo(
  TaskMasterData data, {
  required String id,
  required String categoryId,
  required String name,
  required TaskKind kind,
  required int targetDaily,
  required int targetTotal,
  required bool isActive,
  TodayVisibility todayVisibility = TodayVisibility.auto,
  required DateTime now,
}) {
  final error = validateTaskName(name);
  if (error != null) throw TaskValidationException(error);

  final targetError = validateTaskTargets(
    kind: kind,
    targetDaily: targetDaily,
    targetTotal: targetTotal,
  );
  if (targetError != null) throw TaskValidationException(targetError);

  final categoryIndex = _categoryIndex(data, categoryId);
  final category = data.categories[categoryIndex];
  final nextSortOrder = category.tasks.isEmpty
      ? 0
      : category.tasks
                .map((task) => task.sortOrder)
                .reduce((a, b) => a > b ? a : b) +
            1;

  final task = Task(
    id: id,
    categoryId: categoryId,
    name: name.trim(),
    kind: kind,
    isActive: isActive,
    sortOrder: nextSortOrder,
    targetDaily: targetDaily,
    targetTotal: targetTotal,
    totalCount: 0,
    createdAt: now,
    updatedAt: now,
    todayVisibility: todayVisibility,
  );

  final categories = [...data.categories];
  categories[categoryIndex] = category.copyWith(
    tasks: [...category.tasks, task],
  );
  return data.copyWith(categories: categories);
}

/// Mengubah nama, jenis, target, dan status tugas tanpa mengubah [Task.id],
/// riwayat, hitungan total, atau urutannya.
TaskMasterData updateTaskIn(
  TaskMasterData data, {
  required String categoryId,
  required String taskId,
  required String name,
  required TaskKind kind,
  required int targetDaily,
  required int targetTotal,
  required bool isActive,
  TodayVisibility? todayVisibility,
  int? countToday,
  String? countDate,
  int? totalCount,
  required DateTime now,
}) {
  final error = validateTaskName(name);
  if (error != null) throw TaskValidationException(error);

  final targetError = validateTaskTargets(
    kind: kind,
    targetDaily: targetDaily,
    targetTotal: targetTotal,
  );
  if (targetError != null) throw TaskValidationException(targetError);

  if (countToday != null && countToday < 0) {
    throw TaskValidationException('Hitungan hari ini tidak boleh negatif.');
  }
  if (totalCount != null && totalCount < 0) {
    throw TaskValidationException('Total hitungan tidak boleh negatif.');
  }

  return _replaceTask(
    data,
    categoryId: categoryId,
    taskId: taskId,
    update: (task) {
      var updatedHistory = task.history;
      var updatedTotalCount = totalCount ?? task.totalCount;
      if (countToday != null && countDate != null) {
        final oldCount = task.countOn(countDate);
        if (countToday != oldCount) {
          updatedHistory = Map<String, DailyProgress>.from(task.history);
          if (countToday == 0) {
            updatedHistory.remove(countDate);
          } else {
            updatedHistory[countDate] = DailyProgress(
              date: countDate,
              count: countToday,
              updatedAt: now,
            );
          }
          updatedTotalCount =
              (updatedTotalCount - oldCount + countToday).clamp(0, 1 << 30);
        }
      }
      return task.copyWith(
        name: name.trim(),
        kind: kind,
        targetDaily: targetDaily,
        targetTotal: targetTotal,
        totalCount: updatedTotalCount,
        history: updatedHistory,
        isActive: isActive,
        todayVisibility: todayVisibility ?? task.todayVisibility,
        updatedAt: now,
      );
    },
  );
}

/// Mengubah pengaturan Tampil di Hari Ini untuk satu tugas.
TaskMasterData setTaskVisibilityIn(
  TaskMasterData data, {
  required String categoryId,
  required String taskId,
  required TodayVisibility todayVisibility,
  required DateTime now,
}) {
  return _replaceTask(
    data,
    categoryId: categoryId,
    taskId: taskId,
    update: (task) => task.copyWith(
      todayVisibility: todayVisibility,
      updatedAt: now,
    ),
  );
}

/// Mengubah pengaturan Tampil di Hari Ini untuk beberapa tugas sekaligus tanpa
/// menyentuh status aktif.
TaskMasterData setTasksVisibilityIn(
  TaskMasterData data, {
  required String categoryId,
  required Iterable<String> taskIds,
  required TodayVisibility todayVisibility,
  required DateTime now,
}) {
  final selected = taskIds.toSet();
  final categoryIndex = _categoryIndex(data, categoryId);
  final category = data.categories[categoryIndex];
  var changed = false;

  final tasks = <Task>[];
  for (final task in category.tasks) {
    if (selected.contains(task.id)) {
      changed = true;
      tasks.add(task.copyWith(todayVisibility: todayVisibility, updatedAt: now));
    } else {
      tasks.add(task);
    }
  }
  if (!changed) {
    throw TaskValidationException('Tidak ada tugas yang dipilih');
  }

  final categories = [...data.categories];
  categories[categoryIndex] = category.copyWith(tasks: tasks);
  return data.copyWith(categories: categories);
}

/// Mengaktifkan atau menonaktifkan tugas tanpa menghapus riwayatnya.
TaskMasterData setTaskActiveIn(
  TaskMasterData data, {
  required String categoryId,
  required String taskId,
  required bool isActive,
  required DateTime now,
}) {
  return _replaceTask(
    data,
    categoryId: categoryId,
    taskId: taskId,
    update: (task) => task.copyWith(isActive: isActive, updatedAt: now),
  );
}

/// Informasi minimum untuk membatalkan satu increment terakhir.
class TaskIncrement {
  const TaskIncrement({
    required this.categoryId,
    required this.taskId,
    required this.dateKey,
  });

  final String categoryId;
  final String taskId;

  /// Tanggal lokal `YYYY-MM-DD` tempat increment dicatat.
  final String dateKey;
}

/// Hasil increment: data terbaru beserta informasi undo.
class IncrementResult {
  const IncrementResult({required this.data, required this.increment});

  final TaskMasterData data;
  final TaskIncrement increment;
}

/// Menaikkan hitungan tugas sebanyak satu pada tanggal lokal [now].
///
/// Total, riwayat harian, dan `updatedAt` diperbarui dalam satu langkah.
/// Entri riwayat dibuat bila belum ada.
IncrementResult incrementTaskIn(
  TaskMasterData data, {
  required String categoryId,
  required String taskId,
  required DateTime now,
}) {
  final dateKey = DailyProgress.dateKey(now);
  final updated = _replaceTask(
    data,
    categoryId: categoryId,
    taskId: taskId,
    update: (task) => _applyDailyCount(
      task,
      dateKey: dateKey,
      count: task.countOn(dateKey) + 1,
      totalDelta: 1,
      now: now,
    ),
  );

  return IncrementResult(
    data: updated,
    increment: TaskIncrement(
      categoryId: categoryId,
      taskId: taskId,
      dateKey: dateKey,
    ),
  );
}

/// Mengembalikan efek satu increment [increment].
///
/// Hitungan harian dikurangi satu; entri riwayat dihapus bila menjadi nol.
/// Bila entri riwayat sudah tidak ada, total tidak diubah agar total dan
/// riwayat tidak saling menyimpang.
TaskMasterData undoIncrementIn(
  TaskMasterData data, {
  required TaskIncrement increment,
  required DateTime now,
}) {
  return _replaceTask(
    data,
    categoryId: increment.categoryId,
    taskId: increment.taskId,
    update: (task) {
      final current = task.history[increment.dateKey];
      if (current == null) return task.copyWith(updatedAt: now);
      return _applyDailyCount(
        task,
        dateKey: increment.dateKey,
        count: current.count - 1,
        totalDelta: -1,
        now: now,
      );
    },
  );
}

Task _applyDailyCount(
  Task task, {
  required String dateKey,
  required int count,
  required int totalDelta,
  required DateTime now,
}) {
  final history = Map<String, DailyProgress>.from(task.history);
  if (count <= 0) {
    history.remove(dateKey);
  } else {
    history[dateKey] = DailyProgress(
      date: dateKey,
      count: count,
      updatedAt: now,
    );
  }

  final total = task.totalCount + totalDelta;
  return task.copyWith(
    totalCount: total < 0 ? 0 : total,
    updatedAt: now,
    history: history,
  );
}

/// Memindahkan tugas ke posisi [newIndex] di dalam kategorinya.
///
/// Indeks dihitung pada urutan tugas yang sudah diurutkan berdasarkan
/// `sortOrder`. Semua tugas di kategori tersebut dinomori ulang agar urutan
/// tetap konsisten setelah reload.
TaskMasterData reorderTaskIn(
  TaskMasterData data, {
  required String categoryId,
  required String taskId,
  required int newIndex,
  required DateTime now,
}) {
  final categoryIndex = _categoryIndex(data, categoryId);
  final category = data.categories[categoryIndex];
  final tasks = [...category.tasks]
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  final currentIndex = tasks.indexWhere((task) => task.id == taskId);
  if (currentIndex == -1) {
    throw TaskValidationException('Tugas tidak ditemukan');
  }

  final moved = tasks.removeAt(currentIndex);
  final targetIndex = newIndex.clamp(0, tasks.length);
  tasks.insert(targetIndex, moved);

  final categories = [...data.categories];
  categories[categoryIndex] = category.copyWith(
    tasks: [
      for (var i = 0; i < tasks.length; i++)
        tasks[i].id == taskId
            ? tasks[i].copyWith(sortOrder: i, updatedAt: now)
            : tasks[i].copyWith(sortOrder: i),
    ],
  );
  return data.copyWith(categories: categories);
}

/// Memindahkan tugas ke kategori lain tanpa mengubah `id`, riwayat, atau
/// hitungan totalnya.
///
/// Tugas diletakkan di urutan paling akhir kategori tujuan. Memindahkan ke
/// kategori yang sama akan menolak operasi agar urutan tidak berubah diam-diam;
/// gunakan [reorderTaskIn] untuk mengubah urutan di dalam kategori.
TaskMasterData moveTaskToCategoryIn(
  TaskMasterData data, {
  required String fromCategoryId,
  required String taskId,
  required String toCategoryId,
  required DateTime now,
}) {
  if (fromCategoryId == toCategoryId) {
    throw TaskValidationException(
      'Pilih kategori tujuan yang berbeda dari kategori saat ini',
    );
  }

  final fromIndex = _categoryIndex(data, fromCategoryId);
  final toIndex = _categoryIndex(data, toCategoryId);
  final fromCategory = data.categories[fromIndex];
  final taskIndex = fromCategory.tasks.indexWhere((task) => task.id == taskId);
  if (taskIndex == -1) {
    throw TaskValidationException('Tugas tidak ditemukan');
  }

  final task = fromCategory.tasks[taskIndex];
  final remaining = [...fromCategory.tasks]..removeAt(taskIndex);
  final toCategory = data.categories[toIndex];
  final nextSortOrder = toCategory.tasks.isEmpty
      ? 0
      : toCategory.tasks
                .map((item) => item.sortOrder)
                .reduce((a, b) => a > b ? a : b) +
            1;

  final categories = [...data.categories];
  categories[fromIndex] = fromCategory.copyWith(tasks: remaining);
  categories[toIndex] = toCategory.copyWith(
    tasks: [
      ...toCategory.tasks,
      task.copyWith(
        categoryId: toCategoryId,
        sortOrder: nextSortOrder,
        updatedAt: now,
      ),
    ],
  );
  return data.copyWith(categories: categories);
}

/// Mengaktifkan atau menonaktifkan beberapa tugas sekaligus.
TaskMasterData setTasksActiveIn(
  TaskMasterData data, {
  required String categoryId,
  required Iterable<String> taskIds,
  required bool isActive,
  required DateTime now,
}) {
  final selected = taskIds.toSet();
  final categoryIndex = _categoryIndex(data, categoryId);
  final category = data.categories[categoryIndex];
  var changed = false;

  final tasks = <Task>[];
  for (final task in category.tasks) {
    if (selected.contains(task.id)) {
      changed = true;
      tasks.add(task.copyWith(isActive: isActive, updatedAt: now));
    } else {
      tasks.add(task);
    }
  }
  if (!changed) {
    throw TaskValidationException('Tidak ada tugas yang dipilih');
  }

  final categories = [...data.categories];
  categories[categoryIndex] = category.copyWith(tasks: tasks);
  return data.copyWith(categories: categories);
}

/// Menghapus beberapa tugas sekaligus dari satu kategori.
TaskMasterData deleteTasksFrom(
  TaskMasterData data, {
  required String categoryId,
  required Iterable<String> taskIds,
}) {
  final selected = taskIds.toSet();
  final categoryIndex = _categoryIndex(data, categoryId);
  final category = data.categories[categoryIndex];
  final remaining = category.tasks
      .where((task) => !selected.contains(task.id))
      .toList();
  if (remaining.length == category.tasks.length) {
    throw TaskValidationException('Tidak ada tugas yang dipilih');
  }

  final categories = [...data.categories];
  categories[categoryIndex] = category.copyWith(tasks: remaining);
  return data.copyWith(categories: categories);
}

/// Menghapus tugas dari kategorinya.
TaskMasterData deleteTaskFrom(
  TaskMasterData data, {
  required String categoryId,
  required String taskId,
}) {
  final categoryIndex = _categoryIndex(data, categoryId);
  final category = data.categories[categoryIndex];
  final remaining = category.tasks.where((task) => task.id != taskId).toList();
  if (remaining.length == category.tasks.length) {
    throw TaskValidationException('Tugas tidak ditemukan');
  }

  final categories = [...data.categories];
  categories[categoryIndex] = category.copyWith(tasks: remaining);
  return data.copyWith(categories: categories);
}

TaskMasterData _replaceTask(
  TaskMasterData data, {
  required String categoryId,
  required String taskId,
  required Task Function(Task task) update,
}) {
  final categoryIndex = _categoryIndex(data, categoryId);
  final category = data.categories[categoryIndex];
  final taskIndex = category.tasks.indexWhere((task) => task.id == taskId);
  if (taskIndex == -1) {
    throw TaskValidationException('Tugas tidak ditemukan');
  }

  final tasks = [...category.tasks];
  tasks[taskIndex] = update(tasks[taskIndex]);

  final categories = [...data.categories];
  categories[categoryIndex] = category.copyWith(tasks: tasks);
  return data.copyWith(categories: categories);
}

int _categoryIndex(TaskMasterData data, String categoryId) {
  final index = data.categories.indexWhere(
    (category) => category.id == categoryId,
  );
  if (index == -1) {
    throw TaskValidationException('Kategori tidak ditemukan');
  }
  return index;
}

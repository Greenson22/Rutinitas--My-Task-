import '../entities/daily_progress.dart';
import '../entities/task.dart';

/// Riwayat disimpan maksimal 365 hari per tugas.
const int historyRetentionDays = 365;

/// Kunci tanggal paling lama yang masih disimpan untuk [today].
String historyRetentionCutoffKey(DateTime today) {
  final cutoff = DateTime(
    today.year,
    today.month,
    today.day - (historyRetentionDays - 1),
  );
  return DailyProgress.dateKey(cutoff);
}

/// Memangkas [history] menjadi maksimal [historyRetentionDays] hari terakhir.
///
/// Hanya tanggal dengan hitungan lebih dari nol yang dipertahankan.
Map<String, DailyProgress> pruneHistory(
  Map<String, DailyProgress> history, {
  required DateTime today,
}) {
  final cutoffKey = historyRetentionCutoffKey(today);
  final pruned = <String, DailyProgress>{};
  for (final entry in history.entries) {
    if (entry.value.count <= 0) continue;
    if (entry.key.compareTo(cutoffKey) < 0) continue;
    pruned[entry.key] = entry.value;
  }
  return pruned;
}

/// Menghitung streak dari hari kemarin ke belakang.
///
/// Hari ini tidak ikut dihitung dan tidak memutus streak ketika belum
/// dikerjakan. Aturan berhasil per hari mengikuti
/// [Task.isDailyGoalMetOn]: target harian bila tersedia, atau aktivitas bila
/// target harian nol.
int calculateStreak(Task task, DateTime today) {
  var cursor = DateTime(today.year, today.month, today.day - 1);
  var streak = 0;

  // Riwayat maksimal 365 hari, sehingga perulangan tidak perlu lebih panjang.
  for (var day = 0; day < historyRetentionDays; day++) {
    final dateKey = DailyProgress.dateKey(cursor);
    if (!task.isDailyGoalMetOn(dateKey)) break;
    streak++;
    cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
  }

  return streak;
}

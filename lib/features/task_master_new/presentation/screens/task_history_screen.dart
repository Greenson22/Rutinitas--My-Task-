import 'package:flutter/material.dart';

import '../../domain/entities/daily_progress.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_kind.dart';
import '../../domain/operations/streak_calculator.dart';

/// Membuka halaman riwayat harian satu tugas.
Future<void> openTaskHistory(
  BuildContext context, {
  required Task task,
  required DateTime today,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => TaskHistoryScreen(task: task, today: today),
    ),
  );
}

/// Menampilkan riwayat harian sparse dan streak satu tugas.
class TaskHistoryScreen extends StatelessWidget {
  const TaskHistoryScreen({super.key, required this.task, required this.today});

  final Task task;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final streak = calculateStreak(task, today);
    final entries = task.history.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      key: const Key('taskHistoryScreen'),
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.indigo[700],
        foregroundColor: Colors.white,
        title: Text('Riwayat ${task.name}'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  size: 22,
                  color: Colors.orange,
                  semanticLabel: 'Streak',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    streak == 0
                        ? 'Belum ada streak berjalan'
                        : 'Streak $streak hari',
                    key: const Key('taskHistoryStreak'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (entries.isEmpty)
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Belum ada riwayat untuk tugas ini.',
                key: const Key('taskHistoryEmpty'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.blueGrey[600]),
              ),
            )
          else
            Card(
              elevation: 1.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                key: const Key('taskHistoryList'),
                children: [
                  for (var i = 0; i < entries.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    _HistoryEntry(task: task, entry: entries[i]),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryEntry extends StatelessWidget {
  const _HistoryEntry({required this.task, required this.entry});

  final Task task;
  final DailyProgress entry;

  @override
  Widget build(BuildContext context) {
    final dateKey = entry.date;
    final count = entry.count;
    final status = _statusFor(dateKey, count);

    return ListTile(
      key: Key('taskHistoryEntry_$dateKey'),
      dense: true,
      leading: Icon(status.icon, size: 20, color: status.color),
      title: Text(
        formatHistoryDate(dateKey),
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        status.label,
        style: TextStyle(fontSize: 11, color: Colors.blueGrey[600]),
      ),
    );
  }

  _HistoryStatus _statusFor(String dateKey, int count) {
    if (task.kind == TaskKind.counter ||
        (task.kind == TaskKind.habit && task.targetDaily == 0) ||
        (task.kind == TaskKind.progress &&
            task.targetDaily == 0 &&
            !task.isProgressComplete)) {
      return _HistoryStatus(
        label: 'Aktivitas • $count×',
        icon: Icons.check_circle_outline,
        color: Colors.teal,
      );
    }
    if (task.kind == TaskKind.progress && task.isProgressComplete) {
      return _HistoryStatus(
        label: 'Target total tercapai • $count×',
        icon: Icons.check_circle_outline,
        color: Colors.teal,
      );
    }
    final met = task.isDailyGoalMetOn(dateKey);
    return _HistoryStatus(
      label: met
          ? 'Target harian tercapai • $count×'
          : 'Di bawah target • $count×',
      icon: met ? Icons.check_circle_outline : Icons.adjust_rounded,
      color: met ? Colors.teal : Colors.orange,
    );
  }
}

class _HistoryStatus {
  const _HistoryStatus({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

const List<String> _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

/// Memformat kunci `YYYY-MM-DD` menjadi tanggal yang mudah dibaca.
String formatHistoryDate(String dateKey) {
  final parts = dateKey.split('-');
  if (parts.length != 3) return dateKey;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return dateKey;
  if (month < 1 || month > 12) return dateKey;
  return '$day ${_monthNames[month - 1]} $year';
}

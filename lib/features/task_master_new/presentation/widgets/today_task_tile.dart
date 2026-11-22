import 'package:flutter/material.dart';

import '../../domain/entities/task.dart';
import '../../domain/entities/task_kind.dart';
import '../../domain/entities/today_visibility.dart';
import '../../domain/operations/dashboard_summary.dart';
import '../../domain/operations/streak_calculator.dart';
import 'task_kind_label.dart';

/// Baris tugas pada daftar "Hari Ini" di dashboard.
///
/// Menampilkan nama tugas, kategori, progres harian, status target, tombol
/// increment, dan pintasan riwayat/streak.
class TodayTaskTile extends StatelessWidget {
  const TodayTaskTile({
    super.key,
    required this.entry,
    required this.todayKey,
    required this.onIncrement,
    this.onShowHistory,
    this.onChangeVisibility,
    this.isJournalLinked = false,
  });

  final TodayTaskEntry entry;
  final String todayKey;
  final VoidCallback onIncrement;
  final VoidCallback? onShowHistory;
  final void Function(TodayVisibility visibility)? onChangeVisibility;
  final bool isJournalLinked;

  Task get task => entry.task;

  @override
  Widget build(BuildContext context) {
    final countToday = task.countOn(todayKey);
    final streak = _streakFor(todayKey);
    final targetMet = isTaskTargetMetToday(task, todayKey);

    return Padding(
      key: Key('todayTask_${task.id}'),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: _kindIcon(task.kind),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 7,
                  runSpacing: 5,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      task.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    _Pill(label: taskKindLabel(task.kind), color: Colors.teal),
                    if (isJournalLinked)
                      _Pill(
                        key: Key('journalLinkBadge_${task.id}'),
                        label: 'Jurnal',
                        color: Colors.deepPurple,
                      ),
                    if (streak > 0)
                      _Pill(
                        key: Key('taskStreak_${task.id}'),
                        label: '🔥 $streak hari',
                        color: Colors.orange,
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${entry.category.icon} ${entry.category.name}',
                  style: TextStyle(fontSize: 11, color: Colors.blueGrey[600]),
                ),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      _progressText(countToday),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blueGrey[700],
                      ),
                    ),
                    _TargetStatus(task: task, targetMet: targetMet),
                  ],
                ),
                if (task.kind == TaskKind.progress && task.targetTotal > 0) ...[
                  const SizedBox(height: 7),
                  Semantics(
                    label:
                        'Progres ${task.name}: ${task.totalCount} dari '
                        '${task.targetTotal}',
                    value: '${(task.progressFraction * 100).round()} persen',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: task.progressFraction,
                        minHeight: 6,
                        backgroundColor: Colors.indigo.withValues(alpha: 0.12),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.teal,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onShowHistory != null)
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Semantics(
                label: 'Riwayat ${task.name}',
                child: IconButton(
                  key: Key('taskHistory_${task.id}'),
                  tooltip: 'Riwayat ${task.name}',
                  onPressed: onShowHistory,
                  style: IconButton.styleFrom(
                    foregroundColor: Colors.blueGrey,
                    minimumSize: const Size(48, 48),
                    tapTargetSize: MaterialTapTargetSize.padded,
                  ),
                  icon: const Icon(Icons.history_rounded, size: 20),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Semantics(
              label: 'Tambah hitungan ${task.name}',
              child: IconButton(
                key: Key('dashboardIncrement_${task.id}'),
                tooltip: 'Tambah hitungan ${task.name}',
                onPressed: onIncrement,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.teal.withValues(alpha: 0.12),
                  foregroundColor: Colors.teal,
                ),
                icon: const Icon(Icons.add_rounded),
              ),
            ),
          ),
          if (onChangeVisibility != null)
            PopupMenuButton<TodayVisibility>(
              key: Key('todayTaskMenu_${task.id}'),
              tooltip: 'Tampil di Hari Ini',
              onSelected: onChangeVisibility,
              itemBuilder: (context) => [
                PopupMenuItem(
                  key: Key('todayVisibilityOption_auto_${task.id}'),
                  value: TodayVisibility.auto,
                  child: Row(
                    children: [
                      if (task.todayVisibility == TodayVisibility.auto)
                        const Icon(Icons.check, size: 18, color: Colors.indigo)
                      else
                        const SizedBox(width: 18),
                      const SizedBox(width: 8),
                      const Text('Otomatis'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  key: Key('todayVisibilityOption_always_${task.id}'),
                  value: TodayVisibility.always,
                  child: Row(
                    children: [
                      if (task.todayVisibility == TodayVisibility.always)
                        const Icon(Icons.check, size: 18, color: Colors.indigo)
                      else
                        const SizedBox(width: 18),
                      const SizedBox(width: 8),
                      const Text('Selalu'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  key: Key('todayVisibilityOption_never_${task.id}'),
                  value: TodayVisibility.never,
                  child: Row(
                    children: [
                      if (task.todayVisibility == TodayVisibility.never)
                        const Icon(Icons.check, size: 18, color: Colors.indigo)
                      else
                        const SizedBox(width: 18),
                      const SizedBox(width: 8),
                      const Text('Sembunyikan'),
                    ],
                  ),
                ),
              ],
              icon: const Icon(Icons.more_vert, size: 20, color: Colors.blueGrey),
            ),
        ],
      ),
    );
  }

  int _streakFor(String todayKey) {
    final today = DateTime.tryParse(todayKey);
    if (today == null) return 0;
    return calculateStreak(task, today);
  }

  String _progressText(int countToday) {
    switch (task.kind) {
      case TaskKind.habit:
        final target = task.targetDaily > 0 ? '${task.targetDaily}' : '∞';
        return 'Hari ini $countToday / $target';
      case TaskKind.counter:
        return 'Hari ini $countToday';
      case TaskKind.progress:
        final total = task.targetTotal > 0 ? ' / ${task.targetTotal}' : '';
        return 'Hari ini $countToday • ${task.totalCount}$total';
    }
  }

  Widget _kindIcon(TaskKind kind) {
    switch (kind) {
      case TaskKind.habit:
        return const Icon(Icons.repeat_rounded, size: 18, color: Colors.teal);
      case TaskKind.counter:
        return const Icon(
          Icons.add_circle_outline_rounded,
          size: 18,
          color: Colors.blueGrey,
        );
      case TaskKind.progress:
        return const Icon(
          Icons.trending_up_rounded,
          size: 18,
          color: Colors.indigo,
        );
    }
  }
}

class _TargetStatus extends StatelessWidget {
  const _TargetStatus({required this.task, required this.targetMet});

  final Task task;
  final bool targetMet;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _labelAndColor();
    return Container(
      key: Key('taskTargetStatus_${task.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  (String, Color) _labelAndColor() {
    if (targetMet) {
      return task.kind == TaskKind.progress && task.targetDaily == 0
          ? ('Selesai', Colors.green)
          : ('Target tercapai', Colors.green);
    }
    if (taskHasTargetToday(task)) {
      return ('Belum tercapai', Colors.orange[800]!);
    }
    return ('Tanpa target', Colors.blueGrey);
  }
}

class _Pill extends StatelessWidget {
  const _Pill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

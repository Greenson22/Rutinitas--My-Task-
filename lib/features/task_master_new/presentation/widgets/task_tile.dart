import 'package:flutter/material.dart';

import '../../domain/entities/task.dart';
import '../../domain/entities/task_kind.dart';
import '../../domain/operations/streak_calculator.dart';
import 'task_kind_label.dart';

enum TaskAction { edit, toggleActive, delete }

/// Baris tugas dengan badge jenis, status, hitungan, dan progress bar.
///
/// Bila [onAction] diberikan, tombol menu untuk ubah, aktif/nonaktif, dan hapus
/// ikut ditampilkan.
class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.todayKey,
    this.onAction,
    this.onIncrement,
    this.onShowHistory,
    this.showActiveStatus = true,
    this.isJournalLinked = false,
  });

  final Task task;
  final String todayKey;
  final void Function(TaskAction action)? onAction;

  /// Dipanggil saat pengguna menaikkan hitungan satu kali.
  final VoidCallback? onIncrement;

  /// Dipanggil saat pengguna ingin melihat riwayat harian tugas.
  final VoidCallback? onShowHistory;

  /// Menampilkan badge "Aktif" juga, bukan hanya "Nonaktif".
  final bool showActiveStatus;

  /// Menandai tugas yang tertaut ke aktivitas Jurnal.
  final bool isJournalLinked;

  @override
  Widget build(BuildContext context) {
    final countToday = task.countOn(todayKey);
    final isInactive = !task.isActive;
    final streak = _streakFor(todayKey);

    return Opacity(
      opacity: isInactive ? 0.62 : 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            task.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isInactive
                                  ? Colors.grey[700]
                                  : Colors.black87,
                            ),
                          ),
                          _KindBadge(kind: task.kind),
                          if (isJournalLinked)
                            _Pill(
                              key: Key('journalLinkBadge_${task.id}'),
                              label: 'Jurnal',
                              color: Colors.deepPurple,
                            ),
                          if (!task.isActive || showActiveStatus)
                            _StatusBadge(isActive: task.isActive),
                          if (streak > 0)
                            _Pill(
                              key: Key('taskStreak_${task.id}'),
                              label: '🔥 $streak hari',
                              color: Colors.orange,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _progressText(countToday),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blueGrey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                if (onShowHistory != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: IconButton(
                      key: Key('taskHistory_${task.id}'),
                      tooltip: 'Riwayat ${task.name}',
                      onPressed: onShowHistory,
                      style: IconButton.styleFrom(
                        foregroundColor: Colors.blueGrey,
                      ),
                      icon: const Icon(Icons.history_rounded),
                    ),
                  ),
                if (onIncrement != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: IconButton(
                      key: Key('incrementTask_${task.id}'),
                      tooltip: 'Tambah hitungan ${task.name}',
                      onPressed: onIncrement,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.teal.withValues(alpha: 0.12),
                        foregroundColor: Colors.teal,
                      ),
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ),
                if (onAction != null)
                  PopupMenuButton<TaskAction>(
                    key: Key('taskMenu_${task.id}'),
                    tooltip: 'Aksi tugas ${task.name}',
                    onSelected: onAction,
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: TaskAction.edit,
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Ubah'),
                        ),
                      ),
                      PopupMenuItem(
                        value: TaskAction.toggleActive,
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            task.isActive
                                ? Icons.pause_circle_outline
                                : Icons.play_circle_outline,
                          ),
                          title: Text(
                            task.isActive ? 'Nonaktifkan' : 'Aktifkan',
                          ),
                        ),
                      ),
                      const PopupMenuItem(
                        value: TaskAction.delete,
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          title: Text(
                            'Hapus',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (task.kind == TaskKind.progress && task.targetTotal > 0) ...[
              const SizedBox(height: 10),
              Semantics(
                label:
                    'Progres ${task.name}: ${task.totalCount} dari '
                    '${task.targetTotal}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: task.progressFraction,
                    minHeight: 7,
                    backgroundColor: Colors.indigo.withValues(alpha: 0.12),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.teal,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${task.totalCount} / ${task.targetTotal}',
                style: TextStyle(fontSize: 11, color: Colors.blueGrey[600]),
              ),
            ],
          ],
        ),
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
        final target = task.targetDaily > 0
            ? '${task.targetDaily}'
            : 'tanpa target';
        return 'Hari ini $countToday / $target • Total ${task.totalCount}';
      case TaskKind.counter:
        return 'Hari ini $countToday • Total ${task.totalCount}';
      case TaskKind.progress:
        final total = task.targetTotal > 0 ? ' / ${task.targetTotal}' : '';
        return 'Hari ini $countToday • Total ${task.totalCount}$total';
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

class _KindBadge extends StatelessWidget {
  const _KindBadge({required this.kind});

  final TaskKind kind;

  @override
  Widget build(BuildContext context) {
    final color = switch (kind) {
      TaskKind.habit => Colors.teal,
      TaskKind.counter => Colors.blueGrey,
      TaskKind.progress => Colors.indigo,
    };

    return _Pill(label: taskKindLabel(kind), color: color);
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return _Pill(
      label: isActive ? 'Aktif' : 'Nonaktif',
      color: isActive ? Colors.green : Colors.grey,
    );
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

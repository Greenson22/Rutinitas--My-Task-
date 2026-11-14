import 'package:flutter/material.dart';

import '../../domain/entities/task.dart';
import '../../domain/entities/task_kind.dart';

class TaskReadOnlyTile extends StatelessWidget {
  const TaskReadOnlyTile({
    super.key,
    required this.task,
    required this.todayKey,
  });

  final Task task;
  final String todayKey;

  @override
  Widget build(BuildContext context) {
    final countToday = task.countOn(todayKey);
    final isInactive = !task.isActive;

    return Opacity(
      opacity: isInactive ? 0.55 : 1,
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
                          if (isInactive) const _StatusBadge(label: 'Nonaktif'),
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
        return 'Hari ini $countToday • Total ${task.totalCount}'
            '${task.targetTotal > 0 ? ' / ${task.targetTotal}' : ''}';
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
    final (label, color) = switch (kind) {
      TaskKind.habit => ('Kebiasaan', Colors.teal),
      TaskKind.counter => ('Hitungan', Colors.blueGrey),
      TaskKind.progress => ('Progres', Colors.indigo),
    };

    return Container(
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
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        ),
      ),
    );
  }
}

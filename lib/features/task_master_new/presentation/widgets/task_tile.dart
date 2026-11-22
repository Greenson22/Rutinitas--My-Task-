import 'package:flutter/material.dart';

import '../../domain/entities/task.dart';
import '../../domain/entities/task_kind.dart';
import '../../domain/entities/today_visibility.dart';
import '../../domain/operations/streak_calculator.dart';
import 'task_kind_label.dart';

enum TaskAction { edit, toggleActive, moveToCategory, delete }

/// Baris tugas dengan badge jenis, status, hitungan, dan progress bar.
///
/// Bila [onAction] diberikan, tombol menu untuk ubah, aktif/nonaktif, pindah
/// kategori, dan hapus ikut ditampilkan. Mode seleksi diaktifkan lewat
/// [selectionMode] dan long press pada baris.
class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.todayKey,
    this.onAction,
    this.onIncrement,
    this.onShowHistory,
    this.onLongPress,
    this.selectionMode = false,
    this.isSelected = false,
    this.onToggleSelection,
    this.dragHandle,
    this.onMoveUp,
    this.onMoveDown,
    this.onMoveToCategory,
    this.onChangeVisibility,
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

  /// Long press membuka mode seleksi tugas.
  final VoidCallback? onLongPress;

  /// Mode seleksi aktif; ketukan pada baris menambah/menghapus pilihan.
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback? onToggleSelection;

  /// Pegangan drag untuk mengubah urutan tugas.
  final Widget? dragHandle;

  /// Fallback aksesibilitas untuk mengubah urutan tanpa drag.
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  /// Membuka pilihan kategori tujuan saat tugas dipindahkan.
  final VoidCallback? onMoveToCategory;

  /// Mengubah visibilitas tugas di daftar Hari Ini.
  final void Function(TodayVisibility visibility)? onChangeVisibility;

  /// Menampilkan badge "Aktif" juga, bukan hanya "Nonaktif".
  final bool showActiveStatus;

  /// Menandai tugas yang tertaut ke aktivitas Jurnal.
  final bool isJournalLinked;

  bool get _isReorderMode => dragHandle != null || onMoveUp != null;

  @override
  Widget build(BuildContext context) {
    final countToday = task.countOn(todayKey);
    final isInactive = !task.isActive;
    final streak = _streakFor(todayKey);

    return Opacity(
      opacity: isInactive ? 0.62 : 1,
      child: Material(
        color: isSelected
            ? Colors.indigo.withValues(alpha: 0.08)
            : Colors.transparent,
        child: InkWell(
          onLongPress: onLongPress,
          onTap: selectionMode ? onToggleSelection : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (dragHandle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: dragHandle,
                      ),
                    if (selectionMode)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          key: Key('taskSelectCheck_${task.id}'),
                          size: 20,
                          color: isSelected ? Colors.indigo : Colors.blueGrey,
                        ),
                      )
                    else
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
                            icon: const Icon(Icons.history_rounded),
                          ),
                        ),
                      ),
                    if (onIncrement != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Semantics(
                          label: 'Tambah hitungan ${task.name}',
                          child: IconButton(
                            key: Key('incrementTask_${task.id}'),
                            tooltip: 'Tambah hitungan ${task.name}',
                            onPressed: onIncrement,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.teal.withValues(
                                alpha: 0.12,
                              ),
                              foregroundColor: Colors.teal,
                            ),
                            icon: const Icon(Icons.add_rounded),
                          ),
                        ),
                      ),
                    if (_isReorderMode)
                      IconButton(
                        key: Key('moveTaskUp_${task.id}'),
                        tooltip: 'Naikkan ${task.name}',
                        onPressed: onMoveUp,
                        style: IconButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          tapTargetSize: MaterialTapTargetSize.padded,
                        ),
                        icon: const Icon(Icons.keyboard_arrow_up_rounded),
                      ),
                    if (_isReorderMode)
                      IconButton(
                        key: Key('moveTaskDown_${task.id}'),
                        tooltip: 'Turunkan ${task.name}',
                        onPressed: onMoveDown,
                        style: IconButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          tapTargetSize: MaterialTapTargetSize.padded,
                        ),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      ),
                    if (onAction != null)
                      PopupMenuButton<dynamic>(
                        key: Key('taskMenu_${task.id}'),
                        tooltip: 'Aksi tugas ${task.name}',
                        onSelected: (value) {
                          if (value is TaskAction) {
                            onAction!(value);
                          } else if (value is TodayVisibility) {
                            onChangeVisibility?.call(value);
                          }
                        },
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
                          if (onChangeVisibility != null)
                            PopupMenuItem<dynamic>(
                              enabled: false,
                              child: PopupMenuButton<TodayVisibility>(
                                tooltip: 'Pilih visibilitas',
                                onSelected: (visibility) {
                                  Navigator.of(context).pop();
                                  onChangeVisibility?.call(visibility);
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    key: Key('visibilityOption_auto_${task.id}'),
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
                                    key: Key('visibilityOption_always_${task.id}'),
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
                                    key: Key('visibilityOption_never_${task.id}'),
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
                                child: ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.visibility_outlined),
                                  title: const Text('Tampil di Hari Ini'),
                                  trailing: const Icon(Icons.arrow_right, size: 20),
                                ),
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
                          if (onMoveToCategory != null)
                            const PopupMenuItem(
                              value: TaskAction.moveToCategory,
                              child: ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.drive_file_move_outline),
                                title: Text('Pindahkan'),
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
                    value: '${(task.progressFraction * 100).round()} persen',
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

import 'daily_progress.dart';
import 'task_kind.dart';

/// Tugas yang dilacak oleh Task Master.
class Task {
  Task({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.kind,
    required this.isActive,
    required this.sortOrder,
    required this.targetDaily,
    required this.targetTotal,
    required this.totalCount,
    required this.createdAt,
    required this.updatedAt,
    Map<String, DailyProgress> history = const {},
  }) : history = Map.unmodifiable(history);

  final String id;
  final String categoryId;
  final String name;
  final TaskKind kind;
  final bool isActive;
  final int sortOrder;

  /// Target harian; `0` berarti tidak ada target.
  final int targetDaily;

  /// Target total; hanya bermakna untuk [TaskKind.progress].
  final int targetTotal;
  final int totalCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Riwayat sparse dengan kunci `YYYY-MM-DD`.
  final Map<String, DailyProgress> history;

  int countOn(String date) => history[date]?.count ?? 0;

  /// Proyeksi `countToday` dari riwayat untuk tanggal yang diberikan.
  int countTodayFor(DateTime today) => countOn(DailyProgress.dateKey(today));

  bool get isProgressComplete =>
      kind == TaskKind.progress && targetTotal > 0 && totalCount >= targetTotal;

  double get progressFraction {
    if (kind != TaskKind.progress || targetTotal <= 0) return 0;
    final fraction = totalCount / targetTotal;
    return fraction.clamp(0.0, 1.0).toDouble();
  }

  Task copyWith({
    String? id,
    String? categoryId,
    String? name,
    TaskKind? kind,
    bool? isActive,
    int? sortOrder,
    int? targetDaily,
    int? targetTotal,
    int? totalCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, DailyProgress>? history,
  }) {
    return Task(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      targetDaily: targetDaily ?? this.targetDaily,
      targetTotal: targetTotal ?? this.targetTotal,
      totalCount: totalCount ?? this.totalCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      history: history ?? this.history,
    );
  }
}

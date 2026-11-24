import '../data/models/daily_model.dart';

class ChecklistCalculationHelper {
  /// Menghitung total leaf items (tanpa anak) dari list [SubSubjectItem].
  /// Item nonaktif (`isDisabled`) dan parent-nya diabaikan.
  static double countTotalItems(List<SubSubjectItem> items) {
    double count = 0.0;
    for (final item in items) {
      if (item.isDisabled) continue;

      if (item.subMateri.isNotEmpty) {
        count += countTotalItems(item.subMateri);
      } else {
        count += 1.0;
      }
    }
    return count;
  }

  /// Menghitung total leaf items yang selesai dari list [SubSubjectItem].
  /// Item nonaktif (`isDisabled`) dan parent-nya diabaikan.
  /// Mendukung perhitungan proporsional untuk tipe `progress` dan `countdown`.
  static double countFinishedItems(List<SubSubjectItem> items) {
    double count = 0.0;
    for (final item in items) {
      if (item.isDisabled) continue;

      if (item.subMateri.isNotEmpty) {
        count += countFinishedItems(item.subMateri);
      } else {
        if (item.itemType == 'progress' && item.targetValue > 0) {
          final double progressRatio = item.currentValue / item.targetValue;
          count += progressRatio.clamp(0.0, 1.0);
        } else if (item.itemType == 'countdown' && item.targetValue > 0) {
          final double progressRatio =
              (item.targetValue - item.currentValue) / item.targetValue;
          count += progressRatio.clamp(0.0, 1.0);
        } else {
          if (item.progress == 'selesai') {
            count += 1.0;
          }
        }
      }
    }
    return count;
  }

  /// Menghitung total leaf entries dari snapshot [DailyLogEntry].
  /// Entry nonaktif (`isDisabled`) dan parent-nya diabaikan.
  static double countTotalFromLog(List<DailyLogEntry> entries) {
    double count = 0.0;
    for (final entry in entries) {
      if (entry.isDisabled) continue;

      if (entry.children.isNotEmpty) {
        count += countTotalFromLog(entry.children);
      } else {
        count += 1.0;
      }
    }
    return count;
  }

  /// Menghitung total leaf entries yang selesai dari snapshot [DailyLogEntry].
  /// Entry nonaktif (`isDisabled`) dan parent-nya diabaikan.
  /// Mendukung perhitungan proporsional untuk tipe `progress` dan `countdown`.
  static double countFinishedFromLog(List<DailyLogEntry> entries) {
    double count = 0.0;
    for (final entry in entries) {
      if (entry.isDisabled) continue;

      if (entry.children.isNotEmpty) {
        count += countFinishedFromLog(entry.children);
      } else {
        if (entry.itemType == 'progress' && entry.targetValue > 0) {
          final double progressRatio = entry.currentValue / entry.targetValue;
          count += progressRatio.clamp(0.0, 1.0);
        } else if (entry.itemType == 'countdown' && entry.targetValue > 0) {
          final double progressRatio =
              (entry.targetValue - entry.currentValue) / entry.targetValue;
          count += progressRatio.clamp(0.0, 1.0);
        } else {
          if (entry.progress == 'selesai') {
            count += 1.0;
          }
        }
      }
    }
    return count;
  }
}

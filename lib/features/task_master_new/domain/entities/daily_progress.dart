/// Satu entri riwayat harian yang disimpan secara sparse.
class DailyProgress {
  const DailyProgress({
    required this.date,
    required this.count,
    required this.updatedAt,
  });

  /// Tanggal lokal dengan format `YYYY-MM-DD`.
  final String date;
  final int count;
  final DateTime updatedAt;

  DailyProgress copyWith({String? date, int? count, DateTime? updatedAt}) {
    return DailyProgress(
      date: date ?? this.date,
      count: count ?? this.count,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Mengubah [date] menjadi kunci tanggal lokal `YYYY-MM-DD`.
  static String dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  @override
  bool operator ==(Object other) {
    return other is DailyProgress &&
        other.date == date &&
        other.count == count &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(date, count, updatedAt);
}

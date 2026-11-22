import 'package:flutter/foundation.dart';

/// Pengaturan visibilitas tugas di daftar "Hari Ini".
enum TodayVisibility {
  /// Mengikuti aturan default (target harian, progress ber-target, atau ada hitungan hari ini).
  auto('auto'),

  /// Selalu tampil di daftar Hari Ini selama tugas aktif dan kategori tidak tersembunyi.
  always('always'),

  /// Tidak pernah tampil di daftar Hari Ini.
  never('never');

  const TodayVisibility(this.jsonValue);

  /// Nilai string yang disimpan pada skema JSON v2.
  final String jsonValue;

  /// Mem-parsing nilai visibilitas dari JSON atau string.
  ///
  /// Mengembalikan [TodayVisibility.auto] untuk nilai `null`, tidak dikenal,
  /// atau rusak, dan mencatat peringatan debug.
  static TodayVisibility parse(Object? value) {
    if (value == null) return TodayVisibility.auto;
    final normalized = value.toString().trim().toLowerCase();
    for (final visibility in TodayVisibility.values) {
      if (visibility.jsonValue == normalized) {
        return visibility;
      }
    }
    debugPrint('TodayVisibility tidak dikenal: "$value". Fallback ke auto.');
    return TodayVisibility.auto;
  }
}

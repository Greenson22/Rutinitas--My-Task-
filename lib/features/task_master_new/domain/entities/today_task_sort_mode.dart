/// Pilihan mode pengurutan tugas di bagian Hari Ini.
enum TodayTaskSortMode {
  defaultOrder,
  nameAsc,
  nameDesc,
  incompleteFirst,
  completedFirst,
  categoryAsc,
  custom,
}

/// Mengurai nama mode pengurutan dari JSON/string secara terpusat.
///
/// Nilai kosong atau tidak dikenal jatuh ke [TodayTaskSortMode.defaultOrder].
TodayTaskSortMode parseTodayTaskSortMode(String? raw) {
  if (raw == null || raw.isEmpty) return TodayTaskSortMode.defaultOrder;
  for (final mode in TodayTaskSortMode.values) {
    if (mode.name == raw) return mode;
  }
  return TodayTaskSortMode.defaultOrder;
}

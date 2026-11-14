/// Jenis tugas yang didukung Task Master New.
enum TaskKind {
  habit('habit'),
  counter('counter'),
  progress('progress');

  const TaskKind(this.jsonValue);

  /// Nilai yang dipakai pada skema v2.
  final String jsonValue;

  /// Membaca kind dari JSON. Nilai lama `type` ditangani oleh mapper.
  static TaskKind? tryParse(Object? value) {
    if (value is! String) return null;
    final normalized = value.trim().toLowerCase();
    for (final kind in TaskKind.values) {
      if (kind.jsonValue == normalized) return kind;
    }
    return null;
  }
}

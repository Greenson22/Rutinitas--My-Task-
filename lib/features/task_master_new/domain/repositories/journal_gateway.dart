/// Durasi fallback saat pengaturan template Jurnal tidak tersedia atau tidak
/// valid.
const int defaultJournalIncrementMinutes = 30;

/// Relasi tugas Task Master dengan aktivitas Jurnal.
///
/// Relasi dimiliki oleh Jurnal melalui `linkedTaskIds`; Task Master hanya
/// menyimpan hasil pembacaan sementara untuk indikator dan increment.
class JournalLinkState {
  const JournalLinkState({
    this.linkedTaskIds = const {},
    this.incrementMinutes = defaultJournalIncrementMinutes,
  });

  static const empty = JournalLinkState();

  final Set<String> linkedTaskIds;

  /// Durasi yang ditambahkan ke Jurnal untuk setiap increment.
  final int incrementMinutes;

  bool isLinked(String taskId) => linkedTaskIds.contains(taskId);
}

/// Perubahan durasi yang benar-benar diterapkan ke satu aktivitas Jurnal.
class JournalAdjustment {
  const JournalAdjustment({required this.journalTaskId, required this.minutes});

  final String journalTaskId;
  final int minutes;

  @override
  String toString() =>
      'JournalAdjustment(journalTaskId: $journalTaskId, minutes: $minutes)';
}

/// Kegagalan integrasi Jurnal yang aman ditampilkan kepada pengguna.
class JournalGatewayException implements Exception {
  JournalGatewayException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

/// Seam integrasi Jurnal untuk increment dan undo Task Master.
///
/// Controller tidak membaca atau menulis file Jurnal secara langsung. Semua
/// akses ke Jurnal melewati kontrak ini sehingga file terenkripsi, atomic
/// write, dan kegagalan rollback dapat diuji secara terpisah.
abstract interface class JournalGateway {
  /// Membaca relasi tugas dan durasi increment yang berlaku.
  Future<JournalLinkState> loadLinks();

  /// Menambah durasi aktivitas Jurnal yang tertaut ke [taskId].
  ///
  /// Mengembalikan `null` bila [taskId] tidak tertaut ke aktivitas Jurnal mana
  /// pun. Melempar [JournalGatewayException] bila file tidak dapat dibaca atau
  /// ditulis.
  Future<JournalAdjustment?> addDuration({
    required String taskId,
    required DateTime at,
  });

  /// Mengurangi durasi yang sebelumnya ditambahkan oleh [adjustment].
  Future<void> subtractDuration({
    required JournalAdjustment adjustment,
    required DateTime at,
  });
}

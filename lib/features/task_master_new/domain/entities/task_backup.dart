/// Backup file Task Master yang tersedia untuk pemulihan.
///
/// [path] adalah referensi buram yang hanya dipakai repository untuk membuka
/// berkas backup. Presentasi cukup menampilkan waktu pembuatan.
class TaskBackup {
  const TaskBackup({required this.path, required this.createdAt});

  final String path;
  final DateTime createdAt;
}

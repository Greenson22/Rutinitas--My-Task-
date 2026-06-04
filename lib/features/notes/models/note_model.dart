class NoteModel {
  final String id;
  final String title;
  final String content;
  final String category;
  final DateTime createdAt; // Tanggal Dibuat
  final DateTime updatedAt; // Tanggal Diperbarui

  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
  });
}

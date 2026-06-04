class NoteGroup {
  String id;
  String groupName;
  String icon;
  List<NoteModel> notes;

  NoteGroup({
    required this.id,
    required this.groupName,
    required this.icon,
    required this.notes,
  });
}

class NoteModel {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });
}

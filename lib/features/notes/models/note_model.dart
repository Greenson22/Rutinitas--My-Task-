// lib/features/notes/models/note_model.dart

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

  Map<String, dynamic> toJson() => {
    'id': id,
    'groupName': groupName,
    'icon': icon,
    'notes': notes.map((note) => note.toJson()).toList(),
  };

  factory NoteGroup.fromJson(Map<String, dynamic> json) => NoteGroup(
    id: json['id'],
    groupName: json['groupName'],
    icon: json['icon'] ?? '📁',
    notes: (json['notes'] as List)
        .map((noteJson) => NoteModel.fromJson(noteJson))
        .toList(),
  );
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory NoteModel.fromJson(Map<String, dynamic> json) => NoteModel(
    id: json['id'],
    title: json['title'],
    content: json['content'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );
}

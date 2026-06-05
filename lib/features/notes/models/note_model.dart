// lib/features/notes/models/note_model.dart

class NoteGroup {
  String id;
  String groupName;
  String icon;
  List<NoteModel> notes;
  final String type; // 'text' atau 'field'
  final Map<String, String> fields;

  NoteGroup({
    required this.id,
    required this.groupName,
    required this.icon,
    required this.notes,
    this.type = 'text',
    this.fields = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'groupName': groupName,
    'icon': icon,
    'notes': notes.map((note) => note.toJson()).toList(),
    'type': type,
    'fields': fields,
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
  final String type; // 'text' atau 'field'
  final Map<String, String> fields; // Penyimpan key-value dinamis

  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.type = 'text',
    this.fields = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'type': type,
    'fields': fields,
  };

  factory NoteModel.fromJson(Map<String, dynamic> json) => NoteModel(
    id: json['id'],
    title: json['title'],
    content: json['content'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
    type: json['type'] ?? 'text',
    fields: Map<String, String>.from(json['fields'] ?? {}),
  );
}

// lib/features/notes/models/note_model.dart

class NoteGroup {
  String id;
  String groupName;
  String icon;
  List<NoteModel> notes;
  final String type; // 'text' atau 'field'
  final Map<String, String> fields;
  String sectionName; // BARU: Menyimpan informasi seksi tempat grup ini berada

  NoteGroup({
    required this.id,
    required this.groupName,
    required this.icon,
    required this.notes,
    this.type = 'text',
    this.fields = const {},
    this.sectionName = 'Catatan Utama', // BARU: Default seksi awal
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'groupName': groupName,
    'icon': icon,
    'notes': notes.map((note) => note.toJson()).toList(),
    'type': type,
    'fields': fields,
    'sectionName': sectionName, // BARU
  };

  factory NoteGroup.fromJson(Map<String, dynamic> json) => NoteGroup(
    id: json['id'],
    groupName: json['groupName'],
    icon: json['icon'] ?? '📁',
    notes: (json['notes'] as List)
        .map((noteJson) => NoteModel.fromJson(noteJson))
        .toList(),
    // BARU: Jika data lama belum punya seksi, otomatis arahkan ke 'Catatan Utama'
    sectionName: json['sectionName'] ?? 'Catatan Utama',
  );
}

class NoteModel {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String type; // 'text' atau 'table'
  final List<String> fieldKeys; // Menyimpan struktur kolom
  final Map<String, String> fieldTypes; // BARU: Menyimpan tipe data per kolom
  final List<Map<String, String>> tableData; // Menyimpan baris-baris data

  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.type = 'text',
    this.fieldKeys = const [],
    this.fieldTypes = const {}, // BARU
    this.tableData = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'type': type,
    'fieldKeys': fieldKeys,
    'fieldTypes': fieldTypes, // BARU
    'tableData': tableData,
  };

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedKeys = [];
    if (json['fieldKeys'] != null) {
      parsedKeys = List<String>.from(json['fieldKeys']);
    }

    Map<String, String> parsedTypes = {};
    if (json['fieldTypes'] != null) {
      parsedTypes = Map<String, String>.from(json['fieldTypes']);
    }

    List<Map<String, String>> parsedData = [];
    if (json['tableData'] != null) {
      var list = json['tableData'] as List;
      parsedData = list.map((e) => Map<String, String>.from(e)).toList();
    }

    return NoteModel(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      type: json['type'] ?? 'text',
      fieldKeys: parsedKeys,
      fieldTypes: parsedTypes, // BARU
      tableData: parsedData,
    );
  }
}

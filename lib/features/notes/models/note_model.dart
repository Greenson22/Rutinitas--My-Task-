// lib/features/notes/models/note_model.dart

class NoteGroup {
  String id;
  String groupName;
  String icon;
  List<NoteModel> notes;
  final String type; // 'text' atau 'field'
  final Map<String, String> fields;
  String sectionName; // Menyimpan informasi seksi tempat grup ini berada
  bool isHidden;
  int orderIndex; // <--- BARU: Menyimpan urutan posisi group note

  NoteGroup({
    required this.id,
    required this.groupName,
    required this.icon,
    required this.notes,
    this.type = 'text',
    this.fields = const {},
    this.sectionName = 'Catatan Utama', // Default seksi awal
    this.isHidden = false,
    this.orderIndex = 0, // <--- BARU: Default value urutan
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'groupName': groupName,
    'icon': icon,
    'notes': notes.map((note) => note.toJson()).toList(),
    'type': type,
    'fields': fields,
    'sectionName': sectionName,
    'isHidden': isHidden,
    'order_index': orderIndex, // <--- BARU: Menyimpan ke JSON storage
  };

  factory NoteGroup.fromJson(Map<String, dynamic> json) => NoteGroup(
    id: json['id'],
    groupName: json['groupName'],
    icon: json['icon'] ?? '📁',
    notes: (json['notes'] as List)
        .map((noteJson) => NoteModel.fromJson(noteJson))
        .toList(),
    // Jika data lama belum punya seksi, otomatis arahkan ke 'Catatan Utama'
    sectionName: json['sectionName'] ?? 'Catatan Utama',
    isHidden: json['isHidden'] ?? false,
    orderIndex:
        json['order_index'] ??
        0, // <--- BARU: Mengambil dari JSON storage (jika kosong, default 0)
  );
}

class NoteModel {
  String id;
  String title;
  String content;
  DateTime createdAt;
  DateTime updatedAt;
  final String type;
  final List<String> fieldKeys;
  final Map<String, String> fieldTypes; // BARU
  final List<Map<String, String>> tableData;

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
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      type: json['type'] ?? 'text',
      fieldKeys: parsedKeys,
      fieldTypes: parsedTypes,
      tableData: parsedData,
    );
  }
}

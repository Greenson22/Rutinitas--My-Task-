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
  int orderIndex; // Menyimpan urutan posisi group note

  NoteGroup({
    required this.id,
    required this.groupName,
    required this.icon,
    required this.notes,
    this.type = 'text',
    this.fields = const {},
    this.sectionName = 'Catatan Utama', // Default seksi awal
    this.isHidden = false,
    this.orderIndex = 0, // Default value urutan
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
    'order_index': orderIndex,
  };

  factory NoteGroup.fromJson(Map<String, dynamic> json) => NoteGroup(
    id: json['id'],
    groupName: json['groupName'],
    icon: json['icon'] ?? '',
    notes: (json['notes'] as List)
        .map((e) => NoteModel.fromJson(e as Map<String, dynamic>))
        .toList(),
    type: json['type'] ?? 'text',
    fields: Map<String, String>.from(json['fields'] ?? {}),
    sectionName: json['sectionName'] ?? 'Catatan Utama',
    isHidden: json['isHidden'] ?? false,
    orderIndex: json['order_index'] ?? 0,
  );
}

class NoteModel {
  String id;
  String title;
  String content;
  String backContent; // Properti untuk menampung data catatan dibaliknya
  DateTime createdAt;
  DateTime updatedAt;
  final String type;
  final List<String> fieldKeys;
  final Map<String, String> fieldTypes;
  final List<Map<String, String>> tableData;
  bool isMarkdownEnabled; // Menyimpan state apakah tampilan markdown aktif

  // === PROPERTI BARU: DUKUNGAN MULTI-HALAMAN CATATAN ===
  List<String>? notePages;
  int? currentNotePage;

  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    this.backContent = '', // Default berupa string kosong jika tidak diisi
    required this.createdAt,
    required this.updatedAt,
    this.type = 'text',
    this.fieldKeys = const [],
    this.fieldTypes = const {},
    this.tableData = const [],
    this.isMarkdownEnabled = false, // Default awal diset off (false)
    this.notePages,
    this.currentNotePage,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'backContent': backContent, // Simpan data sisi belakang ke JSON storage
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'type': type,
    'fieldKeys': fieldKeys,
    'fieldTypes': fieldTypes,
    'tableData': tableData,
    'isMarkdownEnabled': isMarkdownEnabled, // Simpan ke JSON storage
    'notePages': notePages, // Simpan halaman ke JSON
    'currentNotePage': currentNotePage, // Simpan indeks halaman aktif
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
      backContent:
          json['backContent'] ?? '', // Parsing data sisi belakang dari JSON
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      type: json['type'] ?? 'text',
      fieldKeys: parsedKeys,
      fieldTypes: parsedTypes,
      tableData: parsedData,
      isMarkdownEnabled: json['isMarkdownEnabled'] ?? false,
      notePages: json['notePages'] != null
          ? List<String>.from(json['notePages'])
          : null,
      currentNotePage: json['currentNotePage'] ?? 0,
    );
  }
}

// lib/features/daily/data/models/daily_model.dart

class DailyData {
  String topics;
  List<DailySubject> subjects;

  DailyData({required this.topics, required this.subjects});

  factory DailyData.fromJson(Map<String, dynamic> json) {
    var subList = json['subjects'] as List? ?? [];
    List<DailySubject> parsedSubjects = subList
        .map((i) => DailySubject.fromJson(i))
        .toList();
    return DailyData(
      topics: json['topics'] ?? 'Rutinitas',
      subjects: parsedSubjects,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topics': topics,
      'subjects': subjects.map((e) => e.toJson()).toList(),
    };
  }
}

class DailySubject {
  String namaMateri;
  String progress;
  List<SubMateriItem> subMateri;
  int backgroundColor;
  int textColor;
  int progressBarColor;
  String icon;
  bool isHidden;
  String section;
  String type;
  String? noteContent;

  DailySubject({
    required this.namaMateri,
    required this.progress,
    required this.subMateri,
    this.backgroundColor = 4281166415,
    this.textColor = 4294967295,
    this.progressBarColor = 4288009650,
    this.icon = "📚",
    this.isHidden = false,
    this.section = "focus",
    this.type = "list",
    this.noteContent,
  });

  factory DailySubject.fromJson(Map<String, dynamic> json) {
    var subMatList = json['sub_materi'] as List? ?? [];
    List<SubMateriItem> parsedList = subMatList
        .map((i) => SubMateriItem.fromJson(i))
        .toList();

    return DailySubject(
      namaMateri: json['nama_materi'] ?? '',
      progress: json['progress'] ?? 'belum',
      subMateri: parsedList,
      backgroundColor: json['backgroundColor'] ?? 4281166415,
      textColor: json['textColor'] ?? 4294967295,
      progressBarColor: json['progressBarColor'] ?? 4288009650,
      icon: json['icon'] ?? "📚",
      isHidden: json['isHidden'] ?? false,
      section: json['section'] ?? "focus",
      type: json['type'] ?? "list",
      noteContent: json['noteContent'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama_materi': namaMateri,
      'progress': progress,
      'sub_materi': subMateri.map((e) => e.toJson()).toList(),
      'backgroundColor': backgroundColor,
      'textColor': textColor,
      'progressBarColor': progressBarColor,
      'icon': icon,
      'isHidden': isHidden,
      'section': section,
      'type': type,
      'noteContent': noteContent,
    };
  }
}

class SubMateriItem {
  String namaMateri;
  String progress; // "belum" atau "selesai"
  String? finishedDate;

  SubMateriItem({
    required this.namaMateri,
    required this.progress,
    this.finishedDate,
  });

  factory SubMateriItem.fromJson(Map<String, dynamic> json) {
    return SubMateriItem(
      namaMateri: json['nama_materi'] ?? '',
      progress: json['progress'] ?? 'belum',
      finishedDate: json['finishedDate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama_materi': namaMateri,
      'progress': progress,
      'finishedDate': finishedDate,
    };
  }
}

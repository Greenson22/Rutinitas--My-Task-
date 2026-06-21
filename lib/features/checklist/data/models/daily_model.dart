// lib/features/daily/data/models/daily_model.dart

import 'package:flutter/material.dart';

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
  String subjectName;
  String progress;
  List<SubSubjectItem> subMateri;
  int backgroundColor;
  int textColor;
  int progressBarColor;
  String icon;
  bool isHidden;
  String section;
  String type;
  String? noteContent;
  String? date;
  bool isDateActive;
  String dateType;
  String? endDate;
  bool
  isMarkdownEnabled; // <--- BARU: Menyimpan status aktif/nonaktif format MD Catatan

  // === TAMBAHAN BARU: Menyimpan konfigurasi default apakah anak list langsung terbuka atau tertutup ===
  bool defaultExpanded;

  // Palet warna standar yang estetis untuk memudahkan pengguna memilih warna kustom
  static const List<Map<String, dynamic>> customPalletColor = [
    {'nama': 'Teal', 'bg': 4281166415, 'text': 4294967295},
    {'nama': 'Indigo', 'bg': 4282340786, 'text': 4294967295},
    {'nama': 'Merah Ruby', 'bg': 4290001456, 'text': 4294967295},
    {'nama': 'Hijau Emerald', 'bg': 4281102431, 'text': 4294967295},
    {'nama': 'Amber', 'bg': 4294943744, 'text': 4278190080},
    {'nama': 'Oranye', 'bg': 4294937600, 'text': 4294967295},
    {'nama': 'Ungu Amethyst', 'bg': 4287831474, 'text': 4294967295},
    {'nama': 'Biru Slate', 'bg': 4284511612, 'text': 4294967295},
    {'nama': 'Kopi', 'bg': 4286734131, 'text': 4294967295},
    {'nama': 'Rose Pink', 'bg': 4293144195, 'text': 4294967295},
    // --- TAMBAHAN PALET WARNA BARU ---
    {'nama': 'Mint Pastel', 'bg': 0xFFE8F8F5, 'text': 0xFF117A65},
    {'nama': 'Lavender', 'bg': 0xFFEBDEF0, 'text': 0xFF6C3483},
    {'nama': 'Sky Blue', 'bg': 0xFFEBF5FB, 'text': 0xFF2E86C1},
    {'nama': 'Desert Sand', 'bg': 0xFFFDF2E9, 'text': 0xFFA04000},
    {'nama': 'Sakura', 'bg': 0xFFFCE4EC, 'text': 0xFFC2185B},
    {'nama': 'Charcoal', 'bg': 0xFF2C3E50, 'text': 0xFFFFFFFF},
    {'nama': 'Mustard', 'bg': 0xFFFEF9E7, 'text': 0xFFB7950B},
    {'nama': 'Olive Green', 'bg': 0xFF1E8449, 'text': 0xFFFFFFFF},
    {'nama': 'Deep Purple', 'bg': 0xFF4A235A, 'text': 0xFFFFFFFF},
    {'nama': 'Coral Red', 'bg': 0xFFE74C3C, 'text': 0xFFFFFFFF},
    {'nama': 'Ocean Cyan', 'bg': 0xFF117A65, 'text': 0xFFFFFFFF},
    {'nama': 'Midnight Blue', 'bg': 0xFF1B4F72, 'text': 0xFFFFFFFF},
    {'nama': 'Terracotta', 'bg': 0xFF6E2C00, 'text': 0xFFFFFFFF},
    {'nama': 'Creamy Lime', 'bg': 0xFFF4F6F7, 'text': 0xFF1E8449},
    {'nama': 'Soft Peach', 'bg': 0xFFFBEEE6, 'text': 0xFFBA4A00},
  ];

  DailySubject({
    required this.subjectName,
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
    this.date,
    this.isDateActive = false,
    this.dateType = 'single',
    this.endDate,
    this.isMarkdownEnabled = false,
    this.defaultExpanded = false, // <--- Default awal diatur tertutup (false)
  });

  factory DailySubject.fromJson(Map<String, dynamic> json) {
    var subMatList = json['sub_materi'] as List? ?? [];
    List<SubSubjectItem> parsedList = subMatList
        .map((i) => SubSubjectItem.fromJson(i))
        .toList();

    return DailySubject(
      subjectName: json['nama_materi'] ?? '',
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
      date: json['date'],
      isDateActive: json['isDateActive'] ?? false,
      dateType: json['dateType'] ?? 'single',
      endDate: json['endDate'],
      isMarkdownEnabled: json['isMarkdownEnabled'] ?? false,
      defaultExpanded:
          json['defaultExpanded'] ?? false, // <--- Amankan parsing dari JSON
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama_materi': subjectName,
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
      'date': date,
      'isDateActive': isDateActive,
      'dateType': dateType,
      'endDate': endDate,
      'isMarkdownEnabled': isMarkdownEnabled,
      'defaultExpanded': defaultExpanded, // <--- Amankan penyimpanan ke JSON
    };
  }

  static List<TextSpan> buildColoredDateSpans(
    DailySubject subject, {
    bool inHeader = false,
  }) {
    if (subject.date == null || subject.date!.trim().isEmpty) return [];
    const List<String> dayName = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const List<String> monthName = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    Color? colorHari;
    Color? colorTgl;
    Color? colorBln;

    if (inHeader) {
      colorHari = Colors.purple[900];
      colorTgl = Colors.pink[800];
      colorBln = Colors.teal[900];
    } else {
      colorHari = Colors.purple[700];
      colorTgl = Colors.pink[700];
      colorBln = Colors.teal[700];
    }

    try {
      final DateTime parsedStart = DateTime.parse(subject.date!);
      if (subject.dateType == 'range' &&
          subject.endDate != null &&
          subject.endDate!.isNotEmpty) {
        final DateTime parsedEnd = DateTime.parse(subject.endDate!);
        return [
          TextSpan(
            text: '${parsedStart.day} - ${parsedEnd.day} ',
            style: TextStyle(color: colorTgl, fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: monthName[parsedEnd.month - 1],
            style: TextStyle(color: colorBln, fontWeight: FontWeight.bold),
          ),
        ];
      }
      return [
        TextSpan(
          text: '(${dayName[parsedStart.weekday - 1]}) ',
          style: TextStyle(color: colorHari, fontWeight: FontWeight.bold),
        ),
        TextSpan(
          text: '${parsedStart.day} ',
          style: TextStyle(color: colorTgl, fontWeight: FontWeight.bold),
        ),
        TextSpan(
          text: monthName[parsedStart.month - 1],
          style: TextStyle(color: colorBln, fontWeight: FontWeight.bold),
        ),
      ];
    } catch (_) {
      return [
        TextSpan(
          text: subject.date,
          style: TextStyle(color: Color(subject.textColor)),
        ),
      ];
    }
  }
}

class SubSubjectItem {
  String subjectName;
  String progress;
  String? finishedDate;
  List<SubSubjectItem> subMateri;

  String itemType; // 'normal' atau 'progress'
  int currentValue;
  int targetValue;
  bool isDisabled;
  String? linkedSubjectName;
  String? accumulatorItemName;

  // =========================================================================
  // PROPERTI BARU: Menyimpan kaitan akumulasi nilai harian lintas Card Checklist
  // =========================================================================
  String? linkedExternalCardName; // Menyimpan nama Card Checklist target
  String?
  linkedExternalItemName; // Menyimpan nama Item List bernilai progres di Card target

  // === TAMBAHAN BARU: Melacak status expand/collapse UI item list secara runtime harian ===
  bool isExpanded;

  SubSubjectItem({
    required this.subjectName,
    required this.progress,
    this.finishedDate,
    List<SubSubjectItem>? subMateri,
    this.itemType = 'normal',
    this.currentValue = 0,
    this.targetValue = 0,
    this.isDisabled = false,
    this.linkedSubjectName,
    this.accumulatorItemName,
    this.linkedExternalCardName,
    this.linkedExternalItemName,
    this.isExpanded = false, // <--- Default runtime awal false
  }) : this.subMateri = subMateri ?? [];

  SubSubjectItem clone() {
    return SubSubjectItem(
      subjectName: this.subjectName,
      progress: this.progress,
      finishedDate: this.finishedDate,
      subMateri: this.subMateri.map((child) => child.clone()).toList(),
      itemType: this.itemType,
      currentValue: this.currentValue,
      targetValue: this.targetValue,
      isDisabled: this.isDisabled,
      linkedSubjectName: this.linkedSubjectName,
      accumulatorItemName: this.accumulatorItemName,
      linkedExternalCardName: this.linkedExternalCardName,
      linkedExternalItemName: this.linkedExternalItemName,
      isExpanded: this
          .isExpanded, // <--- Salin state expand saat kloning histori undo/redo
    );
  }

  factory SubSubjectItem.fromJson(Map<String, dynamic> json) {
    var subList = json['sub_materi'] as List? ?? [];
    List<SubSubjectItem> parsedSub = subList
        .map((i) => SubSubjectItem.fromJson(i))
        .toList();

    return SubSubjectItem(
      subjectName: json['nama_materi'] ?? '',
      progress: json['progress'] ?? 'belum',
      finishedDate: json['finishedDate'],
      subMateri: parsedSub,
      itemType: json['itemType'] ?? 'normal',
      currentValue: json['currentValue'] ?? 0,
      targetValue: json['targetValue'] ?? 0,
      isDisabled: json['isDisabled'] ?? false,
      linkedSubjectName: json['linkedSubjectName'],
      accumulatorItemName: json['accumulatorItemName'],
      linkedExternalCardName: json['linkedExternalCardName'],
      linkedExternalItemName: json['linkedExternalItemName'],
      isExpanded: false, // <--- Selalu mulai dari false saat memuat file mentah
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama_materi': subjectName,
      'progress': progress,
      'finishedDate': finishedDate,
      'sub_materi': subMateri.map((e) => e.toJson()).toList(),
      'itemType': itemType,
      'currentValue': currentValue,
      'targetValue': targetValue,
      'isDisabled': isDisabled,
      'linkedSubjectName': linkedSubjectName,
      'accumulatorItemName': accumulatorItemName,
      'linkedExternalCardName': linkedExternalCardName,
      'linkedExternalItemName': linkedExternalItemName,
      // Properti `isExpanded` sengaja tidak ditulis ke berkas JSON
      // karena status buka-tutup ini hanya digunakan sebagai UI state dinamis sementara.
    };
  }

  void updateStatusFromChildren() {
    if (isDisabled) return;

    if (subMateri.isEmpty) {
      if (itemType == 'progress' && targetValue > 0) {
        progress = currentValue >= targetValue ? 'selesai' : 'belum';
      }
      return;
    }

    for (var child in subMateri) {
      child.updateStatusFromChildren();
    }

    final activeChildren = subMateri.where((sm) => !sm.isDisabled).toList();
    if (activeChildren.isEmpty) return;

    int total = activeChildren.length;
    int finish = activeChildren.where((sm) => sm.progress == 'selesai').length;

    if (finish == total) {
      progress = 'selesai';
    } else if (finish > 0) {
      progress = 'sementara';
    } else {
      progress = 'belum';
    }
  }
}

class ChecklistGroup {
  String id;
  String groupName;
  String icon;
  String sectionCategory;
  List<ChecklistSection> allList;
  bool isHidden;

  ChecklistGroup({
    required this.id,
    required this.groupName,
    required this.icon,
    this.sectionCategory = "Lainnya",
    this.isHidden = false,
    required this.allList,
  });

  void updateSectionCategory(String newSection) {
    sectionCategory = newSection;
  }

  factory ChecklistGroup.fromJson(Map<String, dynamic> json) {
    var list = json['semua_list'] as List? ?? [];
    return ChecklistGroup(
      id: json['id'] ?? '',
      groupName: json['nama_hub'] ?? 'Hub Baru',
      icon: json['ikon'] ?? '📁',
      sectionCategory: json['kategori_seksi'] ?? 'Lainnya',
      isHidden: json['isHidden'] ?? false,
      allList: list.map((i) => ChecklistSection.fromJson(i)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_hub': groupName,
      'ikon': icon,
      'kategori_seksi': sectionCategory,
      'isHidden': isHidden,
      'semua_list': allList.map((e) => e.toJson()).toList(),
    };
  }
}

class ChecklistSection {
  String sectionName;
  List<DailySubject> items;

  ChecklistSection({required this.sectionName, required this.items});

  factory ChecklistSection.fromJson(Map<String, dynamic> json) {
    var list = json['items'] as List? ?? [];
    return ChecklistSection(
      sectionName: json['nama_seksi'] ?? 'Seksi Baru',
      items: list.map((i) => DailySubject.fromJson(i)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama_seksi': sectionName,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

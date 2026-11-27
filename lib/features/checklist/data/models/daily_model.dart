// lib/features/daily/data/models/daily_model.dart
import 'package:flutter/material.dart';

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

  // === PROPERTI BARU UNTUK DUKUNGAN MULTI-HALAMAN CATATAN ===
  List<String>? notePages; // Menampung kumpulan daftar halaman catatan teks
  int? currentNotePage; // Melacak indeks halaman aktif/terakhir yang dibuka

  String? date;
  bool isDateActive;
  String dateType;
  String? endDate;
  bool isMarkdownEnabled; // Menyimpan status aktif/nonaktif format MD Catatan

  // Menyimpan konfigurasi default apakah anak list langsung terbuka atau tertutup
  bool defaultExpanded;

  // Mode DailyTracker
  bool isDailyTrackerEnabled;
  Map<String, List<DailyLogEntry>> dailyLogs;

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
    this.icon = "📝",
    this.isHidden = false,
    this.section = "focus",
    this.type = "list",
    this.noteContent,
    this.notePages,
    this.currentNotePage,
    this.date,
    this.isDateActive = false,
    this.dateType = 'single',
    this.endDate,
    this.isMarkdownEnabled = false,
    this.defaultExpanded = false,
    this.isDailyTrackerEnabled = false,
    Map<String, List<DailyLogEntry>>? dailyLogs,
  }) : dailyLogs = dailyLogs ?? {};

  factory DailySubject.fromJson(Map<String, dynamic> json) {
    var subMatList = json['sub_materi'] as List? ?? [];
    List<SubSubjectItem> parsedList = subMatList
        .map((i) => SubSubjectItem.fromJson(i))
        .toList();

    Map<String, List<DailyLogEntry>> parsedDailyLogs = {};
    if (json['dailyLogs'] != null && json['dailyLogs'] is Map) {
      final rawLogs = json['dailyLogs'] as Map;
      rawLogs.forEach((key, value) {
        if (value is List) {
          parsedDailyLogs[key.toString()] = value
              .map((e) => DailyLogEntry.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      });
    }

    return DailySubject(
      subjectName: json['nama_materi'] ?? '',
      progress: json['progress'] ?? 'belum',
      subMateri: parsedList,
      backgroundColor: json['backgroundColor'] ?? 4281166415,
      textColor: json['textColor'] ?? 4294967295,
      progressBarColor: json['progressBarColor'] ?? 4288009650,
      icon: json['icon'] ?? "📝",
      isHidden: json['isHidden'] ?? false,
      section: json['section'] ?? "focus",
      type: json['type'] ?? "list",
      noteContent: json['noteContent'],

      // PARSING REKURENSI LIST HALAMAN DAN POSISI HALAMAN AKTIF
      notePages: json['notePages'] != null
          ? List<String>.from(json['notePages'])
          : null,
      currentNotePage: json['currentNotePage'] ?? 0,

      date: json['date'],
      isDateActive: json['isDateActive'] ?? false,
      dateType: json['dateType'] ?? 'single',
      endDate: json['endDate'],
      isMarkdownEnabled: json['isMarkdownEnabled'] ?? false,
      defaultExpanded: json['defaultExpanded'] ?? false,
      isDailyTrackerEnabled: json['isDailyTrackerEnabled'] ?? false,
      dailyLogs: parsedDailyLogs,
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

      // KONVERSI BALIK STRUKTUR DATA HALAMAN KE FORMAT JSON
      'notePages': notePages,
      'currentNotePage': currentNotePage,

      'date': date,
      'isDateActive': isDateActive,
      'dateType': dateType,
      'endDate': endDate,
      'isMarkdownEnabled': isMarkdownEnabled,
      'defaultExpanded': defaultExpanded,
      'isDailyTrackerEnabled': isDailyTrackerEnabled,
      'dailyLogs': dailyLogs.map(
        (key, list) => MapEntry(key, list.map((e) => e.toJson()).toList()),
      ),
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
  String id;
  String subjectName;
  String progress;
  String? finishedDate;
  List<SubSubjectItem> subMateri;
  String itemType; // 'normal', 'progress', atau 'countdown'
  int currentValue;
  int targetValue;
  bool isDisabled;

  String? linkedSubjectId;
  String? linkedSubjectName;
  String? accumulatorItemId;
  String? accumulatorItemName;

  // Menyimpan kaitan akumulasi nilai harian lintas Card Checklist
  String? linkedExternalCardName;
  String? linkedExternalItemId;
  String? linkedExternalItemName;

  // Tautan berkas My Documents
  String? linkedDocumentGroupId;
  String? linkedDocumentRelativePath;
  String? linkedDocumentName;

  bool get hasLinkedDocument =>
      linkedDocumentGroupId != null &&
      linkedDocumentGroupId!.isNotEmpty &&
      linkedDocumentRelativePath != null &&
      linkedDocumentRelativePath!.isNotEmpty;

  // Melacak status expand/collapse UI item list secara runtime harian
  bool isExpanded;

  static int _idCounter = 0;
  static String generateId() {
    final now = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final counter = (++_idCounter).toRadixString(36);
    return '$now-$counter';
  }

  SubSubjectItem({
    String? id,
    required this.subjectName,
    required this.progress,
    this.finishedDate,
    List<SubSubjectItem>? subMateri,
    this.itemType = 'normal',
    this.currentValue = 0,
    this.targetValue = 0,
    this.isDisabled = false,
    this.linkedSubjectId,
    this.linkedSubjectName,
    this.accumulatorItemId,
    this.accumulatorItemName,
    this.linkedExternalCardName,
    this.linkedExternalItemId,
    this.linkedExternalItemName,
    this.linkedDocumentGroupId,
    this.linkedDocumentRelativePath,
    this.linkedDocumentName,
    this.isExpanded = false,
  })  : id = id ?? generateId(),
        subMateri = subMateri ?? [];

  SubSubjectItem clone() {
    return SubSubjectItem(
      id: id,
      subjectName: subjectName,
      progress: progress,
      finishedDate: finishedDate,
      subMateri: subMateri.map((child) => child.clone()).toList(),
      itemType: itemType,
      currentValue: currentValue,
      targetValue: targetValue,
      isDisabled: isDisabled,
      linkedSubjectId: linkedSubjectId,
      linkedSubjectName: linkedSubjectName,
      accumulatorItemId: accumulatorItemId,
      accumulatorItemName: accumulatorItemName,
      linkedExternalCardName: linkedExternalCardName,
      linkedExternalItemId: linkedExternalItemId,
      linkedExternalItemName: linkedExternalItemName,
      linkedDocumentGroupId: linkedDocumentGroupId,
      linkedDocumentRelativePath: linkedDocumentRelativePath,
      linkedDocumentName: linkedDocumentName,
      isExpanded: isExpanded,
    );
  }

  factory SubSubjectItem.fromJson(Map<String, dynamic> json) {
    var subList = json['sub_materi'] as List? ?? [];
    List<SubSubjectItem> parsedSub = subList
        .map((i) => SubSubjectItem.fromJson(i))
        .toList();

    return SubSubjectItem(
      id: json['id'],
      subjectName: json['nama_materi'] ?? '',
      progress: json['progress'] ?? 'belum',
      finishedDate: json['finishedDate'],
      subMateri: parsedSub,
      itemType: json['itemType'] ?? 'normal',
      currentValue: json['currentValue'] ?? 0,
      targetValue: json['targetValue'] ?? 0,
      isDisabled: json['isDisabled'] ?? false,
      linkedSubjectId: json['linkedSubjectId'],
      linkedSubjectName: json['linkedSubjectName'],
      accumulatorItemId: json['accumulatorItemId'],
      accumulatorItemName: json['accumulatorItemName'],
      linkedExternalCardName: json['linkedExternalCardName'],
      linkedExternalItemId: json['linkedExternalItemId'],
      linkedExternalItemName: json['linkedExternalItemName'],
      linkedDocumentGroupId: json['linkedDocumentGroupId'],
      linkedDocumentRelativePath: json['linkedDocumentRelativePath'],
      linkedDocumentName: json['linkedDocumentName'],
      isExpanded: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_materi': subjectName,
      'progress': progress,
      'finishedDate': finishedDate,
      'sub_materi': subMateri.map((e) => e.toJson()).toList(),
      'itemType': itemType,
      'currentValue': currentValue,
      'targetValue': targetValue,
      'isDisabled': isDisabled,
      'linkedSubjectId': linkedSubjectId,
      'linkedSubjectName': linkedSubjectName,
      'accumulatorItemId': accumulatorItemId,
      'accumulatorItemName': accumulatorItemName,
      'linkedExternalCardName': linkedExternalCardName,
      'linkedExternalItemId': linkedExternalItemId,
      'linkedExternalItemName': linkedExternalItemName,
      'linkedDocumentGroupId': linkedDocumentGroupId,
      'linkedDocumentRelativePath': linkedDocumentRelativePath,
      'linkedDocumentName': linkedDocumentName,
    };
  }

  void updateStatusFromChildren() {
    if (isDisabled) return;

    if (subMateri.isEmpty) {
      if (itemType == 'progress' && targetValue > 0) {
        progress = currentValue >= targetValue ? 'selesai' : 'belum';
      } else if (itemType == 'countdown' && targetValue > 0) {
        progress = currentValue <= 0 ? 'selesai' : 'belum';
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

class DailyLogEntry {
  final String itemName;
  final String progress;
  final String itemType;
  final int currentValue;
  final int targetValue;
  final bool isDisabled;
  final List<DailyLogEntry> children;

  const DailyLogEntry({
    required this.itemName,
    required this.progress,
    required this.itemType,
    required this.currentValue,
    required this.targetValue,
    this.isDisabled = false,
    this.children = const [],
  });

  DailyLogEntry copyWith({
    String? itemName,
    String? progress,
    String? itemType,
    int? currentValue,
    int? targetValue,
    bool? isDisabled,
    List<DailyLogEntry>? children,
  }) {
    return DailyLogEntry(
      itemName: itemName ?? this.itemName,
      progress: progress ?? this.progress,
      itemType: itemType ?? this.itemType,
      currentValue: currentValue ?? this.currentValue,
      targetValue: targetValue ?? this.targetValue,
      isDisabled: isDisabled ?? this.isDisabled,
      children: children ?? this.children,
    );
  }

  factory DailyLogEntry.fromSubSubjectItem(SubSubjectItem item) {
    return DailyLogEntry(
      itemName: item.subjectName,
      progress: item.progress,
      itemType: item.itemType,
      currentValue: item.currentValue,
      targetValue: item.targetValue,
      isDisabled: item.isDisabled,
      children: item.subMateri
          .map((child) => DailyLogEntry.fromSubSubjectItem(child))
          .toList(),
    );
  }

  factory DailyLogEntry.fromJson(Map<String, dynamic> json) {
    var rawChildren = json['children'] as List? ?? [];
    List<DailyLogEntry> parsedChildren = rawChildren
        .map((e) => DailyLogEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return DailyLogEntry(
      itemName: json['itemName'] ?? '',
      progress: json['progress'] ?? 'belum',
      itemType: json['itemType'] ?? 'normal',
      currentValue: json['currentValue'] ?? 0,
      targetValue: json['targetValue'] ?? 0,
      isDisabled: json['isDisabled'] ?? false,
      children: parsedChildren,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemName': itemName,
      'progress': progress,
      'itemType': itemType,
      'currentValue': currentValue,
      'targetValue': targetValue,
      'isDisabled': isDisabled,
      'children': children.map((e) => e.toJson()).toList(),
    };
  }
}

class ChecklistGroup {
  String id;
  String groupName;
  String icon;
  String sectionCategory;
  List<ChecklistSection> allList;
  bool isHidden;
  bool isEncrypted;
  int orderIndex;

  ChecklistGroup({
    required this.id,
    required this.groupName,
    required this.icon,
    this.sectionCategory = "Lainnya",
    this.isHidden = false,
    this.isEncrypted = false,
    this.orderIndex = 0,
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
      isEncrypted: json['isEncrypted'] ?? false,
      orderIndex: json['order_index'] ?? 0,
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
      'isEncrypted': isEncrypted,
      'order_index': orderIndex,
      'semua_list': allList.map((e) => e.toJson()).toList(),
    };
  }
}

class ChecklistSection {
  String sectionName;
  List<DailySubject> items;
  bool isHidden;
  bool isCollapsed;

  ChecklistSection({
    required this.sectionName,
    required this.items,
    this.isHidden = false,
    this.isCollapsed = false,
  });

  factory ChecklistSection.fromJson(Map<String, dynamic> json) {
    var list = json['items'] as List? ?? [];
    return ChecklistSection(
      sectionName: json['nama_seksi'] ?? 'Seksi Baru',
      items: list.map((i) => DailySubject.fromJson(i)).toList(),
      isHidden: json['isHidden'] ?? false,
      isCollapsed: json['isCollapsed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama_seksi': sectionName,
      'items': items.map((e) => e.toJson()).toList(),
      'isHidden': isHidden,
      'isCollapsed': isCollapsed,
    };
  }
}

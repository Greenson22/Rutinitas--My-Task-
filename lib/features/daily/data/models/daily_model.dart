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
  String? date;
  bool isDateActive;
  String dateType;
  String? endDate;

  // Palet warna standar yang estetis untuk memudahkan pengguna memilih warna kustom
  // Palet warna standar yang estetis untuk memudahkan pengguna memilih warna kustom
  static const List<Map<String, dynamic>> kustomPaletWarna = [
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
    this.date,
    this.isDateActive = false,
    this.dateType = 'single',
    this.endDate,
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
      date: json['date'],
      isDateActive: json['isDateActive'] ?? false,
      dateType: json['dateType'] ?? 'single',
      endDate: json['endDate'],
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
      'date': date,
      'isDateActive': isDateActive,
      'dateType': dateType,
      'endDate': endDate,
    };
  }

  static List<TextSpan> buildColoredDateSpans(
    DailySubject subject, {
    bool inHeader = false,
  }) {
    if (subject.date == null || subject.date!.trim().isEmpty) return [];
    const List<String> namaHari = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const List<String> namaBulan = [
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

    // 1. Deteksi tingkat kecerahan latar belakang materi saat ini
    final Color bgColor = Color(subject.backgroundColor);
    final bool isDarkBackground =
        ThemeData.estimateBrightnessForColor(bgColor) == Brightness.dark;

    // 2. Tentukan warna dasar komponen berdasarkan mode (Header vs Grid)
    //    dan kecerahan latar belakang yang aktif secara dinamis.
    Color? colorHari;
    Color? colorTgl;
    Color? colorBln;

    if (inHeader) {
      // Jika di dalam Header Dialog
      if (isDarkBackground) {
        // Latar belakang gelap: Gunakan warna cerah/pastel agar kontras
        colorHari = Colors.purple[100];
        colorTgl = Colors.pink[200];
        colorBln = Colors.teal[100];
      } else {
        // Latar belakang terang: Gunakan warna yang lebih pekat/gelap agar terbaca
        colorHari = Colors.purple[900];
        colorTgl = Colors.pink[800];
        colorBln = Colors.teal[900];
      }
    } else {
      // Jika di dalam Grid Card Utama
      colorHari = isDarkBackground ? Colors.purple[100] : Colors.purple[900];
      colorTgl = isDarkBackground ? Colors.pink[200] : Colors.pink[700];
      colorBln = isDarkBackground ? Colors.teal[100] : Colors.teal[700];
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
            text: namaBulan[parsedEnd.month - 1],
            style: TextStyle(color: colorBln, fontWeight: FontWeight.bold),
          ),
        ];
      }
      return [
        TextSpan(
          text: '(${namaHari[parsedStart.weekday - 1]}) ',
          style: TextStyle(color: colorHari, fontWeight: FontWeight.bold),
        ),
        TextSpan(
          text: '${parsedStart.day} ',
          style: TextStyle(color: colorTgl, fontWeight: FontWeight.bold),
        ),
        TextSpan(
          text: namaBulan[parsedStart.month - 1],
          style: TextStyle(color: colorBln, fontWeight: FontWeight.bold),
        ),
      ];
    } catch (_) {
      return [
        TextSpan(
          text: subject.date,
          // Mengikuti warna teks judul utama yang sudah adaptif
          style: TextStyle(color: Color(subject.textColor)),
        ),
      ];
    }
  }
}

class SubMateriItem {
  String namaMateri;
  String progress;
  String? finishedDate;
  List<SubMateriItem> subMateri;

  SubMateriItem({
    required this.namaMateri,
    required this.progress,
    this.finishedDate,
    List<SubMateriItem>? subMateri,
  }) : this.subMateri = subMateri ?? [];

  factory SubMateriItem.fromJson(Map<String, dynamic> json) {
    var subList = json['sub_materi'] as List? ?? [];
    List<SubMateriItem> parsedSub = subList
        .map((i) => SubMateriItem.fromJson(i))
        .toList();

    return SubMateriItem(
      namaMateri: json['nama_materi'] ?? '',
      progress: json['progress'] ?? 'belum',
      finishedDate: json['finishedDate'],
      subMateri: parsedSub,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama_materi': namaMateri,
      'progress': progress,
      'finishedDate': finishedDate,
      'sub_materi': subMateri.map((e) => e.toJson()).toList(),
    };
  }

  void updateStatusFromChildren() {
    if (subMateri.isEmpty) return;

    for (var child in subMateri) {
      child.updateStatusFromChildren();
    }

    int total = subMateri.length;
    int selesai = subMateri.where((sm) => sm.progress == 'selesai').length;

    if (selesai == total) {
      progress = 'selesai';
    } else if (selesai > 0) {
      progress = 'sementara';
    } else {
      progress = 'belum';
    }
  }
}

// Model untuk Level 1: Checklist Hub (File JSON)
class ChecklistHub {
  String id;
  String namaHub;
  String ikon;
  List<ChecklistSection> semuaList;
  bool isHidden; // <--- TAMBAHKAN INI

  ChecklistHub({
    required this.id,
    required this.namaHub,
    required this.ikon,
    this.isHidden = false, // <--- TAMBAHKAN DEFAULT VALUE FALSE
    required this.semuaList,
  });

  factory ChecklistHub.fromJson(Map<String, dynamic> json) {
    var list = json['semua_list'] as List? ?? [];
    return ChecklistHub(
      id: json['id'] ?? '',
      namaHub: json['nama_hub'] ?? 'Hub Baru',
      ikon: json['ikon'] ?? '📁',
      isHidden: json['isHidden'] ?? false, // <--- BACA DARI JSON
      semuaList: list.map((i) => ChecklistSection.fromJson(i)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_hub': namaHub,
      'ikon': ikon,
      'isHidden': isHidden, // <--- SIMPAN KE JSON
      'semua_list': semuaList.map((e) => e.toJson()).toList(),
    };
  }
}

// Model untuk Level 2: Seksi Dinamis di dalam Hub
class ChecklistSection {
  String namaSeksi;
  List<DailySubject>
  items; // Mempertahankan DailySubject agar fitur warna, progress, dan tanggal tidak hilang!

  ChecklistSection({required this.namaSeksi, required this.items});

  factory ChecklistSection.fromJson(Map<String, dynamic> json) {
    var list = json['items'] as List? ?? [];
    return ChecklistSection(
      namaSeksi: json['nama_seksi'] ?? 'Seksi Baru',
      items: list.map((i) => DailySubject.fromJson(i)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama_seksi': namaSeksi,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

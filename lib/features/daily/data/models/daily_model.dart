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
  String dateType; // <-- TAMBAHAN: 'single' atau 'range'
  String? endDate; // <-- TAMBAHAN: Tanggal tujuan untuk rentang

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
    this.dateType = 'single', // <-- DEFAULT single
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
      dateType: json['dateType'] ?? 'single', // <-- PARSING JSON
      endDate: json['endDate'], // <-- PARSING JSON
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
      'dateType': dateType, // <-- SIMPAN KE JSON
      'endDate': endDate, // <-- SIMPAN KE JSON
    };
  }

  // Helper static untuk memformat tanggal penuh warna baru sesuai aturan tipe
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

    Color? colorHari = inHeader ? Colors.purple[100] : Colors.purple[900];
    Color? colorTgl = inHeader ? Colors.pink[200] : Colors.pink[700];
    Color? colorBln = inHeader ? Colors.teal[100] : Colors.teal[700];

    try {
      final DateTime parsedStart = DateTime.parse(subject.date!);

      // 1. JIKA TIPE TANGGAL ADALAH RENTANG (RANGE)
      if (subject.dateType == 'range' &&
          subject.endDate != null &&
          subject.endDate!.isNotEmpty) {
        final DateTime parsedEnd = DateTime.parse(subject.endDate!);

        final String tglMulai = '${parsedStart.day}';
        final String tglSelesai = '${parsedEnd.day}';
        final String bulanSelesai = namaBulan[parsedEnd.month - 1];

        return [
          TextSpan(
            text: '$tglMulai - $tglSelesai ',
            style: TextStyle(color: colorTgl, fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: bulanSelesai,
            style: TextStyle(color: colorBln, fontWeight: FontWeight.bold),
          ),
        ];
      }

      // 2. JIKA TIPE TANGGAL ADALAH BIASA (SINGLE) -> Hilangkan Tahun
      final String hari = '(${namaHari[parsedStart.weekday - 1]}) ';
      final String tanggal = '${parsedStart.day} ';
      final String bulan = namaBulan[parsedStart.month - 1];

      return [
        TextSpan(
          text: hari,
          style: TextStyle(color: colorHari, fontWeight: FontWeight.bold),
        ),
        TextSpan(
          text: tanggal,
          style: TextStyle(color: colorTgl, fontWeight: FontWeight.bold),
        ),
        TextSpan(
          text: bulan,
          style: TextStyle(color: colorBln, fontWeight: FontWeight.bold),
        ),
      ];
    } catch (_) {
      return [
        TextSpan(
          text: subject.date,
          style: TextStyle(color: inHeader ? Colors.white70 : Colors.black87),
        ),
      ];
    }
  }
}

class SubMateriItem {
  String namaMateri;
  String progress;
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

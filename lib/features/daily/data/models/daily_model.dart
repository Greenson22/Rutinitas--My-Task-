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
  String? date; // <-- TAMBAHAN FIELD BARU
  bool isDateActive; // <-- TAMBAHAN FIELD BARU

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
    this.date, // <-- INISIALISASI
    this.isDateActive = false, // <-- DEFAULT FALSE
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
      isDateActive:
          json['isDateActive'] ??
          false, // <-- PERBAIKAN: Gunakan titik dua (:), bukan (=)
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
      'date': date, // <-- SIMPAN KE JSON
      'isDateActive': isDateActive, // <-- SIMPAN KE JSON
    };
  }

  // Helper static untuk memformat tanggal penuh warna (bisa dipakai di Screen & Dialog)
  static List<TextSpan> buildColoredDateSpans(
    String? dateStr, {
    bool inHeader = false,
  }) {
    if (dateStr == null || dateStr.trim().isEmpty) return [];

    try {
      final DateTime parsedDate = DateTime.parse(dateStr);
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

      final String hari = '(${namaHari[parsedDate.weekday - 1]}) ';
      final String tanggal = '${parsedDate.day} ';
      final String bulan = '${namaBulan[parsedDate.month - 1]} ';
      // Mengambil 2 angka terakhir dari tahun (contoh: 2026 -> 26)
      final String tahun = parsedDate.year.toString().substring(2);

      // Warna disesuaikan jika diletakkan di header dialog (agar kontras dengan background gelap)
      return [
        TextSpan(
          text: hari,
          style: TextStyle(
            color: inHeader ? Colors.purple[100] : Colors.purple[900],
            fontWeight: FontWeight.bold,
          ),
        ),
        TextSpan(
          text: tanggal,
          style: TextStyle(
            color: inHeader ? Colors.pink[200] : Colors.pink[700],
            fontWeight: FontWeight.bold,
          ),
        ),
        TextSpan(
          text: bulan,
          style: TextStyle(
            color: inHeader ? Colors.teal[100] : Colors.teal[700],
            fontWeight: FontWeight.bold,
          ),
        ),
        TextSpan(
          text: tahun,
          style: TextStyle(
            color: inHeader ? Colors.orange[200] : Colors.deepOrange[700],
            fontWeight: FontWeight.bold,
          ),
        ),
      ];
    } catch (_) {
      return [
        TextSpan(
          text: dateStr,
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

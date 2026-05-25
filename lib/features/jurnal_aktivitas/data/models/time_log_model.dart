// lib/features/jurnal_aktivitas/data/models/time_log_model.dart

class TimeLogEntry {
  final String tanggal;
  final List<TimeLogTask> tasks;

  TimeLogEntry({required this.tanggal, required this.tasks});

  factory TimeLogEntry.fromJson(Map<String, dynamic> json) {
    return TimeLogEntry(
      tanggal: json['tanggal'] as String,
      tasks: (json['tasks'] as List<dynamic>)
          .map((e) => TimeLogTask.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'tanggal': tanggal, 'tasks': tasks.map((e) => e.toJson()).toList()};
  }
}

class TimeLogTask {
  final int id;
  final String nama;
  final int durasiMenit;
  final String? kategori;
  final List<String> linkedTaskIds;

  TimeLogTask({
    required this.id,
    required this.nama,
    required this.durasiMenit,
    this.kategori,
    required this.linkedTaskIds,
  });

  factory TimeLogTask.fromJson(Map<String, dynamic> json) {
    return TimeLogTask(
      id: json['id'] as int,
      nama: json['nama'] as String,
      durasiMenit: json['durasi_menit'] as int,
      kategori: json['kategori'] as String?,
      linkedTaskIds:
          (json['linkedTaskIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'durasi_menit': durasiMenit,
      'kategori': kategori,
      'linkedTaskIds': linkedTaskIds,
    };
  }
}

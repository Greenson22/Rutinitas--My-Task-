import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/features/jurnal_aktivitas/data/models/time_log_model.dart';
import 'package:rutinitasku/features/jurnal_aktivitas/presentation/controllers/jurnal_aktivitas_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('jurnal_ticket_02_test_');
    SharedPreferences.setMockInitialValues({
      'ubuntu_base_dir': tempDir.path,
      'ubuntu_base_dir_debug': tempDir.path,
    });
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('JurnalAktivitasController - Ticket 02: Perkuat addActivityDuration — hapus fallback bulan lama', () {
    test('Jika entri hari ini belum ada di logs, entri baru dibuat untuk hari ini sebelum durasi ditambahkan', () {
      DateTime simulatedNow = DateTime(2026, 12, 1, 10, 0);
      final controller = JurnalAktivitasController(clock: () => simulatedNow);

      expect(controller.logs, isEmpty);

      final task = TimeLogTask(
        id: 101,
        nama: 'Belajar Flutter',
        durasiMenit: 0,
        linkedTaskIds: [],
      );

      controller.addActivityDuration(task, 30);

      expect(controller.logs.length, equals(1));
      expect(controller.logs.first.tanggal, equals('2026-12-01'));
      expect(controller.logs.first.tasks.length, equals(1));
      expect(controller.logs.first.tasks.first.id, equals(101));
      expect(controller.logs.first.tasks.first.nama, equals('Belajar Flutter'));
      expect(controller.logs.first.tasks.first.durasiMenit, equals(30));
    });

    test('Tidak ada entri dengan tanggal selain hari ini yang dimodifikasi oleh operasi increment', () {
      DateTime simulatedNow = DateTime(2026, 12, 1, 10, 0);
      final controller = JurnalAktivitasController(clock: () => simulatedNow);

      final taskOld = TimeLogTask(
        id: 101,
        nama: 'Belajar Flutter',
        durasiMenit: 60,
        linkedTaskIds: [],
      );

      controller.logs = [
        TimeLogEntry(
          tanggal: '2026-11-30',
          tasks: [taskOld],
        ),
      ];

      // Panggil addActivityDuration dengan task yang id-nya sama dengan entri tanggal lama
      controller.addActivityDuration(taskOld, 30);

      // Entri 2026-11-30 TIDAK boleh berubah
      final oldEntry = controller.logs.firstWhere((e) => e.tanggal == '2026-11-30');
      expect(oldEntry.tasks.first.durasiMenit, equals(60));

      // Entri baru untuk 2026-12-01 harus ada dengan durasi 30 menit
      final todayEntry = controller.logs.firstWhere((e) => e.tanggal == '2026-12-01');
      expect(todayEntry.tasks.length, equals(1));
      expect(todayEntry.tasks.first.id, equals(101));
      expect(todayEntry.tasks.first.durasiMenit, equals(30));
    });

    test('Increment di hari-hari normal (entri hari ini sudah ada) tetap bekerja persis seperti sebelumnya', () {
      DateTime simulatedNow = DateTime(2026, 12, 1, 10, 0);
      final controller = JurnalAktivitasController(clock: () => simulatedNow);

      final taskToday = TimeLogTask(
        id: 101,
        nama: 'Belajar Flutter',
        durasiMenit: 45,
        linkedTaskIds: [],
      );

      controller.logs = [
        TimeLogEntry(
          tanggal: '2026-12-01',
          tasks: [taskToday],
        ),
      ];

      controller.addActivityDuration(taskToday, 30);

      expect(controller.logs.length, equals(1));
      expect(controller.logs.first.tanggal, equals('2026-12-01'));
      expect(controller.logs.first.tasks.first.durasiMenit, equals(75));
    });

    test('Increment dapat di-undo/dikurangi dari entri hari ini yang sama (termasuk nilai negatif)', () {
      DateTime simulatedNow = DateTime(2026, 12, 1, 10, 0);
      final controller = JurnalAktivitasController(clock: () => simulatedNow);

      final taskToday = TimeLogTask(
        id: 101,
        nama: 'Belajar Flutter',
        durasiMenit: 30,
        linkedTaskIds: [],
      );

      controller.logs = [
        TimeLogEntry(
          tanggal: '2026-12-01',
          tasks: [taskToday],
        ),
      ];

      // Undo increment: kurangi 30 menit
      controller.addActivityDuration(taskToday, -30);

      expect(controller.logs.first.tasks.first.durasiMenit, equals(0));
    });

    test('File bulan sebelumnya tidak berubah setelah saveData dipanggil di bulan baru', () async {
      DateTime simulatedNow = DateTime(2026, 12, 1, 10, 0);
      final controller = JurnalAktivitasController(clock: () => simulatedNow);

      final jurnalDir = Directory('${tempDir.path}/jurnal_aktivitas');
      await jurnalDir.create(recursive: true);

      final oldMonthFile = File('${jurnalDir.path}/jurnal_2026_11.json');
      await oldMonthFile.writeAsString(jsonEncode([
        {
          'tanggal': '2026-11-30',
          'tasks': [{'id': 101, 'nama': 'Belajar Flutter', 'durasiMenit': 60, 'linkedTaskIds': []}]
        }
      ]));

      // Panggil loadData
      await controller.loadData(onNotify: () {});

      // Sekarang entri hari ini ada di logs
      final task = controller.logs.firstWhere((e) => e.tanggal == '2026-12-01').tasks.firstWhere(
        (t) => t.id == 101,
        orElse: () => TimeLogTask(id: 101, nama: 'Belajar Flutter', durasiMenit: 0, linkedTaskIds: []),
      );

      controller.addActivityDuration(task, 30);
      await controller.saveData();

      // Cek isi file bulan baru
      final newMonthFile = File('${jurnalDir.path}/jurnal_2026_12.json');
      expect(await newMonthFile.exists(), isTrue);
      final newContent = await newMonthFile.readAsString();
      expect(newContent, contains('2026-12-01'));
      expect(newContent, contains('30'));

      // Cek isi file bulan lama
      final oldContent = await oldMonthFile.readAsString();
      expect(oldContent, contains('2026-11-30'));
      expect(oldContent, contains('60'));
      expect(oldContent, isNot(contains('2026-12-01')));
    });
  });
}

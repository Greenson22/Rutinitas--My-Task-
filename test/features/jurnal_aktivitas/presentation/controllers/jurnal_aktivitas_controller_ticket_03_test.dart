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
    tempDir = await Directory.systemTemp.createTemp('jurnal_ticket_03_test_');
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

  group('JurnalAktivitasController - Ticket 03: Unit test skenario pergantian bulan', () {
    test(
      'loadData yang dipanggil di hari pertama bulan baru membaca/membuat file bulan yang benar, bukan file bulan sebelumnya',
      () async {
        DateTime simulatedNow = DateTime(2026, 12, 1, 8, 0);
        final controller = JurnalAktivitasController(clock: () => simulatedNow);

        // Siapkan direktori dan file bulan sebelumnya
        final jurnalDir = Directory('${tempDir.path}/jurnal_aktivitas');
        await jurnalDir.create(recursive: true);
        final oldMonthFile = File('${jurnalDir.path}/jurnal_2026_11.json');
        await oldMonthFile.writeAsString(jsonEncode([
          {
            'tanggal': '2026-11-30',
            'tasks': [
              {'id': 1, 'nama': 'Tugas Lama', 'durasi_menit': 120, 'linkedTaskIds': []}
            ]
          }
        ]));

        // Sengaja set currentActiveMonth ke bulan sebelumnya
        controller.currentActiveMonth = DateTime(2026, 11, 1);

        await controller.loadData(onNotify: () {});

        // currentActiveMonth harus bulan baru (Desember 2026)
        expect(controller.currentActiveMonth.year, equals(2026));
        expect(controller.currentActiveMonth.month, equals(12));

        // File bulan baru (jurnal_2026_12.json) harus dibuat
        final newMonthFile = File('${jurnalDir.path}/jurnal_2026_12.json');
        expect(await newMonthFile.exists(), isTrue);

        // File bulan lama (jurnal_2026_11.json) tidak termodifikasi
        final oldContent = await oldMonthFile.readAsString();
        expect(oldContent, contains('2026-11-30'));
        expect(oldContent, contains('120'));
      },
    );

    test(
      'setelah loadData di bulan baru, logs di memori mengandung entri untuk hari ini (tanggal bulan baru)',
      () async {
        DateTime simulatedNow = DateTime(2026, 12, 1, 9, 30);
        final controller = JurnalAktivitasController(clock: () => simulatedNow);

        // Siapkan file template tugas
        final jurnalDir = Directory('${tempDir.path}/jurnal_aktivitas');
        await jurnalDir.create(recursive: true);
        final templateFile = File('${jurnalDir.path}/jurnal_template.json');
        await templateFile.writeAsString(jsonEncode({
          'settings': {'default_increment_minutes': 30},
          'tasks': [
            {'id': 201, 'nama': 'Review PR', 'durasi_menit': 0, 'linkedTaskIds': []},
            {'id': 202, 'nama': 'Dokumentasi', 'durasi_menit': 0, 'linkedTaskIds': []}
          ]
        }));

        await controller.loadData(onNotify: () {});

        // Harus ada entri untuk hari ini (2026-12-01)
        expect(controller.logs.any((e) => e.tanggal == '2026-12-01'), isTrue);
        final todayEntry = controller.logs.firstWhere((e) => e.tanggal == '2026-12-01');
        expect(todayEntry.tasks.length, equals(2));
        expect(todayEntry.tasks.map((t) => t.nama), containsAll(['Review PR', 'Dokumentasi']));
        expect(todayEntry.tasks.every((t) => t.durasiMenit == 0), isTrue);
      },
    );

    test(
      'addActivityDuration di hari pertama bulan baru menambahkan durasi ke entri hari ini — bukan ke entri bulan sebelumnya',
      () async {
        DateTime simulatedNow = DateTime(2026, 12, 1, 10, 0);
        final controller = JurnalAktivitasController(clock: () => simulatedNow);

        // Siapkan riwayat bulan lalu di logs
        final taskBulanLalu = TimeLogTask(
          id: 301,
          nama: 'Sprint Planning',
          durasiMenit: 60,
          linkedTaskIds: [],
        );
        controller.logs = [
          TimeLogEntry(
            tanggal: '2026-11-30',
            tasks: [taskBulanLalu],
          ),
        ];

        // Lakukan increment 30 menit pada task 301 di hari pertama bulan baru
        controller.addActivityDuration(taskBulanLalu, 30);

        // Verifikasi entri bulan lalu (2026-11-30) tidak bertambah durasinya
        final oldEntry = controller.logs.firstWhere((e) => e.tanggal == '2026-11-30');
        expect(oldEntry.tasks.first.durasiMenit, equals(60));

        // Verifikasi entri hari ini (2026-12-01) terbuat dan berdurasi 30 menit
        final todayEntry = controller.logs.firstWhere((e) => e.tanggal == '2026-12-01');
        expect(todayEntry.tasks.length, equals(1));
        expect(todayEntry.tasks.first.id, equals(301));
        expect(todayEntry.tasks.first.durasiMenit, equals(30));
      },
    );

    test(
      'saveData setelah increment di bulan baru menulis ke file bulan baru; file bulan lama tidak berubah',
      () async {
        DateTime simulatedNow = DateTime(2026, 12, 1, 11, 0);
        final controller = JurnalAktivitasController(clock: () => simulatedNow);

        final jurnalDir = Directory('${tempDir.path}/jurnal_aktivitas');
        await jurnalDir.create(recursive: true);

        // File bulan sebelumnya sudah ada
        final oldMonthFile = File('${jurnalDir.path}/jurnal_2026_11.json');
        final oldMonthJson = jsonEncode([
          {
            'tanggal': '2026-11-30',
            'tasks': [
              {'id': 401, 'nama': 'Refactoring', 'durasi_menit': 90, 'linkedTaskIds': []}
            ]
          }
        ]);
        await oldMonthFile.writeAsString(oldMonthJson);

        await controller.loadData(onNotify: () {});

        final task = TimeLogTask(
          id: 401,
          nama: 'Refactoring',
          durasiMenit: 0,
          linkedTaskIds: [],
        );

        // Increment 30 menit di hari pertama bulan baru
        controller.addActivityDuration(task, 30);
        await controller.saveData();

        // Verifikasi file bulan baru tertulis dengan data 2026-12-01 durasi 30 menit
        final newMonthFile = File('${jurnalDir.path}/jurnal_2026_12.json');
        expect(await newMonthFile.exists(), isTrue);
        final newContent = await newMonthFile.readAsString();
        expect(newContent, contains('2026-12-01'));
        expect(newContent, contains('30'));

        // Verifikasi file bulan lama sama sekali tidak berubah
        final oldContentAfter = await oldMonthFile.readAsString();
        expect(oldContentAfter, equals(oldMonthJson));
      },
    );

    test(
      'loadData yang dipanggil dua kali berturut-turut di bulan yang sama tidak menduplikasi entri hari ini',
      () async {
        DateTime simulatedNow = DateTime(2026, 12, 1, 14, 0);
        final controller = JurnalAktivitasController(clock: () => simulatedNow);

        final jurnalDir = Directory('${tempDir.path}/jurnal_aktivitas');
        await jurnalDir.create(recursive: true);
        final templateFile = File('${jurnalDir.path}/jurnal_template.json');
        await templateFile.writeAsString(jsonEncode({
          'tasks': [
            {'id': 501, 'nama': 'Coding Feature', 'durasi_menit': 0, 'linkedTaskIds': []}
          ]
        }));

        // Pemanggilan loadData pertama
        await controller.loadData(onNotify: () {});
        expect(controller.logs.where((e) => e.tanggal == '2026-12-01').length, equals(1));

        // Tambah durasi dan simpan
        final task = controller.logs.first.tasks.first;
        controller.addActivityDuration(task, 45);
        await controller.saveData();

        // Pemanggilan loadData kedua berturut-turut
        await controller.loadData(onNotify: () {});

        // Entri hari ini tidak boleh terduplikasi
        final todayEntries = controller.logs.where((e) => e.tanggal == '2026-12-01').toList();
        expect(todayEntries.length, equals(1));
        expect(todayEntries.first.tasks.length, equals(1));
        expect(todayEntries.first.tasks.first.durasiMenit, equals(45));
      },
    );

    test(
      'skenario normal (pertengahan bulan, entri hari ini sudah ada) tetap lulus tanpa perubahan perilaku',
      () async {
        DateTime simulatedNow = DateTime(2026, 12, 15, 16, 0);
        final controller = JurnalAktivitasController(clock: () => simulatedNow);

        final jurnalDir = Directory('${tempDir.path}/jurnal_aktivitas');
        await jurnalDir.create(recursive: true);

        // File bulan Desember sudah ada dengan riwayat tanggal 15
        final monthFile = File('${jurnalDir.path}/jurnal_2026_12.json');
        await monthFile.writeAsString(jsonEncode([
          {
            'tanggal': '2026-12-15',
            'tasks': [
              {'id': 601, 'nama': 'Bug Fixing', 'durasi_menit': 30, 'linkedTaskIds': []}
            ]
          }
        ]));

        await controller.loadData(onNotify: () {});

        expect(controller.logs.length, equals(1));
        expect(controller.logs.first.tanggal, equals('2026-12-15'));
        expect(controller.logs.first.tasks.first.durasiMenit, equals(30));

        // Increment normal
        final task = controller.logs.first.tasks.first;
        controller.addActivityDuration(task, 30);
        expect(controller.logs.first.tasks.first.durasiMenit, equals(60));

        await controller.saveData();
        final content = await monthFile.readAsString();
        expect(content, contains('2026-12-15'));
        expect(content, contains('60'));
      },
    );

    test('Semua test menggunakan direktori sementara dan dibersihkan setelah selesai', () async {
      // Verifikasi tempDir valid dan terisolasi
      expect(await tempDir.exists(), isTrue);
      expect(tempDir.path, contains('jurnal_ticket_03_test_'));
    });
  });
}

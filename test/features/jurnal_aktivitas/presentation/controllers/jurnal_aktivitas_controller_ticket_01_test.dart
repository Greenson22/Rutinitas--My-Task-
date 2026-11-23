import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/features/jurnal_aktivitas/presentation/controllers/jurnal_aktivitas_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('jurnal_controller_test_');
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

  group('JurnalAktivitasController - Ticket 01: Segarkan currentActiveMonth di awal loadData', () {
    test('loadData memperbarui currentActiveMonth ke waktu saat ini sebelum menentukan file jurnal', () async {
      DateTime simulatedNow = DateTime(2026, 12, 1, 10, 0);
      final controller = JurnalAktivitasController(clock: () => simulatedNow);

      // Set currentActiveMonth ke bulan sebelumnya
      controller.currentActiveMonth = DateTime(2026, 11, 1);

      await controller.loadData(onNotify: () {});

      expect(controller.currentActiveMonth.year, equals(2026));
      expect(controller.currentActiveMonth.month, equals(12));

      // Verifikasi file bulan baru dibuat
      final monthFile = File('${tempDir.path}/jurnal_aktivitas/jurnal_2026_12.json');
      expect(await monthFile.exists(), isTrue);
      expect(await monthFile.readAsString(), equals('[]'));
    });

    test('loadData membuat file jurnal bulan baru secara otomatis jika belum ada dan entri hari ini terbentuk di logs', () async {
      DateTime simulatedNow = DateTime(2026, 12, 1, 8, 30);
      final controller = JurnalAktivitasController(clock: () => simulatedNow);

      // Siapkan file template
      final jurnalDir = Directory('${tempDir.path}/jurnal_aktivitas');
      await jurnalDir.create(recursive: true);
      final templateFile = File('${jurnalDir.path}/jurnal_template.json');
      await templateFile.writeAsString(jsonEncode({
        'settings': {'default_increment_minutes': 30},
        'tasks': [
          {'id': 101, 'nama': 'Belajar Dart', 'durasi_menit': 0, 'linkedTaskIds': []}
        ]
      }));

      await controller.loadData(onNotify: () {});

      expect(controller.logs.length, equals(1));
      expect(controller.logs.first.tanggal, equals('2026-12-01'));
      expect(controller.logs.first.tasks.length, equals(1), reason: 'Expected 1 task in logs.first.tasks, got: ${controller.logs.first.tasks.map((t) => t.nama).toList()}');
      expect(controller.logs.first.tasks.first.nama, equals('Belajar Dart'));
      expect(controller.logs.first.tasks.first.durasiMenit, equals(0));
    });

    test('saveData yang dipanggil setelah loadData menulis ke file bulan baru, bukan bulan lama', () async {
      DateTime simulatedNow = DateTime(2026, 12, 1, 9, 0);
      final controller = JurnalAktivitasController(clock: () => simulatedNow);

      // Simulasikan file bulan sebelumnya ada
      final jurnalDir = Directory('${tempDir.path}/jurnal_aktivitas');
      await jurnalDir.create(recursive: true);
      final oldMonthFile = File('${jurnalDir.path}/jurnal_2026_11.json');
      await oldMonthFile.writeAsString(jsonEncode([
        {
          'tanggal': '2026-11-30',
          'tasks': [{'id': 101, 'nama': 'Belajar Dart', 'durasiMenit': 60, 'linkedTaskIds': []}]
        }
      ]));

      // Panggil loadData di bulan baru
      await controller.loadData(onNotify: () {});

      // Lakukan perubahan atau langsung saveData
      await controller.saveData();

      final newMonthFile = File('${jurnalDir.path}/jurnal_2026_12.json');
      expect(await newMonthFile.exists(), isTrue);

      // File bulan lama tidak tersentuh atau tertimpa
      final oldContent = await oldMonthFile.readAsString();
      expect(oldContent, contains('2026-11-30'));
      expect(oldContent, contains('60'));
    });

    test('ketika bulan aktif sudah sama dengan bulan sekarang, perilaku tidak berubah (tanpa regresi)', () async {
      DateTime simulatedNow = DateTime(2026, 11, 23, 10, 0);
      final controller = JurnalAktivitasController(clock: () => simulatedNow);

      await controller.loadData(onNotify: () {});

      expect(controller.currentActiveMonth.year, equals(2026));
      expect(controller.currentActiveMonth.month, equals(11));
      expect(controller.logs.any((e) => e.tanggal == '2026-11-23'), isTrue);
    });
  });
}

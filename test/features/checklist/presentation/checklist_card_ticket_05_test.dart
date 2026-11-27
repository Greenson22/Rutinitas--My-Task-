import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/features/checklist/data/models/daily_model.dart';
import 'package:rutinitasku/features/checklist/presentation/checklist_detail_screen/checklist_detail_screen.dart';
import 'package:rutinitasku/features/checklist/presentation/daily_tracker_history_screen/daily_tracker_history_screen.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('checklist_ticket_05_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Widget buildTestWidget({required ChecklistGroup group, List<ChecklistGroup>? allGroups}) {
    return MaterialApp(
      home: ChecklistDetailScreen(
        group: group,
        baseDir: tempDir.path,
        allAvailableGroups: allGroups ?? [group],
      ),
    );
  }

  group('ChecklistDetailScreen — DailyTracker Ticket 05 (Tombol Aksi Card)', () {
    testWidgets('ketiga tombol tampil ketika isDailyTrackerEnabled == true', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final subject = DailySubject(
        subjectName: 'Rutinitas Harian',
        progress: 'belum',
        isDailyTrackerEnabled: true,
        subMateri: [
          SubSubjectItem(subjectName: 'Item 1', progress: 'selesai'),
        ],
      );

      final group = ChecklistGroup(
        id: 'g1',
        groupName: 'Grup 1',
        icon: '📝',
        allList: [
          ChecklistSection(sectionName: 'Seksi 1', items: [subject]),
        ],
      );

      await tester.pumpWidget(buildTestWidget(group: group));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btn_save_today_log')), findsOneWidget);
      expect(find.byKey(const Key('btn_reset_for_new_day')), findsOneWidget);
      expect(find.byKey(const Key('btn_view_history')), findsOneWidget);

      expect(find.text('Simpan Hari Ini'), findsOneWidget);
      expect(find.text('Reset Hari Baru'), findsNothing);
      expect(find.text('Lihat History'), findsOneWidget);
    });

    testWidgets('tidak ada satu pun tombol DailyTracker ketika isDailyTrackerEnabled == false', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final subject = DailySubject(
        subjectName: 'Tugas Biasa',
        progress: 'belum',
        isDailyTrackerEnabled: false,
        subMateri: [],
      );

      final group = ChecklistGroup(
        id: 'g1',
        groupName: 'Grup 1',
        icon: '📝',
        allList: [
          ChecklistSection(sectionName: 'Seksi 1', items: [subject]),
        ],
      );

      await tester.pumpWidget(buildTestWidget(group: group));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btn_save_today_log')), findsNothing);
      expect(find.byKey(const Key('btn_reset_for_new_day')), findsNothing);
      expect(find.byKey(const Key('btn_view_history')), findsNothing);

      expect(find.text('Simpan Hari Ini'), findsNothing);
      expect(find.text('Reset Hari Baru'), findsNothing);
      expect(find.text('Lihat History'), findsNothing);
    });

    testWidgets('menekan "Simpan Hari Ini" memanggil saveTodayLog() dan menampilkan SnackBar dengan tanggal', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final subject = DailySubject(
        subjectName: 'Rutinitas Harian',
        progress: 'belum',
        isDailyTrackerEnabled: true,
        subMateri: [
          SubSubjectItem(subjectName: 'Membaca', progress: 'selesai'),
        ],
      );

      final group = ChecklistGroup(
        id: 'g1',
        groupName: 'Grup 1',
        icon: '📝',
        allList: [
          ChecklistSection(sectionName: 'Seksi 1', items: [subject]),
        ],
      );

      await tester.pumpWidget(buildTestWidget(group: group));
      await tester.pumpAndSettle();

      final now = DateTime.now();
      final todayFormatted =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      await tester.tap(find.byKey(const Key('btn_save_today_log')));
      await tester.pumpAndSettle();

      // Memastikan data tersimpan di subject.dailyLogs
      expect(subject.dailyLogs.containsKey(todayFormatted), isTrue);
      expect(subject.dailyLogs[todayFormatted]!.length, 1);
      expect(subject.dailyLogs[todayFormatted]!.first.itemName, 'Membaca');
      expect(subject.dailyLogs[todayFormatted]!.first.progress, 'selesai');
    });

    testWidgets('menekan "Reset Hari Baru" menampilkan dialog konfirmasi; membatalkan tidak mengubah apapun', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final subject = DailySubject(
        subjectName: 'Rutinitas Pagi',
        progress: 'selesai',
        isDailyTrackerEnabled: true,
        subMateri: [
          SubSubjectItem(subjectName: 'Olahraga', progress: 'selesai'),
        ],
      );

      final group = ChecklistGroup(
        id: 'g1',
        groupName: 'Grup 1',
        icon: '📝',
        allList: [
          ChecklistSection(sectionName: 'Seksi 1', items: [subject]),
        ],
      );

      await tester.pumpWidget(buildTestWidget(group: group));
      await tester.pumpAndSettle();

      // Tekan tombol Reset Hari Baru
      await tester.tap(find.byKey(const Key('btn_reset_for_new_day')));
      await tester.pumpAndSettle();

      // Dialog konfirmasi muncul
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Reset Hari Baru?'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Ya, Reset'), findsOneWidget);

      // Tekan Batal
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      // Dialog tertutup dan progress tetap 'selesai'
      expect(find.byType(AlertDialog), findsNothing);
      expect(subject.subMateri.first.progress, 'selesai');
    });

    testWidgets('menekan "Konfirmasi" di dialog reset memanggil resetForNewDay() dan me-refresh tampilan item', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final subject = DailySubject(
        subjectName: 'Rutinitas Pagi',
        progress: 'selesai',
        isDailyTrackerEnabled: true,
        subMateri: [
          SubSubjectItem(subjectName: 'Olahraga', progress: 'selesai'),
        ],
      );

      final group = ChecklistGroup(
        id: 'g1',
        groupName: 'Grup 1',
        icon: '📝',
        allList: [
          ChecklistSection(sectionName: 'Seksi 1', items: [subject]),
        ],
      );

      await tester.pumpWidget(buildTestWidget(group: group));
      await tester.pumpAndSettle();

      expect(find.text('Selesai Semua'), findsOneWidget);

      // Tekan tombol Reset Hari Baru
      await tester.tap(find.byKey(const Key('btn_reset_for_new_day')));
      await tester.pumpAndSettle();

      // Tekan Konfirmasi (Ya, Reset)
      await tester.tap(find.text('Ya, Reset'));
      await tester.pumpAndSettle();

      // Status item di-reset ke 'belum'
      expect(subject.subMateri.first.progress, 'belum');
      // Tampilan progress bar me-refresh (tidak lagi 'Selesai Semua')
      expect(find.text('Selesai Semua'), findsNothing);
      expect(find.text('0 / 1 List (0.0%)'), findsOneWidget);
    });

    testWidgets('menekan "Lihat History" menavigasi ke DailyTrackerHistoryScreen dengan subject yang sesuai', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final subject = DailySubject(
        subjectName: 'Rutinitas Pagi',
        progress: 'belum',
        isDailyTrackerEnabled: true,
        subMateri: [],
      );

      final group = ChecklistGroup(
        id: 'g1',
        groupName: 'Grup 1',
        icon: '📝',
        allList: [
          ChecklistSection(sectionName: 'Seksi 1', items: [subject]),
        ],
      );

      await tester.pumpWidget(buildTestWidget(group: group));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_view_history')));
      await tester.pumpAndSettle();

      // DailyTrackerHistoryScreen tampil
      expect(find.byType(DailyTrackerHistoryScreen), findsOneWidget);
      expect(find.text('Rutinitas Pagi'), findsWidgets);
    });
  });
}

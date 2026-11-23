import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/features/checklist/data/models/daily_model.dart';
import 'package:rutinitasku/features/checklist/presentation/checklist_detail_screen/checklist_detail_screen.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('checklist_ticket_04_test_');
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

  group('ChecklistDetailScreen — DailyTracker Ticket 04 (Toggle Aktivasi & Badge)', () {
    testWidgets('badge muncul di tree widget ketika isDailyTrackerEnabled == true', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final subject = DailySubject(
        subjectName: 'Ibadah Harian',
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

      expect(find.byKey(const Key('daily_tracker_badge')), findsOneWidget);
      expect(find.text('Daily'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today_rounded), findsOneWidget);
    });

    testWidgets('badge tidak ada di tree widget ketika isDailyTrackerEnabled == false', (tester) async {
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

      expect(find.byKey(const Key('daily_tracker_badge')), findsNothing);
      expect(find.text('Daily'), findsNothing);
    });

    testWidgets("item menu Aktifkan DailyTracker muncul pada card yang nonaktif, dan menekan menu mengaktifkannya", (tester) async {
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

      // Badge belum ada
      expect(find.byKey(const Key('daily_tracker_badge')), findsNothing);

      // Long press pada card untuk masuk mode edit (menampilkan tombol actions di card)
      await tester.longPress(find.text('Tugas Biasa'));
      await tester.pumpAndSettle();

      // Buka popup menu card (ikon more_vert)
      final moreVertFinder = find.byIcon(Icons.more_vert);
      expect(moreVertFinder, findsOneWidget);
      await tester.tap(moreVertFinder);
      await tester.pumpAndSettle();

      // Menu "Aktifkan DailyTracker" harus muncul
      expect(find.text('Aktifkan DailyTracker'), findsOneWidget);
      expect(find.text('Nonaktifkan DailyTracker'), findsNothing);

      // Tap menu "Aktifkan DailyTracker"
      await tester.tap(find.text('Aktifkan DailyTracker'));
      await tester.pumpAndSettle();

      // Status berubah menjadi true
      expect(subject.isDailyTrackerEnabled, isTrue);
      // Badge sekarang muncul di card
      expect(find.byKey(const Key('daily_tracker_badge')), findsOneWidget);
    });

    testWidgets('item menu Nonaktifkan DailyTracker muncul pada card yang aktif, dan menekan menu menonaktifkannya', (tester) async {
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

      // Badge ada di awal
      expect(find.byKey(const Key('daily_tracker_badge')), findsOneWidget);

      // Long press untuk masuk edit mode
      await tester.longPress(find.text('Rutinitas Pagi'));
      await tester.pumpAndSettle();

      // Buka popup menu card
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Menu "Nonaktifkan DailyTracker" harus muncul
      expect(find.text('Nonaktifkan DailyTracker'), findsOneWidget);
      expect(find.text('Aktifkan DailyTracker'), findsNothing);

      // Tap menu "Nonaktifkan DailyTracker"
      await tester.tap(find.text('Nonaktifkan DailyTracker'));
      await tester.pumpAndSettle();

      // Status berubah menjadi false
      expect(subject.isDailyTrackerEnabled, isFalse);
      // Badge hilang dari card
      expect(find.byKey(const Key('daily_tracker_badge')), findsNothing);
    });
  });
}

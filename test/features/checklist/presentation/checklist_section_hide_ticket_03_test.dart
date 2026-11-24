import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/features/checklist/data/models/daily_model.dart';
import 'package:rutinitasku/features/checklist/presentation/checklist_detail_screen/checklist_detail_screen.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('checklist_section_hide_ticket_03_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Widget buildScreenTestWidget({required ChecklistGroup group}) {
    return MaterialApp(
      home: ChecklistDetailScreen(
        group: group,
        baseDir: tempDir.path,
        allAvailableGroups: [group],
      ),
    );
  }

  group('ChecklistDetailScreen — Section Hide (Ticket 03)', () {
    testWidgets('seksi dengan isHidden = true tidak dirender di widget tree dalam mode normal', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final visibleItem = DailySubject(
        subjectName: 'Item Terlihat',
        progress: 'belum',
        subMateri: [],
      );

      final hiddenItem = DailySubject(
        subjectName: 'Item Tersembunyi Seksi',
        progress: 'belum',
        subMateri: [],
      );

      final group = ChecklistGroup(
        id: 'g1',
        groupName: 'Grup Pengujian',
        icon: '📋',
        allList: [
          ChecklistSection(sectionName: 'Seksi Terlihat', items: [visibleItem], isHidden: false),
          ChecklistSection(sectionName: 'Seksi Tersembunyi', items: [hiddenItem], isHidden: true),
        ],
      );

      await tester.pumpWidget(buildScreenTestWidget(group: group));
      await tester.pumpAndSettle();

      expect(find.text('Seksi Terlihat'), findsOneWidget);
      expect(find.text('Item Terlihat'), findsOneWidget);

      // Seksi tersembunyi tidak ada di widget tree saat mode normal
      expect(find.text('Seksi Tersembunyi'), findsNothing);
      expect(find.text('Item Tersembunyi Seksi'), findsNothing);
    });

    testWidgets('tap ikon visibility pada header seksi normal men-toggle section.isHidden == true dan seksi hilang', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final itemA = DailySubject(
        subjectName: 'Item A',
        progress: 'belum',
        subMateri: [],
      );

      final section = ChecklistSection(
        sectionName: 'Seksi A',
        items: [itemA],
        isHidden: false,
      );

      final group = ChecklistGroup(
        id: 'g1',
        groupName: 'Grup Pengujian',
        icon: '📋',
        allList: [section],
      );

      await tester.pumpWidget(buildScreenTestWidget(group: group));
      await tester.pumpAndSettle();

      expect(find.text('Seksi A'), findsOneWidget);
      expect(section.isHidden, isFalse);

      // Tap ikon visibility pada header seksi
      final visibilityButton = find.byTooltip('Sembunyikan Seksi');
      expect(visibilityButton, findsOneWidget);
      await tester.tap(visibilityButton);
      await tester.pumpAndSettle();

      // Seksi sekarang isHidden == true dan tidak ada di widget tree
      expect(section.isHidden, isTrue);
      expect(find.text('Seksi A'), findsNothing);
      expect(find.text('Item A'), findsNothing);
    });

    testWidgets('aktifkan mode tampilkan tersembunyi menampilkan seksi yang hidden kembali di widget tree', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final itemHidden = DailySubject(
        subjectName: 'Tugas Rahasia',
        progress: 'belum',
        subMateri: [],
      );

      final sectionHidden = ChecklistSection(
        sectionName: 'Seksi Rahasia',
        items: [itemHidden],
        isHidden: true,
      );

      final group = ChecklistGroup(
        id: 'g1',
        groupName: 'Grup Pengujian',
        icon: '📋',
        allList: [sectionHidden],
      );

      await tester.pumpWidget(buildScreenTestWidget(group: group));
      await tester.pumpAndSettle();

      // Awalnya seksi tersembunyi tidak ada di widget tree
      expect(find.text('Seksi Rahasia'), findsNothing);

      // Tap toggle global di AppBar untuk menampilkan item/seksi tersembunyi
      final globalToggle = find.byTooltip('Tampilkan Item Tersembunyi');
      expect(globalToggle, findsOneWidget);
      await tester.tap(globalToggle);
      await tester.pumpAndSettle();

      // Seksi yang hidden kembali muncul di widget tree dengan indikator badge "Tersembunyi"
      expect(find.text('Seksi Rahasia'), findsOneWidget);
      expect(find.text('Tersembunyi'), findsOneWidget);
      expect(find.text('Tugas Rahasia'), findsOneWidget);
    });

    testWidgets('tap ikon visibility pada seksi yang hidden (saat mode tampil) mengembalikannya ke normal (unhide)', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final itemHidden = DailySubject(
        subjectName: 'Tugas Proyek',
        progress: 'belum',
        subMateri: [],
      );

      final sectionHidden = ChecklistSection(
        sectionName: 'Seksi Proyek',
        items: [itemHidden],
        isHidden: true,
      );

      final group = ChecklistGroup(
        id: 'g1',
        groupName: 'Grup Pengujian',
        icon: '📋',
        allList: [sectionHidden],
      );

      await tester.pumpWidget(buildScreenTestWidget(group: group));
      await tester.pumpAndSettle();

      // Aktifkan mode tampilkan tersembunyi
      await tester.tap(find.byTooltip('Tampilkan Item Tersembunyi'));
      await tester.pumpAndSettle();

      expect(find.text('Seksi Proyek'), findsOneWidget);
      expect(sectionHidden.isHidden, isTrue);

      // Tap ikon visibility_off pada header seksi untuk unhide
      final unhideButton = find.byTooltip('Tampilkan Seksi');
      expect(unhideButton, findsOneWidget);
      await tester.tap(unhideButton);
      await tester.pumpAndSettle();

      // Sekarang sectionHidden.isHidden kembali menjadi false
      expect(sectionHidden.isHidden, isFalse);

      // Matikan kembali mode global tampilkan tersembunyi
      await tester.tap(find.byTooltip('Sembunyikan Item Nonaktif'));
      await tester.pumpAndSettle();

      // Seksi tetap muncul normal di mode biasa
      expect(find.text('Seksi Proyek'), findsOneWidget);
      expect(find.text('Tugas Proyek'), findsOneWidget);
    });

    testWidgets('data item seksi yang dihide tidak berubah setelah siklus hide dan unhide', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final item1 = DailySubject(
        subjectName: 'Item 1 Utama',
        progress: 'selesai',
        subMateri: [
          SubSubjectItem(subjectName: 'Sub 1', progress: 'selesai'),
        ],
      );
      final item2 = DailySubject(
        subjectName: 'Item 2 Kedua',
        progress: 'belum',
        subMateri: [],
      );

      final section = ChecklistSection(
        sectionName: 'Seksi Komplit',
        items: [item1, item2],
        isHidden: false,
      );

      final group = ChecklistGroup(
        id: 'g1',
        groupName: 'Grup Utuh',
        icon: '📋',
        allList: [section],
      );

      await tester.pumpWidget(buildScreenTestWidget(group: group));
      await tester.pumpAndSettle();

      // Hide seksi
      await tester.tap(find.byTooltip('Sembunyikan Seksi'));
      await tester.pumpAndSettle();
      expect(section.isHidden, isTrue);

      // Unhide seksi via mode tampil tersembunyi
      await tester.tap(find.byTooltip('Tampilkan Item Tersembunyi'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Tampilkan Seksi'));
      await tester.pumpAndSettle();

      expect(section.isHidden, isFalse);
      expect(section.items.length, 2);
      expect(section.items[0].subjectName, 'Item 1 Utama');
      expect(section.items[0].progress, 'selesai');
      expect(section.items[0].subMateri.length, 1);
      expect(section.items[0].subMateri[0].subjectName, 'Sub 1');
      expect(section.items[1].subjectName, 'Item 2 Kedua');
    });
  });
}

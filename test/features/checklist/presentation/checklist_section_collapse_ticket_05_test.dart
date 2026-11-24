import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rutinitasku/core/presentation/widgets/settings_dialog.dart';
import 'package:rutinitasku/features/checklist/data/models/daily_model.dart';
import 'package:rutinitasku/features/checklist/presentation/checklist_detail_screen/checklist_detail_screen.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('checklist_collapse_ticket_05_test_');
    SharedPreferences.setMockInitialValues({});
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

  group('ChecklistDetailScreen — Collapse Seksi (Ticket 05)', () {
    testWidgets('seksi dengan isCollapsed = true -> item tidak ditemukan di widget tree, header ada', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues({
        'section_remember_collapse_state': true,
      });

      final section = ChecklistSection(
        sectionName: 'Seksi Terlipat',
        items: [
          DailySubject(subjectName: 'Item Rahasia Lipatan', progress: 'belum', subMateri: []),
        ],
        isCollapsed: true,
      );

      final group = ChecklistGroup(
        id: 'g1',
        groupName: 'Grup Pengujian',
        icon: '📋',
        allList: [section],
      );

      await tester.pumpWidget(buildScreenTestWidget(group: group));
      await tester.pumpAndSettle();

      // Header ada
      expect(find.text('Seksi Terlipat'), findsOneWidget);
      // Ikon chevron right (kondisi terlipat) ada
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsNothing);

      // Item di bawah header tidak ada di widget tree
      expect(find.text('Item Rahasia Lipatan'), findsNothing);
    });

    testWidgets('tap header seksi -> item muncul di widget tree, ikon chevron berubah arah', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues({
        'section_remember_collapse_state': true,
      });

      final section = ChecklistSection(
        sectionName: 'Seksi Expand',
        items: [
          DailySubject(subjectName: 'Item Tampil', progress: 'belum', subMateri: []),
        ],
        isCollapsed: true,
      );

      final group = ChecklistGroup(
        id: 'g1',
        groupName: 'Grup Pengujian',
        icon: '📋',
        allList: [section],
      );

      await tester.pumpWidget(buildScreenTestWidget(group: group));
      await tester.pumpAndSettle();

      expect(find.text('Item Tampil'), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);

      // Tap header seksi
      await tester.tap(find.text('Seksi Expand'));
      await tester.pumpAndSettle();

      // Item muncul, chevron berubah ke expand_more
      expect(find.text('Item Tampil'), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('tap header lagi -> item hilang kembali dari widget tree', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues({
        'section_remember_collapse_state': true,
      });

      final section = ChecklistSection(
        sectionName: 'Seksi Bolak Balik',
        items: [
          DailySubject(subjectName: 'Item Muncul Hilang', progress: 'belum', subMateri: []),
        ],
        isCollapsed: false,
      );

      final group = ChecklistGroup(
        id: 'g1',
        groupName: 'Grup Pengujian',
        icon: '📋',
        allList: [section],
      );

      await tester.pumpWidget(buildScreenTestWidget(group: group));
      await tester.pumpAndSettle();

      expect(find.text('Item Muncul Hilang'), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);

      // Tap untuk melipat
      await tester.tap(find.text('Seksi Bolak Balik'));
      await tester.pumpAndSettle();

      expect(find.text('Item Muncul Hilang'), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);

      // Tap lagi untuk membuka kembali
      await tester.tap(find.text('Seksi Bolak Balik'));
      await tester.pumpAndSettle();

      expect(find.text('Item Muncul Hilang'), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });

    testWidgets('remember ON: toggle collapse -> section.isCollapsed berubah di model', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues({
        'section_remember_collapse_state': true,
      });

      final section = ChecklistSection(
        sectionName: 'Seksi Simpan Model',
        items: [
          DailySubject(subjectName: 'Item Test', progress: 'belum', subMateri: []),
        ],
        isCollapsed: false,
      );

      final group = ChecklistGroup(
        id: 'g1',
        groupName: 'Grup Pengujian',
        icon: '📋',
        allList: [section],
      );

      await tester.pumpWidget(buildScreenTestWidget(group: group));
      await tester.pumpAndSettle();

      expect(section.isCollapsed, isFalse);

      await tester.tap(find.text('Seksi Simpan Model'));
      await tester.pumpAndSettle();

      // Model section.isCollapsed ikut berubah menjadi true
      expect(section.isCollapsed, isTrue);
    });

    testWidgets('remember OFF: toggle collapse -> section.isCollapsed di model tidak berubah', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues({
        'section_remember_collapse_state': false,
        'section_default_collapsed': false,
      });

      final section = ChecklistSection(
        sectionName: 'Seksi Abaikan Model',
        items: [
          DailySubject(subjectName: 'Item Test', progress: 'belum', subMateri: []),
        ],
        isCollapsed: false,
      );

      final group = ChecklistGroup(
        id: 'g1',
        groupName: 'Grup Pengujian',
        icon: '📋',
        allList: [section],
      );

      await tester.pumpWidget(buildScreenTestWidget(group: group));
      await tester.pumpAndSettle();

      expect(section.isCollapsed, isFalse);
      expect(find.text('Item Test'), findsOneWidget);

      await tester.tap(find.text('Seksi Abaikan Model'));
      await tester.pumpAndSettle();

      // Di widget tree item menghilang (session state berubah)
      expect(find.text('Item Test'), findsNothing);
      // Namun di model data asli tetap false (tidak tersimpan ke disk/model)
      expect(section.isCollapsed, isFalse);
    });

    testWidgets('section_default_collapsed = true via mock SharedPreferences -> seksi dimulai terlipat saat widget dibuild', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues({
        'section_default_collapsed': true,
        'section_remember_collapse_state': false,
      });

      final section = ChecklistSection(
        sectionName: 'Seksi Default Tertutup',
        items: [
          DailySubject(subjectName: 'Item Tersembunyi Default', progress: 'belum', subMateri: []),
        ],
        isCollapsed: false,
      );

      final group = ChecklistGroup(
        id: 'g1',
        groupName: 'Grup Pengujian',
        icon: '📋',
        allList: [section],
      );

      await tester.pumpWidget(buildScreenTestWidget(group: group));
      await tester.pumpAndSettle();

      // Karena default_collapsed = true dan remember = false, seksi langsung dimulai terlipat
      expect(find.text('Seksi Default Tertutup'), findsOneWidget);
      expect(find.text('Item Tersembunyi Default'), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('section_default_collapsed = false -> seksi dimulai terbuka', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues({
        'section_default_collapsed': false,
        'section_remember_collapse_state': false,
      });

      final section = ChecklistSection(
        sectionName: 'Seksi Default Terbuka',
        items: [
          DailySubject(subjectName: 'Item Terbuka Default', progress: 'belum', subMateri: []),
        ],
        isCollapsed: true, // diabaikan karena remember = false
      );

      final group = ChecklistGroup(
        id: 'g1',
        groupName: 'Grup Pengujian',
        icon: '📋',
        allList: [section],
      );

      await tester.pumpWidget(buildScreenTestWidget(group: group));
      await tester.pumpAndSettle();

      expect(find.text('Seksi Default Terbuka'), findsOneWidget);
      expect(find.text('Item Terbuka Default'), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });
  });

  group('SettingsDialog — Checklist Appearance Settings (Ticket 05)', () {
    testWidgets('toggle "Tutup seksi secara default" di settings mengubah SharedPreferences', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues({
        'section_default_collapsed': false,
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsDialog(
              currentBaseDir: tempDir.path,
              onSave: (_) {},
              onEncryptionToggled: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tampilan Checklist'), findsOneWidget);
      expect(find.text('Tutup seksi secara default'), findsOneWidget);

      final switchFinder = find.widgetWithText(ListTile, 'Tutup seksi secara default');
      expect(switchFinder, findsOneWidget);

      final switchWidgetFinder = find.descendant(
        of: switchFinder,
        matching: find.byType(Switch),
      );
      expect(switchWidgetFinder, findsOneWidget);

      // Tap switch untuk mengaktifkan
      await tester.tap(switchWidgetFinder);
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('section_default_collapsed'), isTrue);
    });

    testWidgets('toggle "Ingat status lipatan seksi" di settings mengubah SharedPreferences', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues({
        'section_remember_collapse_state': true,
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsDialog(
              currentBaseDir: tempDir.path,
              onSave: (_) {},
              onEncryptionToggled: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ingat status lipatan seksi'), findsOneWidget);

      final switchFinder = find.widgetWithText(ListTile, 'Ingat status lipatan seksi');
      expect(switchFinder, findsOneWidget);

      final switchWidgetFinder = find.descendant(
        of: switchFinder,
        matching: find.byType(Switch),
      );
      expect(switchWidgetFinder, findsOneWidget);

      // Tap switch untuk menonaktifkan
      await tester.tap(switchWidgetFinder);
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('section_remember_collapse_state'), isFalse);
    });
  });
}

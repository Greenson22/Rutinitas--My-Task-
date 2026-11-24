import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/features/checklist/data/models/daily_model.dart';
import 'package:rutinitasku/features/checklist/presentation/checklist_detail_screen/checklist_detail_screen.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('checklist_delete_section_guard_test_');
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

  group('ChecklistDetailScreen — Guard Hapus Seksi Berisi (Ticket 04)', () {
    testWidgets('hapus seksi berisi 3 item (semua visible) memunculkan dialog konfirmasi dengan info 3 item', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final section = ChecklistSection(
        sectionName: 'Seksi Kerja',
        items: [
          DailySubject(subjectName: 'Tugas 1', progress: 'belum', subMateri: []),
          DailySubject(subjectName: 'Tugas 2', progress: 'belum', subMateri: []),
          DailySubject(subjectName: 'Tugas 3', progress: 'belum', subMateri: []),
        ],
      );

      final group = ChecklistGroup(
        id: 'g1',
        groupName: 'Grup Pengujian',
        icon: '📋',
        allList: [section],
      );

      await tester.pumpWidget(buildScreenTestWidget(group: group));
      await tester.pumpAndSettle();

      // Long press pada header seksi untuk mengaktifkan edit mode seksi
      await tester.longPress(find.text('Seksi Kerja'));
      await tester.pumpAndSettle();

      // Cari ikon delete di header seksi
      final deleteIconFinder = find.byIcon(Icons.delete);
      expect(deleteIconFinder, findsOneWidget);

      await tester.tap(deleteIconFinder);
      await tester.pumpAndSettle();

      // Dialog konfirmasi harus muncul
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Hapus Seksi?'), findsOneWidget);
      expect(find.textContaining('Seksi "Seksi Kerja" masih berisi 3 item'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Hapus Semua'), findsOneWidget);
    });

    testWidgets('hapus seksi berisi 2 item visible + 1 item hidden memunculkan dialog dengan info 3 item (1 tersembunyi)', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final section = ChecklistSection(
        sectionName: 'Seksi Campuran',
        items: [
          DailySubject(subjectName: 'Item Terlihat 1', progress: 'belum', subMateri: []),
          DailySubject(subjectName: 'Item Terlihat 2', progress: 'belum', subMateri: []),
          DailySubject(subjectName: 'Item Sembunyi', progress: 'belum', isHidden: true, subMateri: []),
        ],
      );

      final group = ChecklistGroup(
        id: 'g1',
        groupName: 'Grup Pengujian',
        icon: '📋',
        allList: [section],
      );

      await tester.pumpWidget(buildScreenTestWidget(group: group));
      await tester.pumpAndSettle();

      // Masuk edit mode seksi
      await tester.longPress(find.text('Seksi Campuran'));
      await tester.pumpAndSettle();

      // Tap tombol delete
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      // Dialog harus menyebutkan 3 item (1 tersembunyi)
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('3 item (1 tersembunyi)'), findsOneWidget);
      expect(find.textContaining('Seksi "Seksi Campuran"'), findsOneWidget);
    });

    testWidgets('tap "Batal" di dialog konfirmasi membatalkan penghapusan seksi', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final section = ChecklistSection(
        sectionName: 'Seksi Aman',
        items: [
          DailySubject(subjectName: 'Item Penting', progress: 'belum', subMateri: []),
        ],
      );

      final group = ChecklistGroup(
        id: 'g1',
        groupName: 'Grup Pengujian',
        icon: '📋',
        allList: [section],
      );

      await tester.pumpWidget(buildScreenTestWidget(group: group));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Seksi Aman'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      // Tap Batal
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      // Dialog hilang dan seksi tetap ada di daftar
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Seksi Aman'), findsOneWidget);
      expect(group.allList.length, 1);
    });

    testWidgets('tap "Hapus Semua" di dialog menghapus seksi beserta seluruh itemnya', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final section1 = ChecklistSection(
        sectionName: 'Seksi Mau Dihapus',
        items: [
          DailySubject(subjectName: 'Item Mau Dihapus', progress: 'belum', subMateri: []),
        ],
      );
      final section2 = ChecklistSection(
        sectionName: 'Seksi Bertahan',
        items: [
          DailySubject(subjectName: 'Item Bertahan', progress: 'belum', subMateri: []),
        ],
      );

      final group = ChecklistGroup(
        id: 'g1',
        groupName: 'Grup Pengujian',
        icon: '📋',
        allList: [section1, section2],
      );

      await tester.pumpWidget(buildScreenTestWidget(group: group));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Seksi Mau Dihapus'));
      await tester.pumpAndSettle();

      // Tap delete pada seksi pertama
      await tester.tap(find.byIcon(Icons.delete).first);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      // Tap "Hapus Semua"
      await tester.tap(find.text('Hapus Semua'));
      await tester.pumpAndSettle();

      // Seksi 1 terhapus dari grup dan widget tree
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Seksi Mau Dihapus'), findsNothing);
      expect(find.text('Item Mau Dihapus'), findsNothing);
      expect(find.text('Seksi Bertahan'), findsOneWidget);
      expect(group.allList.length, 1);
      expect(group.allList.first.sectionName, 'Seksi Bertahan');
    });

    testWidgets('hapus seksi kosong langsung terhapus tanpa dialog konfirmasi', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final emptySection = ChecklistSection(
        sectionName: 'Seksi Kosong',
        items: [],
      );
      final otherSection = ChecklistSection(
        sectionName: 'Seksi Lain',
        items: [
          DailySubject(subjectName: 'Item Lain', progress: 'belum', subMateri: []),
        ],
      );

      final group = ChecklistGroup(
        id: 'g1',
        groupName: 'Grup Pengujian',
        icon: '📋',
        allList: [emptySection, otherSection],
      );

      await tester.pumpWidget(buildScreenTestWidget(group: group));
      await tester.pumpAndSettle();

      expect(find.text('Seksi Kosong'), findsOneWidget);

      // Masuk edit mode
      await tester.longPress(find.text('Seksi Kosong'));
      await tester.pumpAndSettle();

      // Tap delete pada seksi kosong
      await tester.tap(find.byIcon(Icons.delete).first);
      await tester.pumpAndSettle();

      // Tidak ada dialog konfirmasi
      expect(find.byType(AlertDialog), findsNothing);

      // Seksi kosong langsung hilang
      expect(find.text('Seksi Kosong'), findsNothing);
      expect(group.allList.length, 1);
      expect(group.allList.first.sectionName, 'Seksi Lain');
    });
  });
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/features/checklist/data/models/daily_model.dart';
import 'package:rutinitasku/features/checklist/presentation/checklist_detail_screen/checklist_detail_screen.dart';
import 'package:rutinitasku/features/checklist/presentation/checklist_detail_screen/widgets/checklist_dialog.dart';
import 'package:rutinitasku/features/checklist/presentation/checklist_detail_screen/widgets/checklist_note_view.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('checklist_markdown_ticket_02_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Widget buildTestWidget({
    required DailySubject subject,
    VoidCallback? onDataChanged,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: DailyChecklistDialog(
          subject: subject,
          allAvailableSubjects: [subject],
          baseDir: tempDir.path,
          onDataChanged: onDataChanged ?? () {},
        ),
      ),
    );
  }

  Widget buildScreenTestWidget({required ChecklistGroup group}) {
    return MaterialApp(
      home: ChecklistDetailScreen(
        group: group,
        baseDir: tempDir.path,
        allAvailableGroups: [group],
      ),
    );
  }

  group('Checklist Note Markdown Persistence (Ticket 02)', () {
    testWidgets('toggle Markdown ON directly updates subject.isMarkdownEnabled and calls onDataChanged', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      int onDataChangedCount = 0;
      final subject = DailySubject(
        subjectName: 'Catatan Rapat',
        progress: 'belum',
        type: 'note',
        noteContent: '# Judul Catatan\nIni adalah isi catatan.',
        isMarkdownEnabled: false,
        subMateri: [],
      );

      await tester.pumpWidget(buildTestWidget(
        subject: subject,
        onDataChanged: () => onDataChangedCount++,
      ));
      await tester.pumpAndSettle();

      expect(subject.isMarkdownEnabled, isFalse);

      // Buka popup menu opsi catatan
      final moreOptionsFinder = find.byTooltip('Opsi Catatan');
      expect(moreOptionsFinder, findsOneWidget);
      await tester.tap(moreOptionsFinder);
      await tester.pumpAndSettle();

      // Tap menu Markdown
      final toggleMdFinder = find.text('Markdown: Nonaktif');
      expect(toggleMdFinder, findsOneWidget);
      await tester.tap(toggleMdFinder);
      await tester.pumpAndSettle();

      // Memastikan subject.isMarkdownEnabled menjadi true dan onDataChanged dipanggil tepat 1 kali
      expect(subject.isMarkdownEnabled, isTrue);
      expect(onDataChangedCount, 1);
    });

    testWidgets('toggle Markdown OFF updates subject.isMarkdownEnabled to false and calls onDataChanged', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      int onDataChangedCount = 0;
      final subject = DailySubject(
        subjectName: 'Catatan MD Aktif',
        progress: 'belum',
        type: 'note',
        noteContent: 'Konten Catatan',
        isMarkdownEnabled: true,
        subMateri: [],
      );

      await tester.pumpWidget(buildTestWidget(
        subject: subject,
        onDataChanged: () => onDataChangedCount++,
      ));
      await tester.pumpAndSettle();

      expect(subject.isMarkdownEnabled, isTrue);

      // Buka popup menu opsi catatan
      final moreOptionsFinder = find.byTooltip('Opsi Catatan');
      expect(moreOptionsFinder, findsOneWidget);
      await tester.tap(moreOptionsFinder);
      await tester.pumpAndSettle();

      // Tap menu Markdown
      final toggleMdFinder = find.text('Markdown: Aktif');
      expect(toggleMdFinder, findsOneWidget);
      await tester.tap(toggleMdFinder);
      await tester.pumpAndSettle();

      // Memastikan subject.isMarkdownEnabled kembali false dan onDataChanged dipanggil tepat 1 kali
      expect(subject.isMarkdownEnabled, isFalse);
      expect(onDataChangedCount, 1);
    });

    testWidgets('opening dialog with subject.isMarkdownEnabled = true directly renders Markdown preview', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final subject = DailySubject(
        subjectName: 'Catatan MD Terbuka',
        progress: 'belum',
        type: 'note',
        noteContent: '# Header Satu\n- Poin A\n- Poin B',
        isMarkdownEnabled: true,
        subMateri: [],
      );

      await tester.pumpWidget(buildTestWidget(subject: subject));
      await tester.pumpAndSettle();

      // ChecklistNoteView harus dalam mode view dan merender Markdown widget
      expect(find.byType(ChecklistNoteView), findsOneWidget);
      expect(find.byType(Markdown), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('closing dialog after toggle ON, then reopening shows Markdown preview; toggle OFF then reopening shows plain text', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final subject = DailySubject(
        subjectName: 'Catatan Siklus',
        progress: 'belum',
        type: 'note',
        noteContent: '# Halo Dunia',
        isMarkdownEnabled: false,
        subMateri: [],
      );

      final group = ChecklistGroup(
        id: 'g1',
        groupName: 'Grup 1',
        icon: '📝',
        allList: [
          ChecklistSection(sectionName: 'Seksi Catatan', items: [subject]),
        ],
      );

      await tester.pumpWidget(buildScreenTestWidget(group: group));
      await tester.pumpAndSettle();

      // 1. Ketuk card catatan untuk membuka dialog pertama kali
      await tester.tap(find.text('Catatan Siklus'));
      await tester.pumpAndSettle();

      // Saat dibuka (isMarkdownEnabled = false), tidak merender Markdown
      expect(find.byType(DailyChecklistDialog), findsOneWidget);
      expect(find.byType(Markdown), findsNothing);

      // 2. Toggle Markdown ON
      await tester.tap(find.byTooltip('Opsi Catatan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Markdown: Nonaktif'));
      await tester.pumpAndSettle();

      expect(subject.isMarkdownEnabled, isTrue);

      // 3. Tutup dialog dengan tombol Tutup
      await tester.tap(find.widgetWithText(ElevatedButton, 'Tutup'));
      await tester.pumpAndSettle();

      expect(find.byType(DailyChecklistDialog), findsNothing);

      // 4. Buka kembali dialog yang sama
      await tester.tap(find.text('Catatan Siklus'));
      await tester.pumpAndSettle();

      expect(find.byType(DailyChecklistDialog), findsOneWidget);
      // Mode pratinjau Markdown langsung ditampilkan
      expect(find.byType(Markdown), findsOneWidget);

      // 5. Toggle Markdown OFF
      await tester.tap(find.byTooltip('Opsi Catatan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Markdown: Aktif'));
      await tester.pumpAndSettle();

      expect(subject.isMarkdownEnabled, isFalse);

      // 6. Tutup dialog kembali
      await tester.tap(find.widgetWithText(ElevatedButton, 'Tutup'));
      await tester.pumpAndSettle();

      expect(find.byType(DailyChecklistDialog), findsNothing);

      // 7. Buka kembali dialog yang sama
      await tester.tap(find.text('Catatan Siklus'));
      await tester.pumpAndSettle();

      expect(find.byType(DailyChecklistDialog), findsOneWidget);
      // Tampil dalam mode teks biasa (Markdown tidak aktif)
      expect(find.byType(Markdown), findsNothing);
    });
  });
}

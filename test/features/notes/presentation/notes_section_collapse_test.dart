import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/core/services/storage_service.dart';
import 'package:rutinitasku/features/notes/models/note_model.dart';
import 'package:rutinitasku/features/notes/presentation/screens/note_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  Future<void> writeNoteGroup(NoteGroup group) async {
    final notesDir = Directory('${tempDir.path}/notes');
    if (!await notesDir.exists()) {
      await notesDir.create(recursive: true);
    }
    final file = File('${notesDir.path}/${group.id}.json');
    await file.writeAsString(jsonEncode(group.toJson()));
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('notes_collapse_test_');
    await writeNoteGroup(
      NoteGroup(
        id: 'g1',
        groupName: 'Catatan Kerja',
        icon: '📝',
        notes: [],
        sectionName: 'KERJA',
        orderIndex: 0,
      ),
    );
    await writeNoteGroup(
      NoteGroup(
        id: 'g2',
        groupName: 'Catatan Pribadi',
        icon: '🏠',
        notes: [],
        sectionName: 'PRIBADI',
        orderIndex: 1,
      ),
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<void> pumpNotesScreen(WidgetTester tester) async {
    await StorageService().saveBaseDirSetting(tempDir.path);
    await tester.pumpWidget(
      const MaterialApp(home: NotesScreen()),
    );
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 20)),
      );
    }
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('NotesScreen — Collapse Seksi', () {
    testWidgets(
      'tap header melipat kartu grup dan mengubah chevron ke chevron_right, tap lagi membuka kembali ke expand_more',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'base_dir': tempDir.path,
          'base_dir_debug': tempDir.path,
          'sections_default_collapsed': false,
          'sections_remember_collapse_state': true,
        });

        await pumpNotesScreen(tester);

        expect(find.text('Catatan Kerja'), findsOneWidget);
        expect(find.text('Catatan Pribadi'), findsOneWidget);
        expect(find.byIcon(Icons.expand_more), findsNWidgets(2));
        expect(find.byIcon(Icons.chevron_right), findsNothing);

        // Tap header KERJA untuk melipat
        await tester.tap(find.text('KERJA'));
        await tester.pumpAndSettle();

        // Seksi KERJA terlipat, seksi PRIBADI tetap terbuka
        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
        expect(find.byIcon(Icons.expand_more), findsOneWidget);

        // Tap header KERJA lagi untuk membuka
        await tester.tap(find.text('KERJA'));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.expand_more), findsNWidgets(2));
        expect(find.byIcon(Icons.chevron_right), findsNothing);
      },
    );

    testWidgets(
      'sections_remember_collapse_state = true menyimpan nama seksi ke notes_collapsed_sections',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'base_dir': tempDir.path,
          'base_dir_debug': tempDir.path,
          'sections_default_collapsed': false,
          'sections_remember_collapse_state': true,
        });

        await pumpNotesScreen(tester);

        await tester.tap(find.text('KERJA'));
        await tester.pumpAndSettle();

        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('notes_collapsed_sections');
        expect(raw, isNotNull);
        final list = List<String>.from(jsonDecode(raw!));
        expect(list, contains('KERJA'));
        expect(list, isNot(contains('PRIBADI')));
      },
    );

    testWidgets(
      'sections_remember_collapse_state = false tidak mengubah notes_collapsed_sections di SharedPreferences',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'base_dir': tempDir.path,
          'base_dir_debug': tempDir.path,
          'sections_default_collapsed': false,
          'sections_remember_collapse_state': false,
        });

        await pumpNotesScreen(tester);

        await tester.tap(find.text('KERJA'));
        await tester.pumpAndSettle();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('notes_collapsed_sections'), isNull);
        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      },
    );

    testWidgets(
      'sections_default_collapsed = true membuat semua seksi terlipat saat build',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'base_dir': tempDir.path,
          'base_dir_debug': tempDir.path,
          'sections_default_collapsed': true,
          'sections_remember_collapse_state': false,
        });

        await pumpNotesScreen(tester);

        expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));
        expect(find.byIcon(Icons.expand_more), findsNothing);
      },
    );
  });
}

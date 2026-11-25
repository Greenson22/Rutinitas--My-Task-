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
    tempDir = await Directory.systemTemp.createTemp('notes_hide_test_');
    await writeNoteGroup(
      NoteGroup(
        id: 'g1',
        groupName: 'Catatan Kerja',
        icon: '📝',
        notes: [],
        sectionName: 'KERJA',
        orderIndex: 0,
        isHidden: false,
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
        isHidden: false,
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
    await tester.pumpWidget(const MaterialApp(home: NotesScreen()));
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 20)),
      );
    }
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('NotesScreen — Sembunyikan Seksi', () {
    testWidgets(
      'tap tombol mata di edit mode menyembunyikan seksi dan menyimpan ke notes_hidden_sections tanpa mengubah NoteGroup.isHidden',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'sections_default_collapsed': false,
          'sections_remember_collapse_state': true,
        });

        await pumpNotesScreen(tester);

        expect(find.text('KERJA'), findsOneWidget);
        expect(find.text('Catatan Kerja'), findsOneWidget);

        // Masuk edit mode seksi
        await tester.tap(find.byIcon(Icons.edit_outlined).first);
        await tester.pumpAndSettle();

        // Tap tombol mata pada header seksi pertama
        await tester.tap(find.byIcon(Icons.visibility).first);
        await tester.pumpAndSettle();

        expect(find.text('KERJA'), findsNothing);
        expect(find.text('Catatan Kerja'), findsNothing);
        expect(find.text('PRIBADI'), findsOneWidget);

        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('notes_hidden_sections');
        expect(raw, isNotNull);
        final list = List<String>.from(jsonDecode(raw!));
        expect(list, contains('KERJA'));

        // Pastikan NoteGroup.isHidden di file JSON tidak berubah
        final file = File('${tempDir.path}/notes/g1.json');
        final decoded = NoteGroup.fromJson(jsonDecode(await file.readAsString()));
        expect(decoded.isHidden, isFalse);
      },
    );

    testWidgets(
      'tap tombol mata AppBar menampilkan seksi hidden dengan badge Tersembunyi dan mempertahankan state collapse',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'sections_default_collapsed': false,
          'sections_remember_collapse_state': true,
          'notes_collapsed_sections': jsonEncode(['KERJA']),
          'notes_hidden_sections': jsonEncode(['KERJA']),
        });

        await pumpNotesScreen(tester);

        expect(find.text('KERJA'), findsNothing);
        expect(find.text('Tersembunyi'), findsNothing);

        // Tap tombol mata AppBar
        await tester.tap(find.byIcon(Icons.visibility_off).first);
        await tester.pumpAndSettle();

        expect(find.text('KERJA'), findsOneWidget);
        expect(find.text('Tersembunyi'), findsOneWidget);
        expect(find.byIcon(Icons.chevron_right), findsOneWidget);

        // Tap tombol mata AppBar lagi -> hilang kembali
        await tester.tap(find.byIcon(Icons.visibility).first);
        await tester.pumpAndSettle();

        expect(find.text('KERJA'), findsNothing);
      },
    );
  });
}

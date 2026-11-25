import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/core/services/storage_service.dart';
import 'package:rutinitasku/features/documents/data/models/document_model.dart';
import 'package:rutinitasku/features/documents/presentation/screens/document_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  Future<void> writeDocumentGroup(DocumentGroup group) async {
    final docsDir = Directory('${tempDir.path}/documents');
    if (!await docsDir.exists()) {
      await docsDir.create(recursive: true);
    }
    final file = File('${docsDir.path}/${group.id}.json');
    await file.writeAsString(jsonEncode(group.toJson()));
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('docs_hide_test_');
    await writeDocumentGroup(
      DocumentGroup(
        id: 'd1',
        groupName: 'Dokumen Kerja',
        icon: '📄',
        sectionName: 'KERJA',
        orderIndex: 0,
        isHidden: false,
      ),
    );
    await writeDocumentGroup(
      DocumentGroup(
        id: 'd2',
        groupName: 'Dokumen Pribadi',
        icon: '📁',
        sectionName: 'PRIBADI',
        orderIndex: 1,
        isHidden: false,
      ),
    );
    await writeDocumentGroup(
      DocumentGroup(
        id: 'd3',
        groupName: 'Dokumen Rahasia',
        icon: '🔒',
        sectionName: 'PRIBADI',
        orderIndex: 2,
        isHidden: true,
      ),
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<void> pumpDocumentsScreen(WidgetTester tester) async {
    await StorageService().saveBaseDirSetting(tempDir.path);
    await tester.pumpWidget(const MaterialApp(home: MyDocumentsScreen()));
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 20)),
      );
    }
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('MyDocumentsScreen — Sembunyikan Seksi', () {
    testWidgets(
      'tap tombol mata di edit mode menyembunyikan seksi dan menyimpan ke docs_hidden_sections tanpa mengubah DocumentGroup.isHidden',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'sections_default_collapsed': false,
          'sections_remember_collapse_state': true,
        });

        await pumpDocumentsScreen(tester);

        await tester.tap(find.byIcon(Icons.edit_outlined).first);
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.visibility).first);
        await tester.pumpAndSettle();

        expect(find.text('KERJA'), findsNothing);
        expect(find.text('Dokumen Kerja'), findsNothing);
        expect(find.text('PRIBADI'), findsOneWidget);

        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('docs_hidden_sections');
        expect(raw, isNotNull);
        final list = List<String>.from(jsonDecode(raw!));
        expect(list, contains('KERJA'));

        final file = File('${tempDir.path}/documents/d1.json');
        final decoded = DocumentGroup.fromJson(
          jsonDecode(await file.readAsString()),
        );
        expect(decoded.isHidden, isFalse);
      },
    );

    testWidgets(
      'showHiddenSections dan showHiddenSection bekerja independen dan mempertahankan state collapse',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'sections_default_collapsed': false,
          'sections_remember_collapse_state': true,
          'docs_collapsed_sections': jsonEncode(['KERJA']),
          'docs_hidden_sections': jsonEncode(['KERJA']),
        });

        await pumpDocumentsScreen(tester);

        expect(find.text('KERJA'), findsNothing);
        expect(find.text('Dokumen Rahasia'), findsNothing);

        // Toggle showHiddenSections (seksi)
        await tester.tap(find.byIcon(Icons.layers_clear));
        await tester.pumpAndSettle();

        expect(find.text('KERJA'), findsOneWidget);
        expect(find.text('Tersembunyi'), findsOneWidget);
        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
        // Grup individual hidden tetap tidak tampil
        expect(find.text('Dokumen Rahasia'), findsNothing);

        // Toggle showHiddenSection (grup individual)
        await tester.tap(find.byIcon(Icons.visibility_off).first);
        await tester.pumpAndSettle();

        expect(find.text('Dokumen Rahasia'), findsOneWidget);

        // Toggle showHiddenSections lagi -> seksi KERJA hilang
        await tester.tap(find.byIcon(Icons.layers));
        await tester.pumpAndSettle();

        expect(find.text('KERJA'), findsNothing);
        expect(find.text('Dokumen Rahasia'), findsOneWidget);
      },
    );
  });
}

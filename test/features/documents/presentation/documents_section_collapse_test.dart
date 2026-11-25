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
    tempDir = await Directory.systemTemp.createTemp('docs_collapse_test_');
    await writeDocumentGroup(
      DocumentGroup(
        id: 'd1',
        groupName: 'Dokumen Kerja',
        icon: '📄',
        mainSectionName: 'KERJA',
        orderIndex: 0,
        isHidden: false,
      ),
    );
    await writeDocumentGroup(
      DocumentGroup(
        id: 'd2',
        groupName: 'Dokumen Pribadi',
        icon: '📁',
        mainSectionName: 'PRIBADI',
        orderIndex: 1,
        isHidden: false,
      ),
    );
    await writeDocumentGroup(
      DocumentGroup(
        id: 'd3',
        groupName: 'Dokumen Rahasia',
        icon: '🔒',
        mainSectionName: 'KERJA',
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

  group('MyDocumentsScreen — Collapse Seksi', () {
    testWidgets(
      'tap header melipat kartu grup dan mengubah chevron ke chevron_right, tap lagi membuka kembali ke expand_more',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'sections_default_collapsed': false,
          'sections_remember_collapse_state': true,
        });

        await pumpDocumentsScreen(tester);

        expect(find.text('Dokumen Kerja'), findsOneWidget);
        expect(find.text('Dokumen Pribadi'), findsOneWidget);
        expect(find.byIcon(Icons.expand_more), findsNWidgets(2));
        expect(find.byIcon(Icons.chevron_right), findsNothing);

        await tester.tap(find.text('KERJA'));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
        expect(find.byIcon(Icons.expand_more), findsOneWidget);

        await tester.tap(find.text('KERJA'));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.expand_more), findsNWidgets(2));
        expect(find.byIcon(Icons.chevron_right), findsNothing);
      },
    );

    testWidgets(
      'sections_remember_collapse_state = true menyimpan nama seksi ke docs_collapsed_sections',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'sections_default_collapsed': false,
          'sections_remember_collapse_state': true,
        });

        await pumpDocumentsScreen(tester);

        await tester.tap(find.text('KERJA'));
        await tester.pumpAndSettle();

        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('docs_collapsed_sections');
        expect(raw, isNotNull);
        final list = List<String>.from(jsonDecode(raw!));
        expect(list, contains('KERJA'));
        expect(list, isNot(contains('PRIBADI')));
      },
    );

    testWidgets(
      'showHiddenSection untuk grup individual tetap berfungsi setelah collapse seksi ditambahkan',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'sections_default_collapsed': false,
          'sections_remember_collapse_state': true,
        });

        await pumpDocumentsScreen(tester);

        expect(find.text('Dokumen Rahasia'), findsNothing);

        await tester.tap(find.byIcon(Icons.visibility_off));
        await tester.pumpAndSettle();

        expect(find.text('Dokumen Rahasia'), findsOneWidget);
      },
    );
  });
}

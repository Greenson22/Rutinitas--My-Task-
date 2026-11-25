import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/core/services/storage_service.dart';
import 'package:rutinitasku/features/prompt/data/models/prompt_model.dart';
import 'package:rutinitasku/features/prompt/presentation/screens/prompt_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  Future<void> writePromptGroup(PromptGroup group) async {
    final promptDir = Directory('${tempDir.path}/prompts');
    if (!await promptDir.exists()) {
      await promptDir.create(recursive: true);
    }
    final file = File('${promptDir.path}/${group.id}.json');
    await file.writeAsString(jsonEncode(group.toJson()));
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('prompt_collapse_test_');
    await writePromptGroup(
      PromptGroup(
        id: 'p1',
        title: 'Prompt Coding',
        icon: '💻',
        sectionName: 'KERJA',
        orderIndex: 0,
        prompts: [],
      ),
    );
    await writePromptGroup(
      PromptGroup(
        id: 'p2',
        title: 'Prompt Menulis',
        icon: '✍️',
        sectionName: 'PRIBADI',
        orderIndex: 1,
        prompts: [],
      ),
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<void> pumpPromptScreen(WidgetTester tester) async {
    await StorageService().saveBaseDirSetting(tempDir.path);
    await tester.pumpWidget(const MaterialApp(home: PromptScreen()));
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 20)),
      );
    }
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('PromptScreen — Collapse Seksi', () {
    testWidgets(
      'tap header melipat kartu grup dan mengubah chevron ke chevron_right, tap lagi membuka kembali ke expand_more',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'sections_default_collapsed': false,
          'sections_remember_collapse_state': true,
        });

        await pumpPromptScreen(tester);

        expect(find.text('Prompt Coding'), findsOneWidget);
        expect(find.text('Prompt Menulis'), findsOneWidget);
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
      'sections_remember_collapse_state = true menyimpan nama seksi ke prompt_collapsed_sections',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'sections_default_collapsed': false,
          'sections_remember_collapse_state': true,
        });

        await pumpPromptScreen(tester);

        await tester.tap(find.text('KERJA'));
        await tester.pumpAndSettle();

        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('prompt_collapsed_sections');
        expect(raw, isNotNull);
        final list = List<String>.from(jsonDecode(raw!));
        expect(list, contains('KERJA'));
        expect(list, isNot(contains('PRIBADI')));
      },
    );

    testWidgets(
      'sections_remember_collapse_state = false tidak mengubah prompt_collapsed_sections di SharedPreferences',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'sections_default_collapsed': false,
          'sections_remember_collapse_state': false,
        });

        await pumpPromptScreen(tester);

        await tester.tap(find.text('KERJA'));
        await tester.pumpAndSettle();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('prompt_collapsed_sections'), isNull);
        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      },
    );

    testWidgets(
      'sections_default_collapsed = true membuat semua seksi terlipat saat build',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'sections_default_collapsed': true,
          'sections_remember_collapse_state': false,
        });

        await pumpPromptScreen(tester);

        expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));
        expect(find.byIcon(Icons.expand_more), findsNothing);
      },
    );
  });
}

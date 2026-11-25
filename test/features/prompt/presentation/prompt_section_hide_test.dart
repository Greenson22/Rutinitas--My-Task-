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
    tempDir = await Directory.systemTemp.createTemp('prompt_hide_test_');
    await writePromptGroup(
      PromptGroup(
        id: 'p1',
        title: 'Prompt Coding',
        icon: '💻',
        sectionName: 'KERJA',
        orderIndex: 0,
        isHidden: false,
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
        isHidden: false,
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

  group('PromptScreen — Sembunyikan Seksi', () {
    testWidgets(
      'tap tombol mata di edit mode menyembunyikan seksi dan menyimpan ke prompt_hidden_sections tanpa mengubah PromptGroup.isHidden',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'sections_default_collapsed': false,
          'sections_remember_collapse_state': true,
        });

        await pumpPromptScreen(tester);

        await tester.tap(find.byIcon(Icons.edit_outlined).first);
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.visibility).first);
        await tester.pumpAndSettle();

        expect(find.text('KERJA'), findsNothing);
        expect(find.text('Prompt Coding'), findsNothing);
        expect(find.text('PRIBADI'), findsOneWidget);

        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('prompt_hidden_sections');
        expect(raw, isNotNull);
        final list = List<String>.from(jsonDecode(raw!));
        expect(list, contains('KERJA'));

        final file = File('${tempDir.path}/prompts/p1.json');
        final decoded = PromptGroup.fromJson(
          jsonDecode(await file.readAsString()),
        );
        expect(decoded.isHidden, isFalse);
      },
    );

    testWidgets(
      'tap tombol mata AppBar menampilkan seksi hidden dengan badge Tersembunyi dan mempertahankan state collapse',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'sections_default_collapsed': false,
          'sections_remember_collapse_state': true,
          'prompt_collapsed_sections': jsonEncode(['KERJA']),
          'prompt_hidden_sections': jsonEncode(['KERJA']),
        });

        await pumpPromptScreen(tester);

        expect(find.text('KERJA'), findsNothing);
        expect(find.text('Tersembunyi'), findsNothing);

        await tester.tap(find.byIcon(Icons.visibility_off).first);
        await tester.pumpAndSettle();

        expect(find.text('KERJA'), findsOneWidget);
        expect(find.text('Tersembunyi'), findsOneWidget);
        expect(find.byIcon(Icons.chevron_right), findsOneWidget);

        await tester.tap(find.byIcon(Icons.visibility).first);
        await tester.pumpAndSettle();

        expect(find.text('KERJA'), findsNothing);
      },
    );
  });
}

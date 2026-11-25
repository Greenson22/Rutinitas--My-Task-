import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/core/presentation/widgets/settings_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsDialog — Tampilan Sections (Notes, Prompt, Dokumen)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'section_default_collapsed': false,
        'section_remember_collapse_state': true,
        'checklist_groups_default_collapsed': false,
        'sections_default_collapsed': false,
        'sections_remember_collapse_state': true,
      });
    });

    testWidgets(
      'toggle "Tutup seksi secara default" mengubah sections_default_collapsed tanpa mengubah key checklist lama',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SettingsDialog(
                currentBaseDir: 'Documents',
                onSave: (_) {},
                onEncryptionToggled: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final sectionHeaderFinder = find.text(
          'Tampilan Sections (Notes, Prompt, Dokumen)',
        );
        await tester.scrollUntilVisible(
          sectionHeaderFinder,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(sectionHeaderFinder, findsOneWidget);

        final labelFinder = find.text('Tutup seksi secara default').last;
        await tester.scrollUntilVisible(
          labelFinder,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(labelFinder, findsOneWidget);

        final tileFinder = find.ancestor(
          of: labelFinder,
          matching: find.byType(ListTile),
        );
        final switchFinder = find.descendant(
          of: tileFinder,
          matching: find.byType(Switch),
        );
        expect(switchFinder, findsOneWidget);

        await tester.tap(switchFinder);
        await tester.pumpAndSettle();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('sections_default_collapsed'), isTrue);
        expect(prefs.getBool('section_default_collapsed'), isFalse);
        expect(prefs.getBool('section_remember_collapse_state'), isTrue);
        expect(prefs.getBool('checklist_groups_default_collapsed'), isFalse);
      },
    );

    testWidgets(
      'toggle "Ingat status lipatan seksi" mengubah sections_remember_collapse_state tanpa mengubah key checklist lama',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SettingsDialog(
                currentBaseDir: 'Documents',
                onSave: (_) {},
                onEncryptionToggled: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final labelFinder = find.text('Ingat status lipatan seksi').last;
        await tester.scrollUntilVisible(
          labelFinder,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(labelFinder, findsOneWidget);

        final tileFinder = find.ancestor(
          of: labelFinder,
          matching: find.byType(ListTile),
        );
        final switchFinder = find.descendant(
          of: tileFinder,
          matching: find.byType(Switch),
        );
        expect(switchFinder, findsOneWidget);

        await tester.tap(switchFinder);
        await tester.pumpAndSettle();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('sections_remember_collapse_state'), isFalse);
        expect(prefs.getBool('section_default_collapsed'), isFalse);
        expect(prefs.getBool('section_remember_collapse_state'), isTrue);
        expect(prefs.getBool('checklist_groups_default_collapsed'), isFalse);
      },
    );
  });
}

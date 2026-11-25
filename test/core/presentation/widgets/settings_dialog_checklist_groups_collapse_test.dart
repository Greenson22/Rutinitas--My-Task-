import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/core/presentation/widgets/settings_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsDialog — Checklist Groups Default Collapse', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'section_default_collapsed': false,
        'checklist_groups_default_collapsed': false,
      });
    });

    testWidgets(
      'switch Checklist Groups: Tutup seksi secara default muncul, toggle mengubah checklist_groups_default_collapsed tanpa mengubah section_default_collapsed',
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

        final labelFinder = find.text(
          'Checklist Groups: Tutup seksi secara default',
        );
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
        expect(prefs.getBool('checklist_groups_default_collapsed'), isTrue);
        expect(prefs.getBool('section_default_collapsed'), isFalse);
      },
    );
  });
}

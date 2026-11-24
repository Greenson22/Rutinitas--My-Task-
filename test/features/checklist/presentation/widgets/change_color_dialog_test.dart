import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/features/checklist/data/models/daily_model.dart';
import 'package:rutinitasku/features/checklist/presentation/checklist_detail_screen/widgets/change_color_dialog.dart';

void main() {
  group('ChangeColorDialog Widget Tests', () {
    late DailySubject sampleSubject;

    setUp(() {
      sampleSubject = DailySubject(
        subjectName: 'Matematika',
        icon: '📐',
        progress: 'belum',
        subMateri: [],
        backgroundColor: 0xFFFADBD8,
        textColor: 0xFF78281F,
      );
    });

    Widget buildDialog({VoidCallback? onColorSaved}) {
      return MaterialApp(
        home: Scaffold(
          body: ChangeColorDialog(
            subject: sampleSubject,
            onColorSaved: onColorSaved ?? () {},
          ),
        ),
      );
    }

    testWidgets('menampilkan color wheel widget di dalam dialog', (tester) async {
      await tester.pumpWidget(buildDialog());

      expect(find.byType(ColorPicker), findsOneWidget);
      expect(find.text('Matematika'), findsOneWidget);
    });

    testWidgets('dropdown Warna Teks (Gelap/Putih) tidak ada di UI', (tester) async {
      await tester.pumpWidget(buildDialog());

      expect(find.text('Warna Teks'), findsNothing);
      expect(find.text('Gelap'), findsNothing);
      expect(find.text('Putih'), findsNothing);
      expect(find.byType(DropdownButton<bool>), findsNothing);
    });

    testWidgets('input HEX valid mengubah warna preview card', (tester) async {
      await tester.pumpWidget(buildDialog());

      final hexField = find.byType(TextFormField);
      expect(hexField, findsOneWidget);

      await tester.enterText(hexField, '1A237E');
      await tester.pump();

      final previewContainer = tester.widget<Container>(
        find.ancestor(
          of: find.text('Matematika'),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = previewContainer.decoration as BoxDecoration;
      expect(decoration.color, equals(const Color(0xFF1A237E)));
    });

    testWidgets('memilih warna dari palet kuratif memperbarui preview dan HEX', (tester) async {
      await tester.pumpWidget(buildDialog());

      // Tap warna kedua di palet (0xFFD4EFDF)
      final inkWells = find.descendant(
        of: find.byType(GridView),
        matching: find.byType(InkWell),
      );
      expect(inkWells, findsWidgets);

      await tester.ensureVisible(inkWells.at(1));
      await tester.tap(inkWells.at(1));
      await tester.pump();

      final hexField = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(hexField.controller?.text, equals('D4EFDF'));
    });

    testWidgets('menekan Simpan Warna menyimpan backgroundColor dan textColor sesuai brightness', (tester) async {
      bool savedCalled = false;
      await tester.pumpWidget(buildDialog(onColorSaved: () => savedCalled = true));

      // Masukkan warna gelap -> textColor harus Colors.white
      await tester.enterText(find.byType(TextFormField), '1A237E');
      await tester.pump();

      await tester.tap(find.text('Simpan Warna'));
      await tester.pumpAndSettle();

      expect(savedCalled, isTrue);
      expect(sampleSubject.backgroundColor, equals(0xFF1A237E));
      expect(sampleSubject.textColor, equals(Colors.white.toARGB32()));
    });

    testWidgets('menekan Batal tidak mengubah subject dan tidak memanggil onColorSaved', (tester) async {
      bool savedCalled = false;
      await tester.pumpWidget(buildDialog(onColorSaved: () => savedCalled = true));

      await tester.enterText(find.byType(TextFormField), '1A237E');
      await tester.pump();

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(savedCalled, isFalse);
      expect(sampleSubject.backgroundColor, equals(0xFFFADBD8));
      expect(sampleSubject.textColor, equals(0xFF78281F));
    });
  });
}

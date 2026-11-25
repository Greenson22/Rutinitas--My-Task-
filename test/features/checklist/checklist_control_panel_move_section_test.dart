import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/features/checklist/data/models/daily_model.dart';
import 'package:rutinitasku/features/checklist/presentation/checklist_detail_screen/widgets/checklist_control_panel.dart';

void main() {
  Widget buildTestPanel({
    required List<ChecklistSection> sections,
    required String currentSectionName,
    ValueChanged<ChecklistSection>? onMoveToSection,
  }) {
    final subject = DailySubject(
      subjectName: 'Belajar Flutter',
      progress: '0%',
      subMateri: const [],
    );

    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ChecklistControlPanel(
            subject: subject,
            singleInputController: TextEditingController(),
            onAddRootItem: () {},
            onPasteFromClipboard: () {},
            onDateActiveChanged: (_) {},
            onDateTypeChanged: (_) {},
            onSelectStartDate: () {},
            onSelectEndDate: () {},
            isEditMode: false,
            isAllSelected: false,
            onSelectAllChanged: (_) {},
            isAllFinishedSelected: false,
            onSelectAllFinishedChanged: (_) {},
            onMarkAllDone: () {},
            hideFinishedItems: false,
            onToggleHideFinished: () {},
            defaultCardExpanded: false,
            onDefaultExpandedPrefChanged: (_) {},
            onTriggerAllExpansion: (_) {},
            onImportJsonPressed: () {},
            availableSections: sections,
            currentSectionName: currentSectionName,
            onMoveToSection: onMoveToSection,
          ),
        ),
      ),
    );
  }

  group('ChecklistControlPanel — Pindah Seksi Lazy-Expand', () {
    final sections = [
      ChecklistSection(sectionName: 'Pekerjaan', items: const []),
      ChecklistSection(sectionName: 'Pribadi', items: const []),
      ChecklistSection(sectionName: 'Belajar', items: const []),
    ];

    testWidgets(
      'daftar seksi tidak terlihat saat awal, muncul saat ketuk Pindah Seksi tanpa seksi aktif, ketuk tujuan memanggil callback & menutup picker, ketuk Pindah Seksi lagi menutup picker',
      (tester) async {
        ChecklistSection? movedTo;

        await tester.pumpWidget(
          buildTestPanel(
            sections: sections,
            currentSectionName: 'Pekerjaan',
            onMoveToSection: (section) {
              movedTo = section;
            },
          ),
        );

        // Awal: tombol Pindah Seksi ada, daftar seksi tidak ada
        expect(find.text('Pindah Seksi'), findsOneWidget);
        expect(find.text('Pribadi'), findsNothing);
        expect(find.text('Belajar'), findsNothing);

        // Ketuk Pindah Seksi -> daftar muncul, seksi aktif ('Pekerjaan') tidak ada
        await tester.tap(find.text('Pindah Seksi'));
        await tester.pumpAndSettle();

        expect(find.text('Pekerjaan'), findsNothing);
        expect(find.text('Pribadi'), findsOneWidget);
        expect(find.text('Belajar'), findsOneWidget);

        // Ketuk seksi tujuan -> callback dipanggil, picker tertutup
        await tester.tap(find.text('Pribadi'));
        await tester.pumpAndSettle();

        expect(movedTo?.sectionName, 'Pribadi');
        expect(find.text('Pribadi'), findsNothing);
        expect(find.text('Belajar'), findsNothing);

        // Ketuk Pindah Seksi -> buka lagi, lalu ketuk Pindah Seksi lagi -> tutup (toggle)
        await tester.tap(find.text('Pindah Seksi'));
        await tester.pumpAndSettle();
        expect(find.text('Belajar'), findsOneWidget);

        await tester.tap(find.text('Pindah Seksi'));
        await tester.pumpAndSettle();
        expect(find.text('Belajar'), findsNothing);
      },
    );
  });
}

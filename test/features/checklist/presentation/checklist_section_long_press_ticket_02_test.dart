import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/features/checklist/data/models/daily_model.dart';
import 'package:rutinitasku/features/checklist/presentation/checklist_detail_screen/checklist_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('checklist_section_long_press_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  ChecklistGroup createTestGroup() {
    return ChecklistGroup(
      id: 'group-1',
      groupName: 'Grup Test',
      icon: 'list',
      allList: [
        ChecklistSection(
          sectionName: 'Seksi Pertama',
          items: [
            DailySubject(
              subjectName: 'Materi A',
              progress: 'belum',
              subMateri: [],
            ),
          ],
        ),
        ChecklistSection(
          sectionName: 'Seksi Kedua',
          items: [
            DailySubject(
              subjectName: 'Materi B',
              progress: 'belum',
              subMateri: [],
            ),
          ],
        ),
      ],
    );
  }

  Widget buildTestScreen(ChecklistGroup group) {
    return MaterialApp(
      home: ChecklistDetailScreen(
        group: group,
        baseDir: tempDir.path,
        allAvailableGroups: [group],
      ),
    );
  }

  group('ChecklistDetailScreen — Ticket 02 (Long Press Section Actions)', () {
    testWidgets(
      '(a) tombol aksi tidak tampil by default, (b) muncul setelah long press, (c) tersembunyi setelah long press kedua, (d) seksi lain tidak terpengaruh',
      (tester) async {
        await tester.pumpWidget(buildTestScreen(createTestGroup()));
        await tester.pumpAndSettle();

        // (a) Default: tidak ada tombol aksi yang tampil (termasuk Sembunyikan Seksi)
        expect(find.byIcon(Icons.visibility), findsNothing);
        expect(find.byIcon(Icons.arrow_upward), findsNothing);
        expect(find.byIcon(Icons.arrow_downward), findsNothing);
        expect(find.byIcon(Icons.edit), findsNothing);
        expect(find.byIcon(Icons.delete), findsNothing);
        expect(find.byIcon(Icons.add_circle_outline), findsNothing);

        // (b) Long press pada Seksi Pertama memunculkan tombol aksi
        await tester.longPress(find.text('Seksi Pertama'));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
        expect(find.byIcon(Icons.edit), findsOneWidget);
        expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
        expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
        expect(find.byIcon(Icons.visibility), findsOneWidget);
        expect(find.byIcon(Icons.delete), findsOneWidget);

        // (d) Hanya 1 set tombol aksi yang tampil (Seksi Kedua tidak terpengaruh)
        // Verifikasi Pindah Atas disabled pada seksi pertama
        final upBtn = tester.widget<IconButton>(
          find.ancestor(
            of: find.byIcon(Icons.arrow_upward),
            matching: find.byType(IconButton),
          ),
        );
        expect(upBtn.onPressed, isNull);

        // (c) Long press kedua pada Seksi Pertama menyembunyikan tombol aksi kembali
        await tester.longPress(find.text('Seksi Pertama'));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.visibility), findsNothing);
        expect(find.byIcon(Icons.edit), findsNothing);
        expect(find.byIcon(Icons.delete), findsNothing);
      },
    );
  });
}

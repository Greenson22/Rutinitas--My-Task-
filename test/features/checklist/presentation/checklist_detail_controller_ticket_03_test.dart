import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/features/checklist/data/models/daily_model.dart';
import 'package:rutinitasku/features/checklist/presentation/checklist_detail_screen/checklist_detail_screen.dart';
import 'package:rutinitasku/features/checklist/presentation/checklist_detail_screen/controllers/checklist_detail_controller.dart';

class _Ticket03TestScreen extends ChecklistDetailScreen {
  const _Ticket03TestScreen({
    required super.group,
    required super.baseDir,
  });

  @override
  State<ChecklistDetailScreen> createState() => _Ticket03TestScreenState();
}

class _Ticket03TestScreenState extends ChecklistDetailController {
  int saveCount = 0;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }

  @override
  Future<void> saveGroupData() async {
    saveCount++;
  }
}

void main() {
  group('ChecklistDetailController — DailyTracker Ticket 03 (deleteDailyLog & deleteDailyLogsByMonth)', () {
    late DailySubject subject;
    late ChecklistGroup group;

    setUp(() {
      subject = DailySubject(
        subjectName: 'Test Tracker',
        progress: 'belum',
        isDailyTrackerEnabled: true,
        subMateri: [],
        dailyLogs: {
          '2026-10-01': [
            const DailyLogEntry(
              itemName: 'Item Okt 1',
              progress: 'selesai',
              itemType: 'normal',
              currentValue: 0,
              targetValue: 0,
            )
          ],
          '2026-10-15': [
            const DailyLogEntry(
              itemName: 'Item Okt 2',
              progress: 'belum',
              itemType: 'normal',
              currentValue: 0,
              targetValue: 0,
            )
          ],
          '2026-11-01': [
            const DailyLogEntry(
              itemName: 'Item Nov 1',
              progress: 'selesai',
              itemType: 'normal',
              currentValue: 0,
              targetValue: 0,
            )
          ],
          '2026-11-20': [
            const DailyLogEntry(
              itemName: 'Item Nov 2',
              progress: 'selesai',
              itemType: 'normal',
              currentValue: 0,
              targetValue: 0,
            )
          ],
          '2026-12-05': [
            const DailyLogEntry(
              itemName: 'Item Des 1',
              progress: 'belum',
              itemType: 'normal',
              currentValue: 0,
              targetValue: 0,
            )
          ],
        },
      );

      group = ChecklistGroup(
        id: 'g1',
        groupName: 'Grup 1',
        icon: '📝',
        allList: [
          ChecklistSection(sectionName: 'Seksi 1', items: [subject]),
        ],
      );
    });

    testWidgets('deleteDailyLog mengosongkan subject.dailyLogs menjadi {} dan memanggil saveGroupData', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: _Ticket03TestScreen(group: group, baseDir: '/tmp'),
      ));
      final state = tester.state<_Ticket03TestScreenState>(find.byType(_Ticket03TestScreen));

      expect(subject.dailyLogs.isNotEmpty, isTrue);

      await state.deleteDailyLog(subject);
      await tester.pumpAndSettle();

      expect(subject.dailyLogs, isEmpty);
      expect(subject.dailyLogs, equals({}));
      expect(state.saveCount, equals(1));
    });

    testWidgets('deleteDailyLogsByMonth dengan yearMonth = 2026-10 hanya menghapus entri Oktober', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: _Ticket03TestScreen(group: group, baseDir: '/tmp'),
      ));
      final state = tester.state<_Ticket03TestScreenState>(find.byType(_Ticket03TestScreen));

      await state.deleteDailyLogsByMonth(subject, '2026-10');
      await tester.pumpAndSettle();

      expect(subject.dailyLogs.containsKey('2026-10-01'), isFalse);
      expect(subject.dailyLogs.containsKey('2026-10-15'), isFalse);
      expect(subject.dailyLogs.containsKey('2026-11-01'), isTrue);
      expect(subject.dailyLogs.containsKey('2026-11-20'), isTrue);
      expect(subject.dailyLogs.containsKey('2026-12-05'), isTrue);
      expect(subject.dailyLogs.length, equals(3));
      expect(state.saveCount, equals(1));
    });

    testWidgets('deleteDailyLogsByMonth pada dailyLogs yang sudah kosong tidak menyebabkan error', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: _Ticket03TestScreen(group: group, baseDir: '/tmp'),
      ));
      final state = tester.state<_Ticket03TestScreenState>(find.byType(_Ticket03TestScreen));

      subject.dailyLogs.clear();

      expect(() async => await state.deleteDailyLogsByMonth(subject, '2026-10'), returnsNormally);
      await tester.pumpAndSettle();

      expect(subject.dailyLogs, isEmpty);
      expect(state.saveCount, equals(1));
    });

    testWidgets('deleteDailyLogsByMonth dengan format bulan yang tidak ada tidak menghapus apapun', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: _Ticket03TestScreen(group: group, baseDir: '/tmp'),
      ));
      final state = tester.state<_Ticket03TestScreenState>(find.byType(_Ticket03TestScreen));

      await state.deleteDailyLogsByMonth(subject, '2025-01');
      await tester.pumpAndSettle();

      expect(subject.dailyLogs.length, equals(5));
      expect(state.saveCount, equals(1));
    });
  });
}

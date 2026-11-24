import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/features/checklist/data/models/daily_model.dart';
import 'package:rutinitasku/features/checklist/presentation/checklist_detail_screen/checklist_detail_screen.dart';
import 'package:rutinitasku/features/checklist/presentation/checklist_detail_screen/controllers/checklist_detail_controller.dart';

class _HistoryEditDeleteTestScreen extends ChecklistDetailScreen {
  const _HistoryEditDeleteTestScreen({
    required super.group,
    required super.baseDir,
  });

  @override
  State<ChecklistDetailScreen> createState() => _HistoryEditDeleteTestScreenState();
}

class _HistoryEditDeleteTestScreenState extends ChecklistDetailController {
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
  group('ChecklistDetailController — editDailyLogEntry & deleteDailyLogEntry (Ticket 02)', () {
    late DailySubject subject;
    late ChecklistGroup group;

    setUp(() {
      subject = DailySubject(
        subjectName: 'Test Tracker Subject',
        progress: 'belum',
        isDailyTrackerEnabled: true,
        subMateri: [],
        dailyLogs: {
          '2026-11-20': [
            const DailyLogEntry(
              itemName: 'Sholat Subuh',
              progress: 'selesai',
              itemType: 'normal',
              currentValue: 0,
              targetValue: 0,
            ),
          ],
          '2026-11-21': [
            const DailyLogEntry(
              itemName: 'Membaca Buku',
              progress: 'sementara',
              itemType: 'progress',
              currentValue: 5,
              targetValue: 10,
            ),
          ],
          '2026-11-22': [
            const DailyLogEntry(
              itemName: 'Olahraga',
              progress: 'belum',
              itemType: 'normal',
              currentValue: 0,
              targetValue: 0,
            ),
          ],
        },
      );

      group = ChecklistGroup(
        id: 'group_test_02',
        groupName: 'Grup Pengujian',
        icon: '📊',
        allList: [
          ChecklistSection(sectionName: 'Seksi Utama', items: [subject]),
        ],
      );
    });

    testWidgets('editDailyLogEntry mengubah entries yang sesuai tanpa mengubah entries hari lain', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: _HistoryEditDeleteTestScreen(group: group, baseDir: '/tmp'),
      ));
      final state = tester.state<_HistoryEditDeleteTestScreenState>(find.byType(_HistoryEditDeleteTestScreen));

      final updatedEntries21 = [
        const DailyLogEntry(
          itemName: 'Membaca Buku',
          progress: 'selesai',
          itemType: 'progress',
          currentValue: 10,
          targetValue: 10,
        ),
      ];

      await state.editDailyLogEntry(subject, '2026-11-21', updatedEntries21);
      await tester.pumpAndSettle();

      // Periksa entry 2026-11-21 telah terupdate
      expect(subject.dailyLogs['2026-11-21']!.first.progress, equals('selesai'));
      expect(subject.dailyLogs['2026-11-21']!.first.currentValue, equals(10));

      // Periksa entry hari lain tetap utuh
      expect(subject.dailyLogs['2026-11-20']!.first.itemName, equals('Sholat Subuh'));
      expect(subject.dailyLogs['2026-11-20']!.first.progress, equals('selesai'));
      expect(subject.dailyLogs['2026-11-22']!.first.itemName, equals('Olahraga'));
      expect(subject.dailyLogs['2026-11-22']!.first.progress, equals('belum'));

      // saveGroupData dipanggil
      expect(state.saveCount, equals(1));
    });

    testWidgets('deleteDailyLogEntry menghapus key tanggal yang sesuai; key lain tetap ada', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: _HistoryEditDeleteTestScreen(group: group, baseDir: '/tmp'),
      ));
      final state = tester.state<_HistoryEditDeleteTestScreenState>(find.byType(_HistoryEditDeleteTestScreen));

      expect(subject.dailyLogs.containsKey('2026-11-21'), isTrue);
      expect(subject.dailyLogs.length, equals(3));

      await state.deleteDailyLogEntry(subject, '2026-11-21');
      await tester.pumpAndSettle();

      expect(subject.dailyLogs.containsKey('2026-11-21'), isFalse);
      expect(subject.dailyLogs.containsKey('2026-11-20'), isTrue);
      expect(subject.dailyLogs.containsKey('2026-11-22'), isTrue);
      expect(subject.dailyLogs.length, equals(2));

      // saveGroupData dipanggil
      expect(state.saveCount, equals(1));
    });

    testWidgets('deleteDailyLogEntry pada key yang tidak ada tetap memanggil save tanpa error', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: _HistoryEditDeleteTestScreen(group: group, baseDir: '/tmp'),
      ));
      final state = tester.state<_HistoryEditDeleteTestScreenState>(find.byType(_HistoryEditDeleteTestScreen));

      await state.deleteDailyLogEntry(subject, '2099-01-01');
      await tester.pumpAndSettle();

      expect(subject.dailyLogs.length, equals(3));
      expect(state.saveCount, equals(1));
    });
  });
}

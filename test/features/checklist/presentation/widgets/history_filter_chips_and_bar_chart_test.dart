import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/features/checklist/data/models/daily_model.dart';
import 'package:rutinitasku/features/checklist/presentation/daily_tracker_history_screen/widgets/history_bar_chart.dart';
import 'package:rutinitasku/features/checklist/presentation/daily_tracker_history_screen/widgets/history_filter_chips.dart';

void main() {
  group('HistoryFilterChips Widget Tests', () {
    testWidgets('merender 4 chip dengan label yang benar dan styling chip terpilih', (tester) async {
      HistoryFilterPreset currentPreset = HistoryFilterPreset.thisMonth;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return HistoryFilterChips(
                  selected: currentPreset,
                  onPresetChanged: (preset) {
                    setState(() {
                      currentPreset = preset;
                    });
                  },
                  onCustomRangeChanged: (_) {},
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Bulan Ini'), findsOneWidget);
      expect(find.text('7 Hari'), findsOneWidget);
      expect(find.text('30 Hari'), findsOneWidget);
      expect(find.text('Custom Range'), findsOneWidget);

      final monthChip = tester.widget<ChoiceChip>(
        find.ancestor(of: find.text('Bulan Ini'), matching: find.byType(ChoiceChip)),
      );
      expect(monthChip.selected, isTrue);

      final sevenDaysChip = tester.widget<ChoiceChip>(
        find.ancestor(of: find.text('7 Hari'), matching: find.byType(ChoiceChip)),
      );
      expect(sevenDaysChip.selected, isFalse);

      // Ketuk 7 Hari
      await tester.tap(find.text('7 Hari'));
      await tester.pumpAndSettle();

      expect(currentPreset, HistoryFilterPreset.last7Days);

      final updatedSevenDaysChip = tester.widget<ChoiceChip>(
        find.ancestor(of: find.text('7 Hari'), matching: find.byType(ChoiceChip)),
      );
      expect(updatedSevenDaysChip.selected, isTrue);
    });

    testWidgets('setelah customRange dipilih, label chip custom range menampilkan rentang tanggal', (tester) async {
      final range = DateTimeRange(
        start: DateTime(2026, 11, 10),
        end: DateTime(2026, 11, 20),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryFilterChips(
              selected: HistoryFilterPreset.custom,
              customRange: range,
              onPresetChanged: (_) {},
              onCustomRangeChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('10–20 Nov'), findsOneWidget);
      final customChip = tester.widget<ChoiceChip>(
        find.ancestor(of: find.text('10–20 Nov'), matching: find.byType(ChoiceChip)),
      );
      expect(customChip.selected, isTrue);
    });

    testWidgets('ketuk chip Custom Range membuka showDateRangePicker', (tester) async {
      DateTimeRange? pickedRange;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryFilterChips(
              selected: HistoryFilterPreset.thisMonth,
              onPresetChanged: (_) {},
              onCustomRangeChanged: (range) {
                pickedRange = range;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Custom Range'));
      await tester.pumpAndSettle();

      // Dialog date range picker terbuka
      expect(find.byType(DateRangePickerDialog), findsOneWidget);
      expect(pickedRange, isNull);
    });
  });

  group('HistoryBarChart Widget Tests', () {
    int countTotal(List<DailyLogEntry> entries) => entries.length;
    int countFinished(List<DailyLogEntry> entries) =>
        entries.where((e) => e.progress == 'selesai').length;

    testWidgets('merender empty state tanpa error saat dateKeys kosong', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryBarChart(
              dateKeys: const [],
              dailyLogs: const {},
              countTotal: countTotal,
              countFinished: countFinished,
            ),
          ),
        ),
      );

      expect(find.text('Tidak ada data untuk grafik pada rentang ini'), findsOneWidget);
      expect(find.byType(BarChart), findsNothing);
    });

    testWidgets('merender 5 bar dengan warna yang sesuai (100% teal, 0% grey)', (tester) async {
      final dateKeys = [
        '2026-11-01',
        '2026-11-02',
        '2026-11-03',
        '2026-11-04',
        '2026-11-05',
      ];

      final dailyLogs = {
        '2026-11-01': [
          const DailyLogEntry(
            itemName: 'Task 1',
            progress: 'selesai',
            itemType: 'normal',
            currentValue: 0,
            targetValue: 0,
          )
        ], // 100% -> teal
        '2026-11-02': [
          const DailyLogEntry(
            itemName: 'Task 1',
            progress: 'belum',
            itemType: 'normal',
            currentValue: 0,
            targetValue: 0,
          )
        ], // 0% -> grey.shade300
        '2026-11-03': [
          const DailyLogEntry(
            itemName: 'Task 1',
            progress: 'selesai',
            itemType: 'normal',
            currentValue: 0,
            targetValue: 0,
          ),
          const DailyLogEntry(
            itemName: 'Task 2',
            progress: 'belum',
            itemType: 'normal',
            currentValue: 0,
            targetValue: 0,
          ),
        ], // 50% -> teal.shade300
        '2026-11-04': [
          const DailyLogEntry(
            itemName: 'Task 1',
            progress: 'selesai',
            itemType: 'normal',
            currentValue: 0,
            targetValue: 0,
          ),
          const DailyLogEntry(
            itemName: 'Task 2',
            progress: 'belum',
            itemType: 'normal',
            currentValue: 0,
            targetValue: 0,
          ),
          const DailyLogEntry(
            itemName: 'Task 3',
            progress: 'belum',
            itemType: 'normal',
            currentValue: 0,
            targetValue: 0,
          ),
          const DailyLogEntry(
            itemName: 'Task 4',
            progress: 'belum',
            itemType: 'normal',
            currentValue: 0,
            targetValue: 0,
          ),
        ], // 25% -> amber
        '2026-11-05': <DailyLogEntry>[], // 0% -> grey.shade300
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryBarChart(
              dateKeys: dateKeys,
              dailyLogs: dailyLogs,
              countTotal: countTotal,
              countFinished: countFinished,
            ),
          ),
        ),
      );

      expect(find.byType(BarChart), findsOneWidget);
      final barChartWidget = tester.widget<BarChart>(find.byType(BarChart));
      final barGroups = barChartWidget.data.barGroups;

      expect(barGroups.length, equals(5));

      // Bar 0: 100% -> Colors.teal
      expect(barGroups[0].barRods.first.toY, equals(100.0));
      expect(barGroups[0].barRods.first.color, equals(Colors.teal));

      // Bar 1: 0% -> Colors.grey.shade300
      expect(barGroups[1].barRods.first.toY, equals(0.0));
      expect(barGroups[1].barRods.first.color, equals(Colors.grey.shade300));

      // Bar 2: 50% -> Colors.teal.shade300
      expect(barGroups[2].barRods.first.toY, equals(50.0));
      expect(barGroups[2].barRods.first.color, equals(Colors.teal.shade300));

      // Bar 3: 25% -> Colors.amber
      expect(barGroups[3].barRods.first.toY, equals(25.0));
      expect(barGroups[3].barRods.first.color, equals(Colors.amber));

      // Bar 4: empty (0%) -> Colors.grey.shade300
      expect(barGroups[4].barRods.first.toY, equals(0.0));
      expect(barGroups[4].barRods.first.color, equals(Colors.grey.shade300));
    });
  });
}

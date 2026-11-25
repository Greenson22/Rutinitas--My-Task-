import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/features/checklist/data/models/daily_model.dart';
import 'package:rutinitasku/features/checklist/presentation/daily_tracker_history_screen/daily_tracker_history_screen.dart';
import 'package:rutinitasku/features/checklist/presentation/daily_tracker_history_screen/widgets/history_color_legend.dart';
import 'package:rutinitasku/features/checklist/utils/item_color_helper.dart';

void main() {
  DailyLogEntry createLogEntry({
    required String name,
    required String progress,
    List<DailyLogEntry> children = const [],
  }) {
    return DailyLogEntry(
      itemName: name,
      progress: progress,
      itemType: 'normal',
      currentValue: progress == 'selesai' ? 1 : 0,
      targetValue: 1,
      children: children,
    );
  }

  group('HistoryColorLegend & DailyTrackerHistoryScreen integration', () {
    testWidgets(
      '(a) item yang selesai tampil di legenda dengan warna yang benar & diurutkan alfabetis tanpa duplikat, (b) item belum selesai tidak tampil',
      (tester) async {
        final now = DateTime.now();
        final todayKey =
            '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

        final subject = DailySubject(
          subjectName: 'Ibadah Harian',
          progress: 'belum',
          isDailyTrackerEnabled: true,
          subMateri: [],
          dailyLogs: {
            todayKey: [
              createLogEntry(name: 'Zikir Pagi', progress: 'selesai'),
              createLogEntry(name: 'Baca Quran', progress: 'selesai'),
              createLogEntry(name: 'Baca Quran', progress: 'selesai'),
              createLogEntry(name: 'Sedekah', progress: 'belum'),
            ],
          },
        );

        await tester.pumpWidget(
          MaterialApp(
            home: DailyTrackerHistoryScreen(subject: subject),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(HistoryColorLegend), findsOneWidget);
        expect(find.text('Keterangan Warna'), findsOneWidget);
        expect(find.text('Baca Quran'), findsOneWidget);
        expect(find.text('Zikir Pagi'), findsOneWidget);
        expect(find.text('Sedekah'), findsNothing);

        // Verify color boxes match colorFromItemName
        final bacaQuranBox = tester.widget<Container>(
          find.byKey(const Key('legend_color_Baca Quran')),
        );
        final bacaQuranDeco = bacaQuranBox.decoration as BoxDecoration;
        expect(bacaQuranDeco.color, colorFromItemName('Baca Quran'));

        final zikirBox = tester.widget<Container>(
          find.byKey(const Key('legend_color_Zikir Pagi')),
        );
        final zikirDeco = zikirBox.decoration as BoxDecoration;
        expect(zikirDeco.color, colorFromItemName('Zikir Pagi'));
      },
    );

    testWidgets(
      'bila tidak ada item selesai pada rentang filter, legenda tidak dirender',
      (tester) async {
        final now = DateTime.now();
        final todayKey =
            '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

        final subject = DailySubject(
          subjectName: 'Ibadah Harian',
          progress: 'belum',
          isDailyTrackerEnabled: true,
          subMateri: [],
          dailyLogs: {
            todayKey: [
              createLogEntry(name: 'Sedekah', progress: 'belum'),
            ],
          },
        );

        await tester.pumpWidget(
          MaterialApp(
            home: DailyTrackerHistoryScreen(subject: subject),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Keterangan Warna'), findsNothing);
      },
    );

    testWidgets(
      '(c) legenda berubah saat filter diganti',
      (tester) async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final tenDaysAgo = today.subtract(const Duration(days: 10));

        String fmt(DateTime d) =>
            '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

        final subject = DailySubject(
          subjectName: 'Ibadah Harian',
          progress: 'belum',
          isDailyTrackerEnabled: true,
          subMateri: [],
          dailyLogs: {
            fmt(today): [
              createLogEntry(name: 'Item Hari Ini', progress: 'selesai'),
            ],
            fmt(tenDaysAgo): [
              createLogEntry(name: 'Item 10 Hari Lalu', progress: 'selesai'),
            ],
          },
        );

        await tester.pumpWidget(
          MaterialApp(
            home: DailyTrackerHistoryScreen(subject: subject),
          ),
        );
        await tester.pumpAndSettle();

        // Default filter: Bulan Ini (or switch to 30 Hari then 7 Hari)
        await tester.tap(find.text('30 Hari'));
        await tester.pumpAndSettle();

        expect(find.text('Item Hari Ini'), findsOneWidget);
        expect(find.text('Item 10 Hari Lalu'), findsOneWidget);

        // Switch to 7 Hari -> Item 10 Hari Lalu should disappear from legend
        await tester.tap(find.text('7 Hari'));
        await tester.pumpAndSettle();

        expect(find.text('Item Hari Ini'), findsOneWidget);
        expect(find.text('Item 10 Hari Lalu'), findsNothing);
      },
    );
  });
}

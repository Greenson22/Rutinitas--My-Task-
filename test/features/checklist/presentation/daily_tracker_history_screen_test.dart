import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/features/checklist/data/models/daily_model.dart';
import 'package:rutinitasku/features/checklist/presentation/daily_tracker_history_screen/daily_tracker_history_screen.dart';

void main() {
  Widget buildTestWidget({
    required DailySubject subject,
    Future<void> Function()? onDeleteAll,
    Future<void> Function(String yearMonth)? onDeleteByMonth,
  }) {
    return MaterialApp(
      home: DailyTrackerHistoryScreen(
        subject: subject,
        onDeleteAll: onDeleteAll,
        onDeleteByMonth: onDeleteByMonth,
      ),
    );
  }

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

  group('DailyTrackerHistoryScreen — Ticket 06', () {
    testWidgets('menampilkan AppBar dengan nama card sebagai judul', (tester) async {
      final subject = DailySubject(
        subjectName: 'Rutinitas Pagi',
        progress: 'belum',
        isDailyTrackerEnabled: true,
        subMateri: [],
        dailyLogs: {},
      );

      await tester.pumpWidget(buildTestWidget(subject: subject));
      await tester.pumpAndSettle();

      expect(find.text('Rutinitas Pagi'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('empty state tampil ketika dailyLogs kosong', (tester) async {
      final subject = DailySubject(
        subjectName: 'Rutinitas Pagi',
        progress: 'belum',
        isDailyTrackerEnabled: true,
        subMateri: [],
        dailyLogs: {},
      );

      await tester.pumpWidget(buildTestWidget(subject: subject));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('daily_tracker_history_empty')), findsOneWidget);
      expect(
        find.textContaining('Belum ada data tersimpan'),
        findsOneWidget,
      );
    });

    testWidgets('daftar tanggal tampil sesuai data dailyLogs diurutkan descending dengan ringkasan', (tester) async {
      final subject = DailySubject(
        subjectName: 'Ibadah Harian',
        progress: 'belum',
        isDailyTrackerEnabled: true,
        subMateri: [],
        dailyLogs: {
          '2026-11-20': [
            createLogEntry(name: 'Tugas 1', progress: 'selesai'),
            createLogEntry(name: 'Tugas 2', progress: 'belum'),
          ],
          '2026-11-24': [
            createLogEntry(
              name: 'Parent',
              progress: 'belum',
              children: [
                createLogEntry(name: 'Child 1', progress: 'selesai'),
                createLogEntry(name: 'Child 2', progress: 'selesai'),
              ],
            ),
          ],
          '2026-11-22': [
            createLogEntry(name: 'Tugas A', progress: 'selesai'),
          ],
        },
      );

      await tester.pumpWidget(buildTestWidget(subject: subject));
      await tester.pumpAndSettle();

      // Empty state tidak tampil
      expect(find.byKey(const Key('daily_tracker_history_empty')), findsNothing);

      // Daftar item tanggal harus ada 3
      final dateTileFinder = find.byKey(const Key('history_date_tile_2026-11-24'));
      expect(dateTileFinder, findsOneWidget);
      expect(find.byKey(const Key('history_date_tile_2026-11-22')), findsOneWidget);
      expect(find.byKey(const Key('history_date_tile_2026-11-20')), findsOneWidget);

      // Verifikasi urutan (2026-11-24 harus muncul paling atas/sebelum 2026-11-22 dan 2026-11-20)
      final topDatePos = tester.getTopLeft(find.byKey(const Key('history_date_tile_2026-11-24'))).dy;
      final midDatePos = tester.getTopLeft(find.byKey(const Key('history_date_tile_2026-11-22'))).dy;
      final bottomDatePos = tester.getTopLeft(find.byKey(const Key('history_date_tile_2026-11-20'))).dy;
      expect(topDatePos < midDatePos, isTrue);
      expect(midDatePos < bottomDatePos, isTrue);

      // Verifikasi ringkasan:
      // 2026-11-24: 2 selesai / 3 total (Parent + 2 children)
      expect(find.text('2 / 3 Selesai'), findsOneWidget);
      // 2026-11-22: 1 selesai / 1 total
      expect(find.text('1 / 1 Selesai'), findsOneWidget);
      // 2026-11-20: 1 selesai / 2 total
      expect(find.text('1 / 2 Selesai'), findsOneWidget);
    });

    testWidgets('mengetuk tanggal menampilkan detail snapshot read-only secara rekursif', (tester) async {
      final subject = DailySubject(
        subjectName: 'Ibadah Harian',
        progress: 'belum',
        isDailyTrackerEnabled: true,
        subMateri: [],
        dailyLogs: {
          '2026-11-24': [
            createLogEntry(
              name: 'Subjek Bertingkat',
              progress: 'belum',
              children: [
                createLogEntry(name: 'Anak 1 Selesai', progress: 'selesai'),
                createLogEntry(name: 'Anak 2 Belum', progress: 'belum'),
              ],
            ),
          ],
        },
      );

      await tester.pumpWidget(buildTestWidget(subject: subject));
      await tester.pumpAndSettle();

      // Ketuk tile tanggal 2026-11-24
      await tester.tap(find.byKey(const Key('history_date_tile_2026-11-24')));
      await tester.pumpAndSettle();

      // Detail snapshot muncul
      expect(find.text('Subjek Bertingkat'), findsOneWidget);
      expect(find.text('Anak 1 Selesai'), findsOneWidget);
      expect(find.text('Anak 2 Belum'), findsOneWidget);

      // Memastikan ada indikasi visual selesai (ikon centang) dan belum
      expect(find.byKey(const Key('status_icon_done')), findsWidgets);
      expect(find.byKey(const Key('status_icon_not_done')), findsWidgets);
    });

    testWidgets('setelah aksi Hapus semua history dengan konfirmasi, daftar menjadi kosong & empty state tampil', (tester) async {
      int deleteCallCount = 0;
      final subject = DailySubject(
        subjectName: 'Ibadah Harian',
        progress: 'belum',
        isDailyTrackerEnabled: true,
        subMateri: [],
        dailyLogs: {
          '2026-11-24': [createLogEntry(name: 'Item 1', progress: 'selesai')],
        },
      );

      await tester.pumpWidget(buildTestWidget(
        subject: subject,
        onDeleteAll: () async {
          deleteCallCount++;
          subject.dailyLogs.clear();
        },
      ));
      await tester.pumpAndSettle();

      // Buka popup menu di AppBar
      await tester.tap(find.byKey(const Key('btn_history_menu')));
      await tester.pumpAndSettle();

      // Pilih 'Hapus semua history'
      await tester.tap(find.text('Hapus semua history'));
      await tester.pumpAndSettle();

      // Dialog konfirmasi muncul
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Hapus Semua Riwayat?'), findsOneWidget);

      // Tekan tombol 'Hapus'
      await tester.tap(find.byKey(const Key('btn_confirm_delete_all')));
      await tester.pumpAndSettle();

      expect(deleteCallCount, 1);
      expect(subject.dailyLogs.isEmpty, isTrue);
      expect(find.byKey(const Key('daily_tracker_history_empty')), findsOneWidget);
    });

    testWidgets('setelah aksi Hapus per bulan, hanya entri bulan tersebut yang hilang; bulan lain tetap ada', (tester) async {
      String? deletedMonth;
      final subject = DailySubject(
        subjectName: 'Ibadah Harian',
        progress: 'belum',
        isDailyTrackerEnabled: true,
        subMateri: [],
        dailyLogs: {
          '2026-11-24': [createLogEntry(name: 'Nov Item', progress: 'selesai')],
          '2026-10-15': [createLogEntry(name: 'Okt Item', progress: 'selesai')],
        },
      );

      await tester.pumpWidget(buildTestWidget(
        subject: subject,
        onDeleteByMonth: (month) async {
          deletedMonth = month;
          subject.dailyLogs.removeWhere((k, _) => k.startsWith(month));
        },
      ));
      await tester.pumpAndSettle();

      // Buka popup menu
      await tester.tap(find.byKey(const Key('btn_history_menu')));
      await tester.pumpAndSettle();

      // Pilih 'Hapus per bulan'
      await tester.tap(find.text('Hapus per bulan'));
      await tester.pumpAndSettle();

      // Dialog pilihan bulan muncul
      expect(find.text('Pilih Bulan yang Dihapus'), findsOneWidget);
      expect(find.byKey(const Key('month_option_2026-10')), findsOneWidget);
      expect(find.byKey(const Key('month_option_2026-11')), findsOneWidget);

      // Pilih bulan 2026-10
      await tester.tap(find.byKey(const Key('month_option_2026-10')));
      await tester.pumpAndSettle();

      // Dialog konfirmasi hapus bulan
      expect(find.text('Konfirmasi Hapus Bulan'), findsOneWidget);
      await tester.tap(find.byKey(const Key('btn_confirm_delete_month')));
      await tester.pumpAndSettle();

      expect(deletedMonth, '2026-10');
      expect(subject.dailyLogs.containsKey('2026-10-15'), isFalse);
      expect(subject.dailyLogs.containsKey('2026-11-24'), isTrue);

      // Di ListView hanya tersisa entri November
      expect(find.byKey(const Key('history_date_tile_2026-10-15')), findsNothing);
      expect(find.byKey(const Key('history_date_tile_2026-11-24')), findsOneWidget);
    });
  });
}

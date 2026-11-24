import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/features/checklist/data/models/daily_model.dart';
import 'package:rutinitasku/features/checklist/presentation/daily_tracker_history_screen/daily_tracker_history_screen.dart';
import 'package:rutinitasku/features/checklist/presentation/daily_tracker_history_screen/widgets/edit_history_entry_sheet.dart';

void main() {
  Widget buildTestWidget({
    required DailySubject subject,
    Future<void> Function()? onDeleteAll,
    Future<void> Function(String yearMonth)? onDeleteByMonth,
    Future<void> Function(String dateKey, List<DailyLogEntry> updated)? onEditEntry,
    Future<void> Function(String dateKey)? onDeleteEntry,
  }) {
    return MaterialApp(
      home: DailyTrackerHistoryScreen(
        subject: subject,
        onDeleteAll: onDeleteAll,
        onDeleteByMonth: onDeleteByMonth,
        onEditEntry: onEditEntry,
        onDeleteEntry: onDeleteEntry,
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

  group('DailyTrackerHistoryScreen — Ticket 06 (Existing & Regressions)', () {
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
      final now = DateTime.now();
      final yearStr = now.year.toString().padLeft(4, '0');
      final monthStr = now.month.toString().padLeft(2, '0');
      final d20 = '$yearStr-$monthStr-20';
      final d22 = '$yearStr-$monthStr-22';
      final d24 = '$yearStr-$monthStr-24';

      final subject = DailySubject(
        subjectName: 'Ibadah Harian',
        progress: 'belum',
        isDailyTrackerEnabled: true,
        subMateri: [],
        dailyLogs: {
          d20: [
            createLogEntry(name: 'Tugas 1', progress: 'selesai'),
            createLogEntry(name: 'Tugas 2', progress: 'belum'),
          ],
          d24: [
            createLogEntry(
              name: 'Parent',
              progress: 'belum',
              children: [
                createLogEntry(name: 'Child 1', progress: 'selesai'),
                createLogEntry(name: 'Child 2', progress: 'selesai'),
              ],
            ),
          ],
          d22: [
            createLogEntry(name: 'Tugas A', progress: 'selesai'),
          ],
        },
      );

      await tester.pumpWidget(buildTestWidget(subject: subject));
      await tester.pumpAndSettle();

      // Empty state tidak tampil
      expect(find.byKey(const Key('daily_tracker_history_empty')), findsNothing);

      // Daftar item tanggal harus ada 3
      final dateTileFinder = find.byKey(Key('history_date_tile_$d24'));
      expect(dateTileFinder, findsOneWidget);
      expect(find.byKey(Key('history_date_tile_$d22')), findsOneWidget);
      expect(find.byKey(Key('history_date_tile_$d20')), findsOneWidget);

      // Verifikasi urutan (d24 harus muncul paling atas/sebelum d22 dan d20)
      final topDatePos = tester.getTopLeft(find.byKey(Key('history_date_tile_$d24'))).dy;
      final midDatePos = tester.getTopLeft(find.byKey(Key('history_date_tile_$d22'))).dy;
      final bottomDatePos = tester.getTopLeft(find.byKey(Key('history_date_tile_$d20'))).dy;
      expect(topDatePos < midDatePos, isTrue);
      expect(midDatePos < bottomDatePos, isTrue);

      // Verifikasi ringkasan (hanya leaf nodes yang dihitung, parent diabaikan)
      expect(find.text('2 / 2 Selesai'), findsOneWidget); // d24: Child 1, Child 2
      expect(find.text('1 / 1 Selesai'), findsOneWidget); // d22: Tugas A
      expect(find.text('1 / 2 Selesai'), findsOneWidget); // d20: Tugas 1, Tugas 2
    });

    testWidgets('mengetuk tanggal menampilkan detail snapshot read-only secara rekursif', (tester) async {
      final now = DateTime.now();
      final yearStr = now.year.toString().padLeft(4, '0');
      final monthStr = now.month.toString().padLeft(2, '0');
      final d24 = '$yearStr-$monthStr-24';

      final subject = DailySubject(
        subjectName: 'Ibadah Harian',
        progress: 'belum',
        isDailyTrackerEnabled: true,
        subMateri: [],
        dailyLogs: {
          d24: [
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

      // Ketuk tile tanggal
      await tester.tap(find.byKey(Key('history_date_tile_$d24')));
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
      final now = DateTime.now();
      final yearStr = now.year.toString().padLeft(4, '0');
      final monthStr = now.month.toString().padLeft(2, '0');
      final currentMonthKey = '$yearStr-$monthStr';
      final prevMonth = now.month == 1 ? 12 : now.month - 1;
      final prevYear = now.month == 1 ? now.year - 1 : now.year;
      final prevMonthKey = '${prevYear.toString().padLeft(4, '0')}-${prevMonth.toString().padLeft(2, '0')}';

      String? deletedMonth;
      final subject = DailySubject(
        subjectName: 'Ibadah Harian',
        progress: 'belum',
        isDailyTrackerEnabled: true,
        subMateri: [],
        dailyLogs: {
          '$currentMonthKey-24': [createLogEntry(name: 'Current Month Item', progress: 'selesai')],
          '$prevMonthKey-15': [createLogEntry(name: 'Prev Month Item', progress: 'selesai')],
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
      expect(find.byKey(Key('month_option_$prevMonthKey')), findsOneWidget);
      expect(find.byKey(Key('month_option_$currentMonthKey')), findsOneWidget);

      // Pilih bulan sebelumnya
      await tester.tap(find.byKey(Key('month_option_$prevMonthKey')));
      await tester.pumpAndSettle();

      // Dialog konfirmasi hapus bulan
      expect(find.text('Konfirmasi Hapus Bulan'), findsOneWidget);
      await tester.tap(find.byKey(const Key('btn_confirm_delete_month')));
      await tester.pumpAndSettle();

      expect(deletedMonth, prevMonthKey);
      expect(subject.dailyLogs.containsKey('$prevMonthKey-15'), isFalse);
      expect(subject.dailyLogs.containsKey('$currentMonthKey-24'), isTrue);

      // Di ListView hanya tersisa entri current month
      expect(find.byKey(Key('history_date_tile_$prevMonthKey-15')), findsNothing);
      expect(find.byKey(Key('history_date_tile_$currentMonthKey-24')), findsOneWidget);
    });
  });

  group('DailyTrackerHistoryScreen — Ticket 05 (Filter & Edit/Delete per Entry)', () {
    testWidgets('default filter = Bulan Ini; hanya entry bulan ini yang tampil saat dibuka', (tester) async {
      final now = DateTime.now();
      final yearStr = now.year.toString().padLeft(4, '0');
      final monthStr = now.month.toString().padLeft(2, '0');
      final prevMonth = now.month == 1 ? 12 : now.month - 1;
      final prevYear = now.month == 1 ? now.year - 1 : now.year;
      final prevMonthKey = '${prevYear.toString().padLeft(4, '0')}-${prevMonth.toString().padLeft(2, '0')}';

      final subject = DailySubject(
        subjectName: 'Test Tracker',
        progress: 'belum',
        isDailyTrackerEnabled: true,
        subMateri: [],
        dailyLogs: {
          '$yearStr-$monthStr-01': [createLogEntry(name: 'Item Bulan Ini', progress: 'selesai')],
          '$prevMonthKey-15': [createLogEntry(name: 'Item Bulan Lalu', progress: 'selesai')],
        },
      );

      await tester.pumpWidget(buildTestWidget(subject: subject));
      await tester.pumpAndSettle();

      // Item bulan ini tampil
      expect(find.byKey(Key('history_date_tile_$yearStr-$monthStr-01')), findsOneWidget);
      // Item bulan lalu tidak tampil karena filter Bulan Ini
      expect(find.byKey(Key('history_date_tile_$prevMonthKey-15')), findsNothing);

      // Ubah filter ke '30 Hari'
      await tester.tap(find.text('30 Hari'));
      await tester.pumpAndSettle();

      // Sekarang kedua item tampil (atau item dalam 30 hari terakhir)
      expect(find.byKey(Key('history_date_tile_$yearStr-$monthStr-01')), findsOneWidget);
    });

    testWidgets('long-press card tanggal menampilkan menu konteks dengan opsi Edit dan Hapus', (tester) async {
      final now = DateTime.now();
      final todayKey = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final subject = DailySubject(
        subjectName: 'Test Tracker',
        progress: 'belum',
        isDailyTrackerEnabled: true,
        subMateri: [],
        dailyLogs: {
          todayKey: [createLogEntry(name: 'Tugas Hari Ini', progress: 'selesai')],
        },
      );

      await tester.pumpWidget(buildTestWidget(subject: subject));
      await tester.pumpAndSettle();

      // Long-press pada card tanggal
      await tester.longPress(find.byKey(Key('history_date_tile_$todayKey')));
      await tester.pumpAndSettle();

      // Menu konteks muncul
      expect(find.text('Edit Entry'), findsOneWidget);
      expect(find.text('Hapus Entry'), findsOneWidget);
    });

    testWidgets('memilih Edit dari menu membuka EditHistoryEntrySheet, dan simpan memanggil onEditEntry', (tester) async {
      final now = DateTime.now();
      final todayKey = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      String? editedKey;
      List<DailyLogEntry>? savedEntries;

      final subject = DailySubject(
        subjectName: 'Test Tracker',
        progress: 'belum',
        isDailyTrackerEnabled: true,
        subMateri: [],
        dailyLogs: {
          todayKey: [createLogEntry(name: 'Tugas Awal', progress: 'belum')],
        },
      );

      await tester.pumpWidget(buildTestWidget(
        subject: subject,
        onEditEntry: (dateKey, updated) async {
          editedKey = dateKey;
          savedEntries = updated;
          subject.dailyLogs[dateKey] = updated;
        },
      ));
      await tester.pumpAndSettle();

      // Long-press pada card tanggal
      await tester.longPress(find.byKey(Key('history_date_tile_$todayKey')));
      await tester.pumpAndSettle();

      // Tap Edit Entry
      await tester.tap(find.text('Edit Entry'));
      await tester.pumpAndSettle();

      // EditHistoryEntrySheet terbuka
      expect(find.byType(EditHistoryEntrySheet), findsOneWidget);
      expect(find.text('Tugas Awal'), findsOneWidget);

      // Ubah status ke 'Selesai'
      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();

      // Tekan Simpan
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      // Sheet tertutup & callback dipanggil
      expect(find.byType(EditHistoryEntrySheet), findsNothing);
      expect(editedKey, equals(todayKey));
      expect(savedEntries, isNotNull);
      expect(savedEntries!.first.progress, equals('selesai'));

      // Tampilan ringkasan card terupdate (1 / 1 Selesai)
      expect(find.text('1 / 1 Selesai'), findsOneWidget);
    });

    testWidgets('memilih Hapus dari menu menampilkan dialog konfirmasi dan memanggil onDeleteEntry', (tester) async {
      final now = DateTime.now();
      final todayKey = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      String? deletedKey;

      final subject = DailySubject(
        subjectName: 'Test Tracker',
        progress: 'belum',
        isDailyTrackerEnabled: true,
        subMateri: [],
        dailyLogs: {
          todayKey: [createLogEntry(name: 'Tugas Hari Ini', progress: 'selesai')],
        },
      );

      await tester.pumpWidget(buildTestWidget(
        subject: subject,
        onDeleteEntry: (dateKey) async {
          deletedKey = dateKey;
          subject.dailyLogs.remove(dateKey);
        },
      ));
      await tester.pumpAndSettle();

      // Long-press
      await tester.longPress(find.byKey(Key('history_date_tile_$todayKey')));
      await tester.pumpAndSettle();

      // Tap Hapus Entry
      await tester.tap(find.text('Hapus Entry'));
      await tester.pumpAndSettle();

      // Dialog konfirmasi hapus muncul
      expect(find.text('Konfirmasi Hapus Entry'), findsOneWidget);

      // Tekan tombol Hapus
      await tester.tap(find.byKey(const Key('btn_confirm_delete_entry')));
      await tester.pumpAndSettle();

      expect(deletedKey, equals(todayKey));
      expect(subject.dailyLogs.containsKey(todayKey), isFalse);
      expect(find.byKey(Key('history_date_tile_$todayKey')), findsNothing);
    });

    testWidgets('tap biasa pada card tetap membuka detail snapshot read-only', (tester) async {
      final now = DateTime.now();
      final todayKey = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final subject = DailySubject(
        subjectName: 'Test Tracker',
        progress: 'belum',
        isDailyTrackerEnabled: true,
        subMateri: [],
        dailyLogs: {
          todayKey: [createLogEntry(name: 'Item Biasa', progress: 'selesai')],
        },
      );

      await tester.pumpWidget(buildTestWidget(subject: subject));
      await tester.pumpAndSettle();

      // Tap biasa (bukan long-press)
      await tester.tap(find.byKey(Key('history_date_tile_$todayKey')));
      await tester.pumpAndSettle();

      // Detail snapshot muncul (bukan menu Edit/Hapus)
      expect(find.text('Edit Entry'), findsNothing);
      expect(find.text('Item Biasa'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });
  });
}

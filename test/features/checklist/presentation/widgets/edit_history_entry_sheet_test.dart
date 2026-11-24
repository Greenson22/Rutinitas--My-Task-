import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/features/checklist/data/models/daily_model.dart';
import 'package:rutinitasku/features/checklist/presentation/daily_tracker_history_screen/widgets/edit_history_entry_sheet.dart';

void main() {
  group('EditHistoryEntrySheet Widget Tests', () {
    late List<DailyLogEntry> sampleEntries;

    setUp(() {
      sampleEntries = [
        const DailyLogEntry(
          itemName: 'Sholat Subuh',
          progress: 'selesai',
          itemType: 'normal',
          currentValue: 0,
          targetValue: 0,
        ),
        const DailyLogEntry(
          itemName: 'Membaca Quran',
          progress: 'sementara',
          itemType: 'progress',
          currentValue: 5,
          targetValue: 10,
          children: [
            DailyLogEntry(
              itemName: 'Surat Al-Baqarah',
              progress: 'selesai',
              itemType: 'normal',
              currentValue: 0,
              targetValue: 0,
            ),
          ],
        ),
        const DailyLogEntry(
          itemName: 'Olahraga Pagi',
          progress: 'belum',
          itemType: 'countdown',
          currentValue: 20,
          targetValue: 30,
        ),
      ];
    });

    testWidgets('merender semua item (level 1 dan child) dengan judul tanggal terformat', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditHistoryEntrySheet(
              dateKey: '2026-11-24',
              entries: sampleEntries,
              onSave: (_) async {},
            ),
          ),
        ),
      );

      // Judul tanggal
      expect(find.text('24 November 2026'), findsOneWidget);

      // Item names
      expect(find.text('Sholat Subuh'), findsOneWidget);
      expect(find.text('Membaca Quran'), findsOneWidget);
      expect(find.text('Surat Al-Baqarah'), findsOneWidget);
      expect(find.text('Olahraga Pagi'), findsOneWidget);

      // Input nilai progress & countdown
      expect(find.text('5'), findsOneWidget);
      expect(find.text('/ 10'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
      expect(find.text('/ 30'), findsOneWidget);

      // Tombol aksi
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Simpan'), findsOneWidget);
    });

    testWidgets('mengubah status item dan nilai lalu menekan Simpan memanggil onSave dengan perubahan', (tester) async {
      List<DailyLogEntry>? savedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditHistoryEntrySheet(
              dateKey: '2026-11-24',
              entries: sampleEntries,
              onSave: (updated) async {
                savedResult = updated;
              },
            ),
          ),
        ),
      );

      // Ubah status Sholat Subuh dari 'selesai' ke 'belum'
      final belumButtons = find.text('Belum');
      // Sholat Subuh adalah entry pertama, jadi segmen 'Belum' pertamanya
      await tester.tap(belumButtons.first);
      await tester.pumpAndSettle();

      // Ubah nilai Membaca Quran dari 5 ke 8
      final progressField = find.byType(TextField).first;
      await tester.enterText(progressField, '8');
      await tester.pumpAndSettle();

      // Tekan Simpan
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      expect(savedResult, isNotNull);
      expect(savedResult!.length, equals(3));

      // Sholat Subuh berubah ke 'belum'
      expect(savedResult![0].itemName, equals('Sholat Subuh'));
      expect(savedResult![0].progress, equals('belum'));

      // Membaca Quran currentValue berubah ke 8
      expect(savedResult![1].itemName, equals('Membaca Quran'));
      expect(savedResult![1].currentValue, equals(8));
      expect(savedResult![1].children.first.progress, equals('selesai'));

      // Olahraga Pagi tetap belum dan 20
      expect(savedResult![2].progress, equals('belum'));
      expect(savedResult![2].currentValue, equals(20));
    });

    testWidgets('menekan Batal tidak memanggil onSave', (tester) async {
      bool onSaveCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditHistoryEntrySheet(
              dateKey: '2026-11-24',
              entries: sampleEntries,
              onSave: (_) async {
                onSaveCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(onSaveCalled, isFalse);
    });

    testWidgets('menekan tombol close [X] menutup sheet tanpa memanggil onSave', (tester) async {
      bool onSaveCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    EditHistoryEntrySheet.show(
                      context: context,
                      dateKey: '2026-11-24',
                      entries: sampleEntries,
                      onSave: (_) async {
                        onSaveCalled = true;
                      },
                    );
                  },
                  child: const Text('Buka'),
                );
              },
            ),
          ),
        ),
      );

      // Buka bottom sheet
      await tester.tap(find.text('Buka'));
      await tester.pumpAndSettle();

      expect(find.byType(EditHistoryEntrySheet), findsOneWidget);

      // Tekan icon close
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byType(EditHistoryEntrySheet), findsNothing);
      expect(onSaveCalled, isFalse);
    });

    testWidgets('menampilkan badge Progress dan Hitung Mundur sesuai tipe item serta label input yang benar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditHistoryEntrySheet(
              dateKey: '2026-11-24',
              entries: sampleEntries,
              onSave: (_) async {},
            ),
          ),
        ),
      );

      // Badge Progress tampil untuk item progress
      expect(find.text('Progress'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);

      // Badge Hitung Mundur tampil untuk item countdown
      expect(find.text('Hitung Mundur'), findsOneWidget);
      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);

      // Label input nilai sesuai tipe
      expect(find.text('Nilai saat ini:'), findsOneWidget);
      expect(find.text('Sisa:'), findsOneWidget);
      expect(find.text('Nilai:'), findsNothing);
    });

    testWidgets('tidak menampilkan badge apapun untuk item bertipe normal', (tester) async {
      const normalOnlyEntries = [
        DailyLogEntry(
          itemName: 'Sholat Subuh',
          progress: 'selesai',
          itemType: 'normal',
          currentValue: 0,
          targetValue: 0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditHistoryEntrySheet(
              dateKey: '2026-11-24',
              entries: normalOnlyEntries,
              onSave: (_) async {},
            ),
          ),
        ),
      );

      expect(find.text('Progress'), findsNothing);
      expect(find.text('Hitung Mundur'), findsNothing);
      expect(find.byIcon(Icons.trending_up), findsNothing);
      expect(find.byIcon(Icons.timer_outlined), findsNothing);
    });

    testWidgets('menampilkan badge dan label input untuk sub-item (children) bertipe progress dan countdown', (tester) async {
      const nestedEntries = [
        DailyLogEntry(
          itemName: 'Parent Normal',
          progress: 'sementara',
          itemType: 'normal',
          currentValue: 0,
          targetValue: 0,
          children: [
            DailyLogEntry(
              itemName: 'Child Progress',
              progress: 'sementara',
              itemType: 'progress',
              currentValue: 3,
              targetValue: 10,
            ),
            DailyLogEntry(
              itemName: 'Child Countdown',
              progress: 'belum',
              itemType: 'countdown',
              currentValue: 5,
              targetValue: 15,
            ),
          ],
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditHistoryEntrySheet(
              dateKey: '2026-11-24',
              entries: nestedEntries,
              onSave: (_) async {},
            ),
          ),
        ),
      );

      expect(find.text('Progress'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
      expect(find.text('Hitung Mundur'), findsOneWidget);
      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
      expect(find.text('Nilai saat ini:'), findsOneWidget);
      expect(find.text('Sisa:'), findsOneWidget);
    });
  });
}

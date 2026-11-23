import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/features/checklist/data/models/daily_model.dart';

void main() {
  group('DailySubject & DailyLogEntry Model Tests', () {
    test('DailySubject defaults: isDailyTrackerEnabled false, dailyLogs empty', () {
      final subject = DailySubject(
        subjectName: 'Rutinitas Pagi',
        progress: 'belum',
        subMateri: [],
      );

      expect(subject.isDailyTrackerEnabled, isFalse);
      expect(subject.dailyLogs, isEmpty);
      expect(subject.dailyLogs, isA<Map<String, List<DailyLogEntry>>>());
    });

    test('DailySubject.fromJson fallback on legacy JSON without new fields', () {
      final legacyJson = {
        'nama_materi': 'Materi Lama',
        'progress': 'belum',
        'sub_materi': [
          {
            'nama_materi': 'Child 1',
            'progress': 'selesai',
          }
        ],
        'backgroundColor': 4281166415,
        'textColor': 4294967295,
      };

      final subject = DailySubject.fromJson(legacyJson);
      expect(subject.subjectName, 'Materi Lama');
      expect(subject.isDailyTrackerEnabled, isFalse);
      expect(subject.dailyLogs, isEmpty);
      expect(subject.subMateri.length, 1);
      expect(subject.subMateri.first.subjectName, 'Child 1');
    });

    test('DailySubject round-trip toJson -> fromJson preserves isDailyTrackerEnabled and dailyLogs', () {
      final entry = DailyLogEntry(
        itemName: 'Sholat Subuh',
        progress: 'selesai',
        itemType: 'normal',
        currentValue: 0,
        targetValue: 0,
        children: [
          DailyLogEntry(
            itemName: 'Dzikir Pagi',
            progress: 'selesai',
            itemType: 'normal',
            currentValue: 0,
            targetValue: 0,
          ),
        ],
      );

      final subject = DailySubject(
        subjectName: 'Ibadah Harian',
        progress: 'selesai',
        subMateri: [],
        isDailyTrackerEnabled: true,
        dailyLogs: {
          '2026-11-23': [entry],
        },
      );

      final json = subject.toJson();
      expect(json['isDailyTrackerEnabled'], isTrue);
      expect(json['dailyLogs'], isNotNull);
      expect(json['dailyLogs']['2026-11-23'], isA<List>());

      final parsed = DailySubject.fromJson(json);
      expect(parsed.subjectName, subject.subjectName);
      expect(parsed.isDailyTrackerEnabled, isTrue);
      expect(parsed.dailyLogs.containsKey('2026-11-23'), isTrue);
      expect(parsed.dailyLogs['2026-11-23']!.length, 1);

      final parsedEntry = parsed.dailyLogs['2026-11-23']!.first;
      expect(parsedEntry.itemName, 'Sholat Subuh');
      expect(parsedEntry.progress, 'selesai');
      expect(parsedEntry.children.length, 1);
      expect(parsedEntry.children.first.itemName, 'Dzikir Pagi');
    });

    test('DailyLogEntry round-trip toJson -> fromJson preserves nested children', () {
      final entry = DailyLogEntry(
        itemName: 'Level 1',
        progress: 'sementara',
        itemType: 'progress',
        currentValue: 5,
        targetValue: 10,
        children: [
          DailyLogEntry(
            itemName: 'Level 2',
            progress: 'selesai',
            itemType: 'normal',
            currentValue: 0,
            targetValue: 0,
            children: [
              DailyLogEntry(
                itemName: 'Level 3',
                progress: 'selesai',
                itemType: 'countdown',
                currentValue: 0,
                targetValue: 3,
              ),
            ],
          ),
        ],
      );

      final json = entry.toJson();
      final parsed = DailyLogEntry.fromJson(json);

      expect(parsed.itemName, 'Level 1');
      expect(parsed.progress, 'sementara');
      expect(parsed.itemType, 'progress');
      expect(parsed.currentValue, 5);
      expect(parsed.targetValue, 10);
      expect(parsed.children.length, 1);

      final child2 = parsed.children.first;
      expect(child2.itemName, 'Level 2');
      expect(child2.children.length, 1);

      final child3 = child2.children.first;
      expect(child3.itemName, 'Level 3');
      expect(child3.itemType, 'countdown');
      expect(child3.currentValue, 0);
      expect(child3.targetValue, 3);
      expect(child3.children, isEmpty);
    });

    test('DailyLogEntry.fromSubSubjectItem recursive snapshot 3 level tree', () {
      final level3 = SubSubjectItem(
        subjectName: 'Item Lvl 3',
        progress: 'selesai',
        itemType: 'normal',
        currentValue: 1,
        targetValue: 1,
      );

      final level2 = SubSubjectItem(
        subjectName: 'Item Lvl 2',
        progress: 'sementara',
        itemType: 'countdown',
        currentValue: 2,
        targetValue: 5,
        subMateri: [level3],
      );

      final level1 = SubSubjectItem(
        subjectName: 'Item Lvl 1',
        progress: 'belum',
        itemType: 'progress',
        currentValue: 10,
        targetValue: 50,
        subMateri: [level2],
      );

      final snapshot = DailyLogEntry.fromSubSubjectItem(level1);

      // Verify Level 1
      expect(snapshot.itemName, 'Item Lvl 1');
      expect(snapshot.progress, 'belum');
      expect(snapshot.itemType, 'progress');
      expect(snapshot.currentValue, 10);
      expect(snapshot.targetValue, 50);
      expect(snapshot.children.length, 1);

      // Verify Level 2
      final snapLvl2 = snapshot.children.first;
      expect(snapLvl2.itemName, 'Item Lvl 2');
      expect(snapLvl2.progress, 'sementara');
      expect(snapLvl2.itemType, 'countdown');
      expect(snapLvl2.currentValue, 2);
      expect(snapLvl2.targetValue, 5);
      expect(snapLvl2.children.length, 1);

      // Verify Level 3
      final snapLvl3 = snapLvl2.children.first;
      expect(snapLvl3.itemName, 'Item Lvl 3');
      expect(snapLvl3.progress, 'selesai');
      expect(snapLvl3.itemType, 'normal');
      expect(snapLvl3.currentValue, 1);
      expect(snapLvl3.targetValue, 1);
      expect(snapLvl3.children, isEmpty);

      // Mutasi item asli tidak boleh mempengaruhi snapshot (deep snapshot)
      level1.subjectName = 'Berubah';
      level2.progress = 'selesai';
      level3.currentValue = 999;

      expect(snapshot.itemName, 'Item Lvl 1');
      expect(snapLvl2.progress, 'sementara');
      expect(snapLvl3.currentValue, 1);
    });
  });
}

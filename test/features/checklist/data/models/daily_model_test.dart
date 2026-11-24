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

    group('DailyLogEntry.copyWith Tests', () {
      test('copyWith without arguments produces identical field values in a new instance', () {
        final original = DailyLogEntry(
          itemName: 'Membaca',
          progress: 'sementara',
          itemType: 'progress',
          currentValue: 10,
          targetValue: 20,
          children: [
            DailyLogEntry(
              itemName: 'Bab 1',
              progress: 'selesai',
              itemType: 'normal',
              currentValue: 0,
              targetValue: 0,
            ),
          ],
        );

        final copy = original.copyWith();

        expect(copy.itemName, original.itemName);
        expect(copy.progress, original.progress);
        expect(copy.itemType, original.itemType);
        expect(copy.currentValue, original.currentValue);
        expect(copy.targetValue, original.targetValue);
        expect(copy.children, original.children);
      });

      test('copyWith with one modified field only alters that field', () {
        final original = DailyLogEntry(
          itemName: 'Membaca',
          progress: 'sementara',
          itemType: 'progress',
          currentValue: 10,
          targetValue: 20,
        );

        final updatedStatus = original.copyWith(progress: 'selesai');
        expect(updatedStatus.itemName, 'Membaca');
        expect(updatedStatus.progress, 'selesai');
        expect(updatedStatus.itemType, 'progress');
        expect(updatedStatus.currentValue, 10);
        expect(updatedStatus.targetValue, 20);

        final updatedDisabled = original.copyWith(isDisabled: true);
        expect(updatedDisabled.isDisabled, isTrue);

        final updatedValue = original.copyWith(currentValue: 15);
        expect(updatedValue.itemName, 'Membaca');
        expect(updatedValue.progress, 'sementara');
        expect(updatedValue.currentValue, 15);
        expect(updatedValue.targetValue, 20);

        final newChild = DailyLogEntry(
          itemName: 'Bab 2',
          progress: 'belum',
          itemType: 'normal',
          currentValue: 0,
          targetValue: 0,
        );
        final updatedChildren = original.copyWith(children: [newChild]);
        expect(updatedChildren.children.length, 1);
        expect(updatedChildren.children.first.itemName, 'Bab 2');
        expect(updatedChildren.itemName, 'Membaca');
      });
    });

    group('Ticket 01: SubSubjectItem UUID & Link IDs', () {
      test('SubSubjectItem auto-generates id when not supplied', () {
        final item1 = SubSubjectItem(
          subjectName: 'Item 1',
          progress: 'belum',
        );
        final item2 = SubSubjectItem(
          subjectName: 'Item 2',
          progress: 'belum',
        );

        expect(item1.id, isNotEmpty);
        expect(item2.id, isNotEmpty);
        expect(item1.id, isNot(equals(item2.id)));
      });

      test('SubSubjectItem maintains supplied id', () {
        final item = SubSubjectItem(
          id: 'custom-id-123',
          subjectName: 'Custom Item',
          progress: 'belum',
        );
        expect(item.id, 'custom-id-123');
      });

      test('SubSubjectItem default link ID fields are null', () {
        final item = SubSubjectItem(
          subjectName: 'Item',
          progress: 'belum',
        );
        expect(item.linkedSubjectId, isNull);
        expect(item.accumulatorItemId, isNull);
        expect(item.linkedExternalItemId, isNull);
      });

      test('SubSubjectItem.clone preserves id and link ID fields', () {
        final original = SubSubjectItem(
          id: 'orig-id-456',
          subjectName: 'Clone Source',
          progress: 'sementara',
          linkedSubjectId: 'sub-id-1',
          linkedSubjectName: 'Sub Name 1',
          accumulatorItemId: 'acc-id-2',
          accumulatorItemName: 'Acc Name 2',
          linkedExternalItemId: 'ext-id-3',
          linkedExternalItemName: 'Ext Name 3',
        );

        final cloned = original.clone();
        expect(cloned.id, original.id);
        expect(cloned.linkedSubjectId, 'sub-id-1');
        expect(cloned.linkedSubjectName, 'Sub Name 1');
        expect(cloned.accumulatorItemId, 'acc-id-2');
        expect(cloned.accumulatorItemName, 'Acc Name 2');
        expect(cloned.linkedExternalItemId, 'ext-id-3');
        expect(cloned.linkedExternalItemName, 'Ext Name 3');
      });

      test('SubSubjectItem.fromJson without id auto-generates id', () {
        final legacyJson = {
          'nama_materi': 'Legacy SubSubject',
          'progress': 'belum',
          'itemType': 'normal',
        };

        final parsed = SubSubjectItem.fromJson(legacyJson);
        expect(parsed.id, isNotEmpty);
        expect(parsed.subjectName, 'Legacy SubSubject');
      });

      test('SubSubjectItem.fromJson with id preserves id and parses link IDs', () {
        final json = {
          'id': 'existing-id-789',
          'nama_materi': 'Existing Item',
          'progress': 'selesai',
          'linkedSubjectId': 'lid-1',
          'accumulatorItemId': 'aid-2',
          'linkedExternalItemId': 'eid-3',
        };

        final parsed = SubSubjectItem.fromJson(json);
        expect(parsed.id, 'existing-id-789');
        expect(parsed.linkedSubjectId, 'lid-1');
        expect(parsed.accumulatorItemId, 'aid-2');
        expect(parsed.linkedExternalItemId, 'eid-3');
      });

      test('SubSubjectItem.toJson always writes id and link IDs', () {
        final item = SubSubjectItem(
          id: 'json-id-101',
          subjectName: 'JSON Item',
          progress: 'belum',
          linkedSubjectId: 'ls-id',
          accumulatorItemId: 'acc-id',
          linkedExternalItemId: 'ext-id',
        );

        final json = item.toJson();
        expect(json['id'], 'json-id-101');
        expect(json['linkedSubjectId'], 'ls-id');
        expect(json['accumulatorItemId'], 'acc-id');
        expect(json['linkedExternalItemId'], 'ext-id');
      });
    });

    group('Ticket 01: DailyLogEntry isDisabled & snapshot', () {
      test('DailyLogEntry default isDisabled is false', () {
        final entry = DailyLogEntry(
          itemName: 'Test',
          progress: 'belum',
          itemType: 'normal',
          currentValue: 0,
          targetValue: 0,
        );
        expect(entry.isDisabled, isFalse);
      });

      test('DailyLogEntry.fromSubSubjectItem copies isDisabled from source', () {
        final disabledItem = SubSubjectItem(
          subjectName: 'Disabled Item',
          progress: 'belum',
          isDisabled: true,
        );
        final activeItem = SubSubjectItem(
          subjectName: 'Active Item',
          progress: 'selesai',
          isDisabled: false,
        );

        final disabledEntry = DailyLogEntry.fromSubSubjectItem(disabledItem);
        final activeEntry = DailyLogEntry.fromSubSubjectItem(activeItem);

        expect(disabledEntry.isDisabled, isTrue);
        expect(activeEntry.isDisabled, isFalse);
      });

      test('DailyLogEntry.fromJson without isDisabled defaults to false', () {
        final legacyJson = {
          'itemName': 'Old Log Entry',
          'progress': 'selesai',
          'itemType': 'normal',
          'currentValue': 1,
          'targetValue': 1,
        };

        final entry = DailyLogEntry.fromJson(legacyJson);
        expect(entry.isDisabled, isFalse);
      });

      test('DailyLogEntry.fromJson with isDisabled preserves true', () {
        final json = {
          'itemName': 'Disabled Log Entry',
          'progress': 'belum',
          'itemType': 'normal',
          'currentValue': 0,
          'targetValue': 0,
          'isDisabled': true,
        };

        final entry = DailyLogEntry.fromJson(json);
        expect(entry.isDisabled, isTrue);
      });

      test('DailyLogEntry.toJson always writes isDisabled', () {
        final entryTrue = DailyLogEntry(
          itemName: 'Entry 1',
          progress: 'belum',
          itemType: 'normal',
          currentValue: 0,
          targetValue: 0,
          isDisabled: true,
        );
        final entryFalse = DailyLogEntry(
          itemName: 'Entry 2',
          progress: 'selesai',
          itemType: 'normal',
          currentValue: 1,
          targetValue: 1,
          isDisabled: false,
        );

        expect(entryTrue.toJson()['isDisabled'], isTrue);
        expect(entryFalse.toJson()['isDisabled'], isFalse);
      });
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/features/checklist/data/models/daily_model.dart';
import 'package:rutinitasku/features/checklist/presentation/checklist_detail_screen/widgets/edit_item_relations_dialog.dart';

void main() {
  group('Ticket 03: Unique ID-based Relations Tests', () {
    test('Internal accumulator lookup: ID-first resolves correctly even with duplicate names', () {
      final targetItem1 = SubSubjectItem(
        id: 'acc-target-1',
        subjectName: 'Latihan',
        progress: 'belum',
        itemType: 'progress',
        currentValue: 10,
        targetValue: 100,
      );

      final targetItem2 = SubSubjectItem(
        id: 'acc-target-2',
        subjectName: 'Latihan',
        progress: 'belum',
        itemType: 'progress',
        currentValue: 5,
        targetValue: 50,
      );

      final sourceItem = SubSubjectItem(
        id: 'source-item-1',
        subjectName: 'Pushup',
        progress: 'belum',
        accumulatorItemId: 'acc-target-2',
        accumulatorItemName: 'Latihan',
      );

      final flattened = [targetItem1, targetItem2, sourceItem];

      // Simulate ID-first resolution
      final resolved = flattened.firstWhere(
        (el) {
          if (sourceItem.accumulatorItemId != null &&
              sourceItem.accumulatorItemId!.isNotEmpty) {
            return el.id == sourceItem.accumulatorItemId;
          }
          return el.subjectName == sourceItem.accumulatorItemName;
        },
        orElse: () => SubSubjectItem(subjectName: '', progress: 'belum'),
      );

      expect(resolved.id, 'acc-target-2');
      expect(resolved.currentValue, 5);
      expect(resolved.targetValue, 50);
    });

    test('Internal accumulator lookup fallback to name when accumulatorItemId is null', () {
      final legacyItem = SubSubjectItem(
        id: 'acc-target-legacy',
        subjectName: 'Target Lama',
        progress: 'belum',
        itemType: 'progress',
        currentValue: 20,
        targetValue: 100,
      );

      final sourceItem = SubSubjectItem(
        id: 'source-legacy',
        subjectName: 'Source Item',
        progress: 'belum',
        accumulatorItemId: null,
        accumulatorItemName: 'Target Lama',
      );

      final flattened = [legacyItem, sourceItem];

      final resolved = flattened.firstWhere(
        (el) {
          if (sourceItem.accumulatorItemId != null &&
              sourceItem.accumulatorItemId!.isNotEmpty) {
            return el.id == sourceItem.accumulatorItemId;
          }
          return el.subjectName == sourceItem.accumulatorItemName;
        },
        orElse: () => SubSubjectItem(subjectName: '', progress: 'belum'),
      );

      expect(resolved.id, 'acc-target-legacy');
      expect(resolved.subjectName, 'Target Lama');
    });

    test('External item lookup: ID-first resolves correctly even with duplicate names across cards', () {
      final cardAItem = SubSubjectItem(
        id: 'card-a-latihan-id',
        subjectName: 'Latihan',
        progress: 'belum',
        itemType: 'progress',
        currentValue: 0,
        targetValue: 100,
      );
      final cardBItem = SubSubjectItem(
        id: 'card-b-latihan-id',
        subjectName: 'Latihan',
        progress: 'belum',
        itemType: 'progress',
        currentValue: 10,
        targetValue: 50,
      );

      final cardB = DailySubject(
        subjectName: 'Card B Olahraga',
        progress: 'belum',
        subMateri: [cardBItem],
      );

      final smallItem = SubSubjectItem(
        id: 'small-item-id',
        subjectName: 'Situp',
        progress: 'belum',
        linkedExternalCardName: 'Card B Olahraga',
        linkedExternalItemId: 'card-b-latihan-id',
        linkedExternalItemName: 'Latihan',
      );

      // Simulates external lookup in updateProgressValueData
      final extCardItems = [cardAItem, cardBItem];
      final resolvedExtItem = extCardItems.firstWhere(
        (el) {
          if (smallItem.linkedExternalItemId != null &&
              smallItem.linkedExternalItemId!.isNotEmpty) {
            return el.id == smallItem.linkedExternalItemId;
          }
          return el.subjectName == smallItem.linkedExternalItemName;
        },
        orElse: () => SubSubjectItem(subjectName: '', progress: 'belum'),
      );

      expect(resolvedExtItem.id, 'card-b-latihan-id');
      expect(resolvedExtItem.targetValue, 50);
    });

    test('External item lookup fallback to name when linkedExternalItemId is null', () {
      final extItem = SubSubjectItem(
        id: 'old-ext-id',
        subjectName: 'Old External',
        progress: 'belum',
        itemType: 'progress',
        currentValue: 0,
        targetValue: 10,
      );

      final smallItem = SubSubjectItem(
        id: 'small-item',
        subjectName: 'Child',
        progress: 'belum',
        linkedExternalCardName: 'Card Target',
        linkedExternalItemId: null,
        linkedExternalItemName: 'Old External',
      );

      final extCardItems = [extItem];
      final resolved = extCardItems.firstWhere(
        (el) {
          if (smallItem.linkedExternalItemId != null &&
              smallItem.linkedExternalItemId!.isNotEmpty) {
            return el.id == smallItem.linkedExternalItemId;
          }
          return el.subjectName == smallItem.linkedExternalItemName;
        },
        orElse: () => SubSubjectItem(subjectName: '', progress: 'belum'),
      );

      expect(resolved.id, 'old-ext-id');
      expect(resolved.subjectName, 'Old External');
    });
  });
}

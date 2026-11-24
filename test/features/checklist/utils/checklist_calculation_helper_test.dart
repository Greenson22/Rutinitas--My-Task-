import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/features/checklist/data/models/daily_model.dart';
import 'package:rutinitasku/features/checklist/utils/checklist_calculation_helper.dart';

void main() {
  group('ChecklistCalculationHelper Tests', () {
    group('SubSubjectItem calculations', () {
      test('all normal finished items -> countFinished == countTotal', () {
        final items = [
          SubSubjectItem(subjectName: 'Item 1', progress: 'selesai'),
          SubSubjectItem(subjectName: 'Item 2', progress: 'selesai'),
        ];

        expect(ChecklistCalculationHelper.countTotalItems(items), 2.0);
        expect(ChecklistCalculationHelper.countFinishedItems(items), 2.0);
      });

      test('mix of normal finished and unfinished', () {
        final items = [
          SubSubjectItem(subjectName: 'Item 1', progress: 'selesai'),
          SubSubjectItem(subjectName: 'Item 2', progress: 'belum'),
          SubSubjectItem(subjectName: 'Item 3', progress: 'sementara'),
        ];

        expect(ChecklistCalculationHelper.countTotalItems(items), 3.0);
        expect(ChecklistCalculationHelper.countFinishedItems(items), 1.0);
      });

      test('progress item 50/100 -> proportional 0.5 contribution', () {
        final items = [
          SubSubjectItem(
            subjectName: 'Progress Item',
            progress: 'sementara',
            itemType: 'progress',
            currentValue: 50,
            targetValue: 100,
          ),
        ];

        expect(ChecklistCalculationHelper.countTotalItems(items), 1.0);
        expect(ChecklistCalculationHelper.countFinishedItems(items), 0.5);
      });

      test('countdown item remaining 30 with target 100 -> proportional 0.7 contribution', () {
        final items = [
          SubSubjectItem(
            subjectName: 'Countdown Item',
            progress: 'sementara',
            itemType: 'countdown',
            currentValue: 30,
            targetValue: 100,
          ),
        ];

        expect(ChecklistCalculationHelper.countTotalItems(items), 1.0);
        expect(ChecklistCalculationHelper.countFinishedItems(items), 0.7);
      });

      test('disabled item is excluded from total and finished', () {
        final items = [
          SubSubjectItem(subjectName: 'Active', progress: 'selesai'),
          SubSubjectItem(
            subjectName: 'Disabled',
            progress: 'belum',
            isDisabled: true,
          ),
        ];

        expect(ChecklistCalculationHelper.countTotalItems(items), 1.0);
        expect(ChecklistCalculationHelper.countFinishedItems(items), 1.0);
      });

      test('nested items: parent is ignored, only leaf nodes counted', () {
        final child1 = SubSubjectItem(subjectName: 'Child 1', progress: 'selesai');
        final child2 = SubSubjectItem(subjectName: 'Child 2', progress: 'belum');
        final parent = SubSubjectItem(
          subjectName: 'Parent',
          progress: 'sementara',
          subMateri: [child1, child2],
        );

        expect(ChecklistCalculationHelper.countTotalItems([parent]), 2.0);
        expect(ChecklistCalculationHelper.countFinishedItems([parent]), 1.0);
      });

      test('disabled parent excludes all its children', () {
        final child1 = SubSubjectItem(subjectName: 'Child 1', progress: 'selesai');
        final parent = SubSubjectItem(
          subjectName: 'Parent Disabled',
          progress: 'selesai',
          isDisabled: true,
          subMateri: [child1],
        );

        expect(ChecklistCalculationHelper.countTotalItems([parent]), 0.0);
        expect(ChecklistCalculationHelper.countFinishedItems([parent]), 0.0);
      });
    });

    group('DailyLogEntry calculations', () {
      test('all normal finished entries -> countFinishedFromLog == countTotalFromLog', () {
        final entries = [
          const DailyLogEntry(
            itemName: 'Item 1',
            progress: 'selesai',
            itemType: 'normal',
            currentValue: 0,
            targetValue: 0,
          ),
          const DailyLogEntry(
            itemName: 'Item 2',
            progress: 'selesai',
            itemType: 'normal',
            currentValue: 0,
            targetValue: 0,
          ),
        ];

        expect(ChecklistCalculationHelper.countTotalFromLog(entries), 2.0);
        expect(ChecklistCalculationHelper.countFinishedFromLog(entries), 2.0);
      });

      test('progress entry 50/100 -> proportional 0.5 contribution', () {
        final entries = [
          const DailyLogEntry(
            itemName: 'Progress Entry',
            progress: 'sementara',
            itemType: 'progress',
            currentValue: 50,
            targetValue: 100,
          ),
        ];

        expect(ChecklistCalculationHelper.countTotalFromLog(entries), 1.0);
        expect(ChecklistCalculationHelper.countFinishedFromLog(entries), 0.5);
      });

      test('countdown entry remaining 30 target 100 -> proportional 0.7 contribution', () {
        final entries = [
          const DailyLogEntry(
            itemName: 'Countdown Entry',
            progress: 'sementara',
            itemType: 'countdown',
            currentValue: 30,
            targetValue: 100,
          ),
        ];

        expect(ChecklistCalculationHelper.countTotalFromLog(entries), 1.0);
        expect(ChecklistCalculationHelper.countFinishedFromLog(entries), 0.7);
      });

      test('disabled entry is excluded from log total and finished', () {
        final entries = [
          const DailyLogEntry(
            itemName: 'Active',
            progress: 'selesai',
            itemType: 'normal',
            currentValue: 0,
            targetValue: 0,
            isDisabled: false,
          ),
          const DailyLogEntry(
            itemName: 'Disabled',
            progress: 'belum',
            itemType: 'normal',
            currentValue: 0,
            targetValue: 0,
            isDisabled: true,
          ),
        ];

        expect(ChecklistCalculationHelper.countTotalFromLog(entries), 1.0);
        expect(ChecklistCalculationHelper.countFinishedFromLog(entries), 1.0);
      });

      test('nested entries: parent ignored, only leaf nodes counted', () {
        const child1 = DailyLogEntry(
          itemName: 'Child 1',
          progress: 'selesai',
          itemType: 'normal',
          currentValue: 0,
          targetValue: 0,
        );
        const child2 = DailyLogEntry(
          itemName: 'Child 2',
          progress: 'belum',
          itemType: 'normal',
          currentValue: 0,
          targetValue: 0,
        );
        const parent = DailyLogEntry(
          itemName: 'Parent',
          progress: 'sementara',
          itemType: 'normal',
          currentValue: 0,
          targetValue: 0,
          children: [child1, child2],
        );

        expect(ChecklistCalculationHelper.countTotalFromLog([parent]), 2.0);
        expect(ChecklistCalculationHelper.countFinishedFromLog([parent]), 1.0);
      });

      test('disabled parent entry excludes all its children', () {
        const child1 = DailyLogEntry(
          itemName: 'Child 1',
          progress: 'selesai',
          itemType: 'normal',
          currentValue: 0,
          targetValue: 0,
        );
        const parent = DailyLogEntry(
          itemName: 'Parent Disabled',
          progress: 'selesai',
          itemType: 'normal',
          currentValue: 0,
          targetValue: 0,
          isDisabled: true,
          children: [child1],
        );

        expect(ChecklistCalculationHelper.countTotalFromLog([parent]), 0.0);
        expect(ChecklistCalculationHelper.countFinishedFromLog([parent]), 0.0);
      });
    });

    group('Equivalence: SubSubjectItem vs DailyLogEntry snapshot', () {
      test('snapshot of complex tree produces identical total and finished counts', () {
        final item1 = SubSubjectItem(
          subjectName: 'Normal Done',
          progress: 'selesai',
        );
        final item2 = SubSubjectItem(
          subjectName: 'Progress Half',
          progress: 'sementara',
          itemType: 'progress',
          currentValue: 50,
          targetValue: 100,
        );
        final item3 = SubSubjectItem(
          subjectName: 'Countdown 30 remaining',
          progress: 'sementara',
          itemType: 'countdown',
          currentValue: 30,
          targetValue: 100,
        );
        final item4Disabled = SubSubjectItem(
          subjectName: 'Disabled Item',
          progress: 'belum',
          isDisabled: true,
        );
        final parentWithChildren = SubSubjectItem(
          subjectName: 'Parent Group',
          progress: 'sementara',
          subMateri: [item1, item2, item3, item4Disabled],
        );

        final items = [parentWithChildren];
        final snapshotEntries = items.map((i) => DailyLogEntry.fromSubSubjectItem(i)).toList();

        final totalFromItems = ChecklistCalculationHelper.countTotalItems(items);
        final totalFromLog = ChecklistCalculationHelper.countTotalFromLog(snapshotEntries);
        expect(totalFromItems, totalFromLog);
        expect(totalFromItems, 3.0); // 3 active leaf items

        final finishedFromItems = ChecklistCalculationHelper.countFinishedItems(items);
        final finishedFromLog = ChecklistCalculationHelper.countFinishedFromLog(snapshotEntries);
        expect(finishedFromItems, finishedFromLog);
        expect(finishedFromItems, 1.0 + 0.5 + 0.7); // 2.2
      });
    });
  });
}

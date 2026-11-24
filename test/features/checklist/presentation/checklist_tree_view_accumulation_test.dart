import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/features/checklist/data/models/daily_model.dart';
import 'package:rutinitasku/features/checklist/presentation/checklist_detail_screen/widgets/checklist_tree_view.dart';

void main() {
  group('ChecklistTreeView Accumulation Text Tests (Ticket 04)', () {
    Widget buildTestWidget({
      required SubSubjectItem item,
      required bool isEditMode,
      String? Function(SubSubjectItem)? resolveExternalAccumulationText,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: ChecklistTreeView(
            item: item,
            depth: 0,
            isEditMode: isEditMode,
            selectedItems: const [],
            highlightedItem: null,
            isFirst: true,
            isLast: true,
            onSelectItem: (_, __) {},
            onMoveOrder: (_, __) {},
            onEditName: (_) {},
            onLongPressToggle: () {},
            onCheckStatusChanged: (_, __) {},
            onTapToggleStatus: (_) {},
            onAddChild: (_) {},
            onDeleteItem: (_) {},
            resolveExternalAccumulationText: resolveExternalAccumulationText,
          ),
        ),
      );
    }

    testWidgets('shows bolt icon and (45/100) accumulation text in non-edit mode', (tester) async {
      final item = SubSubjectItem(
        id: 'child-item-id',
        subjectName: 'Item B',
        progress: 'belum',
        linkedExternalCardName: 'Card X',
        linkedExternalItemId: 'item-a-id',
        linkedExternalItemName: 'Item A',
      );

      await tester.pumpWidget(
        buildTestWidget(
          item: item,
          isEditMode: false,
          resolveExternalAccumulationText: (it) => '(45/100)',
        ),
      );

      expect(find.byIcon(Icons.bolt), findsOneWidget);
      expect(find.text('(45/100)'), findsOneWidget);
    });

    testWidgets('shows accumulation text in edit mode as well', (tester) async {
      final item = SubSubjectItem(
        id: 'child-item-id',
        subjectName: 'Item B',
        progress: 'belum',
        linkedExternalCardName: 'Card X',
        linkedExternalItemId: 'item-a-id',
        linkedExternalItemName: 'Item A',
      );

      await tester.pumpWidget(
        buildTestWidget(
          item: item,
          isEditMode: true,
          resolveExternalAccumulationText: (it) => '(45/100)',
        ),
      );

      expect(find.byIcon(Icons.bolt), findsOneWidget);
      expect(find.text('(45/100)'), findsOneWidget);
    });

    testWidgets('item without external link does not show bolt or accumulation text', (tester) async {
      final item = SubSubjectItem(
        id: 'plain-item-id',
        subjectName: 'Plain Item',
        progress: 'belum',
      );

      await tester.pumpWidget(
        buildTestWidget(
          item: item,
          isEditMode: false,
          resolveExternalAccumulationText: (it) => null,
        ),
      );

      expect(find.byIcon(Icons.bolt), findsNothing);
      expect(find.text('(45/100)'), findsNothing);
    });

    testWidgets('item with external link but unresolved target shows bolt without accumulation text', (tester) async {
      final item = SubSubjectItem(
        id: 'orphan-link-id',
        subjectName: 'Orphan Link Item',
        progress: 'belum',
        linkedExternalCardName: 'Missing Card',
        linkedExternalItemId: 'missing-id',
      );

      await tester.pumpWidget(
        buildTestWidget(
          item: item,
          isEditMode: false,
          resolveExternalAccumulationText: (it) => null,
        ),
      );

      expect(find.byIcon(Icons.bolt), findsOneWidget);
      expect(find.text('(45/100)'), findsNothing);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/core/presentation/widgets/grouped_section_layout.dart';
import 'package:rutinitasku/core/presentation/widgets/base_detail_app_bar.dart';

void main() {
  testWidgets('GroupedSectionLayout passes forceShowMenu to BaseDetailAppBar (default true)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GroupedSectionLayout<String>(
          title: 'Test Title',
          isLoading: false,
          isEmpty: false,
          isSelectMode: false,
          selectedItemsCount: 0,
          onClearSelection: () {},
          sectionKeys: const ['A'],
          groupedItems: const {
            'A': ['item1'],
          },
          sectionHeaderBuilder: (context, index, sectionName, isEdit) => Text(sectionName),
          gridItemBuilder: (context, item, index, sectionItems, isEdit) => Text(item),
        ),
      ),
    );

    final appBarFinder = find.byType(BaseDetailAppBar);
    expect(appBarFinder, findsOneWidget);
    final appBar = tester.widget<BaseDetailAppBar>(appBarFinder);
    expect(appBar.forceShowMenu, isTrue);
  });

  testWidgets('GroupedSectionLayout passes custom forceShowMenu value to BaseDetailAppBar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GroupedSectionLayout<String>(
          title: 'Test Title',
          forceShowMenu: false,
          isLoading: false,
          isEmpty: false,
          isSelectMode: false,
          selectedItemsCount: 0,
          onClearSelection: () {},
          sectionKeys: const ['A'],
          groupedItems: const {
            'A': ['item1'],
          },
          sectionHeaderBuilder: (context, index, sectionName, isEdit) => Text(sectionName),
          gridItemBuilder: (context, item, index, sectionItems, isEdit) => Text(item),
        ),
      ),
    );

    final appBarFinder = find.byType(BaseDetailAppBar);
    expect(appBarFinder, findsOneWidget);
    final appBar = tester.widget<BaseDetailAppBar>(appBarFinder);
    expect(appBar.forceShowMenu, isFalse);
  });
}

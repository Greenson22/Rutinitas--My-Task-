import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/core/presentation/widgets/grouped_section_layout.dart';
import 'package:rutinitasku/core/presentation/widgets/interactive_section_header.dart';
import 'package:rutinitasku/features/checklist/data/models/daily_model.dart';
import 'package:rutinitasku/features/checklist/presentation/checklist_screen/controllers/daily_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestWidget(DailyController controller) {
    final stubGroup = ChecklistGroup(
      id: 'g1',
      groupName: 'Grup Pekerjaan',
      icon: '💼',
      sectionCategory: 'Pekerjaan',
      allList: const [],
    );

    return MaterialApp(
      home: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Scaffold(
            body: GroupedSectionLayout<ChecklistGroup>(
              title: 'Checklist Groups',
              isLoading: false,
              isEmpty: false,
              emptyStateView: const SizedBox.shrink(),
              sectionKeys: const ['Pekerjaan'],
              groupedItems: {
                'Pekerjaan': [stubGroup],
              },
              isSelectMode: false,
              selectedItemsCount: 0,
              onClearSelection: () {},
              isSectionCollapsed: (key) => controller.isSectionCollapsed(key),
              sectionHeaderBuilder: (context, index, sectionKey, isEditMode) {
                return InteractiveSectionHeader(
                  sectionName: sectionKey,
                  themeColor: Colors.indigo[900]!,
                  isEditMode: false,
                  isUpperCase: false,
                  isFirst: true,
                  isLast: true,
                  onToggleEdit: () {},
                  onEditName: () {},
                  onDelete: () {},
                  onAddItem: () {},
                  isCollapsed: controller.isSectionCollapsed(sectionKey),
                  onToggleCollapse: () =>
                      controller.toggleSectionCollapsed(sectionKey),
                );
              },
              gridItemBuilder: (context, group, index, items, isEditMode) {
                return Card(child: Center(child: Text(group.groupName)));
              },
            ),
          );
        },
      ),
    );
  }

  group('DailyScreen Collapse Seksi', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets(
      'ketuk header seksi menyembunyikan card dan mengubah chevron ke chevron_right, ketuk lagi memunculkan kembali',
      (tester) async {
        final controller = DailyController();
        await tester.pumpWidget(buildTestWidget(controller));

        // Awal: terbuka, card ada, chevron expand_more
        expect(find.text('Grup Pekerjaan'), findsOneWidget);
        expect(find.byIcon(Icons.expand_more), findsOneWidget);
        expect(find.byIcon(Icons.chevron_right), findsNothing);

        // Ketuk header -> tertutup
        await tester.tap(find.text('Pekerjaan'));
        await tester.pumpAndSettle();

        expect(find.text('Grup Pekerjaan'), findsNothing);
        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
        expect(find.byIcon(Icons.expand_more), findsNothing);

        // Ketuk header lagi -> terbuka kembali
        await tester.tap(find.text('Pekerjaan'));
        await tester.pumpAndSettle();

        expect(find.text('Grup Pekerjaan'), findsOneWidget);
        expect(find.byIcon(Icons.expand_more), findsOneWidget);
        expect(find.byIcon(Icons.chevron_right), findsNothing);
      },
    );

    testWidgets(
      'dengan checklist_groups_default_collapsed: true, seksi langsung tertutup saat pertama dirender',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'checklist_groups_default_collapsed': true,
        });
        final controller = DailyController();
        await tester.runAsync(
          () => controller.loadGroupsData(showLoading: false),
        );

        await tester.pumpWidget(buildTestWidget(controller));
        await tester.pumpAndSettle();

        expect(find.text('Grup Pekerjaan'), findsNothing);
        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      },
    );
  });
}

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
              isSectionCollapsed: (key) =>
                  controller.isSectionCollapsed(key) ||
                  controller.isSectionHidden(key),
              sectionHeaderBuilder: (context, index, sectionKey, isEditMode) {
                return InteractiveSectionHeader(
                  sectionName: sectionKey,
                  themeColor: Colors.indigo[900]!,
                  isEditMode: controller.isSectionEditMode,
                  isUpperCase: false,
                  isFirst: true,
                  isLast: true,
                  onToggleEdit: controller.toggleSectionEditMode,
                  onEditName: () {},
                  onDelete: () {},
                  onAddItem: () {},
                  isCollapsed: controller.isSectionCollapsed(sectionKey),
                  onToggleCollapse: () =>
                      controller.toggleSectionCollapsed(sectionKey),
                  isHidden: controller.isSectionHidden(sectionKey),
                  onToggleVisibility: () =>
                      controller.toggleSectionHidden(sectionKey),
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

  group('DailyScreen Hide Seksi', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets(
      'long-press header masuk edit mode, ketuk Sembunyikan Seksi menampilkan badge Tersembunyi dan menyembunyikan card, ketuk Tampilkan Seksi mengembalikan card',
      (tester) async {
        final controller = DailyController();
        await tester.pumpWidget(buildTestWidget(controller));

        // Awal: tidak di edit mode, tombol Sembunyikan Seksi tidak ada
        expect(find.byTooltip('Sembunyikan Seksi'), findsNothing);
        expect(find.text('Grup Pekerjaan'), findsOneWidget);

        // Long-press header -> masuk edit mode
        await tester.longPress(find.text('Pekerjaan'));
        await tester.pumpAndSettle();

        expect(find.byTooltip('Sembunyikan Seksi'), findsOneWidget);

        // Ketuk Sembunyikan Seksi
        await tester.tap(find.byTooltip('Sembunyikan Seksi'));
        await tester.pumpAndSettle();

        expect(find.text('Tersembunyi'), findsOneWidget);
        expect(find.text('Grup Pekerjaan'), findsNothing);
        expect(find.byTooltip('Tampilkan Seksi'), findsOneWidget);

        // Ketuk Tampilkan Seksi (unhide)
        await tester.tap(find.byTooltip('Tampilkan Seksi'));
        await tester.pumpAndSettle();

        expect(find.text('Tersembunyi'), findsNothing);
        expect(find.text('Grup Pekerjaan'), findsOneWidget);
      },
    );
  });
}

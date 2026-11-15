import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/category.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/daily_progress.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_kind.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_master_data.dart';
import 'package:rutinitasku/features/task_master_new/presentation/layout/task_master_layout.dart';
import 'package:rutinitasku/features/task_master_new/presentation/screens/category_detail_screen.dart';
import 'package:rutinitasku/features/task_master_new/presentation/screens/task_master_screen.dart';

import '../support/fake_task_repository.dart';

void main() {
  final now = DateTime(2026, 11, 14, 12);
  final today = DailyProgress.dateKey(now);

  Task task({
    required String id,
    required String categoryId,
    required String name,
    required TaskKind kind,
    required int sortOrder,
    int targetDaily = 0,
    int targetTotal = 0,
    int totalCount = 0,
    int countToday = 0,
  }) {
    return Task(
      id: id,
      categoryId: categoryId,
      name: name,
      kind: kind,
      isActive: true,
      sortOrder: sortOrder,
      targetDaily: targetDaily,
      targetTotal: targetTotal,
      totalCount: totalCount,
      createdAt: now,
      updatedAt: now,
      history: countToday == 0
          ? const {}
          : {
              today: DailyProgress(
                date: today,
                count: countToday,
                updatedAt: now,
              ),
            },
    );
  }

  TaskMasterData sampleData() {
    return TaskMasterData(
      schemaVersion: 2,
      categories: [
        Category(
          id: 'cat_1',
          name: 'Olahraga',
          icon: '🏃',
          isHidden: false,
          sortOrder: 0,
          tasks: [
            task(
              id: 'task_1',
              categoryId: 'cat_1',
              name: 'Push up',
              kind: TaskKind.habit,
              sortOrder: 0,
              targetDaily: 20,
              totalCount: 120,
              countToday: 15,
            ),
            task(
              id: 'task_2',
              categoryId: 'cat_1',
              name: 'Baca buku',
              kind: TaskKind.progress,
              sortOrder: 1,
              targetDaily: 1,
              targetTotal: 100,
              totalCount: 40,
            ),
          ],
        ),
        Category(
          id: 'cat_2',
          name: 'Belajar',
          icon: '📚',
          isHidden: false,
          sortOrder: 1,
          tasks: [
            task(
              id: 'task_3',
              categoryId: 'cat_2',
              name: 'Catatan',
              kind: TaskKind.counter,
              sortOrder: 0,
              totalCount: 4,
            ),
          ],
        ),
      ],
    );
  }

  Widget app(FakeTaskRepository repository) {
    return MaterialApp(
      home: TaskMasterNewScreen(repository: repository, clock: () => now),
    );
  }

  void setViewport(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Future<void> openSinglePaneCategory(WidgetTester tester) async {
    final finder = find.byKey(const Key('manageTasks_cat_1'));
    await tester.scrollUntilVisible(
      finder,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  group('breakpoint', () {
    test('mobile di bawah 600, tablet 600-1024, desktop di atas 1024', () {
      expect(taskMasterLayoutForWidth(360), TaskMasterLayout.mobile);
      expect(taskMasterLayoutForWidth(599), TaskMasterLayout.mobile);
      expect(taskMasterLayoutForWidth(600), TaskMasterLayout.tablet);
      expect(taskMasterLayoutForWidth(800), TaskMasterLayout.tablet);
      expect(taskMasterLayoutForWidth(1024), TaskMasterLayout.tablet);
      expect(taskMasterLayoutForWidth(1025), TaskMasterLayout.desktop);
      expect(usesTwoPaneLayout(TaskMasterLayout.desktop), isTrue);
      expect(usesTwoPaneLayout(TaskMasterLayout.tablet), isFalse);
      expect(usesPushedCategoryDetail(TaskMasterLayout.mobile), isTrue);
      expect(usesPushedCategoryDetail(TaskMasterLayout.tablet), isTrue);
    });
  });

  testWidgets('mobile membuka detail kategori lewat push dan kembali', (
    tester,
  ) async {
    setViewport(tester, const Size(480, 900));
    final repository = FakeTaskRepository(data: sampleData());

    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('desktopCategorySidebar')), findsNothing);

    await openSinglePaneCategory(tester);

    expect(find.byType(CategoryDetailScreen), findsOneWidget);
    expect(find.text('Push up'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byType(CategoryDetailScreen), findsNothing);
    expect(find.byKey(const Key('summaryActiveCategories')), findsOneWidget);
  });

  testWidgets('desktop menampilkan dua panel tanpa push screen', (
    tester,
  ) async {
    setViewport(tester, const Size(1400, 900));
    final repository = FakeTaskRepository(data: sampleData());

    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('desktopCategorySidebar')), findsOneWidget);
    expect(find.byKey(const Key('desktopDashboard')), findsOneWidget);
    expect(find.byKey(const Key('desktopCategoryTile_cat_1')), findsOneWidget);
    expect(find.byKey(const Key('desktopCategoryTile_cat_2')), findsOneWidget);
    expect(find.byType(CategoryDetailScreen), findsNothing);

    await tester.tap(find.byKey(const Key('desktopCategoryTile_cat_1')));
    await tester.pumpAndSettle();

    // Detail tampil di panel kanan; daftar kategori tetap terlihat dan tidak
    // ada rute baru yang di-push.
    expect(find.byType(CategoryDetailScreen), findsOneWidget);
    expect(find.byKey(const Key('desktopDetailPanel')), findsOneWidget);
    expect(find.byKey(const Key('desktopCategorySidebar')), findsOneWidget);
    expect(
      tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
      isFalse,
    );
    expect(find.text('Push up'), findsOneWidget);

    await tester.tap(find.byKey(const Key('desktopDashboardTile')));
    await tester.pumpAndSettle();

    expect(find.byType(CategoryDetailScreen), findsNothing);
    expect(find.byKey(const Key('desktopDashboard')), findsOneWidget);
  });

  testWidgets('tablet memakai satu panel tanpa overflow', (tester) async {
    setViewport(tester, const Size(800, 900));
    final repository = FakeTaskRepository(data: sampleData());

    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('desktopCategorySidebar')), findsNothing);

    await openSinglePaneCategory(tester);
    expect(find.byType(CategoryDetailScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('layout mobile tidak overflow pada text scale 1.5', (
    tester,
  ) async {
    setViewport(tester, const Size(400, 800));
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final repository = FakeTaskRepository(data: sampleData());

    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await openSinglePaneCategory(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Push up'), findsOneWidget);
  });

  testWidgets('layout desktop tidak overflow pada text scale 1.5', (
    tester,
  ) async {
    setViewport(tester, const Size(1200, 800));
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final repository = FakeTaskRepository(data: sampleData());

    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('desktopCategoryTile_cat_1')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('desktopDetailPanel')), findsOneWidget);
  });

  testWidgets('target sentuh aksi utama minimal 48x48 dp', (tester) async {
    setViewport(tester, const Size(480, 900));
    final repository = FakeTaskRepository(data: sampleData());

    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();

    void expectTouchTarget(String key) {
      final size = tester.getSize(find.byKey(Key(key)));
      expect(
        size.width,
        greaterThanOrEqualTo(48),
        reason: '$key terlalu sempit: $size',
      );
      expect(
        size.height,
        greaterThanOrEqualTo(48),
        reason: '$key terlalu pendek: $size',
      );
    }

    expectTouchTarget('openSearchButton');
    expectTouchTarget('dashboardIncrement_task_1');
    expectTouchTarget('taskHistory_task_1');

    await tester.tap(find.byKey(const Key('openSearchButton')));
    await tester.pumpAndSettle();
    expectTouchTarget('taskFilter_all');
    expectTouchTarget('taskFilter_active');

    await openSinglePaneCategory(tester);
    expectTouchTarget('incrementTask_task_1');
    expectTouchTarget('taskMenu_task_1');
    expectTouchTarget('reorderTasksButton');
  });

  testWidgets('ikon aksi dan progress bar punya label aksesibilitas', (
    tester,
  ) async {
    setViewport(tester, const Size(480, 900));
    final semantics = tester.ensureSemantics();
    final repository = FakeTaskRepository(data: sampleData());

    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel(RegExp('Tambah hitungan Push up')),
      findsOneWidget,
    );

    await openSinglePaneCategory(tester);

    expect(
      find.bySemanticsLabel(RegExp('Progres Baca buku: 40 dari 100')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('Tambah hitungan Push up')),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('shortcut desktop membuka pencarian dan memfokuskan kolom', (
    tester,
  ) async {
    setViewport(tester, const Size(1400, 900));
    final repository = FakeTaskRepository(data: sampleData());

    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('taskSearchField')), findsNothing);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('taskSearchField')), findsOneWidget);
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.focusNode.hasFocus, isTrue);
  });

  testWidgets('shortcut desktop menambah tugas dan Esc menutup dialog', (
    tester,
  ) async {
    setViewport(tester, const Size(1400, 900));
    final repository = FakeTaskRepository(data: sampleData());

    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('desktopCategoryTile_cat_1')));
    await tester.pumpAndSettle();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(find.text('Tambah Tugas Baru'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text('Tambah Tugas Baru'), findsNothing);
  });

  testWidgets('Esc pada desktop kembali dari detail ke dashboard', (
    tester,
  ) async {
    setViewport(tester, const Size(1400, 900));
    final repository = FakeTaskRepository(data: sampleData());

    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('desktopCategoryTile_cat_1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('desktopDetailPanel')), findsOneWidget);

    // Fokuskan panel detail agar shortcut Esc diterima oleh layar, bukan
    // dialog.
    await tester.tap(find.text('Push up'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('desktopDetailPanel')), findsNothing);
    expect(find.byKey(const Key('desktopDashboard')), findsOneWidget);
  });
}

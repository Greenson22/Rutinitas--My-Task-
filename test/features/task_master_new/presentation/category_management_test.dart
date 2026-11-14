import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/features/task_master_new/data/exceptions/task_master_exceptions.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/category.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/daily_progress.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_kind.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_master_data.dart';
import 'package:rutinitasku/features/task_master_new/presentation/screens/task_master_screen.dart';

import '../support/fake_task_repository.dart';

void main() {
  final now = DateTime(2026, 11, 14, 12);

  TaskMasterData sampleData() {
    final today = DailyProgress.dateKey(now);
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
            Task(
              id: 'task_1',
              categoryId: 'cat_1',
              name: 'Push up',
              kind: TaskKind.habit,
              isActive: true,
              sortOrder: 0,
              targetDaily: 20,
              targetTotal: 0,
              totalCount: 120,
              createdAt: now,
              updatedAt: now,
              history: {
                today: DailyProgress(date: today, count: 15, updatedAt: now),
              },
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

  Future<void> openCategoryMenu(WidgetTester tester, String categoryId) async {
    await tester.tap(find.byKey(Key('categoryMenu_$categoryId')));
    await tester.pumpAndSettle();
  }

  group('pengelolaan kategori', () {
    testWidgets('pengguna dapat menambah kategori dengan nama dan emoji', (
      tester,
    ) async {
      final repository = FakeTaskRepository(data: sampleData());
      await tester.pumpWidget(app(repository));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('addCategoryButton')));
      await tester.pumpAndSettle();

      expect(find.text('Tambah Kategori Baru'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('categoryNameField')),
        'Belajar',
      );
      await tester.enterText(
        find.byKey(const Key('categoryIconField')),
        '📚',
      );
      await tester.tap(find.byKey(const Key('categorySaveButton')));
      await tester.pumpAndSettle();

      expect(find.text('Tambah Kategori Baru'), findsNothing);
      expect(find.text('Belajar'), findsOneWidget);
      expect(find.text('📚'), findsOneWidget);
      expect(repository.data!.categories, hasLength(2));
      expect(repository.data!.categories.last.icon, '📚');
    });

    testWidgets('pengguna dapat mengedit nama dan ikon tanpa mengubah id', (
      tester,
    ) async {
      final repository = FakeTaskRepository(data: sampleData());
      await tester.pumpWidget(app(repository));
      await tester.pumpAndSettle();

      await openCategoryMenu(tester, 'cat_1');
      await tester.tap(find.text('Ubah'));
      await tester.pumpAndSettle();

      expect(find.text('Ubah Kategori'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('categoryNameField')),
        'Kebugaran',
      );
      await tester.enterText(
        find.byKey(const Key('categoryIconField')),
        '💪',
      );
      await tester.tap(find.byKey(const Key('categorySaveButton')));
      await tester.pumpAndSettle();

      expect(find.text('Kebugaran'), findsOneWidget);
      expect(find.text('💪'), findsOneWidget);
      expect(find.text('Push up'), findsOneWidget);

      final category = repository.data!.categories.single;
      expect(category.id, 'cat_1');
      expect(category.tasks.single.id, 'task_1');
    });

    testWidgets('rename kategori tidak memutus tugas di dalamnya', (
      tester,
    ) async {
      final repository = FakeTaskRepository(data: sampleData());
      await tester.pumpWidget(app(repository));
      await tester.pumpAndSettle();

      await openCategoryMenu(tester, 'cat_1');
      await tester.tap(find.text('Ubah'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('categoryNameField')),
        'Latihan',
      );
      await tester.tap(find.byKey(const Key('categorySaveButton')));
      await tester.pumpAndSettle();

      expect(find.text('Latihan'), findsOneWidget);
      expect(find.text('Push up'), findsOneWidget);
      expect(
        repository.data!.categories.single.tasks.single.categoryId,
        'cat_1',
      );
    });

    testWidgets('nama kategori duplikat ditolak dengan pesan jelas', (
      tester,
    ) async {
      final repository = FakeTaskRepository(data: sampleData());
      await tester.pumpWidget(app(repository));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('addCategoryButton')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('categoryNameField')),
        'olahraga',
      );
      await tester.tap(find.byKey(const Key('categorySaveButton')));
      await tester.pumpAndSettle();

      expect(find.textContaining('sudah digunakan'), findsOneWidget);
      expect(find.text('Tambah Kategori Baru'), findsOneWidget);
      expect(repository.data!.categories, hasLength(1));
    });

    testWidgets('pengguna dapat menyembunyikan dan menampilkan kategori', (
      tester,
    ) async {
      final repository = FakeTaskRepository(data: sampleData());
      await tester.pumpWidget(app(repository));
      await tester.pumpAndSettle();

      await openCategoryMenu(tester, 'cat_1');
      await tester.tap(find.text('Sembunyikan'));
      await tester.pumpAndSettle();

      expect(find.text('Disembunyikan'), findsOneWidget);
      expect(repository.data!.categories.single.isHidden, isTrue);

      await openCategoryMenu(tester, 'cat_1');
      await tester.tap(find.text('Tampilkan'));
      await tester.pumpAndSettle();

      expect(find.text('Disembunyikan'), findsNothing);
      expect(repository.data!.categories.single.isHidden, isFalse);
    });

    testWidgets('hapus kategori meminta konfirmasi dan memperingatkan tugas', (
      tester,
    ) async {
      final repository = FakeTaskRepository(data: sampleData());
      await tester.pumpWidget(app(repository));
      await tester.pumpAndSettle();

      await openCategoryMenu(tester, 'cat_1');
      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();

      expect(find.text('Hapus kategori?'), findsOneWidget);
      expect(find.textContaining('masih memiliki 1 tugas'), findsOneWidget);

      await tester.tap(find.byKey(const Key('deleteCategoryCancelButton')));
      await tester.pumpAndSettle();
      expect(repository.data!.categories, hasLength(1));

      await openCategoryMenu(tester, 'cat_1');
      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('deleteCategoryConfirmButton')));
      await tester.pumpAndSettle();

      expect(repository.data!.categories, isEmpty);
      expect(find.text('Belum ada kategori'), findsOneWidget);
    });

    testWidgets('kategori bertahan setelah layar dibuka ulang', (tester) async {
      final repository = FakeTaskRepository(data: sampleData());
      await tester.pumpWidget(app(repository));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('addCategoryButton')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('categoryNameField')),
        'Belajar',
      );
      await tester.tap(find.byKey(const Key('categorySaveButton')));
      await tester.pumpAndSettle();

      // Simulasikan aplikasi ditutup lalu dibuka kembali dengan repository
      // yang sama (data sudah tersimpan).
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app(repository));
      await tester.pumpAndSettle();

      expect(find.text('Belajar'), findsOneWidget);
      expect(find.text('Olahraga'), findsOneWidget);
    });

    testWidgets('kegagalan menyimpan menampilkan banner dan bisa dicoba lagi', (
      tester,
    ) async {
      final repository = FakeTaskRepository(data: sampleData());
      repository.categoryActionError = TaskDataSourceException(
        'Gagal menulis file Task Master.',
      );
      await tester.pumpWidget(app(repository));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('addCategoryButton')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('categoryNameField')),
        'Belajar',
      );
      await tester.tap(find.byKey(const Key('categorySaveButton')));
      await tester.pumpAndSettle();

      // Dialog tetap terbuka dan memberi tahu perubahan belum tersimpan.
      expect(find.textContaining('belum tersimpan'), findsOneWidget);
      await tester.tap(find.byKey(const Key('categoryCancelButton')));
      await tester.pumpAndSettle();

      expect(find.text('Gagal menulis file Task Master.'), findsOneWidget);
      expect(find.byKey(const Key('retryActionButton')), findsOneWidget);

      repository.categoryActionError = null;
      await tester.tap(find.byKey(const Key('retryActionButton')));
      await tester.pumpAndSettle();

      expect(find.text('Belajar'), findsOneWidget);
      expect(find.byKey(const Key('retryActionButton')), findsNothing);
    });
  });
}

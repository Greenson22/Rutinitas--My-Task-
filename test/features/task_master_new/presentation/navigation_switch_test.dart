import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/core/config/task_master_rollout.dart';
import 'package:rutinitasku/core/presentation/widgets/drawer_menu.dart';
import 'package:rutinitasku/core/presentation/widgets/settings_dialog.dart';
import 'package:rutinitasku/core/presentation/widgets/task_master_entry.dart';
import 'package:rutinitasku/features/task_master/presentation/controllers/task_master_controller.dart';
import 'package:rutinitasku/features/task_master/presentation/screens/task_master_screen.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_master_data.dart';
import 'package:rutinitasku/features/task_master_new/presentation/screens/task_master_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_journal_gateway.dart';
import '../support/fake_task_repository.dart';

void main() {
  final now = DateTime(2026, 11, 18, 9);

  setUp(() {
    resetTaskMasterRolloutCacheForTesting();
  });

  group('unit test preferensi rollout dan penurunan status penulis', () {
    test('fresh install default false dan modul lama boleh menulis', () async {
      SharedPreferences.setMockInitialValues({});
      resetTaskMasterRolloutCacheForTesting();

      final useNew = await getTaskMasterUseNewModule(useCache: false);
      final legacyWrites = await isTaskMasterLegacyWritesEnabled();

      expect(useNew, isFalse);
      expect(legacyWrites, isTrue);
    });

    test('saklar hidup: modul baru aktif dan modul lama dilarang menulis', () async {
      SharedPreferences.setMockInitialValues({
        taskMasterUseNewModulePrefKey: true,
      });
      resetTaskMasterRolloutCacheForTesting();

      final useNew = await getTaskMasterUseNewModule(useCache: false);
      final legacyWrites = await isTaskMasterLegacyWritesEnabled();

      expect(useNew, isTrue);
      expect(legacyWrites, isFalse);
    });

    test('setTaskMasterUseNewModule memperbarui preferensi dan status penulis', () async {
      SharedPreferences.setMockInitialValues({});
      resetTaskMasterRolloutCacheForTesting();

      await setTaskMasterUseNewModule(true);
      expect(await getTaskMasterUseNewModule(useCache: false), isTrue);
      expect(await isTaskMasterLegacyWritesEnabled(), isFalse);

      await setTaskMasterUseNewModule(false);
      expect(await getTaskMasterUseNewModule(useCache: false), isFalse);
      expect(await isTaskMasterLegacyWritesEnabled(), isTrue);
    });
  });

  group('switch navigasi Task Master', () {
    testWidgets('fresh install (saklar mati) membuka modul lama HomeScreen', (tester) async {
      SharedPreferences.setMockInitialValues({
        taskMasterUseNewModulePrefKey: false,
      });
      resetTaskMasterRolloutCacheForTesting();

      await tester.pumpWidget(
        MaterialApp(
          home: TaskMasterEntry(
            repository: FakeTaskRepository(data: TaskMasterData.empty()),
            journalGateway: FakeJournalGateway(),
            clock: () => now,
          ),
        ),
      );
      // Tunggu load preference async TaskMasterEntry selesai
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(TaskMasterNewScreen), findsNothing);
    });

    testWidgets('saklar hidup membuka Task Master New', (tester) async {
      SharedPreferences.setMockInitialValues({
        taskMasterUseNewModulePrefKey: true,
      });
      resetTaskMasterRolloutCacheForTesting();

      final repository = FakeTaskRepository(data: TaskMasterData.empty());

      await tester.pumpWidget(
        MaterialApp(
          home: TaskMasterEntry(
            repository: repository,
            journalGateway: FakeJournalGateway(),
            clock: () => now,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TaskMasterNewScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Task Master'),
        ),
        findsOneWidget,
      );
      expect(repository.loadCount, 1);
    });

    testWidgets('drawer hanya punya satu pintu masuk Task Master', (tester) async {
      SharedPreferences.setMockInitialValues({
        taskMasterUseNewModulePrefKey: true,
      });
      resetTaskMasterRolloutCacheForTesting();

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: DrawerMenu())),
      );

      expect(find.text('Task Master'), findsOneWidget);
      expect(find.text('Task Master New'), findsNothing);
    });

    testWidgets('menu Task Master membuka modul sesuai saklar', (tester) async {
      SharedPreferences.setMockInitialValues({
        taskMasterUseNewModulePrefKey: true,
      });
      resetTaskMasterRolloutCacheForTesting();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: null,
            drawer: DrawerMenu(),
            body: SizedBox.shrink(),
          ),
        ),
      );

      final scaffoldState = tester.firstState<ScaffoldState>(
        find.byType(Scaffold),
      );
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Task Master'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(TaskMasterNewScreen), findsOneWidget);
    });
  });

  group('Settings Fitur Eksperimental Task Master New', () {
    testWidgets('menampilkan item Task Master New di Fitur Eksperimental', (tester) async {
      SharedPreferences.setMockInitialValues({
        taskMasterUseNewModulePrefKey: false,
      });
      resetTaskMasterRolloutCacheForTesting();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsDialog(
              currentBaseDir: 'Documents',
              onSave: (_) {},
              onEncryptionToggled: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fitur Eksperimental'), findsOneWidget);
      expect(find.text('Task Master New'), findsOneWidget);
      expect(
        find.text(
          'Gunakan modul Task Master baru yang sedang diuji. '
          'Perubahan berlaku setelah aplikasi dimulai ulang.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('mengaktifkan saklar memunculkan dialog konfirmasi aktif, simpan preferensi, dan notice restart', (tester) async {
      SharedPreferences.setMockInitialValues({
        taskMasterUseNewModulePrefKey: false,
      });
      resetTaskMasterRolloutCacheForTesting();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsDialog(
              currentBaseDir: 'Documents',
              onSave: (_) {},
              onEncryptionToggled: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final taskMasterNewSwitch = find.descendant(
        of: find.widgetWithText(ListTile, 'Task Master New'),
        matching: find.byType(Switch),
      );
      await tester.scrollUntilVisible(
        taskMasterNewSwitch,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(taskMasterNewSwitch, findsOneWidget);

      await tester.tap(taskMasterNewSwitch);
      await tester.pumpAndSettle();

      // Dialog konfirmasi muncul
      expect(find.text('Aktifkan Task Master New?'), findsOneWidget);
      expect(
        find.textContaining('Task Master New adalah penulisan ulang modul'),
        findsOneWidget,
      );

      // Tekan tombol Aktifkan
      await tester.tap(find.text('Aktifkan'));
      await tester.pumpAndSettle();

      // Verifikasi preferensi tersimpan segera
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(taskMasterUseNewModulePrefKey), isTrue);

      // Verifikasi notice restart muncul
      expect(
        find.text('Task Master New akan aktif setelah aplikasi dimulai ulang.'),
        findsOneWidget,
      );
    });

    testWidgets('menonaktifkan saklar memunculkan dialog konfirmasi nonaktif, simpan preferensi, dan notice restart', (tester) async {
      SharedPreferences.setMockInitialValues({
        taskMasterUseNewModulePrefKey: true,
      });
      resetTaskMasterRolloutCacheForTesting();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsDialog(
              currentBaseDir: 'Documents',
              onSave: (_) {},
              onEncryptionToggled: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final taskMasterNewSwitch = find.descendant(
        of: find.widgetWithText(ListTile, 'Task Master New'),
        matching: find.byType(Switch),
      );
      await tester.scrollUntilVisible(
        taskMasterNewSwitch,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(taskMasterNewSwitch, findsOneWidget);

      await tester.tap(taskMasterNewSwitch);
      await tester.pumpAndSettle();

      // Dialog konfirmasi nonaktif muncul
      expect(find.text('Kembali ke Modul Lama?'), findsOneWidget);
      expect(
        find.textContaining('Riwayat baru tersimpan dalam file v2'),
        findsOneWidget,
      );

      // Tekan tombol Nonaktifkan
      await tester.tap(find.text('Nonaktifkan'));
      await tester.pumpAndSettle();

      // Verifikasi preferensi tersimpan segera
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(taskMasterUseNewModulePrefKey), isFalse);

      // Verifikasi notice restart muncul
      expect(
        find.text('Modul lama akan aktif setelah aplikasi dimulai ulang.'),
        findsOneWidget,
      );
    });
  });

  group('test regresi satu penulis: saat modul baru aktif, modul lama dilarang menulis', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('task_master_legacy_');
      SharedPreferences.setMockInitialValues({
        taskMasterUseNewModulePrefKey: true,
        'ubuntu_base_dir_debug': tempDir.path,
      });
      resetTaskMasterRolloutCacheForTesting();
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('saveAllCategoriesToFile modul lama tidak membuat atau menulis file', () async {
      final controller = TaskMasterController(onUpdate: () {})
        ..selectedBaseDir = tempDir.path;

      await controller.saveAllCategoriesToFile();

      expect(tempDir.listSync(), isEmpty);
    });

    test('memuat saat file belum ada tidak membuat folder atau file baru', () async {
      final controller = TaskMasterController(onUpdate: () {});

      await controller.initStorageAndLoadData();

      expect(controller.isFileCorrupted, isTrue);
      expect(Directory('${tempDir.path}/mytask').existsSync(), isFalse);
    });

    test('forceResetNewFile tidak membuat file baru saat guard aktif', () async {
      final controller = TaskMasterController(onUpdate: () {});
      final target = File('${tempDir.path}/my_tasks.json');

      await controller.forceResetNewFile(target);

      expect(await target.exists(), isFalse);
    });

    test('guard tetap berlaku saat file gagal dibaca / korup', () async {
      // Simpan file korup
      final myTaskDir = Directory('${tempDir.path}/mytask');
      await myTaskDir.create(recursive: true);
      final jsonFile = File('${myTaskDir.path}/my_tasks.json');
      await jsonFile.writeAsString('Bukan JSON yang valid!');

      final controller = TaskMasterController(onUpdate: () {});
      await controller.initStorageAndLoadData();

      expect(controller.isFileCorrupted, isTrue);

      // Coba panggil reset atau save saat file korup
      await controller.forceResetNewFile(jsonFile);
      // File asli tidak berubah menjadi file baru
      expect(await jsonFile.readAsString(), 'Bukan JSON yang valid!');
    });
  });

  group('test satu penulis: saat modul baru mati, modul lama boleh menulis', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('task_master_legacy_enabled_');
      SharedPreferences.setMockInitialValues({
        taskMasterUseNewModulePrefKey: false,
        'ubuntu_base_dir_debug': tempDir.path,
      });
      resetTaskMasterRolloutCacheForTesting();
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('modul lama dapat membuat dan menyimpan file saat saklar mati', () async {
      final controller = TaskMasterController(onUpdate: () {})
        ..selectedBaseDir = tempDir.path;

      final target = File('${tempDir.path}/my_tasks.json');
      await controller.forceResetNewFile(target);

      expect(await target.exists(), isTrue);
      expect(await target.readAsString(), contains('categories'));
    });
  });

  group('promo sekali-jalan Task Master New', () {
    setUp(() {
      resetTaskMasterRolloutCacheForTesting();
    });

    testWidgets('dialog promo muncul bila saklar mati, file v2 ada, dan promo belum pernah tampil', (tester) async {
      SharedPreferences.setMockInitialValues({
        taskMasterUseNewModulePrefKey: false,
        seenTaskMasterNewPromoPrefKey: false,
      });
      resetTaskMasterRolloutCacheForTesting();

      await tester.pumpWidget(
        MaterialApp(
          home: TaskMasterEntry(
            repository: FakeTaskRepository(data: TaskMasterData.empty()),
            journalGateway: FakeJournalGateway(),
            clock: () => now,
            isSchemaV2Checker: () async => true,
            legacyBuilder: (context) => const SizedBox(key: Key('legacy_content')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aktifkan Task Master New?'), findsOneWidget);
      expect(find.text('Aktifkan Sekarang'), findsOneWidget);
      expect(find.text('Nanti'), findsOneWidget);
    });

    testWidgets('dialog promo TIDAK muncul bila saklar sudah hidup', (tester) async {
      SharedPreferences.setMockInitialValues({
        taskMasterUseNewModulePrefKey: true,
        seenTaskMasterNewPromoPrefKey: false,
      });
      resetTaskMasterRolloutCacheForTesting();

      await tester.pumpWidget(
        MaterialApp(
          home: TaskMasterEntry(
            repository: FakeTaskRepository(data: TaskMasterData.empty()),
            journalGateway: FakeJournalGateway(),
            clock: () => now,
            isSchemaV2Checker: () async => true,
            legacyBuilder: (context) => const SizedBox(key: Key('legacy_content')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aktifkan Task Master New?'), findsNothing);
    });

    testWidgets('dialog promo TIDAK muncul untuk pengguna baru (file v2 belum ada)', (tester) async {
      SharedPreferences.setMockInitialValues({
        taskMasterUseNewModulePrefKey: false,
        seenTaskMasterNewPromoPrefKey: false,
      });
      resetTaskMasterRolloutCacheForTesting();

      await tester.pumpWidget(
        MaterialApp(
          home: TaskMasterEntry(
            repository: FakeTaskRepository(data: TaskMasterData.empty()),
            journalGateway: FakeJournalGateway(),
            clock: () => now,
            isSchemaV2Checker: () async => false,
            legacyBuilder: (context) => const SizedBox(key: Key('legacy_content')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aktifkan Task Master New?'), findsNothing);
    });

    testWidgets('dialog promo TIDAK muncul bila seen_task_master_new_promo sudah true', (tester) async {
      SharedPreferences.setMockInitialValues({
        taskMasterUseNewModulePrefKey: false,
        seenTaskMasterNewPromoPrefKey: true,
      });
      resetTaskMasterRolloutCacheForTesting();

      await tester.pumpWidget(
        MaterialApp(
          home: TaskMasterEntry(
            repository: FakeTaskRepository(data: TaskMasterData.empty()),
            journalGateway: FakeJournalGateway(),
            clock: () => now,
            isSchemaV2Checker: () async => true,
            legacyBuilder: (context) => const SizedBox(key: Key('legacy_content')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aktifkan Task Master New?'), findsNothing);
    });

    testWidgets('memilih Nanti menyimpan seen_promo=true dan tidak mengubah saklar', (tester) async {
      SharedPreferences.setMockInitialValues({
        taskMasterUseNewModulePrefKey: false,
        seenTaskMasterNewPromoPrefKey: false,
      });
      resetTaskMasterRolloutCacheForTesting();

      await tester.pumpWidget(
        MaterialApp(
          home: TaskMasterEntry(
            repository: FakeTaskRepository(data: TaskMasterData.empty()),
            journalGateway: FakeJournalGateway(),
            clock: () => now,
            isSchemaV2Checker: () async => true,
            legacyBuilder: (context) => const SizedBox(key: Key('legacy_content')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aktifkan Task Master New?'), findsOneWidget);
      await tester.tap(find.text('Nanti'));
      await tester.pumpAndSettle();

      expect(find.text('Aktifkan Task Master New?'), findsNothing);
      expect(await getSeenTaskMasterNewPromo(useCache: false), isTrue);
      expect(await getTaskMasterUseNewModule(useCache: false), isFalse);
    });

    testWidgets('memilih Aktifkan Sekarang menyalakan saklar, menyimpan seen_promo=true, dan menampilkan instruksi restart', (tester) async {
      SharedPreferences.setMockInitialValues({
        taskMasterUseNewModulePrefKey: false,
        seenTaskMasterNewPromoPrefKey: false,
      });
      resetTaskMasterRolloutCacheForTesting();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskMasterEntry(
              repository: FakeTaskRepository(data: TaskMasterData.empty()),
              journalGateway: FakeJournalGateway(),
              clock: () => now,
              isSchemaV2Checker: () async => true,
              legacyBuilder: (context) => const SizedBox(key: Key('legacy_content')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aktifkan Task Master New?'), findsOneWidget);
      await tester.tap(find.text('Aktifkan Sekarang'));
      await tester.pumpAndSettle();

      expect(find.text('Aktifkan Task Master New?'), findsNothing);
      expect(await getSeenTaskMasterNewPromo(useCache: false), isTrue);
      expect(await getTaskMasterUseNewModule(useCache: false), isTrue);
      expect(
        find.textContaining('Silakan mulai ulang aplikasi untuk menerapkan perubahan'),
        findsOneWidget,
      );
    });

    testWidgets('preferensi tawaran bertahan setelah restart (tidak muncul lagi saat dibuka kembali)', (tester) async {
      SharedPreferences.setMockInitialValues({
        taskMasterUseNewModulePrefKey: false,
        seenTaskMasterNewPromoPrefKey: false,
      });
      resetTaskMasterRolloutCacheForTesting();

      // Buka pertama kali dan pilih Nanti
      await tester.pumpWidget(
        MaterialApp(
          home: TaskMasterEntry(
            repository: FakeTaskRepository(data: TaskMasterData.empty()),
            journalGateway: FakeJournalGateway(),
            clock: () => now,
            isSchemaV2Checker: () async => true,
            legacyBuilder: (context) => const SizedBox(key: Key('legacy_content')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aktifkan Task Master New?'), findsOneWidget);
      await tester.tap(find.text('Nanti'));
      await tester.pumpAndSettle();

      // Simulasi restart / navigasi ulang dengan mereset in-memory cache dan me-rebuild widget
      resetTaskMasterRolloutCacheForTesting();
      await tester.pumpWidget(
        MaterialApp(
          home: TaskMasterEntry(
            repository: FakeTaskRepository(data: TaskMasterData.empty()),
            journalGateway: FakeJournalGateway(),
            clock: () => now,
            isSchemaV2Checker: () async => true,
            legacyBuilder: (context) => const SizedBox(key: Key('legacy_content')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Dialog promo tidak boleh muncul lagi
      expect(find.text('Aktifkan Task Master New?'), findsNothing);
    });
  });
}

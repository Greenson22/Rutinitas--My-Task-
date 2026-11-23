import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/core/presentation/widgets/drawer_menu.dart';
import 'package:rutinitasku/core/presentation/widgets/settings_dialog.dart';
import 'package:rutinitasku/features/ad_banner_showcase/presentation/screens/ad_banner_showcase_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildSettingsApp() {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            child: SettingsDialog(
              currentBaseDir: 'Documents',
              onSave: (_) {},
              onEncryptionToggled: () {},
            ),
          ),
        ),
      ),
    );
  }

  group('SettingsDialog - Ad Banner Showcase Toggle', () {
    testWidgets('menampilkan toggle Ad Banner Showcase di bagian Fitur Eksperimental', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildSettingsApp());
      await tester.pumpAndSettle();

      expect(find.text('Ad Banner Showcase'), findsOneWidget);
      expect(
        find.text('Tampilkan semua slot banner iklan sekaligus dalam satu layar.'),
        findsOneWidget,
      );
    });

    testWidgets('mengaktifkan toggle menyimpan enable_ad_banner_showcase = true ke SharedPreferences', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({'enable_ad_banner_showcase': false});

      await tester.pumpWidget(buildSettingsApp());
      await tester.pumpAndSettle();

      final switchFinder = find.descendant(
        of: find.widgetWithText(ListTile, 'Ad Banner Showcase'),
        matching: find.byType(Switch),
      );
      expect(switchFinder, findsOneWidget);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('enable_ad_banner_showcase'), isTrue);
    });

    testWidgets('menonaktifkan toggle menyimpan enable_ad_banner_showcase = false ke SharedPreferences', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({'enable_ad_banner_showcase': true});

      await tester.pumpWidget(buildSettingsApp());
      await tester.pumpAndSettle();

      final switchFinder = find.descendant(
        of: find.widgetWithText(ListTile, 'Ad Banner Showcase'),
        matching: find.byType(Switch),
      );
      expect(switchFinder, findsOneWidget);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('enable_ad_banner_showcase'), isFalse);
    });
  });

  group('DrawerMenu - Ad Banner Showcase Menu Item', () {
    testWidgets('menu tidak tampil saat enable_ad_banner_showcase bernilai false', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({'enable_ad_banner_showcase': false});

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            drawer: DrawerMenu(),
          ),
        ),
      );

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Ad Banner Showcase'), findsNothing);
    });

    testWidgets('menu tampil saat enable_ad_banner_showcase bernilai true dan diletakkan sebelum Data Center', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({
        'enable_random_generator': true,
        'enable_ad_banner_showcase': true,
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            drawer: DrawerMenu(),
          ),
        ),
      );

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Ad Banner Showcase'), findsOneWidget);
      expect(find.text('Random Generator'), findsOneWidget);
      expect(find.text('Data Center'), findsOneWidget);

      final randomY = tester.getTopLeft(find.text('Random Generator')).dy;
      final showcaseY = tester.getTopLeft(find.text('Ad Banner Showcase')).dy;
      final dataCenterY = tester.getTopLeft(find.text('Data Center')).dy;

      expect(randomY < showcaseY, isTrue);
      expect(showcaseY < dataCenterY, isTrue);
    });

    testWidgets('mengetuk menu Ad Banner Showcase membuka AdBannerShowcaseScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({'enable_ad_banner_showcase': true});

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            drawer: DrawerMenu(),
          ),
        ),
      );

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Ad Banner Showcase'));
      await tester.pumpAndSettle();

      expect(find.byType(AdBannerShowcaseScreen), findsOneWidget);
    });
  });
}

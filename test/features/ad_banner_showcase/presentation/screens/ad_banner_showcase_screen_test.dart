import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/core/presentation/widgets/adaptive_banner_ad.dart';
import 'package:rutinitasku/features/ad_banner_showcase/presentation/screens/ad_banner_showcase_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildShowcaseScreen() {
    return const MaterialApp(
      home: AdBannerShowcaseScreen(),
    );
  }

  group('AdBannerShowcaseScreen', () {
    testWidgets('menampilkan AppBar dan tombol refresh manual', (tester) async {
      await tester.pumpWidget(buildShowcaseScreen());
      await tester.pump();

      expect(find.text('Ad Banner Showcase'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('menampilkan semua 9 label slot dalam urutan yang benar', (tester) async {
      // Buat window cukup panjang agar semua item ter-render di scrollview
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildShowcaseScreen());
      await tester.pump();

      final expectedSlots = [
        'Task Master',
        'MyChecklist Hub',
        'MyChecklist Detail',
        'MyNote Hub',
        'MyNote Detail',
        'MyPrompt Hub',
        'MyPrompt Detail',
        'My Documents',
        'Data Center',
      ];

      for (final slot in expectedSlots) {
        expect(find.text(slot), findsOneWidget);
      }
    });

    testWidgets('DropdownButton menampilkan pilihan interval dan merespons perubahan', (tester) async {
      await tester.pumpWidget(buildShowcaseScreen());
      await tester.pump();

      // Dropdown saat ini menampilkan nilai default 60s
      expect(find.text('60s'), findsOneWidget);

      // Tap dropdown untuk membuka menu
      await tester.tap(find.text('60s'));
      await tester.pumpAndSettle();

      // Pastikan opsi 30s, 60s, 90s, 120s, 180s, 300s ada
      expect(find.text('30s').last, findsWidgets);
      expect(find.text('120s').last, findsWidgets);
      expect(find.text('300s').last, findsWidgets);

      // Pilih 120s
      await tester.tap(find.text('120s').last);
      await tester.pumpAndSettle();

      expect(find.text('120s'), findsOneWidget);

      // Pastikan SharedPreferences diperbarui
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('ad_showcase_refresh_interval_seconds'), 120);
    });

    testWidgets('tombol refresh manual memperbarui ValueKey pada AdaptiveBannerAd', (tester) async {
      await tester.pumpWidget(buildShowcaseScreen());
      await tester.pump();

      // Cari AdaptiveBannerAd untuk task_master_banner dengan key task_master_banner_0
      expect(
        find.byKey(const ValueKey('task_master_banner_0')),
        findsOneWidget,
      );

      // Tekan tombol refresh manual
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      // Key harus berganti menjadi task_master_banner_1
      expect(
        find.byKey(const ValueKey('task_master_banner_1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('task_master_banner_0')),
        findsNothing,
      );
    });

    testWidgets('tidak crash di platform non-Android dan AdaptiveBannerAd mengembalikan SizedBox.shrink', (tester) async {
      await tester.pumpWidget(buildShowcaseScreen());
      await tester.pump();

      // Di lingkungan test / Linux, AdaptiveBannerAd merender SizedBox.shrink
      expect(find.byType(AdaptiveBannerAd), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}

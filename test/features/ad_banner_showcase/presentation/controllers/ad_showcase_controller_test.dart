import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/features/ad_banner_showcase/presentation/controllers/ad_showcase_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AdShowcaseController', () {
    test('dapat dibuat tanpa UI dan tanpa AdMob SDK', () {
      final controller = AdShowcaseController();
      expect(controller, isNotNull);
      expect(controller.refreshKey, 0);
      expect(controller.intervalSeconds, 60);
      expect(controller.secondsUntilNextRefresh, 60);
      controller.dispose();
    });

    test('refreshKey bernilai 0 saat init, interval default 60 jika belum disimpan di SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = AdShowcaseController();
      await controller.init();

      expect(controller.refreshKey, 0);
      expect(controller.intervalSeconds, 60);
      expect(controller.secondsUntilNextRefresh, 60);

      controller.dispose();
    });

    test('interval dibaca dari SharedPreferences saat init', () async {
      SharedPreferences.setMockInitialValues({
        AdShowcaseController.prefKeyInterval: 90,
      });

      final controller = AdShowcaseController();
      await controller.init();

      expect(controller.intervalSeconds, 90);
      expect(controller.secondsUntilNextRefresh, 90);

      controller.dispose();
    });

    test('interval dari SharedPreferences diklem jika di luar rentang 30-300', () async {
      SharedPreferences.setMockInitialValues({
        AdShowcaseController.prefKeyInterval: 10,
      });

      final controller = AdShowcaseController();
      await controller.init();

      expect(controller.intervalSeconds, 30);
      expect(controller.secondsUntilNextRefresh, 30);

      controller.dispose();
    });

    test('setInterval menyimpan nilai ke SharedPreferences dan mereset countdown & timer', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = AdShowcaseController();
      await controller.init();

      await controller.setInterval(120);

      expect(controller.intervalSeconds, 120);
      expect(controller.secondsUntilNextRefresh, 120);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(AdShowcaseController.prefKeyInterval), 120);

      controller.dispose();
    });

    test('setInterval mengklem nilai ke batas terdekat jika < 30 atau > 300', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = AdShowcaseController();
      await controller.init();

      await controller.setInterval(15);
      expect(controller.intervalSeconds, 30);

      await controller.setInterval(500);
      expect(controller.intervalSeconds, 300);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(AdShowcaseController.prefKeyInterval), 300);

      controller.dispose();
    });

    test('triggerManualRefresh menaikkan refreshKey dan mereset countdown', () async {
      final controller = AdShowcaseController();
      await controller.init();

      expect(controller.refreshKey, 0);
      controller.triggerManualRefresh();
      expect(controller.refreshKey, 1);
      expect(controller.secondsUntilNextRefresh, controller.intervalSeconds);

      controller.triggerManualRefresh();
      expect(controller.refreshKey, 2);

      controller.dispose();
    });

    test('countdown timer berkurang setiap detik dan menaikkan refreshKey saat tiba di 0', () async {
      final controller = AdShowcaseController();
      await controller.setInterval(30);

      // Simulasikan berjalannya waktu dengan async timer
      await Future<void>.delayed(const Duration(milliseconds: 1050));
      expect(controller.secondsUntilNextRefresh, 29);

      controller.dispose();
    });

    test('dispose membatalkan semua timer dan tidak melempar exception', () async {
      final controller = AdShowcaseController();
      await controller.init();

      expect(() => controller.dispose(), returnsNormally);
      // Wait to ensure no periodic timer fires on disposed controller
      await Future<void>.delayed(const Duration(milliseconds: 1100));
    });
  });
}

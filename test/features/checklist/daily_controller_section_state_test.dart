import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/features/checklist/presentation/checklist_screen/controllers/daily_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DailyController section collapse & hidden state', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('isSectionCollapsed returns defaultCollapseState (false) for untoggled section', () {
      final controller = DailyController();

      expect(controller.isSectionCollapsed('Pekerjaan'), isFalse);
    });

    test('toggleSectionCollapsed twice returns to initial state and notifies listeners', () {
      final controller = DailyController();
      var notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.toggleSectionCollapsed('Pekerjaan');
      expect(controller.isSectionCollapsed('Pekerjaan'), isTrue);
      expect(notifyCount, 1);

      controller.toggleSectionCollapsed('Pekerjaan');
      expect(controller.isSectionCollapsed('Pekerjaan'), isFalse);
      expect(notifyCount, 2);
    });

    test('isSectionHidden returns false for untoggled section and toggles properly', () {
      final controller = DailyController();
      var notifyCount = 0;
      controller.addListener(() => notifyCount++);

      expect(controller.isSectionHidden('Pekerjaan'), isFalse);

      controller.toggleSectionHidden('Pekerjaan');
      expect(controller.isSectionHidden('Pekerjaan'), isTrue);
      expect(notifyCount, 1);

      controller.toggleSectionHidden('Pekerjaan');
      expect(controller.isSectionHidden('Pekerjaan'), isFalse);
      expect(notifyCount, 2);
    });

    test('loads checklist_groups_default_collapsed from SharedPreferences on first loadGroupsData', () async {
      SharedPreferences.setMockInitialValues({
        'checklist_groups_default_collapsed': true,
      });
      final controller = DailyController();

      await controller.loadGroupsData(showLoading: false);

      expect(controller.isSectionCollapsed('Seksi Baru'), isTrue);
    });

    test('preserves ephemeral collapse and hidden state across loadGroupsData reloads', () async {
      final controller = DailyController();
      controller.toggleSectionCollapsed('Seksi A');
      controller.toggleSectionHidden('Seksi B');

      await controller.loadGroupsData(showLoading: false);

      expect(controller.isSectionCollapsed('Seksi A'), isTrue);
      expect(controller.isSectionHidden('Seksi B'), isTrue);
    });

    test('persists section collapse state across new DailyController instances', () async {
      final controller1 = DailyController();
      controller1.toggleSectionCollapsed('Pekerjaan');
      await Future<void>.delayed(Duration.zero);

      final controller2 = DailyController();
      await controller2.loadGroupsData(showLoading: false);

      expect(controller2.isSectionCollapsed('Pekerjaan'), isTrue);
    });

    test('persists section hidden state across new DailyController instances', () async {
      final controller1 = DailyController();
      controller1.toggleSectionHidden('Pekerjaan');
      await Future<void>.delayed(Duration.zero);

      final controller2 = DailyController();
      await controller2.loadGroupsData(showLoading: false);

      expect(controller2.isSectionHidden('Pekerjaan'), isTrue);
    });
  });
}

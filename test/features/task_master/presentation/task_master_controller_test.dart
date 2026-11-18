import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/features/task_master/data/models/task_model.dart';
import 'package:rutinitasku/features/task_master/presentation/controllers/task_master_controller.dart';

void main() {
  group('edit kategori modul lama', () {
    test('mengganti nama dan ikon tidak menghapus key tak dikenal', () async {
      final controller = TaskMasterController(onUpdate: () {});
      controller.allCategoriesRaw = [
        TaskCategory.fromJson({
          'name': 'Olahraga',
          'icon': '🏃',
          'isHidden': false,
          'unknownCategoryField': 'dipertahankan',
          'tasks': [
            {
              'id': 't1',
              'name': 'Push up',
              'count': 0,
              'checked': false,
              'countToday': 0,
              'lastUpdated': '',
              'targetCountToday': 0,
              'type': 0,
              'targetCount': 0,
              'isActive': true,
              'history': {'2026-11-18': 3},
            },
          ],
        }),
      ];

      await controller.updateCategory(
        controller.allCategoriesRaw.first,
        'Kebugaran',
        '💪',
      );

      final result = controller.allCategoriesRaw.single.toJson();
      expect(result['name'], 'Kebugaran');
      expect(result['icon'], '💪');
      expect(result['unknownCategoryField'], 'dipertahankan');
      final task = result['tasks'][0] as Map<String, dynamic>;
      expect(task['history'], {'2026-11-18': 3});
    });
  });
}

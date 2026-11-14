import 'dart:async';

import 'package:rutinitasku/features/task_master_new/domain/entities/task_master_data.dart';
import 'package:rutinitasku/features/task_master_new/domain/operations/category_operations.dart';
import 'package:rutinitasku/features/task_master_new/domain/repositories/task_repository.dart';

class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository({this.data, this.error});

  TaskMasterData? data;
  Object? error;
  Completer<TaskMasterData>? loadCompleter;
  int loadCount = 0;
  int saveCount = 0;
  int _categoryIdCounter = 0;

  /// Bila diisi, operasi kategori melempar error ini.
  Object? categoryActionError;

  @override
  Future<TaskMasterData> load() async {
    loadCount++;
    if (loadCompleter != null) return loadCompleter!.future;
    if (error != null) throw error!;
    return data ?? TaskMasterData.empty();
  }

  @override
  Future<void> save(TaskMasterData data) async {
    saveCount++;
    this.data = data;
  }

  @override
  Future<TaskMasterData> addCategory({
    required String name,
    required String icon,
  }) {
    return _mutateCategories(
      (data) => addCategoryTo(
        data,
        id: 'cat_generated_${_categoryIdCounter++}',
        name: name,
        icon: icon,
      ),
    );
  }

  @override
  Future<TaskMasterData> updateCategory({
    required String categoryId,
    required String name,
    required String icon,
  }) {
    return _mutateCategories(
      (data) => updateCategoryIn(
        data,
        categoryId: categoryId,
        name: name,
        icon: icon,
      ),
    );
  }

  @override
  Future<TaskMasterData> setCategoryHidden({
    required String categoryId,
    required bool isHidden,
  }) {
    return _mutateCategories(
      (data) => setCategoryHiddenIn(
        data,
        categoryId: categoryId,
        isHidden: isHidden,
      ),
    );
  }

  @override
  Future<TaskMasterData> deleteCategory(String categoryId) {
    return _mutateCategories(
      (data) => deleteCategoryFrom(data, categoryId: categoryId),
    );
  }

  Future<TaskMasterData> _mutateCategories(
    TaskMasterData Function(TaskMasterData data) transform,
  ) async {
    final failure = categoryActionError;
    if (failure != null) throw failure;
    final updated = transform(data ?? TaskMasterData.empty());
    await save(updated);
    return updated;
  }
}

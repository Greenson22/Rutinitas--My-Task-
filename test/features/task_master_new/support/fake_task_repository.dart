import 'dart:async';

import 'package:rutinitasku/features/task_master_new/data/exceptions/task_master_exceptions.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_backup.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_kind.dart';
import 'package:rutinitasku/features/task_master_new/domain/entities/task_master_data.dart';
import 'package:rutinitasku/features/task_master_new/domain/operations/category_operations.dart';
import 'package:rutinitasku/features/task_master_new/domain/operations/task_operations.dart';
import 'package:rutinitasku/features/task_master_new/domain/repositories/task_repository.dart';

class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository({this.data, this.error});

  TaskMasterData? data;
  Object? error;
  Completer<TaskMasterData>? loadCompleter;
  int loadCount = 0;
  int saveCount = 0;
  int _categoryIdCounter = 0;
  int _taskIdCounter = 0;

  /// PIN yang diterima saat pemulihan file terkunci.
  String? expectedPassword;

  /// Data yang dihasilkan setelah backup dipulihkan.
  TaskMasterData? restoredData;
  List<TaskBackup> backups = const [];
  String rawJson = '{"schemaVersion":2,"categories":[]}';
  Object? rawJsonError;
  int rawSaveCount = 0;
  int createNewFileCount = 0;
  int restoreBackupCount = 0;
  String? lastRawSavedContent;

  /// Bila diisi, operasi kategori melempar error ini.
  Object? categoryActionError;

  /// Bila diisi, operasi tugas melempar error ini.
  Object? taskActionError;

  /// Bila diisi, pemanggilan [save] melempar error ini.
  Object? saveError;

  DateTime now = DateTime(2026, 11, 14, 12);

  @override
  Future<TaskMasterData> load({String? password}) async {
    loadCount++;
    if (password != null) {
      if (expectedPassword == null || password != expectedPassword) {
        throw TaskDecryptionException('Kata sandi salah.');
      }
      error = null;
    }
    if (loadCompleter != null) return loadCompleter!.future;
    if (error != null) throw error!;
    return data ?? TaskMasterData.empty();
  }

  @override
  Future<void> save(TaskMasterData data) async {
    final failure = saveError;
    if (failure != null) throw failure;
    saveCount++;
    this.data = data;
  }

  @override
  Future<String> readRawJson() async {
    final failure = rawJsonError;
    if (failure != null) throw failure;
    return rawJson;
  }

  @override
  Future<TaskMasterData> saveRawJson(String content) async {
    rawSaveCount++;
    lastRawSavedContent = content;
    final failure = rawJsonError;
    if (failure != null) throw failure;
    final updated = data ?? TaskMasterData.empty();
    await save(updated);
    return updated;
  }

  @override
  Future<List<TaskBackup>> listBackups() async => backups;

  @override
  Future<TaskMasterData> restoreBackup(TaskBackup backup) async {
    restoreBackupCount++;
    final restored = restoredData ?? data ?? TaskMasterData.empty();
    data = restored;
    error = null;
    return restored;
  }

  @override
  Future<TaskMasterData> createNewFile() async {
    createNewFileCount++;
    final empty = TaskMasterData.empty();
    await save(empty);
    error = null;
    return empty;
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
      (data) =>
          setCategoryHiddenIn(data, categoryId: categoryId, isHidden: isHidden),
    );
  }

  @override
  Future<TaskMasterData> reorderCategory({
    required String categoryId,
    required int newIndex,
  }) {
    return _mutateCategories(
      (data) =>
          reorderCategoryIn(data, categoryId: categoryId, newIndex: newIndex),
    );
  }

  @override
  Future<TaskMasterData> deleteCategory(String categoryId) {
    return _mutateCategories(
      (data) => deleteCategoryFrom(data, categoryId: categoryId),
    );
  }

  @override
  Future<TaskMasterData> addTask({
    required String categoryId,
    required String name,
    required TaskKind kind,
    required int targetDaily,
    required int targetTotal,
    required bool isActive,
  }) {
    return _mutateTasks(
      (data) => addTaskTo(
        data,
        id: 'task_generated_${_taskIdCounter++}',
        categoryId: categoryId,
        name: name,
        kind: kind,
        targetDaily: targetDaily,
        targetTotal: targetTotal,
        isActive: isActive,
        now: now,
      ),
    );
  }

  @override
  Future<TaskMasterData> updateTask({
    required String categoryId,
    required String taskId,
    required String name,
    required TaskKind kind,
    required int targetDaily,
    required int targetTotal,
    required bool isActive,
  }) {
    return _mutateTasks(
      (data) => updateTaskIn(
        data,
        categoryId: categoryId,
        taskId: taskId,
        name: name,
        kind: kind,
        targetDaily: targetDaily,
        targetTotal: targetTotal,
        isActive: isActive,
        now: now,
      ),
    );
  }

  @override
  Future<TaskMasterData> setTaskActive({
    required String categoryId,
    required String taskId,
    required bool isActive,
  }) {
    return _mutateTasks(
      (data) => setTaskActiveIn(
        data,
        categoryId: categoryId,
        taskId: taskId,
        isActive: isActive,
        now: now,
      ),
    );
  }

  @override
  Future<TaskMasterData> reorderTask({
    required String categoryId,
    required String taskId,
    required int newIndex,
  }) {
    return _mutateTasks(
      (data) => reorderTaskIn(
        data,
        categoryId: categoryId,
        taskId: taskId,
        newIndex: newIndex,
        now: now,
      ),
    );
  }

  @override
  Future<TaskMasterData> moveTask({
    required String fromCategoryId,
    required String taskId,
    required String toCategoryId,
  }) {
    return _mutateTasks(
      (data) => moveTaskToCategoryIn(
        data,
        fromCategoryId: fromCategoryId,
        taskId: taskId,
        toCategoryId: toCategoryId,
        now: now,
      ),
    );
  }

  @override
  Future<TaskMasterData> setTasksActive({
    required String categoryId,
    required Iterable<String> taskIds,
    required bool isActive,
  }) {
    return _mutateTasks(
      (data) => setTasksActiveIn(
        data,
        categoryId: categoryId,
        taskIds: taskIds,
        isActive: isActive,
        now: now,
      ),
    );
  }

  @override
  Future<TaskMasterData> deleteTasks({
    required String categoryId,
    required Iterable<String> taskIds,
  }) {
    return _mutateTasks(
      (data) => deleteTasksFrom(data, categoryId: categoryId, taskIds: taskIds),
    );
  }

  @override
  Future<TaskMasterData> deleteTask({
    required String categoryId,
    required String taskId,
  }) {
    return _mutateTasks(
      (data) => deleteTaskFrom(data, categoryId: categoryId, taskId: taskId),
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

  Future<TaskMasterData> _mutateTasks(
    TaskMasterData Function(TaskMasterData data) transform,
  ) async {
    final failure = taskActionError;
    if (failure != null) throw failure;
    final updated = transform(data ?? TaskMasterData.empty());
    await save(updated);
    return updated;
  }
}

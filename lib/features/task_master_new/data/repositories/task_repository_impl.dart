import 'dart:convert';
import 'dart:math';

import '../../domain/entities/task_kind.dart';
import '../../domain/entities/task_master_data.dart';
import '../../domain/operations/category_operations.dart';
import '../../domain/operations/task_operations.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_data_source.dart';
import '../exceptions/task_master_exceptions.dart';
import '../mappers/task_master_mapper.dart';

/// Memuat data, memigrasikan file legacy, menyimpan skema v2, dan menangani
/// operasi kategori.
class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl({
    required TaskLocalDataSource localDataSource,
    TaskMasterMapper? mapper,
    String Function()? categoryIdGenerator,
    String Function()? taskIdGenerator,
    DateTime Function()? clock,
  }) : _localDataSource = localDataSource,
       _mapper = mapper ?? TaskMasterMapper(),
       _clock = clock ?? DateTime.now {
    _categoryIdGenerator = categoryIdGenerator ?? () => _generateId('cat');
    _taskIdGenerator = taskIdGenerator ?? () => _generateId('task');
  }

  final TaskLocalDataSource _localDataSource;
  final TaskMasterMapper _mapper;
  final DateTime Function() _clock;
  late final String Function() _categoryIdGenerator;
  late final String Function() _taskIdGenerator;

  @override
  Future<TaskMasterData> load() async {
    final snapshot = await _localDataSource.read();
    if (snapshot == null) return TaskMasterData.empty();

    final Map<String, dynamic> decoded;
    try {
      final parsed = jsonDecode(snapshot.content);
      if (parsed is! Map) {
        throw const FormatException('Akar JSON bukan objek.');
      }
      decoded = parsed.map((key, value) => MapEntry(key.toString(), value));
    } catch (error) {
      throw TaskDataCorruptedException(
        'File Task Master tidak berisi JSON yang valid. '
        'Data tidak diubah; pulihkan backup atau buat file baru.',
        cause: error,
      );
    }

    final version = _mapper.detectSchemaVersion(decoded);
    if (version != 1 && version != TaskMasterData.currentSchemaVersion) {
      // Jangan membuat backup atau menulis apa pun untuk versi yang tidak dikenal.
      throw UnsupportedSchemaVersionException(version);
    }

    if (version == TaskMasterData.currentSchemaVersion) {
      return _mapper.fromJson(decoded);
    }

    return _migrate(snapshot, decoded);
  }

  Future<TaskMasterData> _migrate(
    TaskFileSnapshot snapshot,
    Map<String, dynamic> decoded,
  ) async {
    final backup = await _localDataSource.createBackup(snapshot);

    final migratedData = _mapper.fromJson(decoded);
    final v2Json = _mapper.toJson(migratedData, original: decoded);
    try {
      await _localDataSource.write(jsonEncode(v2Json));
      return migratedData;
    } catch (error) {
      throw TaskMigrationException(
        'Migrasi Task Master gagal. File asli tidak diubah. '
        'Backup tersedia di: ${backup.path}',
        backupPath: backup.path,
        cause: error,
      );
    }
  }

  @override
  Future<void> save(TaskMasterData data) async {
    final json = _mapper.toJson(data);
    await _localDataSource.write(jsonEncode(json));
  }

  @override
  Future<TaskMasterData> addCategory({
    required String name,
    required String icon,
  }) {
    return _mutateData(
      (data) => addCategoryTo(
        data,
        id: _categoryIdGenerator(),
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
    return _mutateData(
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
    return _mutateData(
      (data) =>
          setCategoryHiddenIn(data, categoryId: categoryId, isHidden: isHidden),
    );
  }

  @override
  Future<TaskMasterData> deleteCategory(String categoryId) {
    return _mutateData(
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
    return _mutateData(
      (data) => addTaskTo(
        data,
        id: _taskIdGenerator(),
        categoryId: categoryId,
        name: name,
        kind: kind,
        targetDaily: targetDaily,
        targetTotal: targetTotal,
        isActive: isActive,
        now: _clock(),
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
    return _mutateData(
      (data) => updateTaskIn(
        data,
        categoryId: categoryId,
        taskId: taskId,
        name: name,
        kind: kind,
        targetDaily: targetDaily,
        targetTotal: targetTotal,
        isActive: isActive,
        now: _clock(),
      ),
    );
  }

  @override
  Future<TaskMasterData> setTaskActive({
    required String categoryId,
    required String taskId,
    required bool isActive,
  }) {
    return _mutateData(
      (data) => setTaskActiveIn(
        data,
        categoryId: categoryId,
        taskId: taskId,
        isActive: isActive,
        now: _clock(),
      ),
    );
  }

  @override
  Future<TaskMasterData> deleteTask({
    required String categoryId,
    required String taskId,
  }) {
    return _mutateData(
      (data) => deleteTaskFrom(data, categoryId: categoryId, taskId: taskId),
    );
  }

  Future<TaskMasterData> _mutateData(
    TaskMasterData Function(TaskMasterData data) transform,
  ) async {
    final data = await load();
    final updated = transform(data);
    await save(updated);
    return updated;
  }

  String _generateId(String prefix) {
    final random = Random();
    final suffix = random.nextInt(1 << 32).toRadixString(36);
    return '${prefix}_'
        '${_clock().microsecondsSinceEpoch.toRadixString(36)}'
        '_$suffix';
  }
}

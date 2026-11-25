import 'dart:async';
import 'dart:math';
import '../../domain/entities/task_backup.dart';
import '../../domain/entities/task_kind.dart';
import '../../domain/entities/task_master_data.dart';
import '../../domain/entities/today_visibility.dart';
import '../../domain/operations/category_operations.dart';
import '../../domain/operations/task_operations.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_data_source.dart';
import '../exceptions/task_master_exceptions.dart';
import '../mappers/task_master_mapper.dart';
import '../services/background_codec.dart';

/// Memuat data, memigrasikan file legacy, menyimpan skema v2, dan menangani
/// operasi kategori.
class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl({
    required TaskLocalDataSource localDataSource,
    TaskMasterMapper? mapper,
    TaskJsonCodec? jsonCodec,
    String Function()? categoryIdGenerator,
    String Function()? taskIdGenerator,
    DateTime Function()? clock,
  }) : _localDataSource = localDataSource,
       _mapper = mapper ?? TaskMasterMapper(),
       _jsonCodec = jsonCodec ?? const IsolateTaskJsonCodec(),
       _clock = clock ?? DateTime.now {
    _categoryIdGenerator = categoryIdGenerator ?? () => _generateId('cat');
    _taskIdGenerator = taskIdGenerator ?? () => _generateId('task');
  }

  final TaskLocalDataSource _localDataSource;
  final TaskMasterMapper _mapper;
  final TaskJsonCodec _jsonCodec;
  final DateTime Function() _clock;
  late final String Function() _categoryIdGenerator;
  late final String Function() _taskIdGenerator;

  /// Mengurutkan seluruh penulisan file utama sesuai urutan pemanggilan.
  ///
  /// Encoding berjalan di isolate dan bisa selesai tidak berurutan. Antrean ini
  /// memastikan penyimpanan berikutnya baru dimulai setelah penyimpanan
  /// sebelumnya selesai, sesuai SPEC bagian konkurensi.
  Future<void> _saveQueue = Future<void>.value();

  @override
  Future<TaskMasterData> load({String? password}) async {
    final snapshot = await _localDataSource.read(password: password);
    if (snapshot == null) return TaskMasterData.empty();

    final decoded = await _decodeJsonMap(
      snapshot.content,
      invalidMessage:
          'File Task Master tidak berisi JSON yang valid. '
          'Data tidak diubah; pulihkan backup atau buat file baru.',
    );

    final version = _validateSchemaVersion(decoded);
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
      await _writeSerialized(() => _jsonCodec.encode(v2Json));
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
  Future<void> save(TaskMasterData data) {
    return _writeSerialized(() async {
      final json = _mapper.toJson(data);
      return _jsonCodec.encode(json);
    });
  }

  /// Menjalankan pembuatan konten dan penulisan file secara berurutan.
  Future<void> _writeSerialized(Future<String> Function() buildContent) {
    return _runSerialized(() async {
      await _localDataSource.write(await buildContent());
    });
  }

  /// Menjalankan operasi yang mengubah file utama sesuai urutan pemanggilan.
  Future<T> _runSerialized<T>(Future<T> Function() action) {
    final previous = _saveQueue;
    final completer = Completer<T>();
    _saveQueue = completer.future.then<void>((_) {}, onError: (_) {});
    unawaited(() async {
      try {
        await previous;
      } catch (_) {
        // Operasi sebelumnya gagal; antrean tetap harus bisa dipakai.
      }
      try {
        completer.complete(await action());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    }());
    return completer.future;
  }

  @override
  Future<String> readRawJson() async {
    final snapshot = await _localDataSource.read();
    if (snapshot == null) {
      return _jsonCodec.encodePretty(_mapper.toJson(TaskMasterData.empty()));
    }
    try {
      final decoded = await _jsonCodec.decodeMap(snapshot.content);
      return _jsonCodec.encodePretty(decoded);
    } on FormatException {
      // File korup tetap dapat dibuka di editor Advanced agar pengguna bisa
      // memperbaiki struktur JSON-nya.
      return snapshot.content;
    }
  }

  @override
  Future<TaskMasterData> saveRawJson(String content) async {
    final map = await _decodeJsonMap(
      content,
      invalidMessage: 'JSON tidak valid',
    );
    _validateSchemaVersion(map);

    // Validasi dan normalisasi di memori sebelum menyentuh file. Dengan begitu
    // JSON yang valid secara sintaks tetapi tidak valid sebagai data Task
    // Master tidak pernah menimpa file asli.
    final data = _mapper.fromJson(map);
    final normalized = _mapper.toJson(data, original: map);
    await _writeSerialized(() => _jsonCodec.encodePretty(normalized));
    return data;
  }

  @override
  Future<String> exportJson() async {
    final snapshot = await _localDataSource.read();
    if (snapshot == null) {
      return _jsonCodec.encodePretty(_mapper.toJson(TaskMasterData.empty()));
    }
    // Konten mentah dipertahankan agar ekspor mengikuti status enkripsi file.
    return snapshot.rawContent;
  }

  @override
  Future<TaskMasterData> validateImportJson(String content) async {
    return (await _prepareImport(content)).data;
  }

  @override
  Future<TaskMasterData> importJson(String content) async {
    final prepared = await _prepareImport(content);

    // Backup dibuat sebelum file utama disentuh. Bila backup gagal, import
    // dibatalkan sehingga data lama tetap utuh.
    await _localDataSource.backupCurrentFile();
    await _writeSerialized(() async => prepared.content);
    return prepared.data;
  }

  Future<({TaskMasterData data, String content})> _prepareImport(
    String rawContent,
  ) async {
    final content = await _localDataSource.decodeExternalContent(rawContent);
    final map = await _decodeJsonMap(
      content,
      invalidMessage:
          'File yang diimpor bukan JSON Task Master yang valid. '
          'Data saat ini tidak diubah.',
    );
    _validateSchemaVersion(map);

    // Pemetakan memvalidasi struktur kategori/tugas sebelum file ditulis.
    final data = _mapper.fromJson(map);
    return (data: data, content: content);
  }

  Future<Map<String, dynamic>> _decodeJsonMap(
    String content, {
    required String invalidMessage,
  }) async {
    try {
      return await _jsonCodec.decodeMap(content);
    } catch (error) {
      throw TaskDataCorruptedException('$invalidMessage: $error', cause: error);
    }
  }

  int _validateSchemaVersion(Map<String, dynamic> json) {
    final version = _mapper.detectSchemaVersion(json);
    if (version != 1 && version != TaskMasterData.currentSchemaVersion) {
      // Jangan membuat backup atau menulis apa pun untuk versi yang tidak dikenal.
      throw UnsupportedSchemaVersionException(version);
    }
    return version;
  }

  @override
  Future<List<TaskBackup>> listBackups() async {
    final backups = await _localDataSource.listBackups();
    final mapped = [
      for (final backup in backups)
        TaskBackup(path: backup.path, createdAt: backup.createdAt),
    ];
    mapped.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return mapped;
  }

  @override
  Future<TaskMasterData> restoreBackup(TaskBackup backup) async {
    await _runSerialized(() => _localDataSource.restoreBackup(backup.path));
    return load();
  }

  @override
  Future<TaskMasterData> createNewFile() async {
    await _localDataSource.backupCurrentFile();
    final empty = TaskMasterData.empty();
    await save(empty);
    return empty;
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
  Future<TaskMasterData> reorderCategory({
    required String categoryId,
    required int newIndex,
  }) {
    return _mutateData(
      (data) =>
          reorderCategoryIn(data, categoryId: categoryId, newIndex: newIndex),
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
    TodayVisibility todayVisibility = TodayVisibility.auto,
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
        todayVisibility: todayVisibility,
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
    TodayVisibility? todayVisibility,
    int? countToday,
    String? countDate,
    int? totalCount,
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
        todayVisibility: todayVisibility,
        countToday: countToday,
        countDate: countDate,
        totalCount: totalCount,
        now: _clock(),
      ),
    );
  }

  @override
  Future<TaskMasterData> setTaskVisibility({
    required String categoryId,
    required String taskId,
    required TodayVisibility todayVisibility,
  }) {
    return _mutateData(
      (data) => setTaskVisibilityIn(
        data,
        categoryId: categoryId,
        taskId: taskId,
        todayVisibility: todayVisibility,
        now: _clock(),
      ),
    );
  }

  @override
  Future<TaskMasterData> setTasksVisibility({
    required String categoryId,
    required Iterable<String> taskIds,
    required TodayVisibility todayVisibility,
  }) {
    return _mutateData(
      (data) => setTasksVisibilityIn(
        data,
        categoryId: categoryId,
        taskIds: taskIds,
        todayVisibility: todayVisibility,
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
  Future<TaskMasterData> reorderTask({
    required String categoryId,
    required String taskId,
    required int newIndex,
  }) {
    return _mutateData(
      (data) => reorderTaskIn(
        data,
        categoryId: categoryId,
        taskId: taskId,
        newIndex: newIndex,
        now: _clock(),
      ),
    );
  }

  @override
  Future<TaskMasterData> moveTask({
    required String fromCategoryId,
    required String taskId,
    required String toCategoryId,
  }) {
    return _mutateData(
      (data) => moveTaskToCategoryIn(
        data,
        fromCategoryId: fromCategoryId,
        taskId: taskId,
        toCategoryId: toCategoryId,
        now: _clock(),
      ),
    );
  }

  @override
  Future<TaskMasterData> setTasksActive({
    required String categoryId,
    required Iterable<String> taskIds,
    required bool isActive,
  }) {
    return _mutateData(
      (data) => setTasksActiveIn(
        data,
        categoryId: categoryId,
        taskIds: taskIds,
        isActive: isActive,
        now: _clock(),
      ),
    );
  }

  @override
  Future<TaskMasterData> deleteTasks({
    required String categoryId,
    required Iterable<String> taskIds,
  }) {
    return _mutateData(
      (data) => deleteTasksFrom(data, categoryId: categoryId, taskIds: taskIds),
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

import 'dart:convert';

import '../../domain/entities/task_master_data.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_data_source.dart';
import '../exceptions/task_master_exceptions.dart';
import '../mappers/task_master_mapper.dart';

/// Memuat data, memigrasikan file legacy, dan menyimpan skema v2.
class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl({
    required TaskLocalDataSource localDataSource,
    TaskMasterMapper? mapper,
  }) : _localDataSource = localDataSource,
       _mapper = mapper ?? TaskMasterMapper();

  final TaskLocalDataSource _localDataSource;
  final TaskMasterMapper _mapper;

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
}

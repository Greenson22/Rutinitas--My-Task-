import 'package:rutinitasku/features/task_master_new/data/datasources/task_local_data_source.dart';
import 'package:rutinitasku/features/task_master_new/data/exceptions/task_master_exceptions.dart';

class FakeTaskLocalDataSource implements TaskLocalDataSource {
  FakeTaskLocalDataSource({this.snapshot});

  TaskFileSnapshot? snapshot;
  Object? readError;
  Object? writeError;

  int readCount = 0;
  int writeCount = 0;
  int backupCount = 0;
  int restoreCount = 0;
  final List<String> writes = [];
  final List<TaskFileSnapshot> backups = [];
  final Map<String, TaskFileSnapshot> backupSnapshots = {};

  @override
  Future<TaskFileSnapshot?> read({String? password}) async {
    readCount++;
    if (readError != null) throw readError!;
    return snapshot;
  }

  @override
  Future<void> write(String content) async {
    if (writeError != null) throw writeError!;
    writeCount++;
    writes.add(content);
    snapshot = TaskFileSnapshot(
      rawContent: content,
      content: content,
      wasEncrypted: false,
    );
  }

  @override
  Future<TaskBackupInfo> createBackup(TaskFileSnapshot snapshot) async {
    backupCount++;
    backups.add(snapshot);
    final path = '/tmp/my_tasks_backup_$backupCount.json';
    backupSnapshots[path] = snapshot;
    return TaskBackupInfo(path: path, createdAt: DateTime(2026, 11, 14, 12));
  }

  @override
  Future<TaskBackupInfo?> backupCurrentFile() async {
    final current = snapshot;
    if (current == null) return null;
    return createBackup(current);
  }

  @override
  Future<List<TaskBackupInfo>> listBackups() async {
    return [
      for (var i = 0; i < backups.length; i++)
        TaskBackupInfo(
          path: '/tmp/my_tasks_backup_${i + 1}.json',
          createdAt: DateTime(2026, 11, 14, 12, i),
        ),
    ];
  }

  @override
  Future<void> restoreBackup(String backupPath) async {
    restoreCount++;
    final restored = backupSnapshots[backupPath];
    if (restored == null) {
      throw TaskDataSourceException('Backup tidak ditemukan.');
    }
    snapshot = restored;
  }
}

import 'package:rutinitasku/core/services/storage_service.dart';

import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_data_source.dart';
import '../mappers/task_master_mapper.dart';
import 'task_repository_impl.dart';

/// Membuat repository default yang memakai penyimpanan, enkripsi, dan
/// atomic write yang sudah ada di core.
TaskRepository createTaskRepository({
  StorageService? storageService,
  DateTime Function()? clock,
}) {
  final storage = storageService ?? StorageService();
  final localDataSource = FileTaskLocalDataSource(
    storageService: storage,
    baseDirProvider: storage.getBaseDirSetting,
    encryptionEnabledProvider: storage.isEncryptionEnabled,
    passwordProvider: storage.getEncryptionPassword,
    clock: clock,
  );

  return TaskRepositoryImpl(
    localDataSource: localDataSource,
    mapper: TaskMasterMapper(clock: clock),
    clock: clock,
  );
}

import 'package:flutter/foundation.dart';

import '../../data/exceptions/task_master_exceptions.dart';
import '../../domain/entities/daily_progress.dart';
import '../../domain/repositories/task_repository.dart';
import 'task_master_state.dart';

/// Controller baca-saja untuk Task Master New.
class TaskMasterNewController extends ChangeNotifier {
  TaskMasterNewController({
    required TaskRepository repository,
    DateTime Function()? clock,
  }) : _repository = repository,
       _clock = clock ?? DateTime.now;

  final TaskRepository _repository;
  final DateTime Function() _clock;

  TaskMasterNewState _state = const TaskMasterNewState.loading();
  TaskMasterNewState get state => _state;

  bool _disposed = false;

  String get todayKey => DailyProgress.dateKey(_clock());

  Future<void> load() async {
    _setState(const TaskMasterNewState.loading());
    try {
      final data = await _repository.load();
      if (data.categories.isEmpty) {
        _setState(
          TaskMasterNewState(status: TaskMasterNewStatus.empty, data: data),
        );
        return;
      }
      _setState(
        TaskMasterNewState(status: TaskMasterNewStatus.ready, data: data),
      );
    } on UnsupportedSchemaVersionException catch (error) {
      _setState(
        TaskMasterNewState(
          status: TaskMasterNewStatus.error,
          errorTitle: 'Versi data tidak didukung',
          errorMessage: error.message,
        ),
      );
    } on TaskMigrationException catch (error) {
      _setState(
        TaskMasterNewState(
          status: TaskMasterNewStatus.error,
          errorTitle: 'Migrasi data gagal',
          errorMessage: error.message,
        ),
      );
    } on TaskLockedException catch (error) {
      _setState(
        TaskMasterNewState(
          status: TaskMasterNewStatus.error,
          errorTitle: 'Data terkunci',
          errorMessage: error.message,
        ),
      );
    } on TaskDecryptionException catch (error) {
      _setState(
        TaskMasterNewState(
          status: TaskMasterNewStatus.error,
          errorTitle: 'Gagal membuka data',
          errorMessage: error.message,
        ),
      );
    } on TaskDataCorruptedException catch (error) {
      _setState(
        TaskMasterNewState(
          status: TaskMasterNewStatus.error,
          errorTitle: 'Data tidak dapat dibaca',
          errorMessage: error.message,
        ),
      );
    } on TaskMasterException catch (error) {
      _setState(
        TaskMasterNewState(
          status: TaskMasterNewStatus.error,
          errorTitle: 'Gagal memuat data',
          errorMessage: error.message,
        ),
      );
    } catch (error) {
      _setState(
        TaskMasterNewState(
          status: TaskMasterNewStatus.error,
          errorTitle: 'Gagal memuat data',
          errorMessage:
              'Terjadi kesalahan tak terduga saat memuat Task Master. '
              'Data asli tidak diubah. Silakan coba lagi.\n\n$error',
        ),
      );
    }
  }

  void _setState(TaskMasterNewState state) {
    if (_disposed) return;
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

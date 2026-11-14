import 'package:flutter/foundation.dart';

import '../../data/exceptions/task_master_exceptions.dart';
import '../../domain/entities/daily_progress.dart';
import '../../domain/entities/task_master_data.dart';
import '../../domain/operations/category_operations.dart' as ops;
import '../../domain/repositories/task_repository.dart';
import 'task_master_state.dart';

/// Controller untuk Task Master New: memuat data dan mengelola kategori.
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
  Future<TaskMasterData> Function()? _retryAction;

  String get todayKey => DailyProgress.dateKey(_clock());

  Future<void> load() async {
    _retryAction = null;
    _setState(const TaskMasterNewState.loading());
    try {
      final data = await _repository.load();
      _setState(_stateForData(data));
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

  /// Memvalidasi nama kategori untuk form tambah/edit.
  String? validateCategoryName(String name, {String? categoryId}) {
    final categories = _state.data?.categories ?? const [];
    return ops.validateCategoryName(
      name,
      existingCategories: categories,
      exceptId: categoryId,
    );
  }

  Future<bool> addCategory({
    required String name,
    required String icon,
  }) async {
    return _runCategoryAction(
      () => _repository.addCategory(name: name, icon: icon),
    );
  }

  Future<bool> updateCategory({
    required String categoryId,
    required String name,
    required String icon,
  }) async {
    return _runCategoryAction(
      () => _repository.updateCategory(
        categoryId: categoryId,
        name: name,
        icon: icon,
      ),
    );
  }

  Future<bool> setCategoryHidden(
    String categoryId, {
    required bool isHidden,
  }) async {
    return _runCategoryAction(
      () => _repository.setCategoryHidden(
        categoryId: categoryId,
        isHidden: isHidden,
      ),
    );
  }

  Future<bool> deleteCategory(String categoryId) async {
    return _runCategoryAction(
      () => _repository.deleteCategory(categoryId),
    );
  }

  void clearActionMessage() {
    if (_state.actionMessage == null) return;
    _retryAction = null;
    _setState(_state.copyWith(clearActionMessage: true));
  }

  /// Mengulang aksi penyimpanan terakhir yang gagal.
  Future<void> retryLastAction() async {
    final action = _retryAction;
    if (action == null || _state.isSaving) return;
    await _runCategoryAction(action);
  }

  Future<bool> _runCategoryAction(
    Future<TaskMasterData> Function() action,
  ) async {
    if (_state.isSaving) return false;
    _retryAction = null;
    _setState(_state.copyWith(isSaving: true, clearActionMessage: true));
    try {
      final data = await action();
      _setState(_stateForData(data).copyWith(isSaving: false));
      return true;
    } on ops.CategoryValidationException catch (error) {
      _setState(
        _state.copyWith(
          isSaving: false,
          actionMessage: error.message,
          actionRetryable: false,
        ),
      );
      return false;
    } on TaskMasterException catch (error) {
      _retryAction = action;
      _setState(
        _state.copyWith(
          isSaving: false,
          actionMessage: error.message,
          actionRetryable: true,
        ),
      );
      return false;
    } catch (_) {
      _retryAction = action;
      _setState(
        _state.copyWith(
          isSaving: false,
          actionMessage:
              'Perubahan belum tersimpan. Data lama tetap aman. '
              'Silakan coba lagi.',
          actionRetryable: true,
        ),
      );
      return false;
    }
  }

  TaskMasterNewState _stateForData(TaskMasterData data) {
    return TaskMasterNewState(
      status: data.categories.isEmpty
          ? TaskMasterNewStatus.empty
          : TaskMasterNewStatus.ready,
      data: data,
    );
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

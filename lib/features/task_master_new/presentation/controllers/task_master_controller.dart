import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/exceptions/task_master_exceptions.dart';
import '../../domain/entities/category.dart' as domain;
import '../../domain/entities/daily_progress.dart';
import '../../domain/entities/task_kind.dart';
import '../../domain/entities/task_master_data.dart';
import '../../domain/operations/category_operations.dart' as ops;
import '../../domain/operations/task_operations.dart' as task_ops;
import '../../domain/repositories/task_repository.dart';
import 'task_master_state.dart';

/// Jeda minimum antar-tap agar double tap tidak menambah hitungan dua kali.
const Duration incrementDoubleTapWindow = Duration(milliseconds: 400);

/// Controller untuk Task Master New: memuat data, mengelola kategori dan tugas.
class TaskMasterNewController extends ChangeNotifier {
  TaskMasterNewController({
    required TaskRepository repository,
    DateTime Function()? clock,
    Duration saveDebounce = const Duration(milliseconds: 300),
  }) : _repository = repository,
       _clock = clock ?? DateTime.now,
       _saveDebounce = saveDebounce;

  final TaskRepository _repository;
  final DateTime Function() _clock;
  final Duration _saveDebounce;

  TaskMasterNewState _state = const TaskMasterNewState.loading();
  TaskMasterNewState get state => _state;

  bool _disposed = false;
  Future<TaskMasterData> Function()? _retryAction;

  String? _lastIncrementTaskId;
  DateTime? _lastIncrementAt;
  Timer? _saveTimer;
  TaskMasterData? _pendingSave;

  String get todayKey => DailyProgress.dateKey(_clock());

  Future<void> load() async {
    _retryAction = null;
    _lastIncrementTaskId = null;
    _lastIncrementAt = null;
    if (!await flushPendingSave()) return;
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

  Future<bool> addCategory({required String name, required String icon}) async {
    return _runDataAction(
      () => _repository.addCategory(name: name, icon: icon),
    );
  }

  Future<bool> updateCategory({
    required String categoryId,
    required String name,
    required String icon,
  }) async {
    return _runDataAction(
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
    return _runDataAction(
      () => _repository.setCategoryHidden(
        categoryId: categoryId,
        isHidden: isHidden,
      ),
    );
  }

  Future<bool> deleteCategory(String categoryId) async {
    return _runDataAction(() => _repository.deleteCategory(categoryId));
  }

  /// Memvalidasi nama tugas untuk form tambah/edit.
  String? validateTaskName(String name) {
    return task_ops.validateTaskName(name);
  }

  /// Mengambil kategori dari state saat ini, atau `null` bila tidak ada.
  domain.Category? categoryById(String categoryId) {
    return _state.data?.categoryById(categoryId);
  }

  Future<bool> addTask({
    required String categoryId,
    required String name,
    required TaskKind kind,
    required int targetDaily,
    required int targetTotal,
    required bool isActive,
  }) async {
    return _runDataAction(
      () => _repository.addTask(
        categoryId: categoryId,
        name: name,
        kind: kind,
        targetDaily: targetDaily,
        targetTotal: targetTotal,
        isActive: isActive,
      ),
    );
  }

  Future<bool> updateTask({
    required String categoryId,
    required String taskId,
    required String name,
    required TaskKind kind,
    required int targetDaily,
    required int targetTotal,
    required bool isActive,
  }) async {
    return _runDataAction(
      () => _repository.updateTask(
        categoryId: categoryId,
        taskId: taskId,
        name: name,
        kind: kind,
        targetDaily: targetDaily,
        targetTotal: targetTotal,
        isActive: isActive,
      ),
    );
  }

  Future<bool> setTaskActive({
    required String categoryId,
    required String taskId,
    required bool isActive,
  }) async {
    return _runDataAction(
      () => _repository.setTaskActive(
        categoryId: categoryId,
        taskId: taskId,
        isActive: isActive,
      ),
    );
  }

  Future<bool> deleteTask({
    required String categoryId,
    required String taskId,
  }) async {
    return _runDataAction(
      () => _repository.deleteTask(categoryId: categoryId, taskId: taskId),
    );
  }

  /// Menaikkan hitungan tugas satu kali tanpa menunggu penulisan file.
  ///
  /// State langsung diperbarui secara optimistis, lalu penyimpanan dijadwalkan
  /// dengan debounce. Mengembalikan `false` bila increment diabaikan, misalnya
  /// karena double tap atau tugas tidak ditemukan.
  bool incrementTask({required String categoryId, required String taskId}) {
    final data = _state.data;
    if (data == null || _state.isSaving) return false;

    final now = _clock();
    final lastAt = _lastIncrementAt;
    if (lastAt != null && _lastIncrementTaskId == taskId) {
      final elapsed = now.difference(lastAt);
      if (!elapsed.isNegative && elapsed < incrementDoubleTapWindow) {
        return false;
      }
    }

    final task_ops.IncrementResult result;
    try {
      result = task_ops.incrementTaskIn(
        data,
        categoryId: categoryId,
        taskId: taskId,
        now: now,
      );
    } on task_ops.TaskValidationException {
      return false;
    }

    _lastIncrementTaskId = taskId;
    _lastIncrementAt = now;
    _setState(
      _state.copyWith(
        data: result.data,
        lastIncrement: result.increment,
        clearActionMessage: true,
      ),
    );
    _scheduleSave(result.data);
    return true;
  }

  /// Membatalkan increment terakhir yang masih tersimpan di state.
  bool undoLastIncrement() {
    final data = _state.data;
    final increment = _state.lastIncrement;
    if (data == null || increment == null || _state.isSaving) return false;

    final TaskMasterData updated;
    try {
      updated = task_ops.undoIncrementIn(
        data,
        increment: increment,
        now: _clock(),
      );
    } on task_ops.TaskValidationException {
      _setState(_state.copyWith(clearLastIncrement: true));
      return false;
    }

    _setState(
      _state.copyWith(
        data: updated,
        clearLastIncrement: true,
        clearActionMessage: true,
      ),
    );
    _scheduleSave(updated);
    return true;
  }

  /// Menyimpan segera perubahan yang masih menunggu debounce.
  ///
  /// Mengembalikan `false` bila penyimpanan gagal; banner retry sudah dipasang
  /// pada state saat itu.
  Future<bool> flushPendingSave() {
    _saveTimer?.cancel();
    _saveTimer = null;
    return _flushPendingSave();
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
    await _runDataAction(action);
  }

  void _scheduleSave(TaskMasterData data) {
    _pendingSave = data;
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDebounce, () {
      _saveTimer = null;
      unawaited(_flushPendingSave());
    });
  }

  Future<bool> _flushPendingSave() async {
    final data = _pendingSave;
    if (data == null) return true;
    _pendingSave = null;

    try {
      await _repository.save(data);
      return true;
    } on TaskMasterException catch (error) {
      _markSaveFailed(error.message);
    } catch (_) {
      _markSaveFailed(
        'Perubahan belum tersimpan. Data di layar tetap aman. '
        'Silakan coba lagi.',
      );
    }
    return false;
  }

  void _markSaveFailed(String message) {
    _retryAction = () async {
      final data = _state.data;
      if (data == null) return TaskMasterData.empty();
      await _repository.save(data);
      _pendingSave = null;
      return data;
    };
    _setState(
      _state.copyWith(
        isSaving: false,
        actionMessage: message,
        actionRetryable: true,
      ),
    );
  }

  Future<bool> _runDataAction(Future<TaskMasterData> Function() action) async {
    if (_state.isSaving) return false;
    _retryAction = null;
    _setState(_state.copyWith(isSaving: true, clearActionMessage: true));
    // Pastikan increment yang masih menunggu debounce tidak tertimpa oleh
    // data yang dibaca ulang oleh aksi berikutnya.
    if (!await flushPendingSave()) return false;
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
    } on task_ops.TaskValidationException catch (error) {
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
    _saveTimer?.cancel();
    _saveTimer = null;
    final pending = _pendingSave;
    _pendingSave = null;
    if (pending != null) {
      unawaited(_repository.save(pending).catchError((_) {}));
    }
    super.dispose();
  }
}

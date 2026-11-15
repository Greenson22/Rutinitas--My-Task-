import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/exceptions/task_master_exceptions.dart';
import '../../domain/entities/category.dart' as domain;
import '../../domain/entities/daily_progress.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_backup.dart';
import '../../domain/entities/task_kind.dart';
import '../../domain/entities/task_master_data.dart';
import '../../domain/operations/category_operations.dart' as ops;
import '../../domain/operations/task_operations.dart' as task_ops;
import '../../domain/operations/task_search.dart';
import '../../domain/repositories/journal_gateway.dart';
import '../../domain/repositories/task_repository.dart';
import 'task_master_state.dart';

/// Jeda minimum antar-tap agar double tap tidak menambah hitungan dua kali.
const Duration incrementDoubleTapWindow = Duration(milliseconds: 400);

/// Controller untuk Task Master New: memuat data, mengelola kategori dan tugas.
class TaskMasterNewController extends ChangeNotifier {
  TaskMasterNewController({
    required TaskRepository repository,
    JournalGateway? journalGateway,
    DateTime Function()? clock,
    Duration saveDebounce = const Duration(milliseconds: 300),
  }) : _repository = repository,
       _journalGateway = journalGateway,
       _clock = clock ?? DateTime.now,
       _saveDebounce = saveDebounce;

  final TaskRepository _repository;
  final JournalGateway? _journalGateway;
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
  _PendingJournalIncrement? _lastJournalIncrement;

  /// Apakah tugas ini tertaut ke aktivitas Jurnal.
  bool isTaskLinkedToJournal(String taskId) =>
      _state.isTaskLinkedToJournal(taskId);

  /// Durasi Jurnal yang akan ditambahkan pada increment berikutnya.
  int get journalIncrementMinutes => _state.journalIncrementMinutes;

  /// Total durasi Jurnal hari ini menurut data terakhir yang dibaca.
  int get journalTodayMinutes => _state.journalTodayMinutes;

  /// Query pencarian yang sudah diterapkan.
  String get searchQuery => _state.searchQuery;

  /// Filter tugas yang sedang aktif.
  TaskFilter get taskFilter => _state.taskFilter;

  /// Apakah pencarian atau filter sedang menyaring daftar.
  bool get isSearchActive => _state.isSearchActive;

  String get todayKey => DailyProgress.dateKey(_clock());

  /// Mengelompokkan hasil pencarian per kategori dari data terakhir.
  List<TaskSearchGroup> searchGroups({bool includeHidden = false}) {
    final data = _state.data;
    if (data == null) return const [];
    return searchTaskGroups(
      data,
      query: _state.searchQuery,
      filter: _state.taskFilter,
      includeHidden: includeHidden,
    );
  }

  /// Menyaring tugas di dalam satu kategori.
  List<Task> filteredTasksIn(
    domain.Category category, {
    String? query,
    TaskFilter? filter,
  }) {
    return filterTasksInCategory(
      category,
      query: query ?? _state.searchQuery,
      filter: filter ?? _state.taskFilter,
    );
  }

  /// Menerapkan query pencarian. Debounce dilakukan oleh widget pencarian.
  void setSearchQuery(String query) {
    final normalized = query.trim();
    if (normalized == _state.searchQuery) return;
    _setState(_state.copyWith(searchQuery: normalized));
  }

  /// Mengganti filter tugas tanpa menunggu debounce.
  void setTaskFilter(TaskFilter filter) {
    if (filter == _state.taskFilter) return;
    _setState(_state.copyWith(taskFilter: filter));
  }

  /// Menghapus pencarian dan mengembalikan filter ke "Semua".
  void clearSearchAndFilter() {
    if (!_state.isSearchActive) return;
    _setState(_state.copyWith(searchQuery: '', taskFilter: TaskFilter.all));
  }

  Future<void> load() async {
    await _load();
  }

  /// Mencoba membuka file terenkripsi dengan PIN yang dimasukkan pengguna.
  Future<bool> unlockWithPin(String pin) async {
    final password = pin.trim();
    if (password.isEmpty) return false;
    return _load(password: password);
  }

  Future<bool> _load({String? password}) async {
    _retryAction = null;
    _lastIncrementTaskId = null;
    _lastIncrementAt = null;
    _lastJournalIncrement = null;
    if (!await flushPendingSave()) return false;
    _setState(const TaskMasterNewState.loading());
    try {
      final data = await _repository.load(password: password);
      final journalResult = await _loadJournalLinks();
      var nextState = _stateForData(data, journalLinks: journalResult.links);
      if (journalResult.warning != null) {
        nextState = nextState.copyWith(
          actionMessage: journalResult.warning,
          actionRetryable: false,
        );
      }
      _setState(nextState);
      return true;
    } on UnsupportedSchemaVersionException catch (error) {
      _setError(
        title: 'Versi data tidak didukung',
        message: error.message,
        recoveryKind: TaskMasterRecoveryKind.unsupportedVersion,
      );
    } on TaskMigrationException catch (error) {
      _setError(
        title: 'Migrasi data gagal',
        message: error.message,
        recoveryKind: TaskMasterRecoveryKind.migration,
      );
    } on TaskLockedException catch (error) {
      _setError(
        title: 'Data terkunci',
        message: error.message,
        recoveryKind: TaskMasterRecoveryKind.locked,
      );
    } on TaskDecryptionException catch (error) {
      _setError(
        title: password == null ? 'Gagal membuka data' : 'PIN tidak cocok',
        message: password == null
            ? error.message
            : 'PIN yang dimasukkan tidak dapat membuka file. Periksa kembali '
                  'PIN Anda, atau pulihkan backup.',
        recoveryKind: TaskMasterRecoveryKind.decryption,
      );
    } on TaskDataCorruptedException catch (error) {
      _setError(
        title: 'Data tidak dapat dibaca',
        message: error.message,
        recoveryKind: TaskMasterRecoveryKind.corrupted,
      );
    } on TaskMasterException catch (error) {
      _setError(
        title: 'Gagal memuat data',
        message: error.message,
        recoveryKind: TaskMasterRecoveryKind.generic,
      );
    } catch (error) {
      _setError(
        title: 'Gagal memuat data',
        message:
            'Terjadi kesalahan tak terduga saat memuat Task Master. '
            'Data asli tidak diubah. Silakan coba lagi.\n\n$error',
        recoveryKind: TaskMasterRecoveryKind.generic,
      );
    }
    return false;
  }

  /// Daftar backup untuk dialog pemulihan. Kegagalan baca menghasilkan daftar
  /// kosong agar layar tetap dapat menampilkan opsi lain.
  Future<List<TaskBackup>> listBackups() async {
    try {
      return await _repository.listBackups();
    } catch (_) {
      return const [];
    }
  }

  /// Memulihkan backup lalu menampilkan data hasil pemulihan.
  Future<bool> restoreBackup(TaskBackup backup) async {
    if (_state.isSaving) return false;
    _setState(_state.copyWith(isSaving: true, clearActionMessage: true));
    try {
      final data = await _repository.restoreBackup(backup);
      _setState(_stateForData(data));
      return true;
    } on TaskMasterException catch (error) {
      _setError(
        title: 'Gagal memulihkan backup',
        message: error.message,
        recoveryKind: TaskMasterRecoveryKind.corrupted,
      );
      return false;
    } catch (_) {
      _setError(
        title: 'Gagal memulihkan backup',
        message:
            'Backup tidak dapat dipulihkan. Data saat ini tidak diubah. '
            'Silakan coba backup lain atau buat file baru.',
        recoveryKind: TaskMasterRecoveryKind.corrupted,
      );
      return false;
    }
  }

  /// Membuat file baru setelah membackup file saat ini.
  Future<bool> createNewFile() async {
    if (_state.isSaving) return false;
    _setState(_state.copyWith(isSaving: true, clearActionMessage: true));
    try {
      final data = await _repository.createNewFile();
      _setState(_stateForData(data));
      return true;
    } on TaskMasterException catch (error) {
      _setError(
        title: 'Gagal membuat file baru',
        message: error.message,
        recoveryKind: TaskMasterRecoveryKind.corrupted,
      );
      return false;
    } catch (_) {
      _setError(
        title: 'Gagal membuat file baru',
        message:
            'File baru tidak dapat dibuat. Data lama tidak diubah. '
            'Silakan coba lagi.',
        recoveryKind: TaskMasterRecoveryKind.corrupted,
      );
      return false;
    }
  }

  /// Membaca JSON mentah untuk editor area Advanced.
  Future<String> readRawJson() => _repository.readRawJson();

  /// Menyimpan JSON dari editor Advanced setelah validasi dan atomic write.
  Future<bool> saveRawJson(String content) async {
    if (_state.isSaving) return false;
    _setState(_state.copyWith(isSaving: true, clearActionMessage: true));
    try {
      final data = await _repository.saveRawJson(content);
      _setState(_stateForData(data));
      return true;
    } on TaskMasterException catch (error) {
      _setState(
        _state.copyWith(
          isSaving: false,
          actionMessage: error.message,
          actionRetryable: false,
        ),
      );
      return false;
    } catch (_) {
      _setState(
        _state.copyWith(
          isSaving: false,
          actionMessage:
              'JSON gagal disimpan. Data lama tetap aman; silakan coba lagi.',
          actionRetryable: false,
        ),
      );
      return false;
    }
  }

  void _setError({
    required String title,
    required String message,
    required TaskMasterRecoveryKind recoveryKind,
  }) {
    _setState(
      TaskMasterNewState(
        status: TaskMasterNewStatus.error,
        errorTitle: title,
        errorMessage: message,
        recoveryKind: recoveryKind,
      ),
    );
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

  /// Memindahkan kategori ke posisi [newIndex] pada daftar terurut.
  Future<bool> reorderCategory({
    required String categoryId,
    required int newIndex,
  }) async {
    return _runDataAction(
      () => _repository.reorderCategory(
        categoryId: categoryId,
        newIndex: newIndex,
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

  /// Mengubah urutan tugas di dalam kategori.
  Future<bool> reorderTask({
    required String categoryId,
    required String taskId,
    required int newIndex,
  }) async {
    return _runDataAction(
      () => _repository.reorderTask(
        categoryId: categoryId,
        taskId: taskId,
        newIndex: newIndex,
      ),
    );
  }

  /// Memindahkan tugas ke kategori lain tanpa mengubah `id` atau riwayatnya.
  Future<bool> moveTask({
    required String fromCategoryId,
    required String taskId,
    required String toCategoryId,
  }) async {
    return _runDataAction(
      () => _repository.moveTask(
        fromCategoryId: fromCategoryId,
        taskId: taskId,
        toCategoryId: toCategoryId,
      ),
    );
  }

  /// Mengaktifkan atau menonaktifkan beberapa tugas sekaligus.
  Future<bool> setTasksActive({
    required String categoryId,
    required Iterable<String> taskIds,
    required bool isActive,
  }) async {
    return _runDataAction(
      () => _repository.setTasksActive(
        categoryId: categoryId,
        taskIds: taskIds,
        isActive: isActive,
      ),
    );
  }

  /// Menghapus beberapa tugas sekaligus.
  Future<bool> deleteTasks({
    required String categoryId,
    required Iterable<String> taskIds,
  }) async {
    return _runDataAction(
      () => _repository.deleteTasks(categoryId: categoryId, taskIds: taskIds),
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

    final isLinked = _state.isTaskLinkedToJournal(taskId);
    final journalGateway = _journalGateway;
    _PendingJournalIncrement? journalIncrement;
    if (isLinked && journalGateway != null) {
      journalIncrement = _PendingJournalIncrement(
        at: now,
        addFuture: _addJournalDuration(
          gateway: journalGateway,
          taskId: taskId,
          at: now,
        ),
      );
    }

    _lastIncrementTaskId = taskId;
    _lastIncrementAt = now;
    _lastJournalIncrement = journalIncrement;
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
      _lastJournalIncrement = null;
      return false;
    }

    // Rollback Task Master selalu selesai lebih dulu. Rollback Jurnal bersifat
    // best-effort dan tidak boleh membatalkan pengembalian data tugas.
    final journalIncrement = _lastJournalIncrement;
    _lastJournalIncrement = null;
    if (journalIncrement != null) {
      unawaited(_rollbackJournalIncrement(journalIncrement));
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

  Future<({JournalLinkState links, String? warning})>
  _loadJournalLinks() async {
    final gateway = _journalGateway;
    if (gateway == null) {
      return (links: JournalLinkState.empty, warning: null);
    }
    try {
      return (links: await gateway.loadLinks(), warning: null);
    } catch (_) {
      // Integrasi Jurnal bersifat tambahan. Kegagalan membaca Jurnal tidak
      // boleh menghalangi pengguna membuka Task Master, tetapi tautan yang
      // tidak diketahui tidak boleh tampil seolah-olah tidak ada tautan.
      return (
        links: JournalLinkState.empty,
        warning:
            'Relasi Jurnal tidak dapat dibaca. Tugas yang tertaut mungkin '
            'tidak menampilkan indikator Jurnal.',
      );
    }
  }

  Future<JournalAdjustment?> _addJournalDuration({
    required JournalGateway gateway,
    required String taskId,
    required DateTime at,
  }) async {
    try {
      final adjustment = await gateway.addDuration(taskId: taskId, at: at);
      if (adjustment != null) {
        _adjustJournalTodayMinutes(adjustment.minutes);
      }
      return adjustment;
    } catch (_) {
      _setState(
        _state.copyWith(
          actionMessage:
              'Hitungan tugas bertambah, tetapi durasi Jurnal gagal '
              'ditambahkan. Periksa Jurnal secara manual.',
          actionRetryable: false,
        ),
      );
      return null;
    }
  }

  Future<void> _rollbackJournalIncrement(
    _PendingJournalIncrement pending,
  ) async {
    final adjustment = await pending.addFuture;
    if (adjustment == null) return;

    final gateway = _journalGateway;
    if (gateway == null) return;
    try {
      // Gunakan waktu increment, bukan waktu undo, agar undo yang melewati
      // tengah malam tetap mengurangi entri Jurnal pada hari yang benar.
      await gateway.subtractDuration(adjustment: adjustment, at: pending.at);
      _adjustJournalTodayMinutes(-adjustment.minutes);
    } catch (_) {
      _setState(
        _state.copyWith(
          actionMessage:
              'Hitungan tugas sudah dikembalikan, tetapi durasi Jurnal gagal '
              'dikurangi. Periksa Jurnal secara manual.',
          actionRetryable: false,
        ),
      );
    }
  }

  void _adjustJournalTodayMinutes(int deltaMinutes) {
    final links = _state.journalLinks;
    final nextMinutes = (links.todayMinutes + deltaMinutes).clamp(0, 1 << 31);
    _setState(
      _state.copyWith(journalLinks: links.copyWith(todayMinutes: nextMinutes)),
    );
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

  TaskMasterNewState _stateForData(
    TaskMasterData data, {
    JournalLinkState? journalLinks,
  }) {
    return TaskMasterNewState(
      status: data.categories.isEmpty
          ? TaskMasterNewStatus.empty
          : TaskMasterNewStatus.ready,
      data: data,
      journalLinks: journalLinks ?? _state.journalLinks,
      searchQuery: _state.searchQuery,
      taskFilter: _state.taskFilter,
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

/// Increment Jurnal yang masih menunggu hasil penambahan durasi.
///
/// Undo menunggu future ini agar pengurangan hanya dilakukan setelah durasi
/// benar-benar ditambahkan.
class _PendingJournalIncrement {
  const _PendingJournalIncrement({required this.at, required this.addFuture});

  /// Waktu increment yang dipakai untuk menulis dan membatalkan Jurnal.
  final DateTime at;
  final Future<JournalAdjustment?> addFuture;
}

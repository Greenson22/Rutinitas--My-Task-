import '../../domain/entities/task_master_data.dart';
import '../../domain/operations/task_operations.dart';
import '../../domain/repositories/journal_gateway.dart';

enum TaskMasterNewStatus { loading, ready, empty, error }

/// State immutable untuk layar Task Master New.
class TaskMasterNewState {
  const TaskMasterNewState({
    required this.status,
    this.data,
    this.errorTitle,
    this.errorMessage,
    this.actionMessage,
    this.actionRetryable = false,
    this.isSaving = false,
    this.lastIncrement,
    this.journalLinks = JournalLinkState.empty,
  });

  const TaskMasterNewState.loading()
    : status = TaskMasterNewStatus.loading,
      data = null,
      errorTitle = null,
      errorMessage = null,
      actionMessage = null,
      actionRetryable = false,
      isSaving = false,
      lastIncrement = null,
      journalLinks = JournalLinkState.empty;

  final TaskMasterNewStatus status;
  final TaskMasterData? data;
  final String? errorTitle;
  final String? errorMessage;

  /// Pesan hasil aksi pengguna, misalnya kegagalan menyimpan kategori.
  final String? actionMessage;

  /// Menandai bahwa [actionMessage] berasal dari kegagalan yang bisa dicoba
  /// ulang tanpa memasukkan data lagi.
  final bool actionRetryable;
  final bool isSaving;

  /// Increment terakhir yang masih dapat dibatalkan.
  ///
  /// Hanya satu nilai yang disimpan, sehingga increment sebelumnya tidak bisa
  /// di-undo lagi setelah increment baru terjadi.
  final TaskIncrement? lastIncrement;

  /// Relasi Jurnal yang dibaca dari sumber Jurnal, bukan disimpan di data
  /// Task Master.
  final JournalLinkState journalLinks;

  bool get isLoading => status == TaskMasterNewStatus.loading;
  bool get hasError => status == TaskMasterNewStatus.error;
  bool isTaskLinkedToJournal(String taskId) => journalLinks.isLinked(taskId);
  int get journalIncrementMinutes => journalLinks.incrementMinutes;

  TaskMasterNewState copyWith({
    TaskMasterNewStatus? status,
    TaskMasterData? data,
    String? errorTitle,
    String? errorMessage,
    String? actionMessage,
    bool? actionRetryable,
    bool? isSaving,
    TaskIncrement? lastIncrement,
    JournalLinkState? journalLinks,
    bool clearActionMessage = false,
    bool clearLastIncrement = false,
  }) {
    return TaskMasterNewState(
      status: status ?? this.status,
      data: data ?? this.data,
      errorTitle: errorTitle ?? this.errorTitle,
      errorMessage: errorMessage ?? this.errorMessage,
      actionMessage: clearActionMessage
          ? null
          : (actionMessage ?? this.actionMessage),
      actionRetryable: clearActionMessage
          ? false
          : (actionRetryable ?? this.actionRetryable),
      isSaving: isSaving ?? this.isSaving,
      lastIncrement: clearLastIncrement
          ? null
          : (lastIncrement ?? this.lastIncrement),
      journalLinks: journalLinks ?? this.journalLinks,
    );
  }
}

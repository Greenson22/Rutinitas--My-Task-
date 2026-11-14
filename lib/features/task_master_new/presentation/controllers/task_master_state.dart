import '../../domain/entities/task_master_data.dart';

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
  });

  const TaskMasterNewState.loading()
    : status = TaskMasterNewStatus.loading,
      data = null,
      errorTitle = null,
      errorMessage = null,
      actionMessage = null,
      actionRetryable = false,
      isSaving = false;

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

  bool get isLoading => status == TaskMasterNewStatus.loading;
  bool get hasError => status == TaskMasterNewStatus.error;

  TaskMasterNewState copyWith({
    TaskMasterNewStatus? status,
    TaskMasterData? data,
    String? errorTitle,
    String? errorMessage,
    String? actionMessage,
    bool? actionRetryable,
    bool? isSaving,
    bool clearActionMessage = false,
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
    );
  }
}

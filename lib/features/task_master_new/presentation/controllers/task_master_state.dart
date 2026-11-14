import '../../domain/entities/task_master_data.dart';

enum TaskMasterNewStatus { loading, ready, empty, error }

/// State immutable untuk layar Task Master New versi baca-saja.
class TaskMasterNewState {
  const TaskMasterNewState({
    required this.status,
    this.data,
    this.errorTitle,
    this.errorMessage,
  });

  const TaskMasterNewState.loading()
    : status = TaskMasterNewStatus.loading,
      data = null,
      errorTitle = null,
      errorMessage = null;

  final TaskMasterNewStatus status;
  final TaskMasterData? data;
  final String? errorTitle;
  final String? errorMessage;

  bool get isLoading => status == TaskMasterNewStatus.loading;
  bool get hasError => status == TaskMasterNewStatus.error;

  TaskMasterNewState copyWith({
    TaskMasterNewStatus? status,
    TaskMasterData? data,
    String? errorTitle,
    String? errorMessage,
  }) {
    return TaskMasterNewState(
      status: status ?? this.status,
      data: data ?? this.data,
      errorTitle: errorTitle ?? this.errorTitle,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

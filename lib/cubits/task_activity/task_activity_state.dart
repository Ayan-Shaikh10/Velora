
import '../../models/task_activity_log.dart';

class TaskActivityState {
  final int? selectedTaskId;
  final List<TaskActivityLog> logs;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const TaskActivityState({
    this.selectedTaskId,
    this.logs = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  TaskActivityState copyWith({
    int? selectedTaskId,
    List<TaskActivityLog>? logs,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
    bool clearSelectedTask = false,
  }) {
    return TaskActivityState(
      selectedTaskId: clearSelectedTask
          ? null
          : (selectedTaskId ?? this.selectedTaskId),
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

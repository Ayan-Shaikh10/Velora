
import '../../models/task_group.dart';

class TaskGroupState {
  final List<TaskGroup> groups;
  final bool isLoading;
  final String? error;

  const TaskGroupState({
    this.groups = const [],
    this.isLoading = false,
    this.error,
  });

  TaskGroupState copyWith({
    List<TaskGroup>? groups,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return TaskGroupState(
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

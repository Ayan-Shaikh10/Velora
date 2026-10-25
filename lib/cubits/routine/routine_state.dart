
import '../../models/routine_completion.dart';
import '../../models/task.dart';

class RoutineState {
  final List<Task> tasks;
  final Map<int, RoutineCompletion> completionsByTaskId;
  final List<RoutineCompletion> history;
  final DateTime selectedDate;
  final bool isLoading;
  final String? error;

  const RoutineState({
    this.tasks = const [],
    this.completionsByTaskId = const {},
    this.history = const [],
    required this.selectedDate,
    this.isLoading = false,
    this.error,
  });

  bool isTaskCompleted(int taskId) {
    return completionsByTaskId[taskId]?.isCompleted ?? false;
  }

  int get completedCount {
    return tasks.where(
          (task) => task.id != null && isTaskCompleted(task.id!),
    ).length;
  }

  int get totalCount => tasks.length;

  double get completionPercentage {
    if (totalCount == 0) {
      return 0;
    }

    return completedCount / totalCount;
  }

  bool get hasMetDailyTarget {
    return totalCount > 0 && completionPercentage >= 0.8;
  }

  RoutineState copyWith({
    List<Task>? tasks,
    Map<int, RoutineCompletion>? completionsByTaskId,
    List<RoutineCompletion>? history,
    DateTime? selectedDate,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return RoutineState(
      tasks: tasks ?? this.tasks,
      completionsByTaskId:
      completionsByTaskId ?? this.completionsByTaskId,
      history: history ?? this.history,
      selectedDate: selectedDate ?? this.selectedDate,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

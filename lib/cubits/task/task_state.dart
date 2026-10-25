import '../../models/task.dart';

class TaskState {
    final List<Task> tasks;
    final bool isLoading;
    final String? error;

    const TaskState({
        this.tasks=const[],
        this.isLoading=false,
        this.error,
    });

    TaskState copyWith({
        List<Task>? tasks,
        bool? isLoading,
        String? error,
    }) {
        return TaskState(
            tasks: tasks ?? this.tasks,
            isLoading: isLoading ?? this.isLoading,
            error: error,
        );
    }
}

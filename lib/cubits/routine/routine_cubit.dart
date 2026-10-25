
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../database/database_service.dart';
import '../../models/routine_completion.dart';
import '../../models/task.dart';
import 'routine_state.dart';

class RoutineCubit extends Cubit<RoutineState> {
  final DatabaseService _databaseService;

  RoutineCubit({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService(),
        super(
        RoutineState(
          selectedDate: _localDate(DateTime.now()),
        ),
      );

  static DateTime _localDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Loads routine tasks and their saved completion status for a date.
  Future<void> loadForDate(DateTime date) async {
    final selectedDate = _localDate(date);

    emit(
      state.copyWith(
        isLoading: true,
        selectedDate: selectedDate,
        clearError: true,
      ),
    );

    try {
      final allTasks = await _databaseService.getTasks();

      final routineTasks = allTasks
          .where((task) => task.taskType == 'routine')
          .toList();

      final completions = await _databaseService
          .getRoutineCompletionsForDate(selectedDate);

      final completionMap = <int, RoutineCompletion>{};

      for (final completion in completions) {
        completionMap[completion.taskId] = completion;
      }

      emit(
        state.copyWith(
          tasks: routineTasks,
          completionsByTaskId: completionMap,
          isLoading: false,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          error: error.toString(),
        ),
      );
    }
  }

  /// Loads saved routine history for an inclusive date range.
  Future<void> loadHistory({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final history = await _databaseService
          .getRoutineCompletionHistory(
        startDate: startDate,
        endDate: endDate,
      );

      emit(
        state.copyWith(
          history: history,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          error: error.toString(),
        ),
      );
    }
  }

  /// Saves or updates a routine task's completion for the selected date.
  Future<void> toggleTask(Task task, bool isCompleted) async {
    final taskId = task.id;

    if (taskId == null || task.taskType != 'routine') {
      emit(
        state.copyWith(
          error: 'This is not a saved routine task.',
        ),
      );
      return;
    }

    try {
      await _databaseService.setRoutineCompletion(
        taskId: taskId,
        date: state.selectedDate,
        isCompleted: isCompleted,
      );

      final updatedCompletions =
      Map<int, RoutineCompletion>.from(
        state.completionsByTaskId,
      );

      updatedCompletions[taskId] = RoutineCompletion(
        taskId: taskId,
        completionDate: _databaseService.dateKey(
          state.selectedDate,
        ),
        isCompleted: isCompleted,
      );

      emit(
        state.copyWith(
          completionsByTaskId: updatedCompletions,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          error: error.toString(),
        ),
      );
    }
  }

  /// Reloads the current local calendar day.
  Future<void> loadToday() {
    return loadForDate(DateTime.now());
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }
}

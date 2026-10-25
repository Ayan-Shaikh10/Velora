
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../database/database_service.dart';
import '../../models/task_activity_log.dart';
import 'task_activity_state.dart';

class TaskActivityCubit extends Cubit<TaskActivityState> {
  final DatabaseService _databaseService;

  TaskActivityCubit({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService(),
        super(const TaskActivityState());

  static const List<String> allowedStatuses = [
    'notStarted',
    'inProgress',
    'completed',
  ];

  /// Loads the activity history for one saved project task.
  Future<void> loadLogs(int taskId) async {
    if (taskId <= 0) {
      emit(
        state.copyWith(
          isLoading: false,
          error: 'A valid saved task is required.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        selectedTaskId: taskId,
        isLoading: true,
        clearError: true,
      ),
    );

    try {
      final logs = await _databaseService.getTaskActivityLogs(taskId);

      emit(
        state.copyWith(
          selectedTaskId: taskId,
          logs: logs,
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

  /// Adds a new progress entry to a task's logbook.
  Future<bool> addLog({
    required int taskId,
    required String accomplished,
    String nextSteps = '',
    String notes = '',
    String status = 'inProgress',
  }) async {
    final cleanedAccomplished = accomplished.trim();

    if (taskId <= 0) {
      return _reportError('A valid saved task is required.');
    }

    if (cleanedAccomplished.isEmpty) {
      return _reportError('Describe what you accomplished first.');
    }

    if (!allowedStatuses.contains(status)) {
      return _reportError('Choose a valid task status.');
    }

    emit(
      state.copyWith(
        isSaving: true,
        clearError: true,
      ),
    );

    try {
      await _databaseService.insertTaskActivityLog(
        TaskActivityLog(
          taskId: taskId,
          accomplished: cleanedAccomplished,
          nextSteps: nextSteps.trim(),
          notes: notes.trim(),
          status: status,
        ),
      );

      final logs = await _databaseService.getTaskActivityLogs(taskId);

      emit(
        state.copyWith(
          selectedTaskId: taskId,
          logs: logs,
          isSaving: false,
          clearError: true,
        ),
      );

      return true;
    } catch (error) {
      emit(
        state.copyWith(
          isSaving: false,
          error: error.toString(),
        ),
      );
      return false;
    }
  }

  /// Updates an existing activity entry.
  Future<bool> updateLog(TaskActivityLog log) async {
    if (log.id == null) {
      return _reportError('This activity entry has not been saved.');
    }

    if (log.accomplished.trim().isEmpty) {
      return _reportError('The accomplishment cannot be empty.');
    }

    if (!allowedStatuses.contains(log.status)) {
      return _reportError('Choose a valid task status.');
    }

    emit(
      state.copyWith(
        isSaving: true,
        clearError: true,
      ),
    );

    try {
      await _databaseService.updateTaskActivityLog(
        TaskActivityLog(
          id: log.id,
          taskId: log.taskId,
          accomplished: log.accomplished.trim(),
          nextSteps: log.nextSteps.trim(),
          notes: log.notes.trim(),
          status: log.status,
          createdAt: log.createdAt,
        ),
      );

      await loadLogs(log.taskId);

      emit(
        state.copyWith(
          isSaving: false,
          clearError: true,
        ),
      );

      return true;
    } catch (error) {
      emit(
        state.copyWith(
          isSaving: false,
          error: error.toString(),
        ),
      );
      return false;
    }
  }

  /// Deletes an activity entry without deleting the task itself.
  Future<bool> deleteLog(TaskActivityLog log) async {
    if (log.id == null) {
      return _reportError('This activity entry has not been saved.');
    }

    try {
      await _databaseService.deleteTaskActivityLog(log.id!);

      if (state.selectedTaskId == log.taskId) {
        await loadLogs(log.taskId);
      }

      return state.error == null;
    } catch (error) {
      emit(
        state.copyWith(
          error: error.toString(),
        ),
      );
      return false;
    }
  }

  bool _reportError(String message) {
    emit(state.copyWith(error: message));
    return false;
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../database/database_service.dart';
import '../../models/task.dart';
import 'task_state.dart';

class TaskCubit extends Cubit<TaskState> {
    final DatabaseService _databaseService = DatabaseService();

    TaskCubit() : super (const TaskState());

    //Load Task

    Future<void> loadTask() async {
        emit(state.copyWith(isLoading:true),);

        try {
            final task = await _databaseService.getTasks();
            emit(state.copyWith(tasks: task, isLoading: false),);
        } catch (e) {
            emit(state.copyWith(isLoading: false, error: e.toString()),);
        }
    }

    //Add Task

    Future<void> addTask(
        Task task,
        ) async {
        await _databaseService.insertTask(task);
        await loadTask();
    }

    /// Deletes a task and its associated activity/routine history.
    /// Returns false if the task cannot be deleted so the UI can report it.
    Future<bool> deleteTask(Task task) async {
        if (task.id == null) {
            emit(state.copyWith(error: 'This task has not been saved yet.'));
            return false;
        }

        try {
            await _databaseService.deleteTask(task.id!);
            await loadTask();
            return state.error == null;
        } catch (error) {
            emit(state.copyWith(isLoading: false, error: error.toString()));
            return false;
        }
    }

    //Is Complete

    Future<void> toggleTask(

        Task task,

        ) async {
        task.isCompleted = !task.isCompleted;
        await _databaseService.updateTask(task);
        await loadTask();
    }

}
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../database/database_service.dart';
import '../../models/task_group.dart';
import 'task_group_state.dart';

class TaskGroupCubit extends Cubit<TaskGroupState> {
  final DatabaseService _databaseService;

  TaskGroupCubit({DatabaseService? databaseService})
    : _databaseService = databaseService ?? DatabaseService(),
      super(const TaskGroupState());

  Future<void> loadGroups({String? type}) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final groups = await _databaseService.getTaskGroups(type: type);
      emit(state.copyWith(groups: groups, isLoading: false, clearError: true));
    } catch (error) {
      emit(state.copyWith(isLoading: false, error: error.toString()));
    }
  }

  Future<bool> addGroup({
    required String name,
    required String type,
    String description = '',
    DateTime? deadline,
  }) async {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      emit(state.copyWith(error: 'Please enter a group name.'));
      return false;
    }

    if (type != 'routine' && type != 'project') {
      emit(state.copyWith(error: 'Choose either a routine or project group.'));
      return false;
    }

    if (type == 'project' && deadline == null) {
      emit(state.copyWith(error: 'Choose a deadline for your project.'));
      return false;
    }

    try {
      final group = TaskGroup(
        name: trimmedName,
        type: type,
        description: description.trim(),
        deadline: type == 'project' ? deadline : null,
      );

      await _databaseService.insertTaskGroup(group);
      await loadGroups();

      return state.error == null;
    } catch (error) {
      emit(state.copyWith(isLoading: false, error: error.toString()));
      return false;
    }
  }

  Future<bool> renameGroup({
    required TaskGroup group,
    required String newName,
    String? description,
    DateTime? deadline,
  }) async {
    final trimmedName = newName.trim();

    if (group.id == null || trimmedName.isEmpty) {
      emit(state.copyWith(error: 'A saved group name is required.'));
      return false;
    }

    if (group.isProject && deadline == null && group.deadline == null) {
      emit(state.copyWith(error: 'Choose a deadline for your project.'));
      return false;
    }

    try {
      final updatedGroup = TaskGroup(
        id: group.id,
        name: trimmedName,
        type: group.type,
        description: description ?? group.description,
        deadline: group.isProject ? (deadline ?? group.deadline) : null,
        createdAt: group.createdAt,
      );

      await _databaseService.updateTaskGroup(updatedGroup);
      await loadGroups();

      return state.error == null;
    } catch (error) {
      emit(state.copyWith(isLoading: false, error: error.toString()));
      return false;
    }
  }

  Future<bool> deleteGroup(TaskGroup group) async {
    if (group.id == null) {
      emit(state.copyWith(error: 'This group has not been saved yet.'));
      return false;
    }

    try {
      await _databaseService.deleteTaskGroup(group.id!);
      await loadGroups();
      return state.error == null;
    } catch (error) {
      emit(state.copyWith(isLoading: false, error: error.toString()));
      return false;
    }
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/routine/routine_cubit.dart';
import '../cubits/routine/routine_state.dart';
import '../cubits/task/task_cubit.dart';
import '../cubits/task/task_state.dart';
import '../models/task.dart';
import '../models/task_group.dart';
import 'task_details_screen.dart';
import '../themes/app_colors.dart';
import '../widgets/task_tile.dart';

class TaskGroupDetailScreen extends StatelessWidget {
  final TaskGroup group;

  const TaskGroupDetailScreen({
    super.key,
    required this.group,
  });

  Future<void> _showAddTaskDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _AddTaskDialog(group: group),
    );
  }

  Future<void> _toggleTask(BuildContext context, Task task) async {
    if (group.isRoutine) {
      final taskId = task.id;
      if (taskId == null) return;

      final routineCubit = context.read<RoutineCubit>();
      final isCurrentlyCompleted =
      routineCubit.state.isTaskCompleted(taskId);

      await routineCubit.toggleTask(
        task,
        !isCurrentlyCompleted,
      );
    } else {
      await context.read<TaskCubit>().toggleTask(task);
    }
  }

  Future<void> _confirmDeleteTask(BuildContext context, Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded, size: 34, color: AppColors.error),
        title: const Text('Delete this task?'),
        content: const Text(
          'This permanently deletes the task, its progress updates, and its routine-completion history. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete task'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    final success = await context.read<TaskCubit>().deleteTask(task);
    await context.read<RoutineCubit>().loadToday();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Task deleted.' : 'Could not delete the task.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRoutine = group.isRoutine;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          group.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
      body: BlocBuilder<TaskCubit, TaskState>(
        builder: (context, taskState) {
          final tasks = taskState.tasks
              .where((task) => task.groupId == group.id)
              .toList()
            ..sort((a, b) {
              int priorityRank(String priority) {
                switch (priority.toLowerCase()) {
                  case 'high':
                    return 0;
                  case 'medium':
                    return 1;
                  case 'low':
                    return 2;
                  default:
                    return 1;
                }
              }

              final priorityComparison =
              priorityRank(a.priority).compareTo(priorityRank(b.priority));

              if (priorityComparison != 0) {
                return priorityComparison;
              }

              // Within the same priority, show the nearest deadline first.
              return a.dueDate.compareTo(b.dueDate);
            });

          if (taskState.isLoading && tasks.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return BlocBuilder<RoutineCubit, RoutineState>(
            builder: (context, routineState) {
              final completedCount = isRoutine
                  ? tasks.where((task) {
                return task.id != null &&
                    routineState.isTaskCompleted(task.id!);
              }).length
                  : tasks.where((task) => task.isCompleted).length;

              final progress = tasks.isEmpty
                  ? 0.0
                  : completedCount / tasks.length;

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: (isRoutine
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.secondary)
                          .withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isRoutine
                              ? Icons.repeat
                              : Icons.folder_outlined,
                          size: 32,
                          color: isRoutine
                              ? AppColors.primary
                              : AppColors.secondary,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isRoutine
                                    ? 'Today’s routine'
                                    : 'Project progress',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$completedCount of ${tasks.length} tasks completed',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 10),
                              LinearProgressIndicator(value: progress),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Tasks',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (tasks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 34),
                      child: Column(
                        children: [
                          const Icon(Icons.checklist, size: 52),
                          const SizedBox(height: 12),
                          Text(
                            'No tasks in this group yet',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Add a task to get started.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ...tasks.map((task) {
                      final routineCompleted = task.id != null &&
                          routineState.isTaskCompleted(task.id!);

                      return TaskTile(
                        task: task,
                        completedOverride: isRoutine
                            ? routineCompleted
                            : task.isCompleted,
                        showDueDate: !isRoutine,
                        onChanged: () => _toggleTask(context, task),
                        onDelete: () => _confirmDeleteTask(context, task),
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute<void>(
                            builder: (_) => TaskDetailsScreen(task: task),
                          ));
                        },
                      );
                    }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _AddTaskDialog extends StatefulWidget {
  final TaskGroup group;

  const _AddTaskDialog({required this.group});

  @override
  State<_AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<_AddTaskDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _subjectController;

  late DateTime _dueDate;
  String _priority = 'medium';
  bool _isSaving = false;

  bool get _isRoutine => widget.group.isRoutine;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _subjectController = TextEditingController();
    _dueDate = DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final today = DateTime.now();
    final firstDay = DateTime(today.year, today.month, today.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate.isBefore(firstDay) ? firstDay : _dueDate,
      firstDate: firstDay,
      lastDate: DateTime(2100),
    );

    if (picked != null && mounted) {
      setState(() => _dueDate = picked);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _saveTask() async {
    if (_isSaving) return;

    final title = _titleController.text.trim();
    final subject = _subjectController.text.trim();

    if (title.isEmpty || subject.isEmpty) {
      _showMessage('Enter both a task title and category.');
      return;
    }

    setState(() => _isSaving = true);

    final task = Task(
      title: title,
      subject: subject,
      dueDate: _isRoutine ? DateTime.now() : _dueDate,
      isCompleted: false,
      groupId: widget.group.id,
      taskType: widget.group.type,
      createdAt: DateTime.now(),
      priority: _priority,
    );

    try {
      final taskCubit = context.read<TaskCubit>();
      await taskCubit.addTask(task);

      if (!mounted) return;

      final taskState = taskCubit.state;
      if (taskState.error != null) {
        setState(() => _isSaving = false);
        _showMessage(taskState.error!);
        return;
      }

      if (_isRoutine) {
        await context.read<RoutineCubit>().loadToday();
        if (!mounted) return;
      }

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage('Could not save the task. Please try again.');
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'low':
        return const Color(0xFF15803D);
      case 'high':
        return const Color(0xFFB91C1C);
      default:
        return const Color(0xFFB45309);
    }
  }

  Widget _priorityOption(String value, String label) {
    final selected = _priority == value;
    final color = _priorityColor(value);

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      labelStyle: TextStyle(
        color: selected ? color : null,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      selectedColor: color.withValues(alpha: 0.12),
      backgroundColor: Theme.of(context).colorScheme.surface,
      side: BorderSide(
        color: selected
            ? color
            : Theme.of(context).colorScheme.outlineVariant,
      ),
      onSelected: _isSaving
          ? null
          : (_) => setState(() => _priority = value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      title: const Text('Add Task'),
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                autofocus: true,
                enabled: !_isSaving,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Task title',
                  hintText: 'What do you need to do?',
                  prefixIcon: Icon(Icons.task_alt),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _subjectController,
                enabled: !_isSaving,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Subject or category',
                  hintText: 'e.g. Study, Flutter',
                  prefixIcon: Icon(Icons.label_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Priority',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _priorityOption('low', 'Low'),
                  _priorityOption('medium', 'Medium'),
                  _priorityOption('high', 'High'),
                ],
              ),
              if (!_isRoutine) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isSaving ? null : _pickDueDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(
                      'Deadline  ${_dueDate.day.toString().padLeft(2, '0')}/'
                          '${_dueDate.month.toString().padLeft(2, '0')}/'
                          '${_dueDate.year}',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed:
          _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _saveTask,
          child: _isSaving
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text('Save Task'),
        ),
      ],
    );
  }
}

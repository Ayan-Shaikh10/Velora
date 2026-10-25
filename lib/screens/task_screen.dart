import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/routine/routine_cubit.dart';
import '../cubits/routine/routine_state.dart';
import '../cubits/task/task_cubit.dart';
import '../cubits/task/task_state.dart';
import '../cubits/task_group/task_group_cubit.dart';
import '../cubits/task_group/task_group_state.dart';
import '../models/task_group.dart';
import '../themes/app_colors.dart';
import 'task_group_detail_screen.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  Future<void> _showAddGroupDialog(BuildContext context) async {
    String name = '';
    String description = '';
    String type = 'routine';
    DateTime? deadline;
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final isProject = type == 'project';

          return AlertDialog(
            title: const Text('Create a group'),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Organise your tasks in one place.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Group name',
                        hintText: 'e.g. Daily Study',
                        prefixIcon: Icon(Icons.folder_outlined),
                      ),
                      onChanged: (value) => name = value,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 3,
                      minLines: 2,
                      maxLength: 180,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'What is this group for?',
                        alignLabelWithHint: true,
                      ),
                      onChanged: (value) => description = value,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Group type',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      expandedInsets: EdgeInsets.zero,
                      segments: const [
                        ButtonSegment(
                          value: 'routine',
                          label: Text('Routine'),
                          icon: Icon(Icons.repeat),
                        ),
                        ButtonSegment(
                          value: 'project',
                          label: Text('Project'),
                          icon: Icon(Icons.flag_outlined),
                        ),
                      ],
                      selected: {type},
                      onSelectionChanged: saving
                          ? null
                          : (selection) => setDialogState(() {
                        type = selection.first;
                        if (type == 'routine') deadline = null;
                      }),
                    ),
                    if (isProject) ...[
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_month_outlined),
                        onPressed: saving
                            ? null
                            : () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: dialogContext,
                            initialDate: deadline ?? now,
                            firstDate: DateTime(
                              now.year,
                              now.month,
                              now.day,
                            ),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setDialogState(() => deadline = picked);
                          }
                        },
                        label: Text(
                          deadline == null
                              ? 'Choose project deadline'
                              : 'Deadline: ${deadline!.day}/${deadline!.month}/${deadline!.year}',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                  if (name.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Enter a group name.'),
                      ),
                    );
                    return;
                  }
                  if (isProject && deadline == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Choose a project deadline.'),
                      ),
                    );
                    return;
                  }

                  setDialogState(() => saving = true);
                  final success = await context
                      .read<TaskGroupCubit>()
                      .addGroup(
                    name: name,
                    type: type,
                    description: description,
                    deadline: deadline,
                  );

                  if (!dialogContext.mounted) return;

                  if (success) {
                    Navigator.pop(dialogContext);
                  } else {
                    setDialogState(() => saving = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          context.read<TaskGroupCubit>().state.error ??
                              'Could not create the group.',
                        ),
                      ),
                    );
                  }
                },
                child: saving
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Create group'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteGroup(
      BuildContext context,
      TaskGroup group,
      int taskCount,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.delete_forever_outlined, size: 34, color: AppColors.error),
        title: Text('Delete "${group.name}"?'),
        content: Text(
          taskCount == 0
              ? 'This group will be permanently deleted. This action cannot be undone.'
              : 'This group contains $taskCount ${taskCount == 1 ? 'task' : 'tasks'}. Deleting it will also permanently delete those tasks, their progress updates, and routine-completion history. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete group'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final success = await context.read<TaskGroupCubit>().deleteGroup(group);
    if (!context.mounted) return;
    await context.read<TaskCubit>().loadTask();
    await context.read<RoutineCubit>().loadToday();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Group and its tasks deleted.' : 'Could not delete the group.',
        ),
      ),
    );
  }

  Future<void> _openGroup(BuildContext context, TaskGroup group) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => TaskGroupDetailScreen(group: group),
      ),
    );

    if (context.mounted) {
      await context.read<TaskGroupCubit>().loadGroups();
      await context.read<TaskCubit>().loadTask();
      await context.read<RoutineCubit>().loadToday();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,


    appBar: AppBar(
    automaticallyImplyLeading: false,
    toolbarHeight: 76,
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    titleSpacing: 20,
    title: Row(
    children: [
    Container(
    width: 40,
        height: 40,
        decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
    borderRadius: BorderRadius.circular(13),
    border: Border.all(
    color: Colors.white.withValues(alpha: 0.22),
    ),
    ),
    child: const Icon(
    Icons.checklist_rounded,
    color: Colors.white,
    size: 22,
    ),
    ),
    const SizedBox(width: 12),
    const Expanded(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
    Text(
    'My Groups',
    style: TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 17,
    letterSpacing: 0.1,
    ),
    ),
    SizedBox(height: 1),
    Text(
    'MANAGE YOUR ROUTINES AND PROJECTS',
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
    fontSize: 9,
    letterSpacing: 1.0,
    color: Color(0xFFDDE2FF),
    fontWeight: FontWeight.w600,
    ),
    ),
    ],
    ),
    ),
    ],
    ),
    ),



      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGroupDialog(context),
        icon: const Icon(Icons.create_new_folder_outlined),
        label: const Text('Add Group'),
      ),
      body: BlocBuilder<TaskGroupCubit, TaskGroupState>(
        builder: (context, groupState) {
          if (groupState.isLoading && groupState.groups.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (groupState.error != null && groupState.groups.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(groupState.error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () =>
                          context.read<TaskGroupCubit>().loadGroups(),
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (groupState.groups.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.folder_open_outlined, size: 56),
                    const SizedBox(height: 16),
                    Text(
                      'No groups yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create a routine or project to start organising your tasks.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => _showAddGroupDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Create your first group'),
                    ),
                  ],
                ),
              ),
            );
          }

          return BlocBuilder<TaskCubit, TaskState>(
            builder: (context, taskState) {
              return BlocBuilder<RoutineCubit, RoutineState>(
                builder: (context, routineState) {
                  final routines = groupState.groups
                      .where((group) => group.isRoutine)
                      .toList();
                  final projects = groupState.groups
                      .where((group) => group.isProject)
                      .toList();

                  return RefreshIndicator(
                    onRefresh: () async {
                      await context.read<TaskGroupCubit>().loadGroups();
                      await context.read<TaskCubit>().loadTask();
                      await context.read<RoutineCubit>().loadToday();
                    },
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      children: [
                        Text(
                          'Keep everything organised',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (routines.isNotEmpty) ...[
                          const SizedBox(height: 22),
                          _SectionHeading(
                            title: 'Daily Routines',
                            count: routines.length,
                          ),
                          const SizedBox(height: 10),
                          ...routines.map(
                                (group) => _GroupCard(
                              group: group,
                              tasks: taskState.tasks
                                  .where((task) => task.groupId == group.id)
                                  .toList(),
                              isRoutine: true,
                              isTaskCompleted: (task) =>
                              task.id != null &&
                                  routineState.isTaskCompleted(task.id!),
                              onTap: () => _openGroup(context, group),
                              onDelete: () => _confirmDeleteGroup(
                                context,
                                group,
                                taskState.tasks.where((task) => task.groupId == group.id).length,
                              ),
                            ),
                          ),
                        ],
                        if (projects.isNotEmpty) ...[
                          const SizedBox(height: 22),
                          _SectionHeading(
                            title: 'Projects',
                            count: projects.length,
                          ),
                          const SizedBox(height: 10),
                          ...projects.map(
                                (group) => _GroupCard(
                              group: group,
                              tasks: taskState.tasks
                                  .where((task) => task.groupId == group.id)
                                  .toList(),
                              isRoutine: false,
                              isTaskCompleted: (task) => task.isCompleted,
                              onTap: () => _openGroup(context, group),
                              onDelete: () => _confirmDeleteGroup(
                                context,
                                group,
                                taskState.tasks.where((task) => task.groupId == group.id).length,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeading({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Text('$count ${count == 1 ? 'group' : 'groups'}'),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  final TaskGroup group;
  final List<dynamic> tasks;
  final bool isRoutine;
  final bool Function(dynamic task) isTaskCompleted;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _GroupCard({
    required this.group,
    required this.tasks,
    required this.isRoutine,
    required this.isTaskCompleted,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completed = tasks.where(isTaskCompleted).length;
    final total = tasks.length;
    final progress = total == 0 ? 0.0 : completed / total;
    final accent = isRoutine
        ? theme.colorScheme.primary
        : theme.colorScheme.secondary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 16, 8, 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isRoutine ? Icons.repeat : Icons.folder_outlined,
                  color: accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (group.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        group.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 5),
                    Text(
                      isRoutine
                          ? 'Daily routine'
                          : group.deadline == null
                          ? 'Project · No deadline'
                          : 'Due ${group.deadline!.day}/${group.deadline!.month}/${group.deadline!.year}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 58,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$completed/$total',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        color: accent,
                        backgroundColor: accent.withValues(alpha: 0.15),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isRoutine ? 'Today' : 'Done',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 2),
              PopupMenuButton<String>(
                tooltip: 'Group options',
                onSelected: (value) {
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, color: AppColors.error),
                        SizedBox(width: 10),
                        Text('Delete group'),
                      ],
                    ),
                  ),
                ],
                icon: Icon(Icons.more_vert_rounded, color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

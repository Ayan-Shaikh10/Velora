
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/task_group/task_group_cubit.dart';
import '../cubits/task_group/task_group_state.dart';
import '../models/task_group.dart';
import '../themes/app_colors.dart';

class TaskGroupsScreen extends StatefulWidget {
  const TaskGroupsScreen({super.key});

  @override
  State<TaskGroupsScreen> createState() => _TaskGroupsScreenState();
}

class _TaskGroupsScreenState extends State<TaskGroupsScreen> {
  String _selectedType = 'routine';

  Future<void> _showGroupDialog({TaskGroup? group}) async {
    final nameController = TextEditingController(
      text: group?.name ?? '',
    );

    String type = group?.type ?? _selectedType;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                group == null ? 'Create group' : 'Rename group',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Group name',
                      hintText: 'e.g. Morning routine',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (group == null) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Group type',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: type,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'routine',
                          child: Text('Daily routine'),
                        ),
                        DropdownMenuItem(
                          value: 'project',
                          child: Text('Project'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => type = value);
                        }
                      },
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      {
                        'name': nameController.text.trim(),
                        'type': type,
                      },
                    );
                  },
                  child: Text(group == null ? 'Create' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();

    if (!mounted || result == null) return;

    final cubit = context.read<TaskGroupCubit>();
    bool success;

    if (group == null) {
      success = await cubit.addGroup(
        name: result['name'] ?? '',
        type: result['type'] ?? _selectedType,
      );
    } else {
      success = await cubit.renameGroup(
        group: group,
        newName: result['name'] ?? '',
      );
    }

    if (!mounted) return;

    final currentError = cubit.state.error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (group == null ? 'Group created.' : 'Group renamed.')
              : (currentError ?? 'Could not save the group.'),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(TaskGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete group?'),
        content: Text(
          'Delete "${group.name}"? Tasks in this group will be kept, '
              'but they will no longer belong to a group.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final cubit = context.read<TaskGroupCubit>();
    final success = await cubit.deleteGroup(group);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Group deleted. Its tasks were kept.'
              : (cubit.state.error ?? 'Could not delete the group.'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Groups'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showGroupDialog(),
        icon: const Icon(Icons.create_new_folder_outlined),
        label: const Text('New Group'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'routine',
                  label: Text('Routines'),
                  icon: Icon(Icons.repeat),
                ),
                ButtonSegment(
                  value: 'project',
                  label: Text('Projects'),
                  icon: Icon(Icons.flag_outlined),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (selection) {
                setState(() => _selectedType = selection.first);
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<TaskGroupCubit, TaskGroupState>(
              builder: (context, state) {
                if (state.isLoading && state.groups.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (state.error != null && state.groups.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 40,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            state.error!,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () {
                              context
                                  .read<TaskGroupCubit>()
                                  .loadGroups();
                            },
                            child: const Text('Try again'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final groups = state.groups
                    .where((group) => group.type == _selectedType)
                    .toList();

                if (groups.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: groups.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    final isRoutine = group.isRoutine;

                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.surfaceVariant,
                          foregroundColor: AppColors.primary,
                          child: Icon(
                            isRoutine
                                ? Icons.repeat
                                : Icons.flag_outlined,
                          ),
                        ),
                        title: Text(
                          group.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          isRoutine ? 'Daily routine group' : 'Project group',
                        ),
                        trailing: PopupMenuButton<String>(
                          tooltip: 'Group options',
                          onSelected: (value) {
                            if (value == 'rename') {
                              _showGroupDialog(group: group);
                            } else if (value == 'delete') {
                              _confirmDelete(group);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'rename',
                              child: ListTile(
                                leading: Icon(Icons.edit_outlined),
                                title: Text('Rename'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                leading: Icon(Icons.delete_outline),
                                title: Text('Delete'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isRoutine = _selectedType == 'routine';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isRoutine ? Icons.repeat : Icons.flag_outlined,
              size: 56,
              color: AppColors.primaryLight,
            ),
            const SizedBox(height: 16),
            Text(
              isRoutine ? 'No routine groups yet' : 'No project groups yet',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isRoutine
                  ? 'Create a group for habits and tasks you repeat daily.'
                  : 'Create a group to organize a project and its tasks.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _showGroupDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Create group'),
            ),
          ],
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/task_group/task_group_cubit.dart';
import '../cubits/task_group/task_group_state.dart';
import '../models/task.dart';
import 'task_groups_screen.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController subjectController = TextEditingController();

  DateTime selectedDate = DateTime.now();
  String selectedType = 'project';
  int? selectedGroupId;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TaskGroupCubit>().loadGroups();
      }
    });
  }

  @override
  void dispose() {
    titleController.dispose();
    subjectController.dispose();
    super.dispose();
  }

  Future<void> selectDate() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate.isBefore(
        DateTime(now.year, now.month, now.day),
      )
          ? DateTime(now.year, now.month, now.day)
          : selectedDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null && mounted) {
      setState(() => selectedDate = pickedDate);
    }
  }

  Future<void> openGroupManager() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const TaskGroupsScreen(),
      ),
    );

    if (!mounted) return;

    await context.read<TaskGroupCubit>().loadGroups();
  }

  void saveTask(List<dynamic> groups) {
    if (!_formKey.currentState!.validate()) return;

    final matchingGroups = groups.where(
          (group) =>
      group.id == selectedGroupId && group.type == selectedType,
    );

    if (matchingGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a group for this task.'),
        ),
      );
      return;
    }

    final task = Task(
      title: titleController.text.trim(),
      subject: subjectController.text.trim(),
      dueDate: selectedType == 'routine' ? DateTime.now() : selectedDate,
      groupId: selectedGroupId,
      taskType: selectedType,
      createdAt: DateTime.now(),
    );

    Navigator.pop(context, task);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Task')),
      body: BlocBuilder<TaskGroupCubit, TaskGroupState>(
        builder: (context, groupState) {
          final groups = groupState.groups
              .where((group) => group.type == selectedType)
              .toList();

          final selectedGroupExists = groups.any(
                (group) => group.id == selectedGroupId,
          );

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Create a new task',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Choose where this task belongs.'),
                const SizedBox(height: 24),

                const Text(
                  'Task type',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'routine',
                      label: Text('Daily Routine'),
                      icon: Icon(Icons.repeat),
                    ),
                    ButtonSegment(
                      value: 'project',
                      label: Text('Project'),
                      icon: Icon(Icons.flag_outlined),
                    ),
                  ],
                  selected: {selectedType},
                  onSelectionChanged: (selection) {
                    setState(() {
                      selectedType = selection.first;
                      selectedGroupId = null;
                    });
                  },
                ),

                const SizedBox(height: 20),
                DropdownButtonFormField<int>(
                  value: selectedGroupExists ? selectedGroupId : null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Group',
                    prefixIcon: Icon(Icons.folder_outlined),
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('Select a group'),
                  items: groups.map((group) {
                    return DropdownMenuItem<int>(
                      value: group.id,
                      child: Text(
                        group.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedGroupId = value);
                  },
                  validator: (value) {
                    if (value == null) return 'Select a group';
                    return null;
                  },
                ),

                if (groups.isEmpty && !groupState.isLoading) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Create a group before adding this task.',
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: openGroupManager,
                      icon: const Icon(Icons.create_new_folder_outlined),
                      label: const Text('Manage Groups'),
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                TextFormField(
                  controller: titleController,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Task title',
                    hintText: 'e.g. Study Japanese',
                    prefixIcon: Icon(Icons.task_alt),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a task title';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),
                TextFormField(
                  controller: subjectController,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Subject or category',
                    hintText: 'e.g. Japanese or Flutter',
                    prefixIcon: Icon(Icons.menu_book_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a subject or category';
                    }
                    return null;
                  },
                ),

                if (selectedType == 'project') ...[
                  const SizedBox(height: 20),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: const Text('Due date'),
                      subtitle: Text(
                        '${selectedDate.day}/'
                            '${selectedDate.month}/'
                            '${selectedDate.year}',
                      ),
                      trailing: const Icon(Icons.edit_calendar_outlined),
                      onTap: selectDate,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.info_outline),
                    title: Text('Repeating daily'),
                    subtitle: Text(
                      'Completion will be tracked separately for each day.',
                    ),
                  ),
                ],

                if (groupState.error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    groupState.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],

                const SizedBox(height: 28),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: isSaving || groupState.isLoading
                        ? null
                        : () => saveTask(groupState.groups),
                    icon: const Icon(Icons.add_task),
                    label: const Text('Save Task'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

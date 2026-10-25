import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/task/task_cubit.dart';
import '../cubits/task_activity/task_activity_cubit.dart';
import '../cubits/task_activity/task_activity_state.dart';
import '../models/task.dart';
import '../models/task_activity_log.dart';
import '../themes/app_colors.dart';

class TaskDetailsScreen extends StatefulWidget {
  final Task task;

  const TaskDetailsScreen({super.key, required this.task});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  late Task _task;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    if (_task.id != null && _task.taskType != 'routine') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<TaskActivityCubit>().loadLogs(_task.id!);
      });
    }
  }

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')} ${_month(value.month)} ${value.year}';

  String _month(int month) => const [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ][month - 1];

  String _statusLabel(String status) {
    switch (status) {
      case 'notStarted':
        return 'Not Started';
      case 'completed':
        return 'Completed';
      default:
        return 'In Progress';
    }
  }

  Color _statusColor(BuildContext context, String status) {
    if (status == 'completed') return AppColors.success;
    if (status == 'notStarted') return Theme.of(context).colorScheme.outline;
    return AppColors.info;
  }

  Future<void> _setTaskCompleted(bool completed) async {
    if (_task.isCompleted != completed) {
      await context.read<TaskCubit>().toggleTask(_task);
    }
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(completed ? 'Task marked as completed.' : 'Task reopened.')),
    );
  }

  Future<void> _showProgressForm({TaskActivityLog? existing}) async {
    if (_task.id == null) return;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _ProgressUpdateSheet(task: _task, existing: existing),
    );
    if (result == true && mounted) {
      await context.read<TaskActivityCubit>().loadLogs(_task.id!);
      final latest = context.read<TaskActivityCubit>().state.logs;
      if (latest.isNotEmpty) {
        final latestStatus = latest.first.status;
        final shouldComplete = latestStatus == 'completed';
        if (_task.isCompleted != shouldComplete) {
          await context.read<TaskCubit>().toggleTask(_task);
        }
      }
      if (mounted) setState(() {});
    }
  }

  Future<void> _deleteLog(TaskActivityLog log) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 34),
        title: const Text('Delete this update?'),
        content: const Text('This update will be permanently removed from this task’s progress history.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton.tonal(
            style: FilledButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final success = await context.read<TaskActivityCubit>().deleteLog(log);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Progress update deleted.' : 'Could not delete this update.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isRoutine = _task.taskType == 'routine';
    final priorityColor = _task.priority == 'high'
        ? AppColors.error
        : _task.priority == 'low'
        ? AppColors.success
        : AppColors.warning;

    return Scaffold(
      appBar: AppBar(title: const Text('Task Details')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: colors.outlineVariant.withValues(alpha: .7)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: .10), borderRadius: BorderRadius.circular(14)),
                    child: Icon(isRoutine ? Icons.repeat_rounded : Icons.design_services_outlined, color: AppColors.primary, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_task.title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 7, runSpacing: 7, children: [
                      _InfoChip(label: isRoutine ? 'Routine task' : 'Project task', color: AppColors.primary),
                      _InfoChip(label: '${_task.priority[0].toUpperCase()}${_task.priority.substring(1)} priority', color: priorityColor),
                      _InfoChip(label: _task.isCompleted ? 'Completed' : 'In Progress', color: _task.isCompleted ? AppColors.success : AppColors.info),
                    ]),
                  ])),
                ]),
                const SizedBox(height: 20),
                Text('Task Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(_task.subject.trim().isEmpty ? 'No description or category added.' : _task.subject, style: theme.textTheme.bodyMedium?.copyWith(height: 1.45)),
                const SizedBox(height: 16),
                _DetailRow(icon: Icons.label_outline, label: 'Category', value: _task.subject.isEmpty ? 'Not specified' : _task.subject),
                const SizedBox(height: 9),
                _DetailRow(icon: Icons.calendar_month_outlined, label: 'Deadline', value: _date(_task.dueDate)),
                if (_task.createdAt != null) ...[
                  const SizedBox(height: 9),
                  _DetailRow(icon: Icons.event_available_outlined, label: 'Created', value: _date(_task.createdAt!)),
                ],
                if (!isRoutine) ...[
                  const SizedBox(height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Task completion', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    Text(_task.isCompleted ? '100%' : '0%', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: _task.isCompleted ? 1 : 0, minHeight: 7, borderRadius: BorderRadius.circular(8)),
                  const SizedBox(height: 16),
                  SizedBox(width: double.infinity, child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: _task.isCompleted ? colors.surfaceContainerHighest : AppColors.success, foregroundColor: _task.isCompleted ? colors.onSurface : Colors.white, padding: const EdgeInsets.symmetric(vertical: 13)),
                    onPressed: () => _setTaskCompleted(!_task.isCompleted),
                    icon: Icon(_task.isCompleted ? Icons.refresh_rounded : Icons.check_circle_outline),
                    label: Text(_task.isCompleted ? 'Reopen Task' : 'Mark as Completed'),
                  )),
                ],
              ]),
            ),
          ),
          if (!isRoutine) ...[
            const SizedBox(height: 22),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: Text('Progress Logbook', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
              BlocBuilder<TaskActivityCubit, TaskActivityState>(builder: (context, state) => Text('${state.selectedTaskId == _task.id ? state.logs.length : 0} entries', style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant))),
            ]),
            const SizedBox(height: 5),
            Text('Keep a record of what you accomplished and what comes next.', style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: FilledButton.icon(
              onPressed: () => _showProgressForm(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Progress Update'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            )),
            const SizedBox(height: 12),
            BlocBuilder<TaskActivityCubit, TaskActivityState>(builder: (context, state) {
              if (state.isLoading && state.selectedTaskId == _task.id) {
                return const Padding(padding: EdgeInsets.all(28), child: Center(child: CircularProgressIndicator()));
              }
              if (state.error != null && state.selectedTaskId == _task.id) {
                return Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Could not load progress history: ${state.error}')));
              }
              final logs = state.selectedTaskId == _task.id ? state.logs : <TaskActivityLog>[];
              if (logs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: colors.surfaceContainerLow, borderRadius: BorderRadius.circular(18), border: Border.all(color: colors.outlineVariant.withValues(alpha: .65))),
                  child: Column(children: [
                    Icon(Icons.auto_stories_outlined, size: 38, color: colors.onSurfaceVariant),
                    const SizedBox(height: 10),
                    Text('No progress updates yet', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 5),
                    Text('Add your first update to start this task’s history.', textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                  ]),
                );
              }
              return Column(children: logs.map((log) => _ActivityCard(
                log: log,
                statusLabel: _statusLabel(log.status),
                statusColor: _statusColor(context, log.status),
                onEdit: () => _showProgressForm(existing: log),
                onDelete: () => _deleteLog(log),
              )).toList());
            }),
          ] else ...[
            const SizedBox(height: 16),
            Card(color: colors.surfaceContainerLow, child: const Padding(padding: EdgeInsets.all(16), child: Text('Routine tasks are checked off for each day. Their daily completion history is tracked separately from project progress updates.'))),
          ],
        ],
      ),
    );
  }
}

class _ProgressUpdateSheet extends StatefulWidget {
  final Task task;
  final TaskActivityLog? existing;
  const _ProgressUpdateSheet({required this.task, this.existing});

  @override
  State<_ProgressUpdateSheet> createState() => _ProgressUpdateSheetState();
}

class _ProgressUpdateSheetState extends State<_ProgressUpdateSheet> {
  late final TextEditingController _accomplished;
  late final TextEditingController _nextSteps;
  late final TextEditingController _notes;
  late String _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _accomplished = TextEditingController(text: widget.existing?.accomplished ?? '');
    _nextSteps = TextEditingController(text: widget.existing?.nextSteps ?? '');
    _notes = TextEditingController(text: widget.existing?.notes ?? '');
    _status = widget.existing?.status ?? (widget.task.isCompleted ? 'completed' : 'inProgress');
  }

  @override
  void dispose() {
    _accomplished.dispose();
    _nextSteps.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_accomplished.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Describe what you accomplished first.')));
      return;
    }
    setState(() => _saving = true);
    final cubit = context.read<TaskActivityCubit>();
    final success = widget.existing == null
        ? await cubit.addLog(taskId: widget.task.id!, accomplished: _accomplished.text, nextSteps: _nextSteps.text, notes: _notes.text, status: _status)
        : await cubit.updateLog(TaskActivityLog(id: widget.existing!.id, taskId: widget.task.id!, accomplished: _accomplished.text.trim(), nextSteps: _nextSteps.text.trim(), notes: _notes.text.trim(), status: _status, createdAt: widget.existing!.createdAt));
    if (!mounted) return;
    if (success) {
      Navigator.pop(context, true);
    } else {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(cubit.state.error ?? 'Could not save this update.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, bottomInset + 20),
      child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(widget.existing == null ? 'Add Progress Update' : 'Edit Progress Update', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(widget.task.title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
        const SizedBox(height: 20),
        _FormLabel(label: 'What did you accomplish?', requiredField: true),
        const SizedBox(height: 7),
        TextField(controller: _accomplished, minLines: 3, maxLines: 5, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(hintText: 'e.g. Completed the Home screen and Profile screen in Figma.')),
        const SizedBox(height: 16),
        const _FormLabel(label: 'What’s next?'),
        const SizedBox(height: 7),
        TextField(controller: _nextSteps, minLines: 2, maxLines: 4, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(hintText: 'e.g. Design the Settings screen and connect navigation.')),
        const SizedBox(height: 16),
        const _FormLabel(label: 'Additional notes (optional)'),
        const SizedBox(height: 7),
        TextField(controller: _notes, minLines: 2, maxLines: 4, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(hintText: 'Anything else worth remembering?')),
        const SizedBox(height: 18),
        const _FormLabel(label: 'Task status'),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _StatusChoice(label: 'Not Started', value: 'notStarted', selected: _status, onTap: (v) => setState(() => _status = v)),
          _StatusChoice(label: 'In Progress', value: 'inProgress', selected: _status, onTap: (v) => setState(() => _status = v)),
          _StatusChoice(label: 'Completed', value: 'completed', selected: _status, onTap: (v) => setState(() => _status = v)),
        ]),
        const SizedBox(height: 14),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)), child: Row(children: [const Icon(Icons.schedule_rounded, color: AppColors.primary), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Date and time', style: TextStyle(fontWeight: FontWeight.w600)), Text(widget.existing == null ? 'Recorded automatically when you save.' : 'Original date: ${widget.existing!.createdAt.toLocal()}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant))]))])),
        const SizedBox(height: 18),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: _saving ? null : _save, style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)), child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(widget.existing == null ? 'Save Update' : 'Update Entry'))),
      ])),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final TaskActivityLog log;
  final String statusLabel;
  final Color statusColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ActivityCard({required this.log, required this.statusLabel, required this.statusColor, required this.onEdit, required this.onDelete});

  String _timestamp(DateTime date) {
    final local = date.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.day.toString().padLeft(2, '0')} ${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][local.month - 1]} ${local.year} · $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12), elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: colors.outlineVariant.withValues(alpha: .7))),
      child: Padding(padding: const EdgeInsets.all(15), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: statusColor.withValues(alpha: .12), shape: BoxShape.circle), child: Icon(log.status == 'completed' ? Icons.check_rounded : log.status == 'notStarted' ? Icons.radio_button_unchecked : Icons.edit_note_rounded, color: statusColor)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(log.accomplished, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text(_timestamp(log.createdAt), style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
          const SizedBox(height: 9),
          Align(alignment: Alignment.centerLeft, child: _InfoChip(label: statusLabel, color: statusColor)),


            const SizedBox(height: 12),

          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 420;

              final accomplishedSection = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What accomplished',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    log.accomplished.trim().isEmpty
                        ? 'No accomplishment details added.'
                        : log.accomplished,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                  ),
                  if (log.nextSteps.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'What’s next?',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      log.nextSteps,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                  ],
                ],
              );

              final notesSection = Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.sticky_note_2_outlined,
                          size: 17,
                          color: colors.secondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Notes',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      log.notes.trim().isEmpty
                          ? 'No additional notes.'
                          : log.notes,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                  ],
                ),
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: accomplishedSection,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: notesSection,
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  accomplishedSection,
                  const SizedBox(height: 14),
                  notesSection,
                ],
              );
            },
          ),

          const SizedBox(height: 8),


          const SizedBox(height: 8),
          Row(children: [TextButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit_outlined, size: 17), label: const Text('Edit')), const SizedBox(width: 4), TextButton.icon(onPressed: onDelete, style: TextButton.styleFrom(foregroundColor: AppColors.error), icon: const Icon(Icons.delete_outline, size: 17), label: const Text('Delete'))]),
        ])),
      ])),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;
  const _InfoChip({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: color.withValues(alpha: .11), borderRadius: BorderRadius.circular(8)), child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700)));
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Row(children: [Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant), const SizedBox(width: 9), SizedBox(width: 86, child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant))), Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500))) ]);
}

class _FormLabel extends StatelessWidget {
  final String label;
  final bool requiredField;
  const _FormLabel({required this.label, this.requiredField = false});
  @override
  Widget build(BuildContext context) => RichText(text: TextSpan(style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600), children: [TextSpan(text: label), if (requiredField) const TextSpan(text: ' *', style: TextStyle(color: AppColors.error))]));
}

class _StatusChoice extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onTap;
  const _StatusChoice({required this.label, required this.value, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final active = selected == value;
    final color = value == 'completed' ? AppColors.success : value == 'notStarted' ? Theme.of(context).colorScheme.outline : AppColors.info;
    return ChoiceChip(label: Text(label), selected: active, onSelected: (_) => onTap(value), selectedColor: color.withValues(alpha: .15), side: BorderSide(color: active ? color : Theme.of(context).colorScheme.outlineVariant), labelStyle: TextStyle(color: active ? color : Theme.of(context).colorScheme.onSurface, fontWeight: active ? FontWeight.w700 : FontWeight.normal));
  }
}

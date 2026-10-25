
import 'package:flutter/material.dart';

import '../models/task.dart';
import '../themes/app_colors.dart';

class TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onChanged;
  final bool? completedOverride;
  final bool showDueDate;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TaskTile({
    super.key,
    required this.task,
    required this.onChanged,
    this.completedOverride,
    this.showDueDate = true,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isCompleted = completedOverride ?? task.isCompleted;

    final priority = task.priority.toLowerCase();
    final priorityColor = _priorityColor(priority);
    final priorityLabel = _priorityLabel(priority);

    final now = DateTime.now();
    final dueDate = task.dueDate;
    final isOverdue = !isCompleted &&
        DateTime(dueDate.year, dueDate.month, dueDate.day)
            .isBefore(DateTime(now.year, now.month, now.day));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: isCompleted ? colors.surfaceContainerLow : colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: colors.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: Checkbox(
                    value: isCompleted,
                    onChanged: (_) => onChanged(),
                    activeColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 3, right: 6),
                            child: Text(
                              task.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                                color: isCompleted
                                    ? colors.onSurfaceVariant
                                    : colors.onSurface,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                        _PriorityTag(
                          label: priorityLabel,
                          color: priorityColor,
                        ),
                        if (onDelete != null) ...[
                          const SizedBox(width: 2),
                          PopupMenuButton<String>(
                            tooltip: 'Task options',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                            onSelected: (value) {
                              if (value == 'delete') onDelete?.call();
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline_rounded, color: AppColors.error),
                                    SizedBox(width: 10),
                                    Text('Delete task'),
                                  ],
                                ),
                              ),
                            ],
                            icon: Icon(Icons.more_horiz_rounded, color: colors.onSurfaceVariant, size: 21),
                          ),
                        ],
                      ],
                    ),
                    if (task.subject.trim().isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Icon(
                            Icons.label_outline_rounded,
                            size: 15,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              task.subject,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                                height: 1.3,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (showDueDate) ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isOverdue
                                ? Icons.warning_amber_rounded
                                : Icons.calendar_today_outlined,
                            size: 15,
                            color: isOverdue
                                ? AppColors.error
                                : colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${dueDate.day.toString().padLeft(2, '0')}/'
                                  '${dueDate.month.toString().padLeft(2, '0')}/'
                                  '${dueDate.year}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: isOverdue
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isOverdue
                                    ? AppColors.error
                                    : colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (isOverdue) ...[
                            const SizedBox(width: 7),
                            Text(
                              'Overdue',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'high':
        return AppColors.error;
      case 'low':
        return AppColors.success;
      case 'medium':
      default:
        return AppColors.warning;
    }
  }

  String _priorityLabel(String priority) {
    switch (priority) {
      case 'high':
        return 'HIGH';
      case 'low':
        return 'LOW';
      case 'medium':
      default:
        return 'MEDIUM';
    }
  }
}

class _PriorityTag extends StatelessWidget {
  final String label;
  final Color color;

  const _PriorityTag({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: color.withValues(alpha: 0.30),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

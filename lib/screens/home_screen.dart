import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/routine/routine_cubit.dart';
import '../cubits/routine/routine_state.dart';
import '../cubits/task/task_cubit.dart';
import '../cubits/task/task_state.dart';

import '../models/task.dart';
import '../themes/app_colors.dart';

class HomeScreen extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onViewTasks;
  final VoidCallback onViewProgress;

  const HomeScreen({
    super.key,
    required this.isLoading,
    required this.onViewTasks,
    required this.onViewProgress,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const List<String> _quotes = [
    'Small steps every day lead to big results.',
    'You do not have to be perfect. You just have to keep going.',
    'A little progress each day adds up to big results.',
    'Your future is built by what you do today.',
    'Consistency turns effort into progress.',
    'Start where you are. Use what you have. Do what you can.',
    'Focus on progress, not perfection.',
    'You are capable of more than you think.',
    'The secret of getting ahead is getting started.',
    'Make today count, one task at a time.',
    'Discipline is choosing what matters most.',
    'Every expert was once a beginner.',
    'The journey gets easier when you keep showing up.',
    'Do something today that your future self will thank you for.',
    'You can do hard things, one step at a time.',
    'A focused hour can change your whole day.',
    'Progress begins when excuses end.',
    'Keep your eyes on the goal and your feet on the ground.',
    'You are not behind. You are building at your own pace.',
    'Great things are done by a series of small things brought together.',
    'One completed task is better than ten perfect plans.',
    'Give your best to this moment.',
    'The more you practice, the more progress you notice.',
    'Your habits shape your days, and your days shape your life.',
    'Keep learning. Keep growing. Keep moving.',
    'A calm mind and a clear plan make a strong start.',
    'Success is the sum of small efforts repeated day in and day out.',
    'You only need to take the next step.',
    'Build a routine that supports the life you want.',
    'Your effort matters, even when progress feels slow.',
    'The best time to begin is the moment you have.',
    'Do not count the days. Make the days count.',
    'Stay patient with the process and committed to the goal.',
    'Every day is another chance to improve.',
    'Action creates clarity.',
    'You grow every time you choose to try again.',
    'Make room for progress, not pressure.',
    'Small wins are still wins.',
    'The work you do today creates options for tomorrow.',
    'Keep the promise you made to yourself.',
    'You can restart at any moment.',
    'Be proud of how far you have come.',
    'A good plan becomes powerful when you act on it.',
    'Do the next right thing.',
    'Your pace is valid. Keep moving forward.',
    'Put your energy into what you can control.',
    'Motivation may start you; habits help you continue.',
    'One step forward is still forward.',
    'Learn from yesterday, act today, prepare for tomorrow.',
    'Protect your focus and your focus will protect your time.',
    'You do not need to see the whole staircase to take the first step.',
    'Be consistent enough to give yourself a chance.',
    'Choose progress over procrastination.',
    'The little things you do regularly become the big things.',
    'Your goals deserve your attention today.',
    'Take a breath, make a plan, and begin.',
    'Growth happens when you keep showing up.',
    'Do what you can with the time you have.',
    'You are building more than a result; you are building yourself.',
    'Finish the day knowing you moved forward.',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshRoutine();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _refreshRoutine();
    }
  }

  Future<void> _refreshRoutine() async {
    final cubit = context.read<RoutineCubit>();
    final today = DateTime.now();
    await cubit.loadToday();
    await cubit.loadHistory(
      startDate: DateTime(today.year, today.month, today.day).subtract(const Duration(days: 89)),
      endDate: DateTime(today.year, today.month, today.day),
    );
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _quoteForToday {
    final now = DateTime.now();
    final dayNumber = DateTime(now.year, now.month, now.day)
        .difference(DateTime(2024, 1, 1))
        .inDays;
    return _quotes[dayNumber.abs() % _quotes.length];
  }

  String _dateLabel(DateTime date) {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final today = DateTime.now();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 68,
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
                border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Day by Day', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, letterSpacing: 0.1)),
                  SizedBox(height: 1),
                  Text('YOUR PERSONAL DASHBOARD', style: TextStyle(fontSize: 9, letterSpacing: 1.35, color: Color(0xFFDDE2FF), fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.13), shape: BoxShape.circle),
              child: const Icon(Icons.wb_sunny_outlined, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _refreshRoutine(),
            context.read<TaskCubit>().loadTask(),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
          children: [
            Text(_dateLabel(today), style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
            const SizedBox(height: 5),
            Text('$_greeting! 👋', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.6)),
            const SizedBox(height: 5),
            Text('Let’s make today a good one.', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 20),
            _QuoteCard(quote: _quoteForToday),
            const SizedBox(height: 24),
            _SectionHeading(title: 'Your day at a glance', subtitle: 'A little progress goes a long way'),
            const SizedBox(height: 12),
            BlocBuilder<RoutineCubit, RoutineState>(
              builder: (context, routineState) => BlocBuilder<TaskCubit, TaskState>(
                builder: (context, taskState) {
                  final ratio = routineState.completionPercentage.clamp(0.0, 1.0);
                  final projectTasks = taskState.tasks.where((task) => task.taskType != 'routine').toList();
                  final completedTasks = projectTasks.where((task) => task.isCompleted).length;
                  final openTasks = projectTasks.where((task) => !task.isCompleted).length;
                  final streak = _calculateStreak(routineState.history);
                  return Column(
                    children: [
                      Row(children: [
                        Expanded(child: _MetricCard(icon: Icons.check_circle_outline_rounded, label: 'Routine done', value: '${(ratio * 100).round()}%', detail: '${routineState.completedCount}/${routineState.totalCount} completed', color: AppColors.secondary)),
                        const SizedBox(width: 12),
                        Expanded(child: _MetricCard(icon: Icons.local_fire_department_rounded, label: 'Current streak', value: '$streak ${streak == 1 ? 'day' : 'days'}', detail: 'Keep showing up', color: const Color(0xFFD97706))),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _MetricCard(icon: Icons.task_alt_rounded, label: 'Completed', value: '$completedTasks', detail: 'Tasks finished', color: const Color(0xFF2563EB))),
                        const SizedBox(width: 12),
                        Expanded(child: _MetricCard(icon: Icons.pending_actions_rounded, label: 'Remaining', value: '$openTasks', detail: 'Tasks to work on', color: const Color(0xFF7C3AED))),
                      ]),
                      const SizedBox(height: 12),
                      _TargetProgressCard(percentage: ratio),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 26),
            Row(
              children: [
                const Expanded(child: _SectionHeading(title: 'Today’s routine', subtitle: 'Check things off as you go')),
                TextButton(onPressed: widget.onViewTasks, child: const Text('All tasks')),
              ],
            ),
            const SizedBox(height: 10),
            BlocBuilder<RoutineCubit, RoutineState>(
              builder: (context, state) {
                if (state.isLoading && state.tasks.isEmpty) return const _LoadingCard();
                if (state.tasks.isEmpty) {
                  return _EmptyCard(icon: Icons.wb_sunny_outlined, title: 'No routine tasks yet', message: 'Create a routine group and add your daily habits.', actionLabel: 'Go to Tasks', onAction: widget.onViewTasks);
                }
                return Container(
                  decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.65))),
                  child: Column(
                    children: [
                      for (var i = 0; i < state.tasks.length; i++) ...[
                        _RoutineRow(
                          task: state.tasks[i],
                          isCompleted: state.tasks[i].id != null && state.isTaskCompleted(state.tasks[i].id!),
                          onChanged: (value) async {
                            final task = state.tasks[i];
                            if (value != null) await context.read<RoutineCubit>().toggleTask(task, value);
                          },
                        ),
                        if (i != state.tasks.length - 1) Divider(height: 1, indent: 16, endIndent: 16, color: colorScheme.outlineVariant.withValues(alpha: 0.55)),
                      ],
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 26),
            Row(children: [const Expanded(child: _SectionHeading(title: 'Upcoming deadlines', subtitle: 'Overdue first, then what’s next')), TextButton(onPressed: widget.onViewTasks, child: const Text('View tasks'))]),
            const SizedBox(height: 10),
            BlocBuilder<TaskCubit, TaskState>(
              builder: (context, state) {
                final upcoming = state.tasks.where((task) => !task.isCompleted && task.taskType != 'routine').toList()
                  ..sort((a, b) {
                    final aOverdue = _isOverdue(a.dueDate, today);
                    final bOverdue = _isOverdue(b.dueDate, today);
                    if (aOverdue != bOverdue) return aOverdue ? -1 : 1;
                    return a.dueDate.compareTo(b.dueDate);
                  });
                final visible = upcoming.take(3).toList();
                if (state.isLoading && state.tasks.isEmpty) return const _LoadingCard();
                if (visible.isEmpty) return const _EmptyCard(icon: Icons.event_available_outlined, title: 'You’re all caught up', message: 'No unfinished project deadlines to show right now.');
                return Column(children: visible.map((task) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _DeadlineCard(task: task, onTap: widget.onViewTasks, isOverdue: _isOverdue(task.dueDate, today)))).toList());
              },
            ),
            const SizedBox(height: 26),
            _SectionHeading(title: 'Quick actions', subtitle: 'Jump straight to what you need'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _QuickAction(icon: Icons.add_task_rounded, title: 'Manage tasks', subtitle: 'Groups & tasks', onTap: widget.onViewTasks, color: AppColors.primary)),
              const SizedBox(width: 12),
              Expanded(child: _QuickAction(icon: Icons.insights_rounded, title: 'View progress', subtitle: 'Your consistency', onTap: widget.onViewProgress, color: AppColors.secondary)),
            ]),
          ],
        ),
      ),
    );
  }

  int _calculateStreak(List<dynamic> history) {
    // Count consecutive days with at least one completed routine item.
    final completedDays = <String>{};
    for (final item in history) {
      if (item.isCompleted == true) completedDays.add(item.completionDate.toString().substring(0, 10));
    }
    var day = DateTime.now();
    var streak = 0;
    if (!completedDays.contains(_dateKey(day))) {
      day = day.subtract(const Duration(days: 1));
    }
    while (completedDays.contains(_dateKey(day))) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  String _dateKey(DateTime date) => '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  bool _isOverdue(DateTime dueDate, DateTime today) => DateTime(dueDate.year, dueDate.month, dueDate.day).isBefore(DateTime(today.year, today.month, today.day));
}

class _QuoteCard extends StatelessWidget {
  final String quote;
  const _QuoteCard({required this.quote});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF3730A3), Color(0xFF5145CD), Color(0xFF0F766E)]),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.18), blurRadius: 22, offset: const Offset(0, 9))],
      ),
      child: Stack(children: [
        Positioned(right: -8, top: -13, child: Icon(Icons.format_quote_rounded, size: 100, color: Colors.white.withValues(alpha: 0.09))),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Container(width: 32, height: 32, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.auto_awesome, size: 17, color: Colors.white)), const SizedBox(width: 10), const Text('A THOUGHT FOR TODAY', style: TextStyle(color: Color(0xFFE2E7FF), fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 1.5))]),
          const SizedBox(height: 15),
          Text('“$quote”', style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600, height: 1.45, fontSize: 17)),
          const SizedBox(height: 13),
          Row(children: [Container(width: 28, height: 2, decoration: BoxDecoration(color: const Color(0xFF99F6E4), borderRadius: BorderRadius.circular(2))), const SizedBox(width: 8), const Text('A little inspiration, every day', style: TextStyle(color: Color(0xFFE2E7FF), fontSize: 11, fontWeight: FontWeight.w500))]),
        ]),
      ]),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeading({required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.35)), const SizedBox(height: 3), Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant))]);
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final Color color;
  const _MetricCard({required this.icon, required this.label, required this.value, required this.detail, required this.color});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.65))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withValues(alpha: 0.11), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)), const SizedBox(height: 13), Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.7)), const SizedBox(height: 2), Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(detail, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, fontSize: 10.5))]));
  }
}

class _TargetProgressCard extends StatelessWidget {
  final double percentage;
  const _TargetProgressCard({required this.percentage});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final met = percentage >= 0.8;
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: scheme.secondaryContainer.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(18)), child: Column(children: [Row(children: [Icon(met ? Icons.verified_rounded : Icons.flag_outlined, color: met ? AppColors.secondary : scheme.primary, size: 20), const SizedBox(width: 8), Expanded(child: Text(met ? 'Daily target reached!' : 'Your daily target is 80%', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700))), Text('${(percentage * 100).round()}%', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800))]), const SizedBox(height: 11), ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: percentage, minHeight: 8, backgroundColor: scheme.surface.withValues(alpha: 0.9), color: met ? AppColors.secondary : scheme.primary)), const SizedBox(height: 7), Align(alignment: Alignment.centerLeft, child: Text(met ? 'Nice work — keep the momentum going.' : 'Every completed routine brings you closer.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)))]));
  }
}

class _RoutineRow extends StatelessWidget {
  final Task task;
  final bool isCompleted;
  final ValueChanged<bool?> onChanged;
  const _RoutineRow({required this.task, required this.isCompleted, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5), child: Row(children: [Checkbox(value: isCompleted, onChanged: onChanged, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)), activeColor: AppColors.secondary), const SizedBox(width: 7), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(task.title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, decoration: isCompleted ? TextDecoration.lineThrough : null, color: isCompleted ? scheme.onSurfaceVariant : scheme.onSurface)), if (task.subject.trim().isNotEmpty) Text(task.subject, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant))])), Icon(isCompleted ? Icons.check_circle_rounded : Icons.circle_outlined, color: isCompleted ? AppColors.secondary : scheme.outlineVariant, size: 19)]));
  }
}

class _DeadlineCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final bool isOverdue;
  const _DeadlineCard({required this.task, required this.onTap, required this.isOverdue});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final due = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
    final baseToday = DateTime(today.year, today.month, today.day);
    final difference = due.difference(baseToday).inDays;
    final dueLabel = isOverdue ? 'OVERDUE' : difference == 0 ? 'DUE TODAY' : difference == 1 ? 'TOMORROW' : 'IN $difference DAYS';
    final statusColor = isOverdue ? AppColors.error : difference <= 1 ? const Color(0xFFD97706) : AppColors.secondary;
    return Material(color: scheme.surface, borderRadius: BorderRadius.circular(18), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.65))), child: Row(children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(13)), child: Icon(Icons.event_note_rounded, color: statusColor)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(task.subject.trim().isEmpty ? 'Project task' : task.subject, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant))])), const SizedBox(width: 8), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(8)), child: Text(dueLabel, style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 9, letterSpacing: 0.3))), const SizedBox(height: 5), Text('${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant))]), const SizedBox(width: 3), Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant, size: 19)]))));
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;
  const _QuickAction({required this.icon, required this.title, required this.subtitle, required this.onTap, required this.color});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(color: scheme.surface, borderRadius: BorderRadius.circular(18), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.65))), child: Row(children: [Container(width: 38, height: 38, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, fontSize: 10.5))]))]))));
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _EmptyCard({required this.icon, required this.title, required this.message, this.actionLabel, this.onAction});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(width: double.infinity, padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.65)),), child: Column(children: [Icon(icon, size: 30, color: scheme.primary), const SizedBox(height: 9), Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)), if (actionLabel != null && onAction != null) ...[const SizedBox(height: 12), OutlinedButton(onPressed: onAction, child: Text(actionLabel!))]]));
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) => const Padding(padding: EdgeInsets.all(28), child: Center(child: CircularProgressIndicator()));
}

class _SubjectRow extends StatelessWidget {
  final String name;
  final String teacher;
  const _SubjectRow({required this.name, required this.teacher});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.65))), child: Row(children: [Container(width: 38, height: 38, decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(12)), child: Icon(Icons.menu_book_rounded, color: scheme.onPrimaryContainer)), const SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)), if (teacher.trim().isNotEmpty) Text(teacher, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant))])), Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant)]));
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/routine/routine_cubit.dart';
import '../cubits/routine/routine_state.dart';
import '../cubits/task/task_cubit.dart';
import '../cubits/task/task_state.dart';
import '../models/routine_completion.dart';
import '../themes/app_colors.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late DateTime _selectedDate;
  late DateTime _displayedMonth;
  bool _isLoading = false;

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  String _dateKey(DateTime date) {
    final d = _dateOnly(date);
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    final today = _dateOnly(DateTime.now());
    _selectedDate = today;
    _displayedMonth = DateTime(today.year, today.month);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    // Capture the Cubits before awaiting so BuildContext is not used across
    // asynchronous gaps.
    final routineCubit = context.read<RoutineCubit>();
    final taskCubit = context.read<TaskCubit>();

    try {
      final now = _dateOnly(DateTime.now());
      await routineCubit.loadToday();
      // Load saved history from the beginning of the app's supported timeline.
      await routineCubit.loadHistory(
        startDate: DateTime(2000, 1, 1),
        endDate: now,
      );
      await taskCubit.loadTask();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _changeMonth(int offset) {
    final next = DateTime(_displayedMonth.year, _displayedMonth.month + offset);
    final current = DateTime(DateTime.now().year, DateTime.now().month);
    if (next.isAfter(current) || next.isBefore(DateTime(2000, 1))) return;
    setState(() {
      _displayedMonth = next;
      _selectedDate = DateTime(next.year, next.month, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 68,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.insights_rounded),
            SizedBox(width: 12),
            Text('Your Progress', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh progress',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: BlocBuilder<RoutineCubit, RoutineState>(
          builder: (context, routineState) {
            return BlocBuilder<TaskCubit, TaskState>(
              builder: (context, taskState) {
                final metrics = _ProgressMetrics.fromStates(
                  routineState: routineState,
                  taskState: taskState,
                  dateKey: _dateKey,
                );

                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                  children: [
                    Text(
                      'Consistency over perfection.',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'See your daily effort, monthly consistency and perfect-day streak.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    _SectionHeading(title: 'Completion overview', subtitle: 'A quick look at your progress'),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _DonutCard(
                            title: 'Daily routine',
                            subtitle: 'Today',
                            percent: metrics.todayPercent,
                            segments: [
                              _DonutSegment(value: metrics.todayCompleted.toDouble(), color: const Color(0xFF0F766E)),
                              _DonutSegment(value: math.max(0, metrics.routineTaskCount - metrics.todayCompleted).toDouble(), color: colors.surfaceContainerHighest),
                            ],
                            legend: [
                              _LegendItem(color: const Color(0xFF0F766E), label: 'Done', value: '${metrics.todayCompleted}/${metrics.routineTaskCount}'),
                              _LegendItem(color: colors.surfaceContainerHighest, label: 'Left', value: '${math.max(0, metrics.routineTaskCount - metrics.todayCompleted)}'),
                            ],
                            emptyLabel: 'No routine',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _DonutCard(
                            title: 'Overall',
                            subtitle: 'Recorded work',
                            percent: metrics.overallPercent,
                            segments: [
                              _DonutSegment(value: metrics.completedRoutineInstances.toDouble(), color: const Color(0xFF4338CA)),
                              _DonutSegment(value: metrics.completedProjectTasks.toDouble(), color: const Color(0xFF0F766E)),
                              _DonutSegment(value: metrics.remainingWork.toDouble(), color: const Color(0xFFD97706)),
                            ],
                            legend: [
                              _LegendItem(color: const Color(0xFF4338CA), label: 'Routine', value: '${metrics.completedRoutineInstances} · ${metrics.shareOfOverall(metrics.completedRoutineInstances)}%'),
                              _LegendItem(color: const Color(0xFF0F766E), label: 'Projects', value: '${metrics.completedProjectTasks} · ${metrics.shareOfOverall(metrics.completedProjectTasks)}%'),
                              _LegendItem(color: const Color(0xFFD97706), label: 'Remaining', value: '${metrics.remainingWork} · ${metrics.shareOfOverall(metrics.remainingWork)}%'),
                            ],
                            emptyLabel: 'No data',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _SectionHeading(title: 'Monthly routine calendar', subtitle: 'Each day is colored by your routine completion'),
                    const SizedBox(height: 10),
                    _MonthCalendarCard(
                      displayedMonth: _displayedMonth,
                      selectedDate: _selectedDate,
                      today: _dateOnly(DateTime.now()),
                      statsForDate: metrics.statsForDate,
                      dateKey: _dateKey,
                      onPrevious: () => _changeMonth(-1),
                      onNext: () => _changeMonth(1),
                      onSelectDate: (date) => setState(() => _selectedDate = date),
                    ),
                    const SizedBox(height: 10),
                    _SelectedDayCard(
                      date: _selectedDate,
                      stats: metrics.statsForDate(_selectedDate),
                      colors: colors,
                    ),
                    const SizedBox(height: 22),
                    _SectionHeading(title: 'Perfect-day streak', subtitle: 'Only 100% routine days count toward a streak'),
                    const SizedBox(height: 10),
                    _StreakCard(
                      currentStreak: metrics.currentPerfectStreak,
                      bestStreak: metrics.bestPerfectStreak,
                      perfectDays: metrics.perfectDays,
                    ),
                    const SizedBox(height: 14),
                    _InsightCard(
                      targetDays: metrics.targetDays,
                      trackedDays: metrics.trackedDays,
                      perfectDays: metrics.perfectDays,
                      averagePercent: metrics.averageRecordedPercent,
                    ),
                    if (_isLoading) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(minHeight: 2),
                    ],
                    if (routineState.error != null || taskState.error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Some progress data could not be refreshed. Pull down to try again.',
                        style: theme.textTheme.bodySmall?.copyWith(color: colors.error),
                      ),
                    ],
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ProgressMetrics {
  final int routineTaskCount;
  final int todayCompleted;
  final int completedRoutineInstances;
  final int completedProjectTasks;
  final int remainingWork;
  final double overallPercent;
  final int trackedDays;
  final int targetDays;
  final int perfectDays;
  final int currentPerfectStreak;
  final int bestPerfectStreak;
  final double averageRecordedPercent;
  final Map<String, _DayStats> dayStats;
  final String Function(DateTime) dateKey;

  const _ProgressMetrics({
    required this.routineTaskCount,
    required this.todayCompleted,
    required this.completedRoutineInstances,
    required this.completedProjectTasks,
    required this.remainingWork,
    required this.overallPercent,
    required this.trackedDays,
    required this.targetDays,
    required this.perfectDays,
    required this.currentPerfectStreak,
    required this.bestPerfectStreak,
    required this.averageRecordedPercent,
    required this.dayStats,
    required this.dateKey,
  });

  double get todayPercent => routineTaskCount == 0 ? 0 : todayCompleted / routineTaskCount;

  int shareOfOverall(int value) {
    final total = completedRoutineInstances + completedProjectTasks + remainingWork;
    return total == 0 ? 0 : (value / total * 100).round();
  }

  _DayStats statsForDate(DateTime date) {
    final key = dateKey(date);
    return dayStats[key] ?? const _DayStats(hasData: false, completed: 0, total: 0);
  }

  factory _ProgressMetrics.fromStates({
    required RoutineState routineState,
    required TaskState taskState,
    required String Function(DateTime) dateKey,
  }) {
    final today = DateTime.now();
    final todayKey = dateKey(today);
    final routineTasks = routineState.tasks;
    final routineCount = routineTasks.length;
    final todayCompleted = routineTasks.where((task) => task.id != null && routineState.isTaskCompleted(task.id!)).length;

    final rowsByDate = <String, List<RoutineCompletion>>{};
    for (final row in routineState.history) {
      rowsByDate.putIfAbsent(row.completionDate, () => []).add(row);
    }

    final dayStats = <String, _DayStats>{};
    for (final entry in rowsByDate.entries) {
      final completed = entry.value.where((row) => row.isCompleted).length;
      dayStats[entry.key] = _DayStats(
        hasData: true,
        completed: completed,
        total: routineCount,
      );
    }
    // Today's live state is authoritative, even if the user has not saved a toggle yet.
    dayStats[todayKey] = _DayStats(
      hasData: true,
      completed: todayCompleted,
      total: routineCount,
    );

    final trackedKeys = dayStats.keys.toList()..sort();
    final trackedDays = trackedKeys.length;
    var completedRoutineInstances = 0;
    var possibleRoutineInstances = 0;
    var targetDays = 0;
    var perfectDays = 0;
    var percentSum = 0.0;

    for (final key in trackedKeys) {
      final stats = dayStats[key]!;
      if (stats.total <= 0) continue;
      final completed = stats.completed.clamp(0, stats.total).toInt();
      completedRoutineInstances += completed;
      possibleRoutineInstances += stats.total;
      final percent = completed / stats.total;
      percentSum += percent;
      if (percent >= 0.8) targetDays++;
      if (percent >= 1) perfectDays++;
    }

    final projectTasks = taskState.tasks.where((task) => task.taskType != 'routine').toList();
    final completedProjectTasks = projectTasks.where((task) => task.isCompleted).length;
    final remainingRoutine = math.max(0, possibleRoutineInstances - completedRoutineInstances);
    final remainingProject = math.max(0, projectTasks.length - completedProjectTasks);
    final remainingWork = remainingRoutine + remainingProject;
    final totalWork = completedRoutineInstances + completedProjectTasks + remainingWork;
    final overallPercent = totalWork == 0 ? 0.0 : (completedRoutineInstances + completedProjectTasks) / totalWork;

    var currentStreak = 0;
    var cursor = DateTime(today.year, today.month, today.day);
    while (true) {
      final stats = dayStats[dateKey(cursor)];
      if (stats == null || stats.total <= 0 || stats.completed < stats.total) {
        break;
      }
      currentStreak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    var bestStreak = 0;
    var runningStreak = 0;
    DateTime? previous;
    for (final key in trackedKeys) {
      final date = DateTime.tryParse(key);
      final stats = dayStats[key];
      if (date == null || stats == null || stats.total <= 0 || stats.completed < stats.total) {
        runningStreak = 0;
        previous = date;
        continue;
      }
      if (previous != null && date.difference(previous).inDays == 1) {
        runningStreak++;
      } else {
        runningStreak = 1;
      }
      bestStreak = math.max(bestStreak, runningStreak);
      previous = date;
    }

    return _ProgressMetrics(
      routineTaskCount: routineCount,
      todayCompleted: todayCompleted,
      completedRoutineInstances: completedRoutineInstances,
      completedProjectTasks: completedProjectTasks,
      remainingWork: remainingWork,
      overallPercent: overallPercent,
      trackedDays: trackedDays,
      targetDays: targetDays,
      perfectDays: perfectDays,
      currentPerfectStreak: currentStreak,
      bestPerfectStreak: bestStreak,
      averageRecordedPercent: possibleRoutineInstances == 0 ? 0 : percentSum / math.max(1, trackedKeys.where((key) => dayStats[key]!.total > 0).length),
      dayStats: dayStats,
      dateKey: dateKey,
    );
  }
}

class _DayStats {
  final bool hasData;
  final int completed;
  final int total;
  const _DayStats({required this.hasData, required this.completed, required this.total});
  double get percent => total == 0 ? 0.0 : (completed / total).clamp(0.0, 1.0).toDouble();
}

class _DonutSegment {
  final double value;
  final Color color;
  const _DonutSegment({required this.value, required this.color});
}

class _LegendItem {
  final Color color;
  final String label;
  final String value;
  const _LegendItem({required this.color, required this.label, required this.value});
}

class _DonutCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double percent;
  final List<_DonutSegment> segments;
  final List<_LegendItem> legend;
  final String emptyLabel;

  const _DonutCard({required this.title, required this.subtitle, required this.percent, required this.segments, required this.legend, required this.emptyLabel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final total = segments.fold<double>(0, (sum, segment) => sum + segment.value);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 13, 10, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant, fontSize: 11)),
          const SizedBox(height: 8),
          Center(
            child: SizedBox(
              width: 102,
              height: 102,
              child: CustomPaint(
                painter: _DonutPainter(segments: segments, total: total, trackColor: colors.surfaceContainerHighest),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(child: Text('${(percent * 100).round()}%', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, fontSize: 21))),
                        Text('complete', style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant, fontSize: 9)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          for (final item in legend)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: item.color, shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Expanded(child: Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelSmall?.copyWith(fontSize: 10))),
                  Text(item.value, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 10)),
                ],
              ),
            ),
          if (total == 0) Text(emptyLabel, style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<_DonutSegment> segments;
  final double total;
  final Color trackColor;
  const _DonutPainter({required this.segments, required this.total, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 7;
    const strokeWidth = 12.0;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final track = Paint()..color = trackColor..style = PaintingStyle.stroke..strokeWidth = strokeWidth;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);
    if (total <= 0) return;
    var start = -math.pi / 2;
    for (final segment in segments) {
      if (segment.value <= 0) continue;
      final sweep = (segment.value / total) * math.pi * 2;
      final paint = Paint()..color = segment.color..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => oldDelegate.segments != segments || oldDelegate.total != total || oldDelegate.trackColor != trackColor;
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeading({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 3),
      Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
    ]);
  }
}

class _MonthCalendarCard extends StatelessWidget {
  final DateTime displayedMonth;
  final DateTime selectedDate;
  final DateTime today;
  final _DayStats Function(DateTime) statsForDate;
  final String Function(DateTime) dateKey;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onSelectDate;

  const _MonthCalendarCard({required this.displayedMonth, required this.selectedDate, required this.today, required this.statsForDate, required this.dateKey, required this.onPrevious, required this.onNext, required this.onSelectDate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final firstWeekday = DateTime(displayedMonth.year, displayedMonth.month, 1).weekday % 7;
    final daysInMonth = DateTime(displayedMonth.year, displayedMonth.month + 1, 0).day;
    final cells = <DateTime?>[...List<DateTime?>.filled(firstWeekday, null)];
    for (var day = 1; day <= daysInMonth; day++) {
      cells.add(DateTime(displayedMonth.year, displayedMonth.month, day));
    }
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.65))),
        child: Column(children: [
        Row(children: [
        IconButton(onPressed: onPrevious, tooltip: 'Previous month', icon: const Icon(Icons.chevron_left_rounded)),
        Expanded(child: Text('${_monthName(displayedMonth.month)} ${displayedMonth.year}', textAlign: TextAlign.center, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
        IconButton(onPressed: DateTime(displayedMonth.year, displayedMonth.month + 1).isAfter(DateTime(today.year, today.month)) ? null : onNext, tooltip: 'Next month', icon: const Icon(Icons.chevron_right_rounded)),
        ]),
    const SizedBox(height: 5),

    Row(
    children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
        .map(
    (label) => Expanded(
    child: Center(
    child: Text(
    label,
    style: theme.textTheme.labelSmall?.copyWith(
    color: colors.onSurfaceVariant,
    fontWeight: FontWeight.w700,
    ),
    ),
    ),
    ),
    )
        .toList(),
    ),

    const SizedBox(height: 8),
    GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: cells.length,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 7, crossAxisSpacing: 5, childAspectRatio: 0.95),
    itemBuilder: (context, index) {
    final date = cells[index];
    if (date == null) return const SizedBox.shrink();
    final stats = statsForDate(date);
    final isSelected = dateKey(date) == dateKey(selectedDate);
    final isToday = dateKey(date) == dateKey(today);
    final fill = _dayColor(stats, colors);
    return Semantics(
    button: true,
    label: '${_monthName(date.month)} ${date.day}, ${stats.hasData ? '${(stats.percent * 100).round()} percent complete' : 'no recorded history'}',
    child: InkWell(
    onTap: () => onSelectDate(date),
    borderRadius: BorderRadius.circular(10),
    child: Container(
    decoration: BoxDecoration(
    color: fill,
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: isSelected ? colors.primary : (isToday ? colors.onSurface : (stats.hasData ? fill : colors.outlineVariant)), width: isSelected ? 2 : (isToday ? 1.3 : 0.8)),
    ),
    alignment: Alignment.center,
    child: Text('${date.day}', style: theme.textTheme.labelMedium?.copyWith(fontWeight: isSelected || isToday ? FontWeight.w900 : FontWeight.w600, color: stats.hasData && stats.percent >= 0.5 ? Colors.white : colors.onSurface, fontSize: 12)),
    ),
    ),
    );
    },
    ),
    const SizedBox(height: 14),
    Wrap(spacing: 10, runSpacing: 8, children: const [
    _CalendarLegend(color: Color(0xFF047857), label: '100%'),
    _CalendarLegend(color: Color(0xFF0F766E), label: '80–99%'),
    _CalendarLegend(color: Color(0xFFD97706), label: '50–79%'),
    _CalendarLegend(color: Color(0xFFE5E7EB), label: 'Below 50%'),
    _CalendarLegend(color: Colors.transparent, label: 'No history', outlined: true),
    ]),
    ]),
    );
  }

  static Color _dayColor(_DayStats stats, ColorScheme colors) {
    if (!stats.hasData || stats.total <= 0) return colors.surface;
    if (stats.percent >= 1) return const Color(0xFF047857);
    if (stats.percent >= 0.8) return const Color(0xFF0F766E);
    if (stats.percent >= 0.5) return const Color(0xFFD97706);
    return const Color(0xFFE5E7EB);
  }

  static String _monthName(int month) => const ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][month - 1];
}

class _CalendarLegend extends StatelessWidget {
  final Color color;
  final String label;
  final bool outlined;
  const _CalendarLegend({required this.color, required this.label, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3), border: outlined ? Border.all(color: theme.colorScheme.outline) : null)),
      const SizedBox(width: 4),
      Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 10)),
    ]);
  }
}

class _SelectedDayCard extends StatelessWidget {
  final DateTime date;
  final _DayStats stats;
  final ColorScheme colors;
  const _SelectedDayCard({required this.date, required this.stats, required this.colors});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = stats.hasData && stats.total > 0 ? (stats.percent * 100).round() : null;
    final badgeColor = percent == null ? colors.surfaceContainerHighest : (percent == 100 ? const Color(0xFF047857) : (percent >= 80 ? const Color(0xFF0F766E) : (percent >= 50 ? const Color(0xFFD97706) : const Color(0xFFE5E7EB))));
    final foreground = percent != null && percent >= 50 ? Colors.white : colors.onSurface;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: colors.surfaceContainerLow, borderRadius: BorderRadius.circular(18)),
      child: Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(14)), alignment: Alignment.center, child: Text(percent == null ? '—' : '$percent%', style: theme.textTheme.labelLarge?.copyWith(color: foreground, fontWeight: FontWeight.w900))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${_weekdayName(date.weekday)}, ${_monthName(date.month)} ${date.day}', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(stats.hasData ? (stats.total == 0 ? 'No routine tasks exist for this date.' : '${stats.completed.clamp(0, stats.total)} of ${stats.total} routine tasks completed') : 'No saved routine history for this day.', style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
        ])),
      ]),
    );
  }

  static String _monthName(int month) => const ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][month - 1];
  static String _weekdayName(int day) => const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][day - 1];
}

class _StreakCard extends StatelessWidget {
  final int currentStreak;
  final int bestStreak;
  final int perfectDays;
  const _StreakCard({required this.currentStreak, required this.bestStreak, required this.perfectDays});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFF3730A3).withValues(alpha: 0.98), const Color(0xFF0F766E).withValues(alpha: 0.94)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(children: [
        Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFFD166), size: 30)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$currentStreak ${currentStreak == 1 ? 'day' : 'days'}', style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
            Text('Current perfect-day streak', style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.85))),
          ])),
        ]),
        const SizedBox(height: 16),
        Container(height: 1, color: Colors.white.withValues(alpha: 0.2)),
        const SizedBox(height: 13),
        Row(children: [
          Expanded(child: _StreakStat(label: 'Best streak', value: '$bestStreak ${bestStreak == 1 ? 'day' : 'days'}')),
          Container(width: 1, height: 34, color: Colors.white.withValues(alpha: 0.25)),
          Expanded(child: _StreakStat(label: 'Perfect days', value: '$perfectDays')),
        ]),
        const SizedBox(height: 12),
        Text('A day counts only when every routine task is completed (100%).', textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.86))),
      ]),
    );
  }
}

class _StreakStat extends StatelessWidget {
  final String label;
  final String value;
  const _StreakStat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
    const SizedBox(height: 3),
    Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white.withValues(alpha: 0.82))),
  ]);
}

class _InsightCard extends StatelessWidget {
  final int targetDays;
  final int trackedDays;
  final int perfectDays;
  final double averagePercent;
  const _InsightCard({required this.targetDays, required this.trackedDays, required this.perfectDays, required this.averagePercent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final targetPercent = trackedDays == 0 ? 0 : targetDays / trackedDays;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.65))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(Icons.auto_awesome_rounded, color: colors.primary), const SizedBox(width: 8), Text('Consistency summary', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _InsightMetric(label: 'Met 80% target', value: '$targetDays/$trackedDays days', detail: '${(targetPercent * 100).round()}% of tracked days', color: const Color(0xFF0F766E))),
          const SizedBox(width: 12),
          Expanded(child: _InsightMetric(label: 'Average routine', value: '${(averagePercent * 100).round()}%', detail: 'Across recorded days', color: const Color(0xFF4338CA))),
        ]),
        if (trackedDays == 0) ...[
          const SizedBox(height: 10),
          Text('Your insights will appear as you start recording routine activity.', style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
        ],
      ]),
    );
  }
}

class _InsightMetric extends StatelessWidget {
  final String label;
  final String value;
  final String detail;
  final Color color;
  const _InsightMetric({required this.label, required this.value, required this.detail, required this.color});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 6),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 3),
        Text(detail, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ]),
    );
  }
}

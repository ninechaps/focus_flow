import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../providers/task_provider.dart';
import '../../models/enums.dart';
import '../../models/task.dart';
import '../../models/goal.dart';

/// Statistics page — displays productivity insights and progress tracking
class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  // ───────────────────────── Helpers ─────────────────────────

  /// Format seconds into a human-readable duration string (e.g. "2h 15m", "45m", "0m")
  static String _formatDuration(int totalSeconds) {
    if (totalSeconds <= 0) return '0m';
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h';
    return '${minutes}m';
  }

  /// Check whether two [DateTime]s fall on the same calendar day.
  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Return a locale-aware short weekday label for [date].
  static String _weekdayLabel(DateTime date, String locale) {
    return DateFormat.E(locale).format(date);
  }

  /// Collect *all* tasks including subtasks from the map.
  static List<Task> _allTasksIncludingSubtasks(
    List<Task> tasks,
    Map<String, List<Task>> subtasksMap,
  ) {
    final all = <Task>[...tasks];
    for (final subtasks in subtasksMap.values) {
      all.addAll(subtasks);
    }
    return all;
  }

  /// Sum focusDuration for tasks whose reference date is [date].
  /// Reference date = completedAt ?? createdAt.
  static int _focusDurationForDay(List<Task> allTasks, DateTime date) {
    int total = 0;
    for (final t in allTasks) {
      final ref = t.completedAt ?? t.createdAt;
      if (_isSameDay(ref, date)) {
        total += t.focusDuration;
      }
    }
    return total;
  }

  // ───────────────────────── Build ──────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        final tasks = provider.tasks;
        final goals = provider.goals;
        final subtasksMap = provider.subtasksMap;
        final allTasks = _allTasksIncludingSubtasks(tasks, subtasksMap);

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        // ── Overview computations ──
        int todayFocus = 0;
        int weekFocus = 0;
        final weekStart = today.subtract(const Duration(days: 6));

        for (final t in allTasks) {
          final ref = t.completedAt ?? t.createdAt;
          final refDay = DateTime(ref.year, ref.month, ref.day);
          if (_isSameDay(refDay, today)) {
            todayFocus += t.focusDuration;
          }
          if (!refDay.isBefore(weekStart)) {
            weekFocus += t.focusDuration;
          }
        }

        final completedTopLevel = tasks
            .where((t) => t.parentTaskId == null && t.status == TaskStatus.completed)
            .length;

        // ── Bar chart data (last 7 days) ──
        final barDays = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
        final barValues = barDays.map((d) => _focusDurationForDay(allTasks, d)).toList();
        final maxBar = barValues.fold<int>(0, (a, b) => a > b ? a : b);

        // ── Task status counts (top-level only, exclude deleted) ──
        final topLevel = tasks.where((t) => t.parentTaskId == null && t.status != TaskStatus.deleted).toList();
        final pendingCount = topLevel.where((t) => t.status == TaskStatus.pending).length;
        final inProgressCount = topLevel.where((t) => t.status == TaskStatus.inProgress).length;
        final completedCount = topLevel.where((t) => t.status == TaskStatus.completed).length;
        final totalStatusCount = pendingCount + inProgressCount + completedCount;

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingLg,
            36,
            AppTheme.spacingLg,
            AppTheme.spacingLg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Title ──
              Text(AppLocalizations.of(context)!.statisticsTitle, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                AppLocalizations.of(context)!.statisticsSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: AppTheme.spacingXl),

              // ── 2. Overview cards ──
              Row(
                children: [
                  Expanded(child: _OverviewCard(label: AppLocalizations.of(context)!.todayFocus, value: _formatDuration(todayFocus), icon: Icons.today_rounded)),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(child: _OverviewCard(label: AppLocalizations.of(context)!.thisWeek, value: _formatDuration(weekFocus), icon: Icons.date_range_rounded)),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(child: _OverviewCard(label: AppLocalizations.of(context)!.completed, value: '$completedTopLevel', icon: Icons.check_circle_outline_rounded)),
                ],
              ),
              const SizedBox(height: AppTheme.spacingXl),

              // ── 3. Bar chart ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBarChart(context, barDays, barValues, maxBar, today, Localizations.localeOf(context).toString()),
                    const SizedBox(height: AppTheme.spacingXl),

                    // ── 4. Bottom two columns ──
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildStatusCard(context, pendingCount, inProgressCount, completedCount, totalStatusCount),
                          ),
                          const SizedBox(width: AppTheme.spacingMd),
                          Expanded(
                            child: _buildGoalProgress(context, goals, tasks),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ───────────────────── Section builders ─────────────────────

  Widget _buildBarChart(
    BuildContext context,
    List<DateTime> days,
    List<int> values,
    int maxValue,
    DateTime today,
    String locale,
  ) {
    final colors = context.appColors;
    const double chartHeight = 160.0;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context)!.dailyFocusLast7Days,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppTheme.spacingLg),
          SizedBox(
            height: chartHeight + 28, // chart + label row
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(days.length, (i) {
                final isToday = _isSameDay(days[i], today);
                final barHeight = maxValue > 0 ? (values[i] / maxValue) * chartHeight : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Duration label above bar
                        if (values[i] > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              _formatDuration(values[i]),
                              style: TextStyle(
                                fontSize: AppTheme.fontSizeXs,
                                color: isToday ? AppTheme.primaryColor.shade700 : colors.textHint,
                              ),
                            ),
                          ),
                        // Bar
                        Container(
                          height: barHeight < 4 && values[i] > 0 ? 4 : barHeight,
                          decoration: BoxDecoration(
                            color: isToday ? AppTheme.primaryColor.shade700 : colors.primary,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Day label
                        Text(
                          _weekdayLabel(days[i], locale),
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeXs,
                            fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                            color: isToday ? colors.textPrimary : colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    int pending,
    int inProgress,
    int completed,
    int total,
  ) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context)!.taskStatus, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppTheme.spacingLg),

          // Simple visual breakdown
          if (total > 0) ...[
            // Stacked horizontal bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 12,
                child: Row(
                  children: [
                    if (completed > 0)
                      Expanded(
                        flex: completed,
                        child: Container(color: AppTheme.successColor),
                      ),
                    if (inProgress > 0)
                      Expanded(
                        flex: inProgress,
                        child: Container(color: AppTheme.accentColor),
                      ),
                    if (pending > 0)
                      Expanded(
                        flex: pending,
                        child: Container(color: colors.textHint),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
          ],

          _StatusRow(color: AppTheme.successColor, label: AppLocalizations.of(context)!.statusCompleted, count: completed),
          const SizedBox(height: AppTheme.spacingSm),
          _StatusRow(color: AppTheme.accentColor, label: AppLocalizations.of(context)!.statusInProgress, count: inProgress),
          const SizedBox(height: AppTheme.spacingSm),
          _StatusRow(color: colors.textHint, label: AppLocalizations.of(context)!.statusPending, count: pending),

          if (total == 0) ...[
            const SizedBox(height: AppTheme.spacingLg),
            Text(AppLocalizations.of(context)!.noTasksYet, style: TextStyle(fontSize: AppTheme.fontSizeSm, color: colors.textHint)),
          ],
        ],
      ),
    );
  }

  Widget _buildGoalProgress(
    BuildContext context,
    List<Goal> goals,
    List<Task> tasks,
  ) {
    final colors = context.appColors;
    // Top-level tasks only (exclude deleted)
    final topLevel = tasks.where((t) => t.parentTaskId == null && t.status != TaskStatus.deleted).toList();

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context)!.goalProgress, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppTheme.spacingLg),
          if (goals.isEmpty)
            Text(AppLocalizations.of(context)!.noGoalsYet, style: TextStyle(fontSize: AppTheme.fontSizeSm, color: colors.textHint))
          else
            Expanded(
              child: ListView.separated(
                itemCount: goals.length,
                separatorBuilder: (context, index) => const SizedBox(height: AppTheme.spacingMd),
                itemBuilder: (context, i) {
                  final goal = goals[i];
                  final goalTasks = topLevel.where((t) => t.goalId == goal.id).toList();
                  final totalGoalTasks = goalTasks.length;
                  final completedGoalTasks = goalTasks.where((t) => t.status == TaskStatus.completed).length;
                  final progress = totalGoalTasks > 0 ? completedGoalTasks / totalGoalTasks : 0.0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              goal.name,
                              style: TextStyle(
                                fontSize: AppTheme.fontSizeSm,
                                fontWeight: FontWeight.w500,
                                color: colors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '$completedGoalTasks / $totalGoalTasks',
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeXs,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: colors.divider,
                          valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ───────────────────── Private widgets ─────────────────────

class _OverviewCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _OverviewCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppTheme.iconSizeLg, color: colors.primary),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            value,
            style: TextStyle(
              fontSize: AppTheme.fontSizeXxl,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            label,
            style: TextStyle(
              fontSize: AppTheme.fontSizeSm,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _StatusRow({required this.color, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: AppTheme.fontSizeSm, color: colors.textSecondary),
          ),
        ),
        Text(
          '$count',
          style: TextStyle(
            fontSize: AppTheme.fontSizeSm,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

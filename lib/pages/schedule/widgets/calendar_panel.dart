import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../../models/task.dart';
import '../../../models/enums.dart';

/// 日历面板 — 含月导航、周标题、日期网格、专注时长指示和 DragTarget
class CalendarPanel extends StatelessWidget {
  final DateTime currentMonth;
  final DateTime selectedDate;
  final Map<DateTime, List<Task>> dateTaskMap;
  final Map<DateTime, int> focusDurationMap;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onToday;
  final ValueChanged<DateTime> onSelectDate;
  final void Function(Task task, DateTime date) onTaskDropped;

  const CalendarPanel({
    super.key,
    required this.currentMonth,
    required this.selectedDate,
    required this.dateTaskMap,
    required this.focusDurationMap,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onToday,
    required this.onSelectDate,
    required this.onTaskDropped,
  });

  static const _priorityHigh = Color(0xFFEF4444);
  static const _priorityMedium = Color(0xFFF59E0B);
  static const _priorityLow = Color(0xFF22C55E);

  List<String> _weekDays(String locale) {
    return List.generate(7, (i) {
      final date = DateTime(2024, 1, 1 + i);
      return DateFormat.E(locale).format(date);
    });
  }

  List<DateTime> _calendarDates(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final offset = (firstDay.weekday - 1) % 7;
    final start = firstDay.subtract(Duration(days: offset));
    return List.generate(42, (i) => start.add(Duration(days: i)));
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isCurrentMonth(DateTime date) =>
      date.year == currentMonth.year && date.month == currentMonth.month;

  Color _priorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return _priorityHigh;
      case TaskPriority.medium:
        return _priorityMedium;
      case TaskPriority.low:
        return _priorityLow;
    }
  }

  String _formatDuration(BuildContext context, int totalSeconds) {
    final l10n = AppLocalizations.of(context)!;
    final minutes = totalSeconds ~/ 60;
    if (minutes >= 60) {
      return l10n.scheduleFocusDurationHours(minutes ~/ 60, minutes % 60);
    }
    return l10n.scheduleFocusDuration(minutes);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final dates = _calendarDates(currentMonth);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingXl),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        children: [
          _buildMonthNavigation(context),
          Divider(height: 1, color: colors.divider),
          _buildWeekdayHeader(context),
          Divider(height: 1, color: colors.divider),
          Expanded(
            child: _buildCalendarGrid(context, dates, todayDate),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthNavigation(BuildContext context) {
    final colors = context.appColors;
    final locale = Localizations.localeOf(context).toString();
    final title = DateFormat.yMMMM(locale).format(currentMonth);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLg,
        vertical: AppTheme.spacingMd,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onPreviousMonth,
            icon: const Icon(Icons.chevron_left, size: AppTheme.iconSizeLg),
            splashRadius: AppTheme.iconSizeMd,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: AppTheme.buttonHeight,
              minHeight: AppTheme.buttonHeight,
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Text(
            title,
            style: TextStyle(
              fontSize: AppTheme.fontSizeLg,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          IconButton(
            onPressed: onNextMonth,
            icon: const Icon(Icons.chevron_right, size: AppTheme.iconSizeLg),
            splashRadius: AppTheme.iconSizeMd,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: AppTheme.buttonHeight,
              minHeight: AppTheme.buttonHeight,
            ),
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: onToday,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
                vertical: AppTheme.spacingXs,
              ),
              minimumSize: Size.zero,
              side: BorderSide(color: colors.divider),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.filterToday,
              style: TextStyle(
                fontSize: AppTheme.fontSizeSm,
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeader(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      child: Row(
        children: _weekDays(Localizations.localeOf(context).toString()).map((day) {
          return Expanded(
            child: Center(
              child: Text(
                day,
                style: TextStyle(
                  fontSize: AppTheme.fontSizeXs,
                  fontWeight: FontWeight.w600,
                  color: colors.textHint,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(
    BuildContext context,
    List<DateTime> dates,
    DateTime todayDate,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rowHeight = constraints.maxHeight / 6;
        return Column(
          children: List.generate(6, (row) {
            return SizedBox(
              height: rowHeight,
              child: Row(
                children: List.generate(7, (col) {
                  final date = dates[row * 7 + col];
                  return Expanded(
                    child: _buildDateCell(context, date, todayDate),
                  );
                }),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildDateCell(
    BuildContext context,
    DateTime date,
    DateTime todayDate,
  ) {
    final colors = context.appColors;
    final isToday = _isSameDay(date, todayDate);
    final isSelected = _isSameDay(date, selectedDate);
    final isInMonth = _isCurrentMonth(date);
    final tasks = dateTaskMap[date] ?? [];
    final focusSeconds = focusDurationMap[date] ?? 0;

    final priorities = <TaskPriority>{};
    for (final t in tasks) {
      priorities.add(t.priority);
      if (priorities.length >= 3) break;
    }
    final sortedPriorities = priorities.toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) => isInMonth,
      onAcceptWithDetails: (details) => onTaskDropped(details.data, date),
      builder: (context, candidateData, rejectedData) {
        final isDragOver = candidateData.isNotEmpty;
        return GestureDetector(
          onTap: () => onSelectDate(date),
          child: Container(
            margin: const EdgeInsets.all(AppTheme.spacingXs),
            decoration: BoxDecoration(
              color: isSelected && !isToday
                  ? colors.primaryLight
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: isDragOver
                  ? Border.all(color: colors.primary, width: 2)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Date number
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: isToday
                      ? BoxDecoration(
                          color: colors.primary,
                          shape: BoxShape.circle,
                        )
                      : null,
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeSm,
                      fontWeight: isToday || isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isToday
                          ? Colors.white
                          : isInMonth
                              ? colors.textPrimary
                              : colors.textHint,
                    ),
                  ),
                ),
                // Priority dots
                if (sortedPriorities.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: sortedPriorities.map((p) {
                      return Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: _priorityColor(p),
                          shape: BoxShape.circle,
                        ),
                      );
                    }).toList(),
                  ),
                ],
                // Focus duration indicator
                if (focusSeconds > 0) ...[
                  const SizedBox(height: 1),
                  Text(
                    _formatDuration(context, focusSeconds),
                    style: TextStyle(
                      fontSize: 9,
                      color: colors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

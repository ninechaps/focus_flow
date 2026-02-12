import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../../models/task.dart';
import '../../../models/enums.dart';

/// 日历面板 — 含月导航、周标题、日期网格（带任务条）和 DragTarget
class CalendarPanel extends StatelessWidget {
  final DateTime currentMonth;
  final DateTime selectedDate;
  final Map<DateTime, List<Task>> dateTaskMap;
  /// 父任务→子任务进度映射 {parentId: (completed, total)}
  final Map<String, (int, int)> subtaskProgressMap;
  final Map<DateTime, int> focusDurationMap;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onToday;
  final ValueChanged<DateTime> onSelectDate;
  final void Function(Task task, DateTime date) onTaskDropped;
  final ValueChanged<Task>? onTaskTap;
  final void Function(DateTime date, Offset position)? onDateContextMenu;

  const CalendarPanel({
    super.key,
    required this.currentMonth,
    required this.selectedDate,
    required this.dateTaskMap,
    required this.subtaskProgressMap,
    required this.focusDurationMap,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onToday,
    required this.onSelectDate,
    required this.onTaskDropped,
    this.onTaskTap,
    this.onDateContextMenu,
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
    final colors = context.appColors;
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
                  final isLastCol = col == 6;
                  final isLastRow = row == 5;
                  return Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          right: isLastCol
                              ? BorderSide.none
                              : BorderSide(
                                  color: colors.divider,
                                  width: 0.5,
                                ),
                          bottom: isLastRow
                              ? BorderSide.none
                              : BorderSide(
                                  color: colors.divider,
                                  width: 0.5,
                                ),
                        ),
                      ),
                      child: _buildDateCell(context, date, todayDate),
                    ),
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

    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) => isInMonth,
      onAcceptWithDetails: (details) => onTaskDropped(details.data, date),
      builder: (context, candidateData, rejectedData) {
        final isDragOver = candidateData.isNotEmpty;
        return GestureDetector(
          onTap: () => onSelectDate(date),
          onSecondaryTapUp: onDateContextMenu != null
              ? (details) => onDateContextMenu!(date, details.globalPosition)
              : null,
          child: Container(
            decoration: BoxDecoration(
              color: isToday
                  ? colors.primary.withValues(alpha: 0.08)
                  : isSelected
                      ? colors.primaryLight
                      : Colors.transparent,
              border: isDragOver
                  ? Border.all(color: colors.primary, width: 2)
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 日期行
                _buildDateHeader(colors, date, isToday, isSelected, isInMonth),
                // 任务条列表
                Expanded(
                  child: _buildTaskBars(context, tasks, date, todayDate, isInMonth),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateHeader(
    AppColors colors,
    DateTime date,
    bool isToday,
    bool isSelected,
    bool isInMonth,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 2),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
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
                fontSize: 11,
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
        ],
      ),
    );
  }

  Widget _buildTaskBars(
    BuildContext context,
    List<Task> tasks,
    DateTime cellDate,
    DateTime todayDate,
    bool isInMonth,
  ) {
    if (tasks.isEmpty || !isInMonth) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        const barHeight = 18.0;
        const barSpacing = 1.0;
        const moreIndicatorHeight = 14.0;
        final availableHeight = constraints.maxHeight;

        // 计算能显示的最大任务条数
        final maxVisibleBars =
            ((availableHeight - moreIndicatorHeight) / (barHeight + barSpacing))
                .floor()
                .clamp(0, tasks.length);
        final hasMore = tasks.length > maxVisibleBars;
        final visibleCount = hasMore ? maxVisibleBars : tasks.length;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < visibleCount; i++)
                _TaskBar(
                  task: tasks[i],
                  subtaskProgress: subtaskProgressMap[tasks[i].id],
                  isOverdue: _isOverdueInCell(tasks[i], cellDate, todayDate),
                  priorityColor: _priorityColor(tasks[i].priority),
                  onTap: onTaskTap != null ? () => onTaskTap!(tasks[i]) : null,
                ),
              if (hasMore)
                SizedBox(
                  height: moreIndicatorHeight,
                  child: Center(
                    child: Text(
                      '+${tasks.length - visibleCount}',
                      style: TextStyle(
                        fontSize: 9,
                        color: context.appColors.textHint,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// 判断任务在该日期格中是否为过期显示
  bool _isOverdueInCell(Task task, DateTime cellDate, DateTime todayDate) {
    if (task.dueDate == null) return false;
    final taskDue = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
    // 如果任务原始 dueDate 早于今天，且当前格子是今天，说明是过期继承
    return taskDue.isBefore(todayDate) && _isSameDay(cellDate, todayDate);
  }
}

/// macOS Calendar 风格任务条 — 彩色背景圆角矩形 + 白色文字
/// 有子任务时显示进度条背景
class _TaskBar extends StatefulWidget {
  final Task task;

  /// 子任务进度：(completed, total)，null 表示无子任务
  final (int, int)? subtaskProgress;
  final bool isOverdue;
  final Color priorityColor;
  final VoidCallback? onTap;

  const _TaskBar({
    required this.task,
    this.subtaskProgress,
    required this.isOverdue,
    required this.priorityColor,
    this.onTap,
  });

  @override
  State<_TaskBar> createState() => _TaskBarState();
}

class _TaskBarState extends State<_TaskBar> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) {
          if (widget.task.status != TaskStatus.completed) {
            setState(() => _isHovered = true);
          }
        },
        onExit: (_) => setState(() => _isHovered = false),
        child: Draggable<Task>(
          data: widget.task,
          feedback: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: widget.priorityColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.task.title,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: _buildBar(colors),
          ),
          child: GestureDetector(
            onTap: widget.onTap,
            child: _buildBar(colors),
          ),
        ),
      ),
    );
  }

  Widget _buildBar(AppColors colors) {
    final isCompleted = widget.task.status == TaskStatus.completed;
    final hasProgress = widget.subtaskProgress != null;
    final progress = hasProgress ? widget.subtaskProgress! : null;
    final progressRatio = (hasProgress && progress!.$2 > 0)
        ? progress.$1 / progress.$2
        : 0.0;

    final baseColor = isCompleted
        ? colors.textHint.withValues(alpha: 0.15)
        : widget.isOverdue
            ? const Color(0xFFEF4444).withValues(alpha: 0.85)
            : widget.priorityColor
                .withValues(alpha: _isHovered ? 0.95 : 0.85);

    return Container(
      height: 18,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: hasProgress && !isCompleted
            ? baseColor.withValues(alpha: 0.35)
            : baseColor,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Stack(
        children: [
          // 进度条背景填充
          if (hasProgress && !isCompleted)
            FractionallySizedBox(
              widthFactor: progressRatio,
              child: Container(color: baseColor),
            ),
          // 文字内容
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  if (isCompleted)
                    Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: Icon(
                        Icons.check,
                        size: 10,
                        color: colors.textHint,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      widget.task.title,
                      style: TextStyle(
                        fontSize: 10,
                        color:
                            isCompleted ? colors.textHint : Colors.white,
                        fontWeight: FontWeight.w500,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasProgress && !isCompleted)
                    Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Text(
                        '${progress!.$1}/${progress.$2}',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

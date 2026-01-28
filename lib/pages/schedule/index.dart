import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/task_provider.dart';
import '../../models/task.dart';
import '../../models/enums.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  late DateTime _selectedDate;
  late DateTime _currentMonth;

  static const _priorityHigh = Color(0xFFEF4444);
  static const _priorityMedium = Color(0xFFF59E0B);
  static const _priorityLow = Color(0xFF22C55E);

  static const _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const _shortMonthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const _dayOfWeekNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _currentMonth = DateTime(now.year, now.month);
  }

  /// Filter tasks: top-level only, not deleted, with a dueDate.
  List<Task> _filterTasks(List<Task> tasks) {
    return tasks
        .where((t) =>
            t.parentTaskId == null &&
            t.status != TaskStatus.deleted &&
            t.dueDate != null)
        .toList();
  }

  /// Build a map from date (year-month-day) to list of tasks.
  Map<DateTime, List<Task>> _buildDateTaskMap(List<Task> tasks) {
    final map = <DateTime, List<Task>>{};
    for (final task in tasks) {
      final d = task.dueDate!;
      final key = DateTime(d.year, d.month, d.day);
      (map[key] ??= []).add(task);
    }
    return map;
  }

  /// Get the 42 calendar dates (6 rows × 7 cols) for [month].
  List<DateTime> _calendarDates(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    // weekday: 1=Mon … 7=Sun; offset = how many previous-month days to show.
    final offset = (firstDay.weekday - 1) % 7;
    final start = firstDay.subtract(Duration(days: offset));
    return List.generate(42, (i) => start.add(Duration(days: i)));
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isCurrentMonth(DateTime date) =>
      date.year == _currentMonth.year && date.month == _currentMonth.month;

  void _goToPreviousMonth() {
    setState(() {
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month - 1,
      );
    });
  }

  void _goToNextMonth() {
    setState(() {
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month + 1,
      );
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _currentMonth = DateTime(now.year, now.month);
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

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

  Color _statusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.completed:
        return AppTheme.successColor;
      case TaskStatus.inProgress:
        return AppTheme.accentColor;
      case TaskStatus.pending:
        return AppTheme.textHint;
      case TaskStatus.deleted:
        return AppTheme.textHint;
    }
  }

  String _statusLabel(TaskStatus status) {
    switch (status) {
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.deleted:
        return 'Deleted';
    }
  }

  String _formatSelectedDate(DateTime date) {
    final dayName = _dayOfWeekNames[date.weekday - 1];
    final monthName = _shortMonthNames[date.month - 1];
    return '$dayName, $monthName ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        final validTasks = _filterTasks(provider.tasks);
        final dateTaskMap = _buildDateTaskMap(validTasks);

        return Container(
          color: colors.background,
          child: Row(
            children: [
              // Left: Calendar
              Expanded(
                flex: 3,
                child: _buildCalendarPanel(dateTaskMap),
              ),
              VerticalDivider(width: 1, color: colors.divider),
              // Right: Task list
              Expanded(
                flex: 2,
                child: _buildTaskListPanel(dateTaskMap),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCalendarPanel(Map<DateTime, List<Task>> dateTaskMap) {
    final colors = context.appColors;
    final dates = _calendarDates(_currentMonth);
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
          // Month navigation
          _buildMonthNavigation(),
          Divider(height: 1, color: colors.divider),
          // Weekday header
          _buildWeekdayHeader(),
          Divider(height: 1, color: colors.divider),
          // Calendar grid
          Expanded(
            child: _buildCalendarGrid(dates, dateTaskMap, todayDate),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthNavigation() {
    final colors = context.appColors;
    final title =
        '${_monthNames[_currentMonth.month - 1]} ${_currentMonth.year}';
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLg,
        vertical: AppTheme.spacingMd,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _goToPreviousMonth,
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
            onPressed: _goToNextMonth,
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
            onPressed: _goToToday,
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
              'Today',
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

  Widget _buildWeekdayHeader() {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      child: Row(
        children: _weekDays.map((day) {
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
    List<DateTime> dates,
    Map<DateTime, List<Task>> dateTaskMap,
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
                    child: _buildDateCell(date, dateTaskMap, todayDate),
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
    DateTime date,
    Map<DateTime, List<Task>> dateTaskMap,
    DateTime todayDate,
  ) {
    final colors = context.appColors;
    final isToday = _isSameDay(date, todayDate);
    final isSelected = _isSameDay(date, _selectedDate);
    final isInMonth = _isCurrentMonth(date);
    final tasks = dateTaskMap[date] ?? [];

    // Collect unique priority dots (max 3)
    final priorities = <TaskPriority>{};
    for (final t in tasks) {
      priorities.add(t.priority);
      if (priorities.length >= 3) break;
    }

    // Sort: high → medium → low for consistent dot order
    final sortedPriorities = priorities.toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    return GestureDetector(
      onTap: () => _selectDate(date),
      child: Container(
        margin: const EdgeInsets.all(AppTheme.spacingXs),
        decoration: BoxDecoration(
          color: isSelected && !isToday
              ? colors.primaryLight
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
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
              const SizedBox(height: AppTheme.spacingXs),
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
          ],
        ),
      ),
    );
  }

  Widget _buildTaskListPanel(Map<DateTime, List<Task>> dateTaskMap) {
    final colors = context.appColors;
    final tasksForDate = dateTaskMap[_selectedDate] ?? [];

    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingXl),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date title
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Text(
              _formatSelectedDate(_selectedDate),
              style: TextStyle(
                fontSize: AppTheme.fontSizeLg,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
          Divider(height: 1, color: colors.divider),
          // Task list
          Expanded(
            child: tasksForDate.isEmpty
                ? Center(
                    child: Text(
                      'No tasks for this day',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeMd,
                        color: colors.textHint,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    itemCount: tasksForDate.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppTheme.spacingSm),
                    itemBuilder: (context, index) {
                      return _buildTaskItem(tasksForDate[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(Task task) {
    final colors = context.appColors;
    final isCompleted = task.status == TaskStatus.completed;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          // Priority dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _priorityColor(task.priority),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          // Title
          Expanded(
            child: Text(
              task.title,
              style: TextStyle(
                fontSize: AppTheme.fontSizeMd,
                color: isCompleted
                    ? colors.textHint
                    : colors.textPrimary,
                decoration:
                    isCompleted ? TextDecoration.lineThrough : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          // Status label
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingSm,
              vertical: AppTheme.spacingXs,
            ),
            decoration: BoxDecoration(
              color: _statusColor(task.status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Text(
              _statusLabel(task.status),
              style: TextStyle(
                fontSize: AppTheme.fontSizeXs,
                fontWeight: FontWeight.w500,
                color: _statusColor(task.status),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../providers/task_provider.dart';
import '../../providers/focus_provider.dart';
import '../../models/task.dart';
import '../../models/enums.dart';
import '../../models/focus_session.dart';
import '../list/widgets/add_task_dialog.dart';
import 'widgets/calendar_panel.dart';
import 'widgets/schedule_tabs.dart';
import 'widgets/plan_panel.dart';
import 'widgets/review_panel.dart';
import 'widgets/schedule_task_item.dart';

/// Schedule 页面 — 日历 + 计划/回顾 面板
class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  late DateTime _selectedDate;
  late DateTime _currentMonth;
  int _selectedTab = 0; // 0 = Plan, 1 = Review

  /// 当月专注数据
  Map<DateTime, int> _focusDurationMap = {};
  List<FocusSession> _sessionsForSelectedDate = [];
  List<FocusSession> _sessionsForMonth = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _currentMonth = DateTime(now.year, now.month);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFocusData();
    });
  }

  /// 加载当月专注数据
  Future<void> _loadFocusData() async {
    final focusProvider = context.read<FocusProvider>();
    final start = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final end = DateTime(_currentMonth.year, _currentMonth.month + 1, 0, 23, 59, 59);

    final sessions = await focusProvider.getSessionsByDateRange(start, end);
    final durationMap = <DateTime, int>{};
    for (final s in sessions) {
      final key = DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day);
      durationMap[key] = (durationMap[key] ?? 0) + s.durationSeconds;
    }

    if (!mounted) return;
    setState(() {
      _sessionsForMonth = sessions;
      _focusDurationMap = durationMap;
      _updateSessionsForSelectedDate();
    });
  }

  void _updateSessionsForSelectedDate() {
    _sessionsForSelectedDate = _sessionsForMonth.where((s) {
      final d = DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day);
      return d == _selectedDate;
    }).toList();
  }

  /// 过滤任务：顶层、非删除、有 dueDate
  List<Task> _filterTasks(List<Task> tasks) {
    return tasks
        .where((t) =>
            t.parentTaskId == null &&
            t.status != TaskStatus.deleted &&
            t.dueDate != null)
        .toList();
  }

  /// 构建日期→任务映射
  Map<DateTime, List<Task>> _buildDateTaskMap(List<Task> tasks) {
    final map = <DateTime, List<Task>>{};
    for (final task in tasks) {
      final d = task.dueDate!;
      final key = DateTime(d.year, d.month, d.day);
      (map[key] ??= []).add(task);
    }
    return map;
  }

  /// 获取没有 dueDate 的待办任务（未安排的任务）
  List<Task> _getUnplannedTasks(List<Task> tasks) {
    return tasks
        .where((t) =>
            t.parentTaskId == null &&
            t.status != TaskStatus.deleted &&
            t.status != TaskStatus.completed &&
            t.dueDate == null)
        .toList();
  }

  /// 构建 taskId→Task 映射（用于回顾面板）
  Map<String, Task> _buildTaskIdMap(List<Task> allTasks) {
    final map = <String, Task>{};
    for (final t in allTasks) {
      map[t.id] = t;
    }
    return map;
  }

  // --- 导航 ---

  void _goToPreviousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
    _loadFocusData();
  }

  void _goToNextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
    _loadFocusData();
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _currentMonth = DateTime(now.year, now.month);
      _selectedDate = DateTime(now.year, now.month, now.day);
      _updateSessionsForSelectedDate();
    });
    _loadFocusData();
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _updateSessionsForSelectedDate();
    });
  }

  // --- 拖拽改期 ---

  Future<void> _onTaskDropped(Task task, DateTime newDate) async {
    final taskProvider = context.read<TaskProvider>();
    final updatedTask = Task(
      id: task.id,
      title: task.title,
      description: task.description,
      dueDate: newDate,
      parentTaskId: task.parentTaskId,
      goalId: task.goalId,
      goal: task.goal,
      priority: task.priority,
      status: task.status,
      tags: task.tags,
      focusDuration: task.focusDuration,
      sortOrder: task.sortOrder,
      completedAt: task.completedAt,
      createdAt: task.createdAt,
      updatedAt: DateTime.now(),
    );
    await taskProvider.updateTask(updatedTask);
    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.scheduleTaskRescheduled),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // --- 任务操作 ---

  Future<void> _handleTaskAction(Task task, ScheduleTaskAction action) async {
    final taskProvider = context.read<TaskProvider>();

    switch (action) {
      case ScheduleTaskAction.edit:
        final result = await showEditTaskDialog(
          context,
          task: task,
          availableTags: taskProvider.tags,
          availableGoals: taskProvider.goals,
        );
        if (result != null) {
          await taskProvider.updateTask(result);
        }
      case ScheduleTaskAction.startFocus:
        if (mounted) context.go('/app/focus/${task.id}');
      case ScheduleTaskAction.setPriorityHigh:
        await _updateTaskPriority(task, TaskPriority.high);
      case ScheduleTaskAction.setPriorityMedium:
        await _updateTaskPriority(task, TaskPriority.medium);
      case ScheduleTaskAction.setPriorityLow:
        await _updateTaskPriority(task, TaskPriority.low);
      case ScheduleTaskAction.setStatusPending:
        await _updateTaskStatus(task, TaskStatus.pending);
      case ScheduleTaskAction.setStatusInProgress:
        await _updateTaskStatus(task, TaskStatus.inProgress);
      case ScheduleTaskAction.setStatusCompleted:
        await _updateTaskStatus(task, TaskStatus.completed);
      case ScheduleTaskAction.reschedule:
        await _showReschedulePicker(task);
      case ScheduleTaskAction.delete:
        await taskProvider.deleteTask(task.id);
    }
  }

  Future<void> _updateTaskPriority(Task task, TaskPriority priority) async {
    final taskProvider = context.read<TaskProvider>();
    final updated = Task(
      id: task.id,
      title: task.title,
      description: task.description,
      dueDate: task.dueDate,
      parentTaskId: task.parentTaskId,
      goalId: task.goalId,
      goal: task.goal,
      priority: priority,
      status: task.status,
      tags: task.tags,
      focusDuration: task.focusDuration,
      sortOrder: task.sortOrder,
      completedAt: task.completedAt,
      createdAt: task.createdAt,
      updatedAt: DateTime.now(),
    );
    await taskProvider.updateTask(updated);
  }

  Future<void> _updateTaskStatus(Task task, TaskStatus status) async {
    final taskProvider = context.read<TaskProvider>();
    final updated = Task(
      id: task.id,
      title: task.title,
      description: task.description,
      dueDate: task.dueDate,
      parentTaskId: task.parentTaskId,
      goalId: task.goalId,
      goal: task.goal,
      priority: task.priority,
      status: status,
      tags: task.tags,
      focusDuration: task.focusDuration,
      sortOrder: task.sortOrder,
      completedAt: status == TaskStatus.completed ? DateTime.now() : task.completedAt,
      createdAt: task.createdAt,
      updatedAt: DateTime.now(),
    );
    await taskProvider.updateTask(updated);
  }

  Future<void> _showReschedulePicker(Task task) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: task.dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      await _onTaskDropped(task, picked);
    }
  }

  ValueChanged<TaskStatus> _onStatusChanged(Task task) {
    return (status) => _updateTaskStatus(task, status);
  }

  // --- 快速添加 ---

  Future<void> _onQuickAdd() async {
    final taskProvider = context.read<TaskProvider>();
    final result = await showAddTaskDialog(
      context,
      availableTags: taskProvider.tags,
      availableGoals: taskProvider.goals,
      defaultDueDate: _selectedDate,
    );
    if (result != null) {
      await taskProvider.addTask(result);
    }
  }

  String _formatSelectedDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.MMMEd(locale).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        final validTasks = _filterTasks(provider.tasks);
        final dateTaskMap = _buildDateTaskMap(validTasks);
        final tasksForDate = dateTaskMap[_selectedDate] ?? [];
        final unplannedTasks = _getUnplannedTasks(provider.tasks);
        final taskIdMap = _buildTaskIdMap(provider.tasks);

        return Container(
          color: colors.background,
          child: Row(
            children: [
              // Left: Calendar
              Expanded(
                flex: 3,
                child: CalendarPanel(
                  currentMonth: _currentMonth,
                  selectedDate: _selectedDate,
                  dateTaskMap: dateTaskMap,
                  focusDurationMap: _focusDurationMap,
                  onPreviousMonth: _goToPreviousMonth,
                  onNextMonth: _goToNextMonth,
                  onToday: _goToToday,
                  onSelectDate: _selectDate,
                  onTaskDropped: _onTaskDropped,
                ),
              ),
              VerticalDivider(width: 1, color: colors.divider),
              // Right: Plan/Review panel
              Expanded(
                flex: 2,
                child: _buildRightPanel(colors, tasksForDate, unplannedTasks, taskIdMap),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRightPanel(
    AppColors colors,
    List<Task> tasksForDate,
    List<Task> unplannedTasks,
    Map<String, Task> taskIdMap,
  ) {
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
          // Header: date title + tabs
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Row(
              children: [
                Text(
                  _formatSelectedDate(context, _selectedDate),
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeLg,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const Spacer(),
                ScheduleTabs(
                  selectedIndex: _selectedTab,
                  onChanged: (index) => setState(() => _selectedTab = index),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.divider),
          // Panel content
          Expanded(
            child: _selectedTab == 0
                ? PlanPanel(
                    tasks: tasksForDate,
                    unplannedTasks: unplannedTasks,
                    onStatusChanged: _onStatusChanged,
                    onAction: _handleTaskAction,
                    onQuickAdd: _onQuickAdd,
                  )
                : ReviewPanel(
                    sessions: _sessionsForSelectedDate,
                    taskMap: taskIdMap,
                  ),
          ),
        ],
      ),
    );
  }
}

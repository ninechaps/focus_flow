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
import '../../widgets/context_menu.dart';
import '../list/widgets/add_task_dialog.dart';
import '../../pages/list/widgets/tips_panel.dart';
import 'widgets/calendar_panel.dart';
import 'widgets/date_focus_panel.dart';
import 'widgets/review_panel.dart';
import 'widgets/task_detail_drawer.dart';

/// Schedule 页面 — 全宽日历视图 + 右侧滑出详情面板
class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  late DateTime _selectedDate;
  late DateTime _currentMonth;

  /// 选中的任务，用于右侧任务详情面板
  Task? _selectedTask;

  /// 是否显示日期专注面板（点击日期后展开）
  bool _showDatePanel = false;

  /// 任务详情是否从日期专注面板中打开（用于返回按钮逻辑）
  bool _taskDetailFromDatePanel = false;

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

  /// 过滤任务：顶层、非删除，支持 Goal 过滤
  /// 所有符合条件的任务都参与日历显示，按创建时间归档到对应日期格
  List<Task> _filterTasks(List<Task> tasks, {String? goalId}) {
    return tasks
        .where((t) =>
            t.parentTaskId == null &&
            t.status != TaskStatus.deleted &&
            (goalId == null || t.goalId == goalId))
        .toList();
  }

  /// 构建日期→任务映射：所有任务按 createdAt 归档到对应日历格
  Map<DateTime, List<Task>> _buildDateTaskMap(
    List<Task> filteredTasks, {
    String? goalId,
  }) {
    final map = <DateTime, List<Task>>{};

    for (final task in filteredTasks) {
      final key = DateTime(
        task.createdAt.year,
        task.createdAt.month,
        task.createdAt.day,
      );
      (map[key] ??= []).add(task);
    }

    return map;
  }

  /// 构建 taskId→Task 映射（用于回顾面板）
  Map<String, Task> _buildTaskIdMap(List<Task> allTasks) {
    final map = <String, Task>{};
    for (final t in allTasks) {
      map[t.id] = t;
    }
    return map;
  }

  /// 构建父任务→子任务进度映射 {parentId: (completed, total)}
  Map<String, (int, int)> _buildSubtaskProgressMap(List<Task> allTasks) {
    final map = <String, (int, int)>{};
    for (final t in allTasks) {
      if (t.parentTaskId != null && t.status != TaskStatus.deleted) {
        final prev = map[t.parentTaskId!] ?? (0, 0);
        final isCompleted = t.status == TaskStatus.completed ? 1 : 0;
        map[t.parentTaskId!] = (prev.$1 + isCompleted, prev.$2 + 1);
      }
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
      _selectedTask = null;
      _showDatePanel = true;
      _updateSessionsForSelectedDate();
    });
  }

  // --- 任务条点击 ---

  /// 从日历任务条点击 → 普通模式（可编辑，关闭后不恢复日期面板）
  void _onCalendarTaskTap(Task task) {
    setState(() {
      _selectedTask = task;
      _taskDetailFromDatePanel = false;
      _showDatePanel = false;
    });
  }

  /// 从日期专注面板点击 → 只读模式（关闭后返回日期面板）
  void _onDatePanelTaskTap(Task task) {
    setState(() {
      _selectedTask = task;
      _taskDetailFromDatePanel = true;
      _showDatePanel = false;
    });
  }

  void _closeTaskDetail() {
    setState(() {
      _selectedTask = null;
      // 只有从日期面板进入时，关闭后才恢复日期面板
      _showDatePanel = _taskDetailFromDatePanel;
      _taskDetailFromDatePanel = false;
    });
  }

  void _closeDatePanel() {
    setState(() {
      _showDatePanel = false;
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

  // --- 日期右键菜单（ContextMenu.show + 循环实现切换） ---

  Future<void> _onDateContextMenu(DateTime date, Offset position) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    final groups = [
      ContextMenuGroup<String>(
        items: [
          ContextMenuItem(
            label: l10n.scheduleAddTaskToDate,
            icon: Icons.add_task,
            value: 'add_task',
          ),
          ContextMenuItem(
            label: l10n.scheduleViewReview,
            icon: Icons.assessment_outlined,
            value: 'view_review',
          ),
          ContextMenuItem(
            label: l10n.scheduleGoToDate,
            icon: Icons.today,
            value: 'go_to_date',
          ),
        ],
      ),
    ];

    // 循环：如果用户在屏障上右键，返回 ContextMenuSecondaryTap，
    // 此时关闭当前菜单并在新位置重新显示
    var currentPosition = position;
    while (mounted) {
      final result = await ContextMenu.show<String>(
        context: context,
        groups: groups,
        position: currentPosition,
      );

      if (result is ContextMenuSecondaryTap) {
        // 用户在菜单外右键 → 在新位置重新打开菜单
        currentPosition = result.position;
        continue;
      }

      // 用户选择了菜单项或点击空白关闭
      if (result is String) {
        _handleContextMenuAction(result, date);
      }
      break;
    }
  }

  Future<void> _handleContextMenuAction(String action, DateTime date) async {
    switch (action) {
      case 'add_task':
        await _addTaskToDate(date);
      case 'view_review':
        _showReviewDialog(date);
      case 'go_to_date':
        _navigateToDate(date);
    }
  }

  Future<void> _addTaskToDate(DateTime date) async {
    final taskProvider = context.read<TaskProvider>();
    final result = await showAddTaskDialog(
      context,
      availableTags: taskProvider.tags,
      availableGoals: taskProvider.goals,
      defaultDueDate: date,
    );
    if (result != null) {
      await taskProvider.addTask(result);
    }
  }

  void _showReviewDialog(DateTime date) {
    setState(() {
      _selectedDate = date;
      _updateSessionsForSelectedDate();
    });

    final taskProvider = context.read<TaskProvider>();
    final taskIdMap = _buildTaskIdMap(taskProvider.tasks);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final dateTitle = DateFormat.MMMEd(locale).format(date);

    showDialog(
      context: context,
      builder: (context) {
        final colors = context.appColors;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          child: SizedBox(
            width: 400,
            height: 500,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingLg),
                  child: Row(
                    children: [
                      Text(
                        '$dateTitle — ${l10n.scheduleTabReview}',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeLg,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, size: AppTheme.iconSizeMd),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: colors.divider),
                Expanded(
                  child: ReviewPanel(
                    sessions: _sessionsForSelectedDate,
                    taskMap: taskIdMap,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToDate(DateTime date) {
    setState(() {
      _currentMonth = DateTime(date.year, date.month);
      _selectedDate = DateTime(date.year, date.month, date.day);
      _updateSessionsForSelectedDate();
    });
    _loadFocusData();
  }

  // --- 任务详情面板操作 ---

  Future<void> _onEditSelectedTask() async {
    if (_selectedTask == null) return;
    final taskProvider = context.read<TaskProvider>();
    final result = await showEditTaskDialog(
      context,
      task: _selectedTask!,
      availableTags: taskProvider.tags,
      availableGoals: taskProvider.goals,
    );
    if (result != null) {
      await taskProvider.updateTask(result);
      if (mounted) {
        final updated = taskProvider.tasks.where((t) => t.id == result.id).firstOrNull;
        setState(() {
          _selectedTask = updated;
        });
      }
    }
  }

  void _onFocusSelectedTask(Task task) {
    if (mounted) context.go('/app/focus/${task.id}');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        final goalId = provider.selectedGoalId;
        final validTasks = _filterTasks(provider.tasks, goalId: goalId);
        final dateTaskMap = _buildDateTaskMap(
          validTasks,
          goalId: goalId,
        );
        final subtaskProgressMap = _buildSubtaskProgressMap(provider.tasks);
        final taskIdMap = _buildTaskIdMap(provider.tasks);

        // 任务详情抽屉和日期专注面板互斥，任务抽屉优先
        final isTaskDrawerOpen = _selectedTask != null;
        final isDatePanelOpen = _showDatePanel && !isTaskDrawerOpen;
        final isRightPanelOpen = isTaskDrawerOpen || isDatePanelOpen;

        return Container(
          color: colors.background,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 日历区域：右侧面板打开时收缩
              AnimatedPadding(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: EdgeInsets.only(
                  right: isRightPanelOpen ? TipsPanel.width : 0,
                ),
                child: CalendarPanel(
                  currentMonth: _currentMonth,
                  selectedDate: _selectedDate,
                  dateTaskMap: dateTaskMap,
                  subtaskProgressMap: subtaskProgressMap,
                  focusDurationMap: _focusDurationMap,
                  onPreviousMonth: _goToPreviousMonth,
                  onNextMonth: _goToNextMonth,
                  onToday: _goToToday,
                  onSelectDate: _selectDate,
                  onTaskDropped: _onTaskDropped,
                  onTaskTap: _onCalendarTaskTap,
                  onDateContextMenu: _onDateContextMenu,
                ),
              ),
              // 日期专注面板（点击日期后显示）
              DateFocusPanel(
                isOpen: isDatePanelOpen,
                selectedDate: _selectedDate,
                sessions: _sessionsForSelectedDate,
                taskMap: taskIdMap,
                onClose: _closeDatePanel,
                onTaskTap: _onDatePanelTaskTap,
              ),
              // 任务详情抽屉（点击任务条后显示，优先级高于日期面板）
              TaskDetailDrawer(
                selectedTask: _selectedTask,
                goals: provider.goals,
                tasks: provider.tasks,
                onEdit: _onEditSelectedTask,
                onFocus: _onFocusSelectedTask,
                onClose: _closeTaskDetail,
                readOnly: _taskDetailFromDatePanel,
              ),
            ],
          ),
        );
      },
    );
  }
}

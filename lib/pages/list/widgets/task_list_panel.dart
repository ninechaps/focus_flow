import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart';
import '../../../models/task.dart';
import '../../../providers/task_provider.dart';
import 'task_group.dart';
import 'status_tabs.dart';

/// Center panel displaying the task list grouped by time
class TaskListPanel extends StatelessWidget {
  final List<Task> tasks;
  final Map<String, List<Task>> subtasksMap;
  final String? searchQuery;
  final String? selectedTaskId;
  final String? selectedStatusFilter;
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<String?>? onStatusChanged;
  final ValueChanged<Task>? onTaskStatusChanged;
  final ValueChanged<Task>? onTaskTap;
  final ValueChanged<Task>? onAddSubtask;
  final VoidCallback? onAddTask;
  final ValueChanged<Task>? onFocus;
  final Function(String groupKey, int oldIndex, int newIndex, List<Task> groupTasks)? onReorder;
  final Function(Task parentTask, int oldIndex, int newIndex)? onSubtasksReorder;

  const TaskListPanel({
    super.key,
    required this.tasks,
    this.subtasksMap = const {},
    this.searchQuery,
    this.selectedTaskId,
    this.selectedStatusFilter,
    this.onSearchChanged,
    this.onStatusChanged,
    this.onTaskStatusChanged,
    this.onTaskTap,
    this.onAddSubtask,
    this.onAddTask,
    this.onFocus,
    this.onReorder,
    this.onSubtasksReorder,
  });

  @override
  Widget build(BuildContext context) {
    // Filter out subtasks (tasks with parentTaskId) for top-level display
    final topLevelTasks = tasks.where((t) => t.parentTaskId == null).toList();
    final groupedTasks = TaskGroupHelper.groupTasksByDate(topLevelTasks);

    // Get tasks filtered by time/tag/goal (but not status) for tab count badges
    final provider = context.read<TaskProvider>();
    final tasksForCounting = provider.tasksForStatusCounting;

    return Container(
      color: AppTheme.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with search and add button
          _TaskListHeader(
            searchQuery: searchQuery,
            onSearchChanged: onSearchChanged,
            onAddTask: onAddTask,
          ),

          // Status tabs with count badges
          StatusTabs(
            selectedStatus: selectedStatusFilter,
            onStatusChanged: onStatusChanged,
            tasks: tasksForCounting,
          ),

          // Task groups
          Expanded(
            child: topLevelTasks.isEmpty
                ? _EmptyState(
                    onAddTask: onAddTask,
                    selectedStatusFilter: selectedStatusFilter,
                  )
                : ListView(
                    padding: const EdgeInsets.only(
                      top: AppTheme.spacingXs,
                      bottom: AppTheme.spacingXl,
                    ),
                    children: [
                      for (final entry in groupedTasks.entries)
                        TaskGroup(
                          title: entry.key,
                          tasks: entry.value,
                          subtasksMap: subtasksMap,
                          selectedTaskId: selectedTaskId,
                          initiallyExpanded: entry.key != 'Later',
                          onTaskStatusChanged: onTaskStatusChanged,
                          onTaskTap: onTaskTap,
                          onAddSubtask: onAddSubtask,
                          onFocus: onFocus,
                          onReorder: (oldIndex, newIndex) {
                            if (onReorder != null) {
                              onReorder!(entry.key, oldIndex, newIndex, entry.value);
                            }
                          },
                          onSubtasksReorder: onSubtasksReorder,
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Header with redesigned search bar and "＋ 新建任务" button
class _TaskListHeader extends StatelessWidget {
  final String? searchQuery;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onAddTask;

  const _TaskListHeader({
    this.searchQuery,
    this.onSearchChanged,
    this.onAddTask,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 12),
      child: Row(
        children: [
          // Search bar - white background, thin border, focus ring
          Expanded(
            child: SizedBox(
              height: 34,
              child: TextField(
                onChanged: onSearchChanged,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: '搜索任务...',
                  hintStyle: TextStyle(
                    color: AppTheme.textHint,
                    fontSize: 13,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: Icon(
                      Icons.search,
                      size: 14,
                      color: AppTheme.textHint,
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 0,
                  ),
                  filled: true,
                  fillColor: AppTheme.surfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.dividerColor, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.dividerColor, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppTheme.primaryColor,
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Add task button - "＋ 新建任务" with purple background
          _AddTaskButton(onTap: onAddTask),
        ],
      ),
    );
  }
}

/// Animated "＋ 新建任务" button with hover effect
class _AddTaskButton extends StatefulWidget {
  final VoidCallback? onTap;

  const _AddTaskButton({this.onTap});

  @override
  State<_AddTaskButton> createState() => _AddTaskButtonState();
}

class _AddTaskButtonState extends State<_AddTaskButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: _isHovered
                ? const Color(0xFF4F46E5) // Darker on hover
                : AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          transform: _isHovered
              ? Matrix4.translationValues(0, -1.0, 0)
              : Matrix4.identity(),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '＋',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 6),
              Text(
                '新建任务',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty state when no tasks exist
class _EmptyState extends StatelessWidget {
  final VoidCallback? onAddTask;
  final String? selectedStatusFilter;

  const _EmptyState({
    this.onAddTask,
    this.selectedStatusFilter,
  });

  @override
  Widget build(BuildContext context) {
    String title;
    String subtitle;
    IconData icon;
    bool showCreateButton;

    switch (selectedStatusFilter) {
      case 'pending':
        title = '没有待办任务';
        subtitle = '创建你的第一个任务开始吧';
        icon = Icons.task_alt_outlined;
        showCreateButton = true;
        break;
      case 'in_progress':
        title = '没有进行中的任务';
        subtitle = '开始一个任务后会显示在这里';
        icon = Icons.hourglass_empty;
        showCreateButton = false;
        break;
      case 'completed':
        title = '没有已完成的任务';
        subtitle = '完成一个任务后会显示在这里';
        icon = Icons.check_circle_outline;
        showCreateButton = false;
        break;
      default:
        title = '还没有任务';
        subtitle = '创建你的第一个任务开始吧';
        icon = Icons.task_alt_outlined;
        showCreateButton = true;
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: AppTheme.dividerColor,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            title,
            style: TextStyle(
              fontSize: AppTheme.fontSizeMd,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: AppTheme.fontSizeXs,
              color: AppTheme.textHint,
            ),
          ),
          if (showCreateButton) ...[
            const SizedBox(height: AppTheme.spacingMd),
            ElevatedButton.icon(
              onPressed: onAddTask,
              icon: const Icon(Icons.add, size: 14),
              label: const Text('新建任务'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(fontSize: AppTheme.fontSizeXs),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

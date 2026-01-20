import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/task.dart';
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

          // Status tabs (fixed below search bar)
          StatusTabs(
            selectedStatus: selectedStatusFilter,
            onStatusChanged: onStatusChanged,
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

/// Header with title, search bar, and add button
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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Search bar
          Expanded(
            child: SizedBox(
              height: 30,
              child: TextField(
                onChanged: onSearchChanged,
                style: const TextStyle(fontSize: AppTheme.fontSizeXs),
                decoration: InputDecoration(
                  hintText: 'Search tasks...',
                  hintStyle: TextStyle(
                    color: AppTheme.textHint,
                    fontSize: AppTheme.fontSizeXs,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 8, right: 4),
                    child: Icon(
                      Icons.search,
                      size: 14,
                      color: AppTheme.textHint,
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSm,
                    vertical: 0,
                  ),
                  filled: true,
                  fillColor: AppTheme.backgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide: BorderSide(
                      color: AppTheme.primaryColor.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: AppTheme.spacingSm),

          // Add task button - icon only, minimal style
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: IconButton(
                onPressed: onAddTask,
                icon: const Icon(
                  Icons.add,
                  size: 16,
                  color: Colors.white,
                ),
                padding: EdgeInsets.zero,
                tooltip: 'Add Task',
              ),
            ),
          ),
        ],
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
    // Determine message and icon based on selected status filter
    String title;
    String subtitle;
    IconData icon;
    bool showCreateButton;

    switch (selectedStatusFilter) {
      case 'pending':
        title = 'No TODO tasks';
        subtitle = 'Create your first task to get started';
        icon = Icons.task_alt_outlined;
        showCreateButton = true;
        break;
      case 'in_progress':
        title = 'No tasks in progress';
        subtitle = 'Start working on a task to see it here';
        icon = Icons.hourglass_empty;
        showCreateButton = false;
        break;
      case 'completed':
        title = 'No completed tasks';
        subtitle = 'Complete a task to see it here';
        icon = Icons.check_circle_outline;
        showCreateButton = false;
        break;
      default:
        // No filter selected - show all tasks empty state
        title = 'No tasks yet';
        subtitle = 'Create your first task to get started';
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
              label: const Text('Add Task'),
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

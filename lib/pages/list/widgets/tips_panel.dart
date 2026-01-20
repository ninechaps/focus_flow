import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/goal.dart';
import '../../../models/task.dart';
import '../../../models/enums.dart';

/// Right sidebar panel showing details of selected goal or task
class TipsPanel extends StatelessWidget {
  static const double width = 260.0;

  final List<Goal> goals;
  final List<Task> tasks;
  final String? selectedGoalId;
  final String? selectedTaskId;

  const TipsPanel({
    super.key,
    this.goals = const [],
    this.tasks = const [],
    this.selectedGoalId,
    this.selectedTaskId,
  });

  /// Get selected goal object
  Goal? get _selectedGoal {
    if (selectedGoalId == null) return null;
    try {
      return goals.firstWhere((g) => g.id == selectedGoalId);
    } catch (_) {
      return null;
    }
  }

  /// Get selected task object (including subtasks)
  Task? get _selectedTask {
    if (selectedTaskId == null) return null;
    // Check all tasks (both top-level and subtasks)
    for (final task in tasks) {
      if (task.id == selectedTaskId) return task;
    }
    return null;
  }

  /// Get tasks belonging to a goal
  List<Task> _getGoalTasks(String goalId) {
    return tasks.where((t) => t.goalId == goalId && t.parentTaskId == null).toList();
  }

  /// Get subtasks for a task
  List<Task> _getSubtasks(String taskId) {
    return tasks.where((t) => t.parentTaskId == taskId).toList();
  }

  /// Format duration for display
  String _formatDuration(int seconds) {
    if (seconds == 0) {
      return '0m';
    } else if (seconds < 60) {
      return '${seconds}s';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      return '${minutes}m';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      if (minutes == 0) {
        return '${hours}h';
      }
      return '${hours}h ${minutes}m';
    }
  }

  /// Format elapsed duration (days, hours, minutes) for completed tasks
  String _formatElapsedDuration(int seconds) {
    if (seconds == 0) {
      return '0m';
    } else if (seconds < 60) {
      // Less than 1 minute
      return '${seconds}s';
    } else if (seconds < 3600) {
      // Less than 1 hour - show only minutes
      final minutes = seconds ~/ 60;
      return '${minutes}m';
    } else if (seconds < 86400) {
      // Less than 1 day - show hours and minutes
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      if (minutes == 0) {
        return '${hours}h';
      }
      return '${hours}h ${minutes}m';
    } else {
      // 1 day or more - show days, hours, and minutes
      final days = seconds ~/ 86400;
      final hours = (seconds % 86400) ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;

      final parts = <String>[];
      parts.add('${days}d');
      if (hours > 0) {
        parts.add('${hours}h');
      }
      if (minutes > 0) {
        parts.add('${minutes}m');
      }
      return parts.join(' ');
    }
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          border: Border(
            left: BorderSide(
              color: AppTheme.dividerColor,
              width: 1,
            ),
          ),
        ),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    // Priority: Show task details if task is selected, otherwise show goal details
    if (selectedTaskId != null && _selectedTask != null) {
      return _buildTaskDetails(_selectedTask!);
    } else if (selectedGoalId != null && _selectedGoal != null) {
      return _buildGoalDetails(_selectedGoal!);
    }

    // Fallback (shouldn't happen since panel is hidden when no selection)
    return const SizedBox.shrink();
  }

  Widget _buildGoalDetails(Goal goal) {
    final goalTasks = _getGoalTasks(goal.id);
    final completedTasks = goalTasks.where((t) => t.status == TaskStatus.completed).length;
    final totalTasks = goalTasks.length;

    // Calculate total focus time including subtasks
    int totalFocusTime = 0;
    for (final task in goalTasks) {
      totalFocusTime += task.focusDuration;
      // Add subtasks' focus time
      final subtasks = _getSubtasks(task.id);
      for (final subtask in subtasks) {
        totalFocusTime += subtask.focusDuration;
      }
    }

    // Count by priority
    final highPriority = goalTasks.where((t) => t.priority == TaskPriority.high && t.status != TaskStatus.completed).length;
    final mediumPriority = goalTasks.where((t) => t.priority == TaskPriority.medium && t.status != TaskStatus.completed).length;
    final lowPriority = goalTasks.where((t) => t.priority == TaskPriority.low && t.status != TaskStatus.completed).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.flag,
                  size: 20,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Goal',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeXs,
                        color: AppTheme.textHint,
                      ),
                    ),
                    Text(
                      goal.name,
                      style: const TextStyle(
                        fontSize: AppTheme.fontSizeMd,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingMd),
          Divider(height: 1, color: AppTheme.dividerColor),
          const SizedBox(height: AppTheme.spacingMd),

          // Due date
          _DetailRow(
            icon: Icons.calendar_today_outlined,
            label: 'Due Date',
            value: _formatDate(goal.dueDate),
          ),

          const SizedBox(height: AppTheme.spacingSm),

          // Focus time
          _DetailRow(
            icon: Icons.timer_outlined,
            label: 'Total Focus Time',
            value: _formatDuration(totalFocusTime),
            valueColor: AppTheme.primaryColor,
          ),

          const SizedBox(height: AppTheme.spacingMd),
          Divider(height: 1, color: AppTheme.dividerColor),
          const SizedBox(height: AppTheme.spacingMd),

          // Progress section
          Text(
            'Progress',
            style: TextStyle(
              fontSize: AppTheme.fontSizeSm,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),

          // Progress bar
          _ProgressBar(
            completed: completedTasks,
            total: totalTasks,
          ),

          const SizedBox(height: AppTheme.spacingMd),

          // Priority breakdown
          Text(
            'Remaining by Priority',
            style: TextStyle(
              fontSize: AppTheme.fontSizeSm,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),

          Row(
            children: [
              _PriorityBadge(
                label: 'High',
                count: highPriority,
                color: const Color(0xFFEF4444),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              _PriorityBadge(
                label: 'Medium',
                count: mediumPriority,
                color: const Color(0xFFF59E0B),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              _PriorityBadge(
                label: 'Low',
                count: lowPriority,
                color: const Color(0xFF22C55E),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingMd),
          Divider(height: 1, color: AppTheme.dividerColor),
          const SizedBox(height: AppTheme.spacingMd),

          // Tasks list
          Text(
            'Tasks (${goalTasks.length})',
            style: TextStyle(
              fontSize: AppTheme.fontSizeSm,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),

          if (goalTasks.isEmpty)
            Text(
              'No tasks yet',
              style: TextStyle(
                fontSize: AppTheme.fontSizeXs,
                color: AppTheme.textHint,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...goalTasks.take(5).map((task) => _TaskListItem(
              task: task,
              formatDuration: _formatDuration,
            )),

          if (goalTasks.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: AppTheme.spacingSm),
              child: Text(
                '+${goalTasks.length - 5} more tasks',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeXs,
                  color: AppTheme.textHint,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskDetails(Task task) {
    final subtasks = _getSubtasks(task.id);
    final completedSubtasks = subtasks.where((t) => t.status == TaskStatus.completed).length;
    final totalSubtasks = subtasks.length;

    // Calculate total focus time including subtasks
    int totalFocusTime = task.focusDuration;
    for (final subtask in subtasks) {
      totalFocusTime += subtask.focusDuration;
    }

    // Get parent task if this is a subtask
    Task? parentTask;
    if (task.parentTaskId != null) {
      try {
        parentTask = tasks.firstWhere((t) => t.id == task.parentTaskId);
      } catch (_) {}
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with priority indicator
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getPriorityColor(task.priority).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.task_alt,
                  size: 20,
                  color: _getPriorityColor(task.priority),
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Task',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeXs,
                            color: AppTheme.textHint,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(task.priority).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getPriorityLabel(task.priority),
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeXs - 1,
                              fontWeight: FontWeight.w600,
                              color: _getPriorityColor(task.priority),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeMd,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                        decoration: task.status == TaskStatus.completed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Status badge
          if (task.status == TaskStatus.completed)
            Padding(
              padding: const EdgeInsets.only(top: AppTheme.spacingSm),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 14,
                      color: AppTheme.successColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Completed',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeXs,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: AppTheme.spacingMd),
          Divider(height: 1, color: AppTheme.dividerColor),
          const SizedBox(height: AppTheme.spacingMd),

          // Hierarchy info
          if (task.goal != null || parentTask != null) ...[
            if (task.goal != null)
              _DetailRow(
                icon: Icons.flag_outlined,
                label: 'Goal',
                value: task.goal!.name,
              ),
            if (parentTask != null)
              Padding(
                padding: const EdgeInsets.only(top: AppTheme.spacingSm),
                child: _DetailRow(
                  icon: Icons.subdirectory_arrow_right,
                  label: 'Parent Task',
                  value: parentTask.title,
                ),
              ),
            const SizedBox(height: AppTheme.spacingSm),
          ],

          // Due date
          if (task.dueDate != null)
            _DetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Due Date',
              value: _formatDate(task.dueDate!),
            ),

          if (task.dueDate != null)
            const SizedBox(height: AppTheme.spacingSm),

          // Focus time
          _DetailRow(
            icon: Icons.timer_outlined,
            label: 'Focus Time',
            value: _formatDuration(totalFocusTime),
            valueColor: AppTheme.primaryColor,
          ),

          // Priority status section
          ..._buildPriorityStatus(task, parentTask, subtasks),

          // Description
          if (task.description != null && task.description!.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingMd),
            Divider(height: 1, color: AppTheme.dividerColor),
            const SizedBox(height: AppTheme.spacingMd),

            Text(
              'Description',
              style: TextStyle(
                fontSize: AppTheme.fontSizeSm,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              task.description!,
              style: TextStyle(
                fontSize: AppTheme.fontSizeXs,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ],

          // Tags
          if (task.tags.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingMd),
            Divider(height: 1, color: AppTheme.dividerColor),
            const SizedBox(height: AppTheme.spacingMd),

            Text(
              'Tags',
              style: TextStyle(
                fontSize: AppTheme.fontSizeSm,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: task.tags.map((tag) {
                final tagColor = _parseTagColor(tag.color);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: tagColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tag.name,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeXs,
                      fontWeight: FontWeight.w500,
                      color: tagColor,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          // Subtasks progress
          if (subtasks.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingMd),
            Divider(height: 1, color: AppTheme.dividerColor),
            const SizedBox(height: AppTheme.spacingMd),

            Text(
              'Subtasks ($totalSubtasks)',
              style: TextStyle(
                fontSize: AppTheme.fontSizeSm,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),

            _ProgressBar(
              completed: completedSubtasks,
              total: totalSubtasks,
            ),

            const SizedBox(height: AppTheme.spacingSm),

            ...subtasks.map((subtask) => _TaskListItem(
              task: subtask,
              formatDuration: _formatDuration,
            )),
          ],

          // Time information section
          const SizedBox(height: AppTheme.spacingMd),
          Divider(height: 1, color: AppTheme.dividerColor),
          const SizedBox(height: AppTheme.spacingMd),

          // For completed tasks, show created, completed, and total duration
          if (task.status == TaskStatus.completed && task.completedAt != null) ...[
            Text(
              'Time Tracking',
              style: TextStyle(
                fontSize: AppTheme.fontSizeSm,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),

            _DetailRow(
              icon: Icons.play_arrow,
              label: 'Created',
              value: _formatDate(task.createdAt),
            ),
            const SizedBox(height: AppTheme.spacingSm),

            _DetailRow(
              icon: Icons.check_circle,
              label: 'Completed',
              value: _formatDate(task.completedAt!),
              valueColor: AppTheme.successColor,
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // Duration section with nested items
            Row(
              children: [
                Icon(
                  Icons.timer,
                  size: 14,
                  color: AppTheme.textHint,
                ),
                const SizedBox(width: 8),
                Text(
                  'Duration',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeSm,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSm),

            // Nested duration details with indentation
            Padding(
              padding: const EdgeInsets.only(left: 22),
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.schedule,
                    label: 'Elapsed Time',
                    value: _formatElapsedDuration(
                      task.completedAt!.difference(task.createdAt).inSeconds,
                    ),
                    valueColor: AppTheme.accentColor,
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  _DetailRow(
                    icon: Icons.psychology,
                    label: 'Focus Time',
                    value: _formatDuration(totalFocusTime),
                    valueColor: AppTheme.primaryColor,
                  ),
                ],
              ),
            ),
          ] else ...[
            // For pending tasks, just show created date
            _DetailRow(
              icon: Icons.access_time,
              label: 'Created',
              value: _formatDate(task.createdAt),
            ),
          ],
        ],
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return const Color(0xFFEF4444);
      case TaskPriority.medium:
        return const Color(0xFFF59E0B);
      case TaskPriority.low:
        return const Color(0xFF22C55E);
    }
  }

  String _getPriorityLabel(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }

  Color _parseTagColor(String hexColor) {
    final hex = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  /// Build priority status display based on task type
  List<Widget> _buildPriorityStatus(Task task, Task? parentTask, List<Task> subtasks) {
    final widgets = <Widget>[];

    // For subtasks: show parent's subtasks priority distribution
    if (parentTask != null) {
      final parentSubtasks = _getSubtasks(parentTask.id);
      if (parentSubtasks.isNotEmpty) {
        final highPriority = parentSubtasks.where((t) =>
          t.priority == TaskPriority.high && t.status != TaskStatus.completed
        ).length;
        final mediumPriority = parentSubtasks.where((t) =>
          t.priority == TaskPriority.medium && t.status != TaskStatus.completed
        ).length;
        final lowPriority = parentSubtasks.where((t) =>
          t.priority == TaskPriority.low && t.status != TaskStatus.completed
        ).length;

        widgets.addAll([
          const SizedBox(height: AppTheme.spacingMd),
          Divider(height: 1, color: AppTheme.dividerColor),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            'Parent Task Subtasks',
            style: TextStyle(
              fontSize: AppTheme.fontSizeSm,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Row(
            children: [
              _PriorityBadge(
                label: 'High',
                count: highPriority,
                color: const Color(0xFFEF4444),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              _PriorityBadge(
                label: 'Medium',
                count: mediumPriority,
                color: const Color(0xFFF59E0B),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              _PriorityBadge(
                label: 'Low',
                count: lowPriority,
                color: const Color(0xFF22C55E),
              ),
            ],
          ),
        ]);
      }
    }
    // For parent tasks: show own subtasks priority distribution
    else if (subtasks.isNotEmpty) {
      final highPriority = subtasks.where((t) =>
        t.priority == TaskPriority.high && t.status != TaskStatus.completed
      ).length;
      final mediumPriority = subtasks.where((t) =>
        t.priority == TaskPriority.medium && t.status != TaskStatus.completed
      ).length;
      final lowPriority = subtasks.where((t) =>
        t.priority == TaskPriority.low && t.status != TaskStatus.completed
      ).length;

      widgets.addAll([
        const SizedBox(height: AppTheme.spacingMd),
        Divider(height: 1, color: AppTheme.dividerColor),
        const SizedBox(height: AppTheme.spacingMd),
        Text(
          'Subtasks by Priority',
          style: TextStyle(
            fontSize: AppTheme.fontSizeSm,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Row(
          children: [
            _PriorityBadge(
              label: 'High',
              count: highPriority,
              color: const Color(0xFFEF4444),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            _PriorityBadge(
              label: 'Medium',
              count: mediumPriority,
              color: const Color(0xFFF59E0B),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            _PriorityBadge(
              label: 'Low',
              count: lowPriority,
              color: const Color(0xFF22C55E),
            ),
          ],
        ),
      ]);
    }

    // If task has a goal: show goal's tasks priority distribution
    if (task.goal != null) {
      final goalTasks = _getGoalTasks(task.goal!.id);
      if (goalTasks.isNotEmpty) {
        final highPriority = goalTasks.where((t) =>
          t.priority == TaskPriority.high && t.status != TaskStatus.completed
        ).length;
        final mediumPriority = goalTasks.where((t) =>
          t.priority == TaskPriority.medium && t.status != TaskStatus.completed
        ).length;
        final lowPriority = goalTasks.where((t) =>
          t.priority == TaskPriority.low && t.status != TaskStatus.completed
        ).length;

        widgets.addAll([
          const SizedBox(height: AppTheme.spacingMd),
          Divider(height: 1, color: AppTheme.dividerColor),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            'Goal Tasks by Priority',
            style: TextStyle(
              fontSize: AppTheme.fontSizeSm,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Row(
            children: [
              _PriorityBadge(
                label: 'High',
                count: highPriority,
                color: const Color(0xFFEF4444),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              _PriorityBadge(
                label: 'Medium',
                count: mediumPriority,
                color: const Color(0xFFF59E0B),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              _PriorityBadge(
                label: 'Low',
                count: lowPriority,
                color: const Color(0xFF22C55E),
              ),
            ],
          ),
        ]);
      }
    }

    return widgets;
  }
}

/// Detail row with icon, label and value
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: AppTheme.textHint,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: AppTheme.fontSizeXs,
            color: AppTheme.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: AppTheme.fontSizeXs,
            fontWeight: FontWeight.w500,
            color: valueColor ?? AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Progress bar with completed/total display
class _ProgressBar extends StatelessWidget {
  final int completed;
  final int total;

  const _ProgressBar({
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? completed / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Completed',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeXs,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                '$completed/$total',
                style: const TextStyle(
                  fontSize: AppTheme.fontSizeXs,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.dividerColor,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? AppTheme.successColor : AppTheme.primaryColor,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Priority badge widget
class _PriorityBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _PriorityBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: AppTheme.fontSizeSm,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: AppTheme.fontSizeXs - 1,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Task list item for showing in goal/task details
class _TaskListItem extends StatelessWidget {
  final Task task;
  final String Function(int) formatDuration;

  const _TaskListItem({
    required this.task,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = task.status == TaskStatus.completed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: isCompleted ? AppTheme.successColor : Colors.transparent,
              border: Border.all(
                color: isCompleted ? AppTheme.successColor : AppTheme.dividerColor,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(3),
            ),
            child: isCompleted
                ? const Icon(Icons.check, size: 10, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              task.title,
              style: TextStyle(
                fontSize: AppTheme.fontSizeXs,
                color: isCompleted ? AppTheme.textHint : AppTheme.textPrimary,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (task.focusDuration > 0)
            Text(
              formatDuration(task.focusDuration),
              style: TextStyle(
                fontSize: AppTheme.fontSizeXs - 1,
                color: AppTheme.primaryColor.withValues(alpha: 0.7),
              ),
            ),
        ],
      ),
    );
  }
}

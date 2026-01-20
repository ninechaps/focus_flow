import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/task.dart';
import 'task_item.dart';

/// Groups tasks by time period (Today, Tomorrow, This Week, etc.)
class TaskGroup extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<Task> tasks;
  final Map<String, List<Task>> subtasksMap;
  final String? selectedTaskId;
  final bool initiallyExpanded;
  final ValueChanged<Task>? onTaskStatusChanged;
  final ValueChanged<Task>? onTaskTap;
  final ValueChanged<Task>? onAddSubtask;
  final ValueChanged<Task>? onFocus;
  final Function(int oldIndex, int newIndex)? onReorder;
  final Function(Task parentTask, int oldIndex, int newIndex)? onSubtasksReorder;

  const TaskGroup({
    super.key,
    required this.title,
    this.subtitle,
    required this.tasks,
    this.subtasksMap = const {},
    this.selectedTaskId,
    this.initiallyExpanded = true,
    this.onTaskStatusChanged,
    this.onTaskTap,
    this.onAddSubtask,
    this.onFocus,
    this.onReorder,
    this.onSubtasksReorder,
  });

  @override
  State<TaskGroup> createState() => _TaskGroupState();
}

class _TaskGroupState extends State<TaskGroup> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = widget.tasks.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group header
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
                vertical: AppTheme.spacingSm,
              ),
              child: Row(
                children: [
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_right_rounded,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeXs,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  // Simple count
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.dividerColor.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$totalCount',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeXs,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textHint,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Task list with drag-and-drop reordering
        if (_isExpanded)
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: widget.tasks.length,
            onReorder: (oldIndex, newIndex) {
              if (widget.onReorder != null) {
                widget.onReorder!(oldIndex, newIndex);
              }
            },
            itemBuilder: (context, index) {
              final task = widget.tasks[index];
              final subtasks = widget.subtasksMap[task.id] ?? [];
              final isTaskSelected = widget.selectedTaskId == task.id;
              final selectedSubtaskId = subtasks.any((s) => s.id == widget.selectedTaskId)
                  ? widget.selectedTaskId
                  : null;

              return ReorderableDragStartListener(
                key: ValueKey(task.id),
                index: index,
                child: TaskItem(
                  task: task,
                  subtasks: subtasks,
                  isSelected: isTaskSelected,
                  selectedSubtaskId: selectedSubtaskId,
                  onTaskStatusChanged: widget.onTaskStatusChanged,
                  onTaskTap: widget.onTaskTap,
                  onAddSubtask: () => widget.onAddSubtask?.call(task),
                  onTaskFocus: widget.onFocus,
                  onSubtasksReorder: (oldIndex, newIndex) {
                    if (widget.onSubtasksReorder != null) {
                      widget.onSubtasksReorder!(task, oldIndex, newIndex);
                    }
                  },
                ),
              );
            },
          ),
      ],
    );
  }
}

/// Helper class to group tasks by date
class TaskGroupHelper {
  /// Groups tasks by date categories based on dueDate
  /// For tasks without dueDate, groups by createdAt with relative labels
  static Map<String, List<Task>> groupTasksByDate(List<Task> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));
    final weekEnd = today.add(Duration(days: 7 - today.weekday));

    // Use LinkedHashMap to maintain insertion order
    final Map<String, List<Task>> groups = {};

    // Initialize standard groups in order
    groups['Overdue'] = [];
    groups['Today'] = [];
    groups['Tomorrow'] = [];
    groups['This Week'] = [];
    groups['Later'] = [];

    // For tasks without due date, we'll group by creation date
    final Map<String, List<Task>> createdDateGroups = {};

    for (final task in tasks) {
      if (task.dueDate == null) {
        // Group by creation date with relative labels
        final createdDate = DateTime(
          task.createdAt.year,
          task.createdAt.month,
          task.createdAt.day,
        );

        String groupKey;
        if (createdDate == today) {
          groupKey = 'Today';
        } else if (createdDate == yesterday) {
          groupKey = 'Yesterday';
        } else {
          // Show exact date for older tasks
          groupKey = _formatFullDate(createdDate);
        }

        createdDateGroups.putIfAbsent(groupKey, () => []);
        createdDateGroups[groupKey]!.add(task);
        continue;
      }

      final taskDate = DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
      );

      if (taskDate.isBefore(today)) {
        groups['Overdue']!.add(task);
      } else if (taskDate == today) {
        groups['Today']!.add(task);
      } else if (taskDate == tomorrow) {
        groups['Tomorrow']!.add(task);
      } else if (taskDate.isBefore(weekEnd) || taskDate == weekEnd) {
        groups['This Week']!.add(task);
      } else {
        groups['Later']!.add(task);
      }
    }

    // Remove empty standard groups
    groups.removeWhere((key, value) => value.isEmpty);

    // Sort created date groups by date (most recent first)
    final sortedCreatedKeys = createdDateGroups.keys.toList()
      ..sort((a, b) {
        // "Today" should come first, then "Yesterday", then by date
        if (a == 'Today') return -1;
        if (b == 'Today') return 1;
        if (a == 'Yesterday') return -1;
        if (b == 'Yesterday') return 1;
        // For date strings, reverse order (newer first)
        return b.compareTo(a);
      });

    // Merge created date groups with standard groups
    // If a key already exists (e.g., "Today"), merge the tasks
    for (final key in sortedCreatedKeys) {
      if (groups.containsKey(key)) {
        groups[key]!.addAll(createdDateGroups[key]!);
      } else {
        groups[key] = createdDateGroups[key]!;
      }
    }

    return groups;
  }

  /// Gets subtitle for date group (e.g., "Monday, Dec 23")
  static String? getGroupSubtitle(String groupName) {
    final now = DateTime.now();
    switch (groupName) {
      case 'Today':
        return _formatDate(now);
      case 'Tomorrow':
        return _formatDate(now.add(const Duration(days: 1)));
      default:
        return null;
    }
  }

  static String _formatDate(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  static String _formatFullDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

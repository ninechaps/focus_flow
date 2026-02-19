import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../../models/task.dart';
import '../../../models/enums.dart';
import 'task_item.dart';

/// Groups tasks by time period (Today, Tomorrow, This Week, etc.)
/// Redesigned header: date text + count badge + separator line
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
  // Right-click menu callbacks
  final ValueChanged<Task>? onEditTask;
  final ValueChanged<Task>? onDeleteTask;
  final void Function(Task task, TaskPriority priority)? onSetPriority;
  final void Function(Task task, TaskStatus status)? onSetStatus;

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
    this.onEditTask,
    this.onDeleteTask,
    this.onSetPriority,
    this.onSetStatus,
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

  String _getGroupLabel() {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final dateFormat = DateFormat.MMMd(locale);
    switch (widget.title) {
      case 'Today':
        return '${l10n.groupToday} · ${dateFormat.format(now)}';
      case 'Yesterday':
        final yesterday = now.subtract(const Duration(days: 1));
        return '${l10n.groupYesterday} · ${dateFormat.format(yesterday)}';
      default:
        return widget.title;
    }
  }

  String _getCountLabel(int count) {
    final l10n = AppLocalizations.of(context)!;
    return l10n.taskCount(count);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final totalCount = widget.tasks.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group header: date text + count badge + line
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 4,
              ),
              child: Row(
                children: [
                  // Date label
                  Text(
                    _getGroupLabel(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Count badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: colors.badgeBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getCountLabel(totalCount),
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textHint,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Separator line
                  Expanded(
                    child: Container(
                      height: 1,
                      color: colors.divider,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 2),

        // Task list with drag-and-drop reordering
        if (_isExpanded)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ReorderableListView.builder(
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
                    onEditTask: widget.onEditTask,
                    onDeleteTask: widget.onDeleteTask,
                    onSetPriority: widget.onSetPriority,
                    onSetStatus: widget.onSetStatus,
                    onSubtasksReorder: (oldIndex, newIndex) {
                      if (widget.onSubtasksReorder != null) {
                        widget.onSubtasksReorder!(task, oldIndex, newIndex);
                      }
                    },
                  ),
                );
              },
            ),
          ),

        const SizedBox(height: 12),
      ],
    );
  }
}

/// Helper class to group tasks by date
class TaskGroupHelper {
  /// Groups tasks by creation date (createdAt), regardless of due date.
  /// Due date is shown as a task attribute only, not used for grouping.
  static Map<String, List<Task>> groupTasksByDate(List<Task> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, List<Task>> dateGroups = {};

    for (final task in tasks) {
      final createdDate = DateTime(
        task.createdAt.year,
        task.createdAt.month,
        task.createdAt.day,
      );

      final String groupKey;
      if (createdDate == today) {
        groupKey = 'Today';
      } else if (createdDate == yesterday) {
        groupKey = 'Yesterday';
      } else {
        groupKey = _formatFullDate(createdDate);
      }

      dateGroups.putIfAbsent(groupKey, () => []);
      dateGroups[groupKey]!.add(task);
    }

    // Sort: Today first, Yesterday second, then remaining dates descending
    final sortedKeys = dateGroups.keys.toList()
      ..sort((a, b) {
        if (a == 'Today') return -1;
        if (b == 'Today') return 1;
        if (a == 'Yesterday') return -1;
        if (b == 'Yesterday') return 1;
        return b.compareTo(a);
      });

    return {
      for (final key in sortedKeys) key: dateGroups[key]!,
    };
  }

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

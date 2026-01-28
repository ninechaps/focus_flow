import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/task.dart';
import '../../../models/enums.dart';
import '../../../widgets/context_menu.dart';

/// Redesigned task item: card-style with border, hover effects, priority bar,
/// meta row (goal, due date, tags, subtask progress), and action buttons.
class TaskItem extends StatefulWidget {
  final Task task;
  final List<Task> subtasks;
  final int indentLevel;
  final bool isSelected;
  final String? selectedSubtaskId;
  final ValueChanged<Task>? onTaskStatusChanged;
  final ValueChanged<Task>? onTaskTap;
  final VoidCallback? onAddSubtask;
  final ValueChanged<Task>? onTaskFocus;
  final Function(int oldIndex, int newIndex)? onSubtasksReorder;
  // Right-click menu callbacks
  final ValueChanged<Task>? onEditTask;
  final ValueChanged<Task>? onDeleteTask;
  final void Function(Task task, TaskPriority priority)? onSetPriority;
  final void Function(Task task, TaskStatus status)? onSetStatus;

  const TaskItem({
    super.key,
    required this.task,
    this.subtasks = const [],
    this.indentLevel = 0,
    this.isSelected = false,
    this.selectedSubtaskId,
    this.onTaskStatusChanged,
    this.onTaskTap,
    this.onAddSubtask,
    this.onTaskFocus,
    this.onSubtasksReorder,
    this.onEditTask,
    this.onDeleteTask,
    this.onSetPriority,
    this.onSetStatus,
  });

  @override
  State<TaskItem> createState() => _TaskItemState();
}

class _TaskItemState extends State<TaskItem> {
  bool _isHovered = false;
  bool _isExpanded = true;

  Color _parseTagColor(String hexColor) {
    final hex = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);

    if (taskDate == today) {
      return '今天到期';
    } else if (taskDate == today.add(const Duration(days: 1))) {
      return '明天';
    } else if (taskDate.isBefore(today)) {
      return '已逾期';
    }

    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  bool _isOverdue() {
    if (widget.task.dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(
      widget.task.dueDate!.year,
      widget.task.dueDate!.month,
      widget.task.dueDate!.day,
    );
    return taskDate.isBefore(today) || taskDate == today;
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) {
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

  int _getTotalFocusDuration() {
    if (widget.subtasks.isEmpty) {
      return widget.task.focusDuration;
    }
    int total = 0;
    for (final subtask in widget.subtasks) {
      total += subtask.focusDuration;
    }
    return total;
  }

  Color _getPriorityColor() {
    switch (widget.task.priority) {
      case TaskPriority.high:
        return AppTheme.errorColor;
      case TaskPriority.medium:
        return const Color(0xFFF59E0B);
      case TaskPriority.low:
        return AppTheme.successColor;
    }
  }

  /// Show right-click context menu
  Future<void> _showContextMenu(BuildContext context, Offset position) async {
    final result = await ContextMenu.show<String>(
      context: context,
      position: position,
      groups: [
        ContextMenuGroup(
          items: [
            const ContextMenuItem(
              label: '编辑任务',
              icon: Icons.edit_outlined,
              value: 'edit',
            ),
          ],
        ),
        ContextMenuGroup(
          items: [
            ContextMenuItem(
              label: '高优先级',
              icon: Icons.circle,
              value: 'priority_high',
              enabled: widget.task.priority != TaskPriority.high,
            ),
            ContextMenuItem(
              label: '中优先级',
              icon: Icons.circle,
              value: 'priority_medium',
              enabled: widget.task.priority != TaskPriority.medium,
            ),
            ContextMenuItem(
              label: '低优先级',
              icon: Icons.circle,
              value: 'priority_low',
              enabled: widget.task.priority != TaskPriority.low,
            ),
          ],
        ),
        ContextMenuGroup(
          items: [
            ContextMenuItem(
              label: '待办',
              icon: Icons.radio_button_unchecked,
              value: 'status_pending',
              enabled: widget.task.status != TaskStatus.pending,
            ),
            ContextMenuItem(
              label: '进行中',
              icon: Icons.timelapse,
              value: 'status_in_progress',
              enabled: widget.task.status != TaskStatus.inProgress,
            ),
            ContextMenuItem(
              label: '已完成',
              icon: Icons.check_circle_outline,
              value: 'status_completed',
              enabled: widget.task.status != TaskStatus.completed,
            ),
          ],
        ),
        ContextMenuGroup(
          items: [
            const ContextMenuItem(
              label: '删除任务',
              icon: Icons.delete_outline,
              value: 'delete',
              isDangerous: true,
            ),
          ],
        ),
      ],
    );

    if (result == null) return;

    switch (result) {
      case 'edit':
        widget.onEditTask?.call(widget.task);
        break;
      case 'priority_high':
        widget.onSetPriority?.call(widget.task, TaskPriority.high);
        break;
      case 'priority_medium':
        widget.onSetPriority?.call(widget.task, TaskPriority.medium);
        break;
      case 'priority_low':
        widget.onSetPriority?.call(widget.task, TaskPriority.low);
        break;
      case 'status_pending':
        widget.onSetStatus?.call(widget.task, TaskStatus.pending);
        break;
      case 'status_in_progress':
        widget.onSetStatus?.call(widget.task, TaskStatus.inProgress);
        break;
      case 'status_completed':
        widget.onSetStatus?.call(widget.task, TaskStatus.completed);
        break;
      case 'delete':
        widget.onDeleteTask?.call(widget.task);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isCompleted = widget.task.status == TaskStatus.completed;
    final hasSubtasks = widget.subtasks.isNotEmpty;
    final isSubtask = widget.task.parentTaskId != null;
    final isTopLevel = widget.task.parentTaskId == null;
    final totalFocusDuration = _getTotalFocusDuration();
    final completedSubtasks =
        widget.subtasks.where((t) => t.status == TaskStatus.completed).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main task item card
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: () => widget.onTaskTap?.call(widget.task),
            onSecondaryTapDown: (details) {
              _showContextMenu(context, details.globalPosition);
            },
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              margin: EdgeInsets.only(
                top: 1,
                bottom: 6,
                left: isSubtask ? 32.0 : 0,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? colors.primaryLight
                    : colors.surface,
                border: Border.all(
                  color: widget.isSelected
                      ? colors.primary
                      : _isHovered
                          ? colors.primary
                          : colors.divider,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : _isHovered
                        ? [
                            BoxShadow(
                              color: colors.shadowLight,
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : [],
              ),
              transform: _isHovered && !widget.isSelected
                  ? Matrix4.translationValues(0, -1.0, 0)
                  : Matrix4.identity(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Expand/collapse button for parent tasks
                  if (hasSubtasks)
                    GestureDetector(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      child: Container(
                        width: 18,
                        height: 18,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          _isExpanded
                              ? Icons.expand_more
                              : Icons.chevron_right,
                          size: 14,
                          color: colors.primary,
                        ),
                      ),
                    ),

                  // Checkbox
                  GestureDetector(
                    onTap: () => widget.onTaskStatusChanged?.call(widget.task),
                    child: Container(
                      width: 18,
                      height: 18,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? colors.success
                            : Colors.transparent,
                        border: Border.all(
                          color: isCompleted
                              ? colors.success
                              : colors.checkboxBorder,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: isCompleted
                          ? const Icon(
                              Icons.check,
                              size: 11,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),

                  // Priority bar
                  Container(
                    width: 3,
                    height: 24,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Task info (title + meta)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title
                        Text(
                          widget.task.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isCompleted
                                ? colors.textHint
                                : colors.textPrimary,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: colors.textHint,
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // Meta row
                        if (_hasMetaInfo(totalFocusDuration))
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Row(
                              children: [
                                // Goal name
                                if (widget.task.goal != null) ...[
                                  _MetaItem(
                                    icon: '📁',
                                    text: widget.task.goal!.name,
                                  ),
                                  const SizedBox(width: 8),
                                ],

                                // Due date
                                if (widget.task.dueDate != null) ...[
                                  _MetaItem(
                                    icon: '⏰',
                                    text: _formatDate(widget.task.dueDate!),
                                    isOverdue: _isOverdue(),
                                  ),
                                  const SizedBox(width: 8),
                                ],

                                // Tags
                                ...widget.task.tags.take(2).map((tag) {
                                  final tagColor = _parseTagColor(tag.color);
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: tagColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        tag.name,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: tagColor,
                                        ),
                                      ),
                                    ),
                                  );
                                }),

                                // Subtask progress
                                if (hasSubtasks) ...[
                                  _MetaItem(
                                    icon: '📎',
                                    text: '$completedSubtasks/${widget.subtasks.length}',
                                  ),
                                ],

                                // Focus duration
                                if (totalFocusDuration > 0 && !hasSubtasks) ...[
                                  _MetaItem(
                                    icon: '⏱',
                                    text: _formatDuration(totalFocusDuration),
                                    isPrimary: true,
                                  ),
                                ],
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Action buttons - visible on hover
                  SizedBox(
                    width: isTopLevel ? 64 : 36,
                    height: 28,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: _isHovered ? 1.0 : 0.0,
                      child: IgnorePointer(
                        ignoring: !_isHovered,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (isTopLevel)
                              _ActionButton(
                                icon: Icons.add,
                                tooltip: '添加子任务',
                                onTap: widget.onAddSubtask,
                              ),

                            if (!isTopLevel && !isCompleted)
                              _PlayButton(
                                onTap: () => widget.onTaskFocus?.call(widget.task),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Subtasks with indentation and left border
        if (hasSubtasks && _isExpanded)
          Container(
            margin: const EdgeInsets.only(left: 0),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: colors.subtaskBorder,
                  width: 2,
                ),
              ),
            ),
            child: ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: widget.subtasks.length,
              onReorder: (oldIndex, newIndex) {
                if (widget.onSubtasksReorder != null) {
                  widget.onSubtasksReorder!(oldIndex, newIndex);
                }
              },
              itemBuilder: (context, index) {
                final subtask = widget.subtasks[index];
                return ReorderableDragStartListener(
                  key: ValueKey(subtask.id),
                  index: index,
                  child: TaskItem(
                    task: subtask,
                    subtasks: const [],
                    indentLevel: widget.indentLevel + 1,
                    isSelected: widget.selectedSubtaskId == subtask.id,
                    onTaskStatusChanged: widget.onTaskStatusChanged,
                    onTaskTap: widget.onTaskTap,
                    onTaskFocus: widget.onTaskFocus,
                    onEditTask: widget.onEditTask,
                    onDeleteTask: widget.onDeleteTask,
                    onSetPriority: widget.onSetPriority,
                    onSetStatus: widget.onSetStatus,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  bool _hasMetaInfo(int focusDuration) {
    return widget.task.tags.isNotEmpty ||
        widget.task.dueDate != null ||
        focusDuration > 0 ||
        widget.subtasks.isNotEmpty ||
        widget.task.goal != null;
  }
}

/// Small meta item (icon + text)
class _MetaItem extends StatelessWidget {
  final String icon;
  final String text;
  final bool isOverdue;
  final bool isPrimary;

  const _MetaItem({
    required this.icon,
    required this.text,
    this.isOverdue = false,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = isOverdue
        ? colors.error
        : isPrimary
            ? colors.primary
            : colors.textHint;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          icon,
          style: const TextStyle(fontSize: 10),
        ),
        const SizedBox(width: 2),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Transparent action button for edit/add subtask
class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Tooltip(
          message: widget.tooltip,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _isHovered
                  ? colors.primaryLight
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              widget.icon,
              size: 14,
              color: _isHovered
                  ? colors.primary
                  : colors.textHint,
            ),
          ),
        ),
      ),
    );
  }
}

/// Play button - purple circle with play icon
class _PlayButton extends StatefulWidget {
  final VoidCallback? onTap;

  const _PlayButton({this.onTap});

  @override
  State<_PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<_PlayButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Tooltip(
          message: '专注此任务',
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _isHovered
                  ? colors.primaryHover
                  : colors.primary,
              shape: BoxShape.circle,
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

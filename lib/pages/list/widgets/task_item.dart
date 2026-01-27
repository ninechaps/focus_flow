import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/task.dart';
import '../../../models/enums.dart';

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

  /// Format focus duration for display
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

  /// Calculate total focus duration including subtasks
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

  @override
  Widget build(BuildContext context) {
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
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              margin: EdgeInsets.only(
                top: 1, // Reserve space for hover transform (-1px upward)
                bottom: 6,
                left: isSubtask ? 32.0 : 0,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? const Color(0xFFEEF2FF) // primary-light
                    : AppTheme.surfaceColor,
                border: Border.all(
                  color: widget.isSelected
                      ? AppTheme.primaryColor
                      : _isHovered
                          ? AppTheme.primaryColor
                          : AppTheme.dividerColor,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : _isHovered
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
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
                          color: AppTheme.primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          _isExpanded
                              ? Icons.expand_more
                              : Icons.chevron_right,
                          size: 14,
                          color: AppTheme.primaryColor,
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
                            ? AppTheme.successColor
                            : Colors.transparent,
                        border: Border.all(
                          color: isCompleted
                              ? AppTheme.successColor
                              : AppTheme.dividerColor,
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
                                ? AppTheme.textHint
                                : AppTheme.textPrimary,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: AppTheme.textHint,
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
                  // Fixed height to prevent layout shift when task completes
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
                            // Edit / add subtask button
                            if (isTopLevel)
                              _ActionButton(
                                icon: Icons.add,
                                tooltip: 'Add subtask',
                                onTap: widget.onAddSubtask,
                              ),

                            // Focus button - play icon in purple circle
                            if (!hasSubtasks && !isCompleted)
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
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Color(0xFFE0E7FF), // primary-50
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
    final color = isOverdue
        ? AppTheme.errorColor
        : isPrimary
            ? AppTheme.primaryColor
            : AppTheme.textHint;

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
                  ? const Color(0xFFEEF2FF)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              widget.icon,
              size: 14,
              color: _isHovered
                  ? AppTheme.primaryColor
                  : AppTheme.textHint,
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
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Tooltip(
          message: 'Focus on this task',
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _isHovered
                  ? const Color(0xFF4F46E5)
                  : AppTheme.primaryColor,
              shape: BoxShape.circle,
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
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

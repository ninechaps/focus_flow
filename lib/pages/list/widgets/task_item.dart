import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/task.dart';
import '../../../models/enums.dart';

/// Individual task item widget with checkbox, priority, tags, and subtask support
class TaskItem extends StatefulWidget {
  final Task task;
  final List<Task> subtasks;
  final int indentLevel;
  final bool isSelected;
  final String? selectedSubtaskId;
  final ValueChanged<Task>? onTaskStatusChanged;  // Changed to accept Task
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
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
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
    // For parent tasks, sum up all subtask durations
    int total = 0;
    for (final subtask in widget.subtasks) {
      total += subtask.focusDuration;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.task.status == TaskStatus.completed;
    final hasSubtasks = widget.subtasks.isNotEmpty;
    final isSubtask = widget.task.parentTaskId != null;
    final isTopLevel = widget.task.parentTaskId == null;
    final dateStr = widget.task.dueDate != null
        ? _formatDate(widget.task.dueDate!)
        : '';
    final totalFocusDuration = _getTotalFocusDuration();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main task item
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: () => widget.onTaskTap?.call(widget.task),
            child: Stack(
              children: [
                // Main content
                Container(
                  constraints: const BoxConstraints(
                    minHeight: 48, // Fixed minimum height to prevent layout shift when status changes
                  ),
                  padding: EdgeInsets.only(
                    left: AppTheme.spacingMd + 3, // Add 3px for priority indicator
                    right: AppTheme.spacingMd,
                    top: AppTheme.spacingSm,
                    bottom: AppTheme.spacingSm,
                  ),
                  decoration: BoxDecoration(
                    color: widget.isSelected
                        ? AppTheme.primaryColor.withValues(alpha: 0.08)
                        : _isHovered
                            ? AppTheme.primaryColor.withValues(alpha: 0.04)
                            : Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: AppTheme.dividerColor.withValues(alpha: 0.6),
                        width: 1,
                      ),
                    ),
                  ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  // Expand/collapse button for parent tasks
                  if (hasSubtasks)
                    GestureDetector(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      child: Container(
                        width: 18,
                        height: 18,
                        margin: const EdgeInsets.only(right: 4),
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

                  // Checkbox - rounded style
                  GestureDetector(
                    onTap: () => widget.onTaskStatusChanged?.call(widget.task),
                    child: Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.only(right: AppTheme.spacingSm),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppTheme.primaryColor
                            : Colors.transparent,
                        border: Border.all(
                          color: isCompleted
                              ? AppTheme.primaryColor
                              : AppTheme.dividerColor,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(3),
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

                  // Task title and meta info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title row with fixed height to prevent layout shift when text decoration changes
                        SizedBox(
                          height: 16,
                          child: Text(
                            widget.task.title,
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeSm,
                              fontWeight: FontWeight.w500,
                              color: isCompleted
                                  ? AppTheme.textHint
                                  : AppTheme.textPrimary,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: AppTheme.textHint,
                              height: 1.2, // Ensure consistent line height
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Meta row: tags, time, focus duration
                        if (_hasMetaInfo(dateStr, totalFocusDuration))
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              children: [
                                // First tag as category
                                if (widget.task.tags.isNotEmpty) ...[
                                  _buildTag(
                                    widget.task.tags.first.name,
                                    _parseTagColor(widget.task.tags.first.color),
                                  ),
                                  const SizedBox(width: 6),
                                ],

                                // Date
                                if (dateStr.isNotEmpty) ...[
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 10,
                                    color: AppTheme.textHint,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    dateStr,
                                    style: TextStyle(
                                      fontSize: AppTheme.fontSizeXs,
                                      color: AppTheme.textHint,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],

                                // Focus duration
                                if (totalFocusDuration > 0) ...[
                                  Icon(
                                    Icons.timer_outlined,
                                    size: 10,
                                    color: AppTheme.primaryColor.withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    _formatDuration(totalFocusDuration),
                                    style: TextStyle(
                                      fontSize: AppTheme.fontSizeXs,
                                      color: AppTheme.primaryColor.withValues(alpha: 0.8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],

                                // Additional tags as hashtags
                                ...widget.task.tags.skip(1).map((tag) => Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: Text(
                                    '#${tag.name}',
                                    style: TextStyle(
                                      fontSize: AppTheme.fontSizeXs,
                                      color: AppTheme.textHint,
                                    ),
                                  ),
                                )),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Action buttons container - fixed width to prevent layout shift
                  SizedBox(
                    width: isTopLevel ? 60 : 36, // Reserve space for both buttons or just focus
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Focus button - visible for leaf tasks that are not completed
                        if (!hasSubtasks && !isCompleted)
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => widget.onTaskFocus?.call(widget.task),
                              child: Tooltip(
                                message: 'Focus on this task',
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: _isHovered
                                        ? AppTheme.primaryColor.withValues(alpha: 0.15)
                                        : AppTheme.primaryColor.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.play_arrow_rounded,
                                    size: 16,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Add subtask button - always present but opacity controlled
                        if (isTopLevel)
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 150),
                            opacity: _isHovered ? 1.0 : 0.0,
                            child: IgnorePointer(
                              ignoring: !_isHovered,
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: widget.onAddSubtask,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    margin: const EdgeInsets.only(left: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.dividerColor.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      size: 14,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

                // Subtask hierarchy indicator (connection line) - CustomPaint with L shape
                // Width is 20px for the L-shape, but vertical line is only 3px wide at left
                if (isSubtask)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 20,
                      height: double.infinity,
                      color: Colors.transparent,
                      child: CustomPaint(
                        painter: _SubtaskLinePainter(
                          color: AppTheme.dividerColor,
                        ),
                      ),
                    ),
                  ),

                // Priority indicator - vertical line at the very left (positioned absolutely, last so it overlays on top)
                if (widget.task.priority == TaskPriority.high || widget.task.priority == TaskPriority.low)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 3,
                      decoration: BoxDecoration(
                        color: widget.task.priority == TaskPriority.high
                            ? const Color(0xFFEF4444) // Red-500 for high
                            : const Color(0xFF9CA3AF), // Gray-400 for low
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(1),
                          bottomRight: Radius.circular(1),
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    ),

        // Subtasks with visual hierarchy and drag-and-drop reordering
        if (hasSubtasks && _isExpanded)
          Container(
            margin: const EdgeInsets.only(left: 30),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
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

  bool _hasMetaInfo(String dateStr, int focusDuration) {
    return widget.task.tags.isNotEmpty || dateStr.isNotEmpty || focusDuration > 0;
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: AppTheme.fontSizeXs,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

/// Custom painter for subtask connecting line
class _SubtaskLinePainter extends CustomPainter {
  final Color color;

  _SubtaskLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw L-shaped connection line
    // Vertical line: from (0, 0) to (0, size.height / 2) - at left edge
    // Horizontal line: from (0, size.height / 2) to (10, size.height / 2) - short line to avoid covering checkbox
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(0, size.height / 2)
      ..lineTo(10, size.height / 2);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/goal.dart';
import '../../../models/task.dart';
import '../../../models/enums.dart';

/// Redesigned detail panel (300px) with sections:
/// - Header: status badges + title + description
/// - Details: goal, due date, focus time, created date
/// - Subtask progress: ring + progress bar
/// - Subtask list: mini checkboxes
/// - Bottom actions: edit + focus
class TipsPanel extends StatelessWidget {
  static const double width = 300.0;

  final List<Goal> goals;
  final List<Task> tasks;
  final String? selectedGoalId;
  final String? selectedTaskId;
  final VoidCallback? onEdit;
  final ValueChanged<Task>? onFocus;

  const TipsPanel({
    super.key,
    this.goals = const [],
    this.tasks = const [],
    this.selectedGoalId,
    this.selectedTaskId,
    this.onEdit,
    this.onFocus,
  });

  Task? get _selectedTask {
    if (selectedTaskId == null) return null;
    for (final task in tasks) {
      if (task.id == selectedTaskId) return task;
    }
    return null;
  }

  Goal? get _selectedGoal {
    if (selectedGoalId == null) return null;
    try {
      return goals.firstWhere((g) => g.id == selectedGoalId);
    } catch (_) {
      return null;
    }
  }

  List<Task> _getSubtasks(String taskId) {
    return tasks.where((t) => t.parentTaskId == taskId).toList();
  }

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

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return AppTheme.errorColor;
      case TaskPriority.medium:
        return const Color(0xFFF59E0B);
      case TaskPriority.low:
        return AppTheme.successColor;
    }
  }

  String _getPriorityLabel(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return '高优先级';
      case TaskPriority.medium:
        return '中优先级';
      case TaskPriority.low:
        return '低优先级';
    }
  }

  String _getStatusLabel(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return '待办';
      case TaskStatus.inProgress:
        return '进行中';
      case TaskStatus.completed:
        return '已完成';
      case TaskStatus.deleted:
        return '已删除';
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return const Color(0xFFF59E0B);
      case TaskStatus.inProgress:
        return AppTheme.primaryColor;
      case TaskStatus.completed:
        return AppTheme.successColor;
      case TaskStatus.deleted:
        return AppTheme.errorColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox(
      width: width,
      height: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(
            left: BorderSide(
              color: colors.divider,
              width: 1,
            ),
          ),
        ),
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (selectedTaskId != null && _selectedTask != null) {
      return _buildTaskDetails(context, _selectedTask!);
    } else if (selectedGoalId != null && _selectedGoal != null) {
      return _buildGoalSummary(context, _selectedGoal!);
    }
    return const SizedBox.shrink();
  }

  Widget _buildTaskDetails(BuildContext context, Task task) {
    final colors = context.appColors;
    final subtasks = _getSubtasks(task.id);
    final completedSubtasks =
        subtasks.where((t) => t.status == TaskStatus.completed).length;
    final totalSubtasks = subtasks.length;

    int totalFocusTime = task.focusDuration;
    for (final subtask in subtasks) {
      totalFocusTime += subtask.focusDuration;
    }

    final priorityColor = _getPriorityColor(task.priority);
    final statusColor = _getStatusColor(task.status);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== Header Section =====
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: colors.divider, width: 1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _StatusBadge(
                            label: _getPriorityLabel(task.priority),
                            color: priorityColor,
                          ),
                          const SizedBox(width: 8),
                          _StatusBadge(
                            label: _getStatusLabel(task.status),
                            color: statusColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                          height: 1.4,
                          decoration: task.status == TaskStatus.completed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (task.description != null &&
                          task.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description!,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                            height: 1.5,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // ===== Details Section =====
                _DetailSection(
                  title: '详情',
                  children: [
                    if (task.goal != null)
                      _DetailField(
                        label: '📁 目标',
                        value: task.goal!.name,
                      ),
                    if (task.dueDate != null)
                      _DetailField(
                        label: '📅 到期日',
                        value: _formatDate(task.dueDate!),
                        valueColor: _isDueSoon(task.dueDate!)
                            ? AppTheme.errorColor
                            : null,
                      ),
                    _DetailField(
                      label: '⏱ 已专注',
                      value: _formatDuration(totalFocusTime),
                      valueColor: colors.primary,
                    ),
                    _DetailField(
                      label: '📆 创建于',
                      value: _formatDate(task.createdAt),
                    ),
                  ],
                ),

                // ===== Subtask Progress Section =====
                if (subtasks.isNotEmpty) ...[
                  _DetailSection(
                    title: '子任务进度',
                    children: [
                      _SubtaskProgressWidget(
                        completed: completedSubtasks,
                        total: totalSubtasks,
                      ),
                    ],
                  ),

                  _DetailSection(
                    title: '子任务',
                    children: [
                      for (final subtask in subtasks)
                        _SubtaskMiniItem(
                          task: subtask,
                          priorityColor: _getPriorityColor(subtask.priority),
                        ),
                    ],
                  ),
                ],

                // Tags section
                if (task.tags.isNotEmpty)
                  _DetailSection(
                    title: '标签',
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: task.tags.map((tag) {
                          final tagColor = _parseTagColor(tag.color);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: tagColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tag.name,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: tagColor,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),

        // ===== Bottom Actions =====
        Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: _DetailButton(
                  label: '✏️ 编辑',
                  onTap: onEdit,
                ),
              ),
              const SizedBox(width: 8),
              if (task.parentTaskId != null)
                Expanded(
                  child: _DetailButton(
                    label: '▶ 开始专注',
                    isPrimary: true,
                    onTap: task.status != TaskStatus.completed && onFocus != null
                        ? () => onFocus!(task)
                        : null,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGoalSummary(BuildContext context, Goal goal) {
    final colors = context.appColors;
    final goalTasks = tasks
        .where((t) => t.goalId == goal.id && t.parentTaskId == null)
        .toList();
    final completedTasks =
        goalTasks.where((t) => t.status == TaskStatus.completed).length;

    int totalFocusTime = 0;
    for (final task in goalTasks) {
      totalFocusTime += task.focusDuration;
      final subtasks = _getSubtasks(task.id);
      for (final subtask in subtasks) {
        totalFocusTime += subtask.focusDuration;
      }
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colors.divider, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.flag, size: 20, color: colors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        goal.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          _DetailSection(
            title: '详情',
            children: [
              _DetailField(
                label: '📅 到期日',
                value: _formatDate(goal.dueDate),
              ),
              _DetailField(
                label: '📋 任务',
                value: '$completedTasks/${goalTasks.length} 已完成',
              ),
              _DetailField(
                label: '⏱ 总专注',
                value: _formatDuration(totalFocusTime),
                valueColor: colors.primary,
              ),
            ],
          ),

          if (goalTasks.isNotEmpty) ...[
            _DetailSection(
              title: '进度',
              children: [
                _SubtaskProgressWidget(
                  completed: completedTasks,
                  total: goalTasks.length,
                ),
              ],
            ),

            _DetailSection(
              title: '任务 (${goalTasks.length})',
              children: [
                for (final task in goalTasks)
                  _SubtaskMiniItem(
                    task: task,
                    priorityColor: _getPriorityColor(task.priority),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  bool _isDueSoon(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return taskDate.isBefore(today) || taskDate == today;
  }

  Color _parseTagColor(String hexColor) {
    final hex = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
}

// ===== Sub-widgets =====

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colors.sectionBorder,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.textHint,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailField({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: valueColor ?? colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubtaskProgressWidget extends StatelessWidget {
  final int completed;
  final int total;

  const _SubtaskProgressWidget({
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final progress = total > 0 ? completed / total : 0.0;
    final percent = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.progressBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CustomPaint(
              painter: _ProgressRingPainter(
                progress: progress,
                backgroundColor: colors.divider,
                progressColor: colors.primary,
                strokeWidth: 4,
              ),
              child: Center(
                child: Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.primary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '已完成 $completed / $total 个子任务',
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textHint,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: colors.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress >= 1.0
                          ? AppTheme.successColor
                          : colors.primary,
                    ),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  _ProgressRingPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _SubtaskMiniItem extends StatelessWidget {
  final Task task;
  final Color priorityColor;

  const _SubtaskMiniItem({
    required this.task,
    required this.priorityColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDone = task.status == TaskStatus.completed;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: isDone ? colors.success : Colors.transparent,
              border: Border.all(
                color: isDone ? colors.success : colors.checkboxBorder,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(3),
            ),
            child: isDone
                ? const Icon(Icons.check, size: 9, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              task.title,
              style: TextStyle(
                fontSize: 12,
                color: isDone ? colors.textHint : colors.textPrimary,
                decoration: isDone ? TextDecoration.lineThrough : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: priorityColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailButton extends StatefulWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback? onTap;

  const _DetailButton({
    required this.label,
    this.isPrimary = false,
    this.onTap,
  });

  @override
  State<_DetailButton> createState() => _DetailButtonState();
}

class _DetailButtonState extends State<_DetailButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDisabled = widget.onTap == null;

    return MouseRegion(
      cursor: isDisabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      onEnter: (_) {
        if (!isDisabled) setState(() => _isHovered = true);
      },
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: widget.isPrimary
                ? (_isHovered ? colors.primaryHover : colors.primary)
                : (_isHovered
                    ? colors.hoverBg
                    : colors.surface),
            border: Border.all(
              color: widget.isPrimary
                  ? colors.primary
                  : colors.divider,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: widget.isPrimary
                    ? Colors.white
                    : (isDisabled
                        ? colors.textHint
                        : colors.textSecondary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../../models/task.dart';
import '../../../models/enums.dart';
import '../../../widgets/context_menu.dart';

/// 右键菜单操作类型
enum ScheduleTaskAction {
  edit,
  setPriorityHigh,
  setPriorityMedium,
  setPriorityLow,
  setStatusPending,
  setStatusInProgress,
  setStatusCompleted,
  reschedule,
  delete,
  startFocus,
}

/// 可交互的任务卡片 — 含复选框、优先级色条、Hover 播放按钮、右键菜单
class ScheduleTaskItem extends StatefulWidget {
  final Task task;
  final ValueChanged<TaskStatus> onStatusChanged;
  final ValueChanged<ScheduleTaskAction> onAction;

  const ScheduleTaskItem({
    super.key,
    required this.task,
    required this.onStatusChanged,
    required this.onAction,
  });

  @override
  State<ScheduleTaskItem> createState() => _ScheduleTaskItemState();
}

class _ScheduleTaskItemState extends State<ScheduleTaskItem> {
  bool _isHovered = false;

  static const _priorityHigh = Color(0xFFEF4444);
  static const _priorityMedium = Color(0xFFF59E0B);
  static const _priorityLow = Color(0xFF22C55E);

  Color _priorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return _priorityHigh;
      case TaskPriority.medium:
        return _priorityMedium;
      case TaskPriority.low:
        return _priorityLow;
    }
  }

  void _toggleStatus() {
    final next = switch (widget.task.status) {
      TaskStatus.pending => TaskStatus.inProgress,
      TaskStatus.inProgress => TaskStatus.completed,
      TaskStatus.completed => TaskStatus.pending,
      TaskStatus.deleted => TaskStatus.pending,
    };
    widget.onStatusChanged(next);
  }

  Future<void> _showContextMenu(Offset position) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await ContextMenu.show<ScheduleTaskAction>(
      context: context,
      position: position,
      groups: [
        ContextMenuGroup(items: [
          ContextMenuItem(
            label: l10n.editTaskContextMenu,
            icon: Icons.edit_outlined,
            value: ScheduleTaskAction.edit,
          ),
          ContextMenuItem(
            label: l10n.scheduleStartFocus,
            icon: Icons.play_arrow_rounded,
            value: ScheduleTaskAction.startFocus,
          ),
        ]),
        ContextMenuGroup(items: [
          ContextMenuItem(
            label: '${l10n.scheduleSetPriority}: ${l10n.priorityHighShort}',
            icon: Icons.flag,
            value: ScheduleTaskAction.setPriorityHigh,
          ),
          ContextMenuItem(
            label: '${l10n.scheduleSetPriority}: ${l10n.priorityMediumShort}',
            icon: Icons.flag_outlined,
            value: ScheduleTaskAction.setPriorityMedium,
          ),
          ContextMenuItem(
            label: '${l10n.scheduleSetPriority}: ${l10n.priorityLowShort}',
            icon: Icons.outlined_flag,
            value: ScheduleTaskAction.setPriorityLow,
          ),
        ]),
        ContextMenuGroup(items: [
          ContextMenuItem(
            label: '${l10n.scheduleSetStatus}: ${l10n.statusPending}',
            icon: Icons.radio_button_unchecked,
            value: ScheduleTaskAction.setStatusPending,
          ),
          ContextMenuItem(
            label: '${l10n.scheduleSetStatus}: ${l10n.statusInProgress}',
            icon: Icons.timelapse,
            value: ScheduleTaskAction.setStatusInProgress,
          ),
          ContextMenuItem(
            label: '${l10n.scheduleSetStatus}: ${l10n.statusCompleted}',
            icon: Icons.check_circle_outline,
            value: ScheduleTaskAction.setStatusCompleted,
          ),
        ]),
        ContextMenuGroup(items: [
          ContextMenuItem(
            label: l10n.scheduleRescheduleDate,
            icon: Icons.calendar_today_outlined,
            value: ScheduleTaskAction.reschedule,
          ),
          ContextMenuItem(
            label: l10n.deleteTaskContextMenu,
            icon: Icons.delete_outline,
            value: ScheduleTaskAction.delete,
            isDangerous: true,
          ),
        ]),
      ],
    );
    if (result != null) {
      widget.onAction(result);
    }
  }

  IconData _statusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Icons.radio_button_unchecked;
      case TaskStatus.inProgress:
        return Icons.timelapse;
      case TaskStatus.completed:
        return Icons.check_circle;
      case TaskStatus.deleted:
        return Icons.remove_circle_outline;
    }
  }

  Color _statusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.completed:
        return AppTheme.successColor;
      case TaskStatus.inProgress:
        return AppTheme.accentColor;
      case TaskStatus.pending:
        return AppTheme.textHint;
      case TaskStatus.deleted:
        return AppTheme.textHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isCompleted = widget.task.status == TaskStatus.completed;

    return LongPressDraggable<Task>(
      data: widget.task,
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: AppTheme.spacingSm,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: colors.primary),
          ),
          child: Text(
            widget.task.title,
            style: TextStyle(
              fontSize: AppTheme.fontSizeSm,
              color: colors.textPrimary,
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: _buildCard(context, colors, isCompleted),
      ),
      child: GestureDetector(
        onSecondaryTapUp: (details) => _showContextMenu(details.globalPosition),
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: _buildCard(context, colors, isCompleted),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, AppColors colors, bool isCompleted) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: _isHovered ? colors.hoverBg : colors.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          // Priority color bar
          Container(
            width: 3,
            height: 28,
            decoration: BoxDecoration(
              color: _priorityColor(widget.task.priority),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          // Status checkbox
          GestureDetector(
            onTap: _toggleStatus,
            child: Icon(
              _statusIcon(widget.task.status),
              size: 18,
              color: _statusColor(widget.task.status),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          // Title
          Expanded(
            child: Text(
              widget.task.title,
              style: TextStyle(
                fontSize: AppTheme.fontSizeSm,
                color: isCompleted ? colors.textHint : colors.textPrimary,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Hover play button
          if (_isHovered && !isCompleted)
            GestureDetector(
              onTap: () => widget.onAction(ScheduleTaskAction.startFocus),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Icon(
                  Icons.play_circle_outline,
                  size: 20,
                  color: colors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

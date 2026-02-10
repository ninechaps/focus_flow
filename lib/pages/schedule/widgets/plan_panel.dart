import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../../models/task.dart';
import '../../../models/enums.dart';
import 'schedule_task_item.dart';

/// 计划面板 — 当天任务 + 未安排任务 + 快速添加按钮
class PlanPanel extends StatelessWidget {
  /// 当天有 dueDate 的任务
  final List<Task> tasks;
  /// 没有 dueDate 的待办任务
  final List<Task> unplannedTasks;
  final ValueChanged<TaskStatus> Function(Task task) onStatusChanged;
  final void Function(Task task, ScheduleTaskAction action) onAction;
  final VoidCallback onQuickAdd;

  const PlanPanel({
    super.key,
    required this.tasks,
    required this.unplannedTasks,
    required this.onStatusChanged,
    required this.onAction,
    required this.onQuickAdd,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;
    final hasScheduled = tasks.isNotEmpty;
    final hasUnplanned = unplannedTasks.isNotEmpty;
    final isEmpty = !hasScheduled && !hasUnplanned;

    return Column(
      children: [
        Expanded(
          child: isEmpty
              ? Center(
                  child: Text(
                    l10n.noTasksForDay,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeMd,
                      color: colors.textHint,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  children: [
                    // Scheduled tasks for this date
                    if (hasScheduled)
                      ...tasks.map((task) => Padding(
                        padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                        child: ScheduleTaskItem(
                          task: task,
                          onStatusChanged: onStatusChanged(task),
                          onAction: (action) => onAction(task, action),
                        ),
                      )),
                    // Unplanned section
                    if (hasUnplanned) ...[
                      if (hasScheduled) const SizedBox(height: AppTheme.spacingSm),
                      // Section header
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.spacingSm,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 14,
                              color: colors.textHint,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l10n.scheduleUnplanned,
                              style: TextStyle(
                                fontSize: AppTheme.fontSizeXs,
                                fontWeight: FontWeight.w600,
                                color: colors.textHint,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Divider(color: colors.divider, height: 1),
                            ),
                          ],
                        ),
                      ),
                      ...unplannedTasks.map((task) => Padding(
                        padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                        child: ScheduleTaskItem(
                          task: task,
                          onStatusChanged: onStatusChanged(task),
                          onAction: (action) => onAction(task, action),
                        ),
                      )),
                    ],
                  ],
                ),
        ),
        // Quick add button
        Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onQuickAdd,
              icon: const Icon(Icons.add, size: 16),
              label: Text(l10n.scheduleQuickAdd),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.spacingSm,
                ),
                side: BorderSide(color: colors.divider),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

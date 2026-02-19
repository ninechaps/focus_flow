import 'package:flutter/material.dart';
import '../../../models/goal.dart';
import '../../../models/task.dart';
import '../../../theme/app_theme.dart';
import '../../list/widgets/tips_panel.dart';

/// 从右侧滑出的任务详情面板，内部复用 TipsPanel
class TaskDetailDrawer extends StatelessWidget {
  final Task? selectedTask;
  final List<Goal> goals;
  final List<Task> tasks;
  final VoidCallback? onEdit;
  final ValueChanged<Task>? onFocus;
  final VoidCallback onClose;

  /// 只读模式：从专注记录进入时为 true
  /// true → 显示返回箭头、隐藏编辑按钮；false → 显示关闭按钮
  final bool readOnly;

  const TaskDetailDrawer({
    super.key,
    required this.selectedTask,
    required this.goals,
    required this.tasks,
    this.onEdit,
    this.onFocus,
    required this.onClose,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isVisible = selectedTask != null;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      top: 0,
      bottom: 0,
      right: isVisible ? 0 : -TipsPanel.width,
      width: TipsPanel.width,
      child: GestureDetector(
        onTap: () {},
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(
              left: BorderSide(color: colors.divider, width: 1),
            ),
            boxShadow: isVisible
                ? [
                    BoxShadow(
                      color: colors.shadow,
                      blurRadius: 16,
                      offset: const Offset(-4, 0),
                    ),
                  ]
                : null,
          ),
          child: selectedTask != null
              ? Column(
                  children: [
                    // 关闭 / 返回按钮头部
                    _DrawerHeader(
                      readOnly: readOnly,
                      onClose: onClose,
                    ),
                    Expanded(
                      child: TipsPanel(
                        goals: goals,
                        tasks: tasks,
                        selectedTaskId: selectedTask!.id,
                        selectedGoalId: selectedTask!.goalId,
                        onEdit: readOnly ? null : onEdit,
                        onFocus: onFocus,
                        showFocusButton: true,
                        readOnly: readOnly,
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// 抽屉顶部操作栏：返回箭头（只读模式）或关闭按钮
class _DrawerHeader extends StatelessWidget {
  final bool readOnly;
  final VoidCallback onClose;

  const _DrawerHeader({
    required this.readOnly,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSm),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.divider, width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: Icon(
              readOnly ? Icons.arrow_back_ios_new : Icons.close,
              size: AppTheme.iconSizeMd,
              color: colors.textHint,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

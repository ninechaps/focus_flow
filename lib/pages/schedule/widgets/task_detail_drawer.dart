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

  const TaskDetailDrawer({
    super.key,
    required this.selectedTask,
    required this.goals,
    required this.tasks,
    this.onEdit,
    this.onFocus,
    required this.onClose,
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
              ? TipsPanel(
                  goals: goals,
                  tasks: tasks,
                  selectedTaskId: selectedTask!.id,
                  selectedGoalId: selectedTask!.goalId,
                  onEdit: onEdit,
                  onFocus: onFocus,
                  showFocusButton: true,
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../../models/enums.dart';
import '../../../models/tag.dart';
import '../../../models/goal.dart';
import '../../../models/task.dart';
import '../../../widgets/context_menu.dart';

/// Left sidebar panel for filtering tasks by time, tags, and goals
class TaskFilterPanel extends StatelessWidget {
  static const double width = 200.0;

  final String? selectedTimeFilter;
  final String? selectedTagId;
  final String? selectedGoalId;
  final List<Tag> tags;
  final List<Goal> goals;
  final List<Task> tasks;
  final ValueChanged<String?>? onTimeFilterChanged;
  final ValueChanged<String?>? onTagChanged;
  final ValueChanged<String?>? onGoalChanged;
  final VoidCallback? onAddTag;
  final VoidCallback? onAddGoal;
  final Function(Goal)? onEditGoal;
  final Function(String)? onDeleteGoal;
  final Function(Tag)? onEditTag;
  final Function(String)? onDeleteTag;

  const TaskFilterPanel({
    super.key,
    this.selectedTimeFilter,
    this.selectedTagId,
    this.selectedGoalId,
    this.tags = const [],
    this.goals = const [],
    this.tasks = const [],
    this.onTimeFilterChanged,
    this.onTagChanged,
    this.onGoalChanged,
    this.onAddTag,
    this.onAddGoal,
    this.onEditGoal,
    this.onDeleteGoal,
    this.onEditTag,
    this.onDeleteTag,
  });

  /// Format count for display, showing "99+" for counts > 99
  String _formatCount(int count) {
    return count > 99 ? '99+' : count.toString();
  }

  /// Calculate task counts by creation date for each time filter
  /// Only counts incomplete (non-completed) parent tasks (top-level)
  Map<String, int> _calculateCounts() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int todayCount = 0;
    int weekCount = 0;
    int monthCount = 0;
    int earlierCount = 0;
    int allCount = 0;

    // Only count parent tasks (parentTaskId == null) that are not completed
    final parentTasks = tasks.where((t) =>
        t.parentTaskId == null && t.status != TaskStatus.completed);

    for (final task in parentTasks) {
      final createdDate = DateTime(
        task.createdAt.year,
        task.createdAt.month,
        task.createdAt.day,
      );

      allCount++;

      // Today: created today
      if (createdDate == today) {
        todayCount++;
      }

      // This week: created within the past 7 days (including today)
      final weekStart = today.subtract(const Duration(days: 6));
      if (!createdDate.isBefore(weekStart)) {
        weekCount++;
      }

      // This month: created in the current month
      if (createdDate.year == today.year && createdDate.month == today.month) {
        monthCount++;
      }

      // Earlier: created before this month
      if (createdDate.isBefore(DateTime(today.year, today.month, 1))) {
        earlierCount++;
      }
    }

    return {
      'today': todayCount,
      'week': weekCount,
      'month': monthCount,
      'earlier': earlierCount,
      'all': allCount,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;
    final counts = _calculateCounts();

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          right: BorderSide(
            color: colors.divider,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppTheme.spacingMd),
          // Time filters section
          _FilterSection(
            title: l10n.scheduleFilterTitle,
            children: [
              _TimeFilterItem(
                icon: Icons.wb_sunny_outlined,
                label: l10n.filterToday,
                countText: counts['today']! > 0 ? _formatCount(counts['today']!) : null,
                isSelected: selectedTimeFilter == 'today',
                onTap: selectedTimeFilter == 'today'
                    ? null
                    : () => onTimeFilterChanged?.call('today'),
              ),
              _TimeFilterItem(
                icon: Icons.date_range_outlined,
                label: l10n.filterThisWeek,
                countText: counts['week']! > 0 ? _formatCount(counts['week']!) : null,
                isSelected: selectedTimeFilter == 'week',
                onTap: selectedTimeFilter == 'week'
                    ? null
                    : () => onTimeFilterChanged?.call('week'),
              ),
              _TimeFilterItem(
                icon: Icons.calendar_month_outlined,
                label: l10n.filterThisMonth,
                countText: counts['month']! > 0 ? _formatCount(counts['month']!) : null,
                isSelected: selectedTimeFilter == 'month',
                onTap: selectedTimeFilter == 'month'
                    ? null
                    : () => onTimeFilterChanged?.call('month'),
              ),
              _TimeFilterItem(
                icon: Icons.history_outlined,
                label: l10n.filterEarlier,
                countText: counts['earlier']! > 0 ? _formatCount(counts['earlier']!) : null,
                isSelected: selectedTimeFilter == 'earlier',
                onTap: selectedTimeFilter == 'earlier'
                    ? null
                    : () => onTimeFilterChanged?.call('earlier'),
              ),
              _TimeFilterItem(
                icon: Icons.all_inbox_outlined,
                label: l10n.filterAllTasks,
                countText: counts['all']! > 0 ? _formatCount(counts['all']!) : null,
                isSelected: selectedTimeFilter == 'all' || selectedTimeFilter == null,
                onTap: selectedTimeFilter == 'all'
                    ? null
                    : () => onTimeFilterChanged?.call('all'),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Divider(height: 1, color: colors.divider),
          const SizedBox(height: AppTheme.spacingMd),
          // Goals section
          _FilterSection(
            title: l10n.sidebarGoals,
            trailing: IconButton(
              icon: const Icon(Icons.add, size: AppTheme.iconSizeSm),
              onPressed: onAddGoal,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 24,
                minHeight: 24,
              ),
            ),
            children: [
              for (final goal in goals)
                _GoalFilterItem(
                  goal: goal,
                  isSelected: selectedGoalId == goal.id,
                  onTap: () => onGoalChanged?.call(
                    selectedGoalId == goal.id ? null : goal.id,
                  ),
                  onEdit: () => onEditGoal?.call(goal),
                  onDelete: () => onDeleteGoal?.call(goal.id),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Divider(height: 1, color: colors.divider),
          const SizedBox(height: AppTheme.spacingMd),
          // Tags section
          _FilterSection(
            title: l10n.sidebarTags,
            trailing: IconButton(
              icon: const Icon(Icons.add, size: AppTheme.iconSizeSm),
              onPressed: onAddTag,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 24,
                minHeight: 24,
              ),
            ),
            children: [
              for (final tag in tags)
                _TagFilterItem(
                  tag: tag,
                  isSelected: selectedTagId == tag.id,
                  onTap: () => onTagChanged?.call(
                    selectedTagId == tag.id ? null : tag.id,
                  ),
                  onEdit: () => onEditTag?.call(tag),
                  onDelete: () => onDeleteTag?.call(tag.id),
                ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

/// Section container with title and children
class _FilterSection extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final List<Widget> children;

  const _FilterSection({
    required this.title,
    this.trailing,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: AppTheme.fontSizeXs,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          ...children,
        ],
      ),
    );
  }
}

/// Time filter item (Today, This Week, etc.)
class _TimeFilterItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? countText;
  final bool isSelected;
  final VoidCallback? onTap;

  const _TimeFilterItem({
    required this.icon,
    required this.label,
    this.countText,
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<_TimeFilterItem> createState() => _TimeFilterItemState();
}

class _TimeFilterItemState extends State<_TimeFilterItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isHighlighted = widget.isSelected || _isHovered;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingSm,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? colors.primary.withValues(alpha: 0.08)
                : _isHovered
                    ? colors.primary.withValues(alpha: 0.04)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: AppTheme.iconSizeSm,
                color: isHighlighted
                    ? colors.primary
                    : colors.textSecondary,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeSm,
                    fontWeight:
                        widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isHighlighted
                        ? colors.primary
                        : colors.textPrimary,
                  ),
                ),
              ),
              // Count badge
              if (widget.countText != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.isSelected
                        ? colors.primary.withValues(alpha: 0.15)
                        : colors.divider.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    widget.countText!,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeXs - 1,
                      fontWeight: FontWeight.w600,
                      color: widget.isSelected
                          ? colors.primary
                          : colors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Goal filter item with flag icon and due date
class _GoalFilterItem extends StatefulWidget {
  final Goal goal;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _GoalFilterItem({
    required this.goal,
    this.isSelected = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<_GoalFilterItem> createState() => _GoalFilterItemState();
}

class _GoalFilterItemState extends State<_GoalFilterItem> {
  bool _isHovered = false;

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;
    final isHighlighted = widget.isSelected || _isHovered;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTapDown: (details) async {
          // ignore: use_build_context_synchronously
          final result = await ContextMenu.show<String>(
            context: context,
            position: details.globalPosition,
            groups: [
              ContextMenuGroup(
                items: [
                  ContextMenuItem(
                    label: l10n.edit,
                    icon: Icons.edit_outlined,
                    value: 'edit',
                  ),
                  ContextMenuItem(
                    label: l10n.delete,
                    icon: Icons.delete_outline,
                    value: 'delete',
                    isDangerous: true,
                  ),
                ],
              ),
            ],
          );

          if (result == 'edit') {
            widget.onEdit?.call();
          } else if (result == 'delete') {
            widget.onDelete?.call();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingSm,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? colors.primary.withValues(alpha: 0.08)
                : _isHovered
                    ? colors.primary.withValues(alpha: 0.04)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Row(
            children: [
              Icon(
                widget.isSelected ? Icons.flag : Icons.flag_outlined,
                size: AppTheme.iconSizeSm,
                color: isHighlighted
                    ? colors.primary
                    : colors.textSecondary,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.goal.name,
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeSm,
                        fontWeight:
                            widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isHighlighted
                            ? colors.primary
                            : colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      l10n.dueDate(_formatDate(widget.goal.dueDate)),
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeXs - 1,
                        color: colors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tag filter item with color indicator
class _TagFilterItem extends StatefulWidget {
  final Tag tag;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _TagFilterItem({
    required this.tag,
    this.isSelected = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<_TagFilterItem> createState() => _TagFilterItemState();
}

class _TagFilterItemState extends State<_TagFilterItem> {
  bool _isHovered = false;

  Color _parseColor(String hexColor) {
    final hex = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;
    final tagColor = _parseColor(widget.tag.color);
    final isHighlighted = widget.isSelected || _isHovered;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTapDown: (details) async {
          // ignore: use_build_context_synchronously
          final result = await ContextMenu.show<String>(
            context: context,
            position: details.globalPosition,
            groups: [
              ContextMenuGroup(
                items: [
                  ContextMenuItem(
                    label: l10n.edit,
                    icon: Icons.edit_outlined,
                    value: 'edit',
                  ),
                  ContextMenuItem(
                    label: l10n.delete,
                    icon: Icons.delete_outline,
                    value: 'delete',
                    isDangerous: true,
                  ),
                ],
              ),
            ],
          );

          if (result == 'edit') {
            widget.onEdit?.call();
          } else if (result == 'delete') {
            widget.onDelete?.call();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingSm,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? tagColor.withValues(alpha: 0.08)
                : _isHovered
                    ? tagColor.withValues(alpha: 0.04)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: tagColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  widget.tag.name,
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeSm,
                    fontWeight:
                        widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isHighlighted ? tagColor : colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

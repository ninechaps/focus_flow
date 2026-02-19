import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../models/enums.dart';
import '../../models/goal.dart';
import '../../models/tag.dart';
import '../../widgets/context_menu.dart';
import '../../pages/list/widgets/add_goal_dialog.dart';
import '../../pages/list/widgets/add_tag_dialog.dart';
import '../../pages/list/widgets/edit_goal_dialog.dart';
import '../../pages/list/widgets/edit_tag_dialog.dart';
import 'window_controls.dart';

/// Redesigned sidebar: 220px wide with user info, navigation, schedule filters,
/// goals, and tags sections.
class Sidebar extends StatelessWidget {
  static const double width = 220.0;

  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

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
        children: [
          // Window controls at the top
          const WindowControls(),

          // Scrollable content
          Expanded(
            child: Consumer2<AuthProvider, TaskProvider>(
              builder: (context, authProvider, taskProvider, _) {
                return _SidebarContent(
                  authProvider: authProvider,
                  taskProvider: taskProvider,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Main sidebar content with all sections
class _SidebarContent extends StatelessWidget {
  final AuthProvider authProvider;
  final TaskProvider taskProvider;

  const _SidebarContent({
    required this.authProvider,
    required this.taskProvider,
  });

  /// Calculate task counts for schedule filters
  Map<String, int> _calculateCounts() {
    final incompleteTasks = taskProvider.tasks.where((t) =>
        t.parentTaskId == null && t.status != TaskStatus.completed).toList();
    final totalIncomplete = incompleteTasks.length;

    return {
      'today': totalIncomplete,
      'week': totalIncomplete,
      'month': totalIncomplete,
    };
  }

  String _formatCount(int count) {
    return count > 99 ? '99+' : count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;
    final user = authProvider.currentUser;
    final username = user?.username ?? 'User';
    final email = user?.email ?? '';
    final initial = username.isNotEmpty ? username[0].toUpperCase() : 'U';
    final currentLocation = GoRouterState.of(context).uri.path;
    final counts = _calculateCounts();

    final totalTasks = taskProvider.tasks
        .where((t) => t.parentTaskId == null && t.status != TaskStatus.completed)
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== User Info =====
          _UserInfoSection(
            initial: initial,
            username: username,
            email: email,
          ),

          const SizedBox(height: 20),

          // ===== Navigation =====
          _SectionTitle(title: l10n.navNavigation),
          const SizedBox(height: 4),
          _SidebarNavItem(
            icon: Icons.list_alt_outlined,
            activeIcon: Icons.list_alt,
            label: l10n.navTaskList,
            count: totalTasks > 0 ? _formatCount(totalTasks) : null,
            isActive: currentLocation == '/app/list',
            onTap: () => context.go('/app/list'),
          ),
          _SidebarNavItem(
            icon: Icons.calendar_month_outlined,
            activeIcon: Icons.calendar_month,
            label: l10n.navSchedule,
            isActive: currentLocation == '/app/schedule',
            onTap: () => context.go('/app/schedule'),
          ),
          _SidebarNavItem(
            icon: Icons.bar_chart_outlined,
            activeIcon: Icons.bar_chart,
            label: l10n.navStatistics,
            isActive: currentLocation == '/app/statistics',
            onTap: () => context.go('/app/statistics'),
          ),
          _SidebarNavItem(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings,
            label: l10n.navSettings,
            isActive: currentLocation == '/app/settings',
            onTap: () => context.go('/app/settings'),
          ),

          const SizedBox(height: 20),

          // ===== Schedule Filters =====
          _SectionTitle(title: l10n.scheduleFilterTitle),
          const SizedBox(height: 4),
          _SidebarNavItem(
            icon: Icons.wb_sunny_outlined,
            activeIcon: Icons.wb_sunny,
            label: l10n.filterToday,
            count: counts['today']! > 0 ? _formatCount(counts['today']!) : null,
            isActive: taskProvider.selectedTimeFilter == 'today' &&
                currentLocation == '/app/list',
            onTap: () {
              taskProvider.setTimeFilter('today');
              taskProvider.setGoalFilter(null);
              taskProvider.setTagFilter(null);
              if (currentLocation != '/app/list') {
                context.go('/app/list');
              }
            },
          ),
          _SidebarNavItem(
            icon: Icons.date_range_outlined,
            activeIcon: Icons.date_range,
            label: l10n.filterThisWeek,
            count: counts['week']! > 0 ? _formatCount(counts['week']!) : null,
            isActive: taskProvider.selectedTimeFilter == 'week' &&
                currentLocation == '/app/list',
            onTap: () {
              taskProvider.setTimeFilter('week');
              taskProvider.setGoalFilter(null);
              taskProvider.setTagFilter(null);
              if (currentLocation != '/app/list') {
                context.go('/app/list');
              }
            },
          ),
          _SidebarNavItem(
            icon: Icons.calendar_month_outlined,
            activeIcon: Icons.calendar_month,
            label: l10n.filterThisMonth,
            count: counts['month']! > 0 ? _formatCount(counts['month']!) : null,
            isActive: taskProvider.selectedTimeFilter == 'month' &&
                currentLocation == '/app/list',
            onTap: () {
              taskProvider.setTimeFilter('month');
              taskProvider.setGoalFilter(null);
              taskProvider.setTagFilter(null);
              if (currentLocation != '/app/list') {
                context.go('/app/list');
              }
            },
          ),

          const SizedBox(height: 20),

          // ===== Goals =====
          _GoalsSection(
            goals: taskProvider.goals,
            selectedGoalId: taskProvider.selectedGoalId,
            currentLocation: currentLocation,
            onGoalTap: (goalId) {
              taskProvider.setGoalFilter(
                taskProvider.selectedGoalId == goalId ? null : goalId,
              );
              taskProvider.setTagFilter(null);
              if (currentLocation != '/app/list' &&
                  currentLocation != '/app/schedule') {
                context.go('/app/list');
              }
            },
            onAddGoal: () => _handleAddGoal(context),
            onEditGoal: (goal) => _handleEditGoal(context, goal),
            onDeleteGoal: (goalId) => _handleDeleteGoal(context, goalId),
          ),

          const SizedBox(height: 20),

          // ===== Tags =====
          _TagsSection(
            tags: taskProvider.tags,
            selectedTagId: taskProvider.selectedTagId,
            currentLocation: currentLocation,
            onTagTap: (tagId) {
              taskProvider.setTagFilter(
                taskProvider.selectedTagId == tagId ? null : tagId,
              );
              taskProvider.setGoalFilter(null);
              if (currentLocation != '/app/list' &&
                  currentLocation != '/app/schedule') {
                context.go('/app/list');
              }
            },
            onAddTag: () => _handleAddTag(context),
            onEditTag: (tag) => _handleEditTag(context, tag),
            onDeleteTag: (tagId) => _handleDeleteTag(context, tagId),
          ),

          const SizedBox(height: 20),

          // ===== Trash =====
          Divider(height: 1, color: colors.divider),
          const SizedBox(height: 8),
          _SidebarNavItem(
            icon: Icons.delete_outline,
            activeIcon: Icons.delete,
            label: l10n.navTrash,
            isActive: currentLocation == '/app/trash',
            onTap: () => context.go('/app/trash'),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ===== Action handlers =====

  Future<void> _handleAddGoal(BuildContext context) async {
    final goal = await showAddGoalDialog(context);
    if (goal != null && context.mounted) {
      try {
        await taskProvider.addGoal(goal);
      } catch (e) {
        if (context.mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.failedToAddGoal('$e')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleEditGoal(BuildContext context, Goal goal) async {
    final updatedGoal = await showEditGoalDialog(context, goal);
    if (updatedGoal != null && context.mounted) {
      try {
        await taskProvider.updateGoal(updatedGoal);
      } catch (e) {
        if (context.mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.failedToUpdateGoal('$e')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleDeleteGoal(BuildContext context, String goalId) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteGoalTitle),
        content: Text(l10n.deleteGoalConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      try {
        await taskProvider.deleteGoal(goalId);
      } catch (e) {
        if (context.mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.failedToDeleteGoal('$e')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleAddTag(BuildContext context) async {
    final tag = await showAddTagDialog(context);
    if (tag != null && context.mounted) {
      try {
        await taskProvider.addTag(tag);
      } catch (e) {
        if (context.mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.failedToAddTag('$e')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleEditTag(BuildContext context, Tag tag) async {
    final updatedTag = await showEditTagDialog(context, tag);
    if (updatedTag != null && context.mounted) {
      try {
        await taskProvider.updateTag(updatedTag);
      } catch (e) {
        if (context.mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.failedToUpdateTag('$e')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleDeleteTag(BuildContext context, String tagId) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteTagTitle),
        content: Text(l10n.deleteTagConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      try {
        await taskProvider.deleteTag(tagId);
      } catch (e) {
        if (context.mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.failedToDeleteTag('$e')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

// ===== Sub-widgets =====

/// Section title: 10px, uppercase, hint color
class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: colors.textHint,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// User info area: avatar + username + email
class _UserInfoSection extends StatelessWidget {
  final String initial;
  final String username;
  final String email;

  const _UserInfoSection({
    required this.initial,
    required this.username,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.primary,
                  AppTheme.primaryColor.shade400,
                ],
              ),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Name + email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textHint,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Navigation item: icon + text + optional count badge
class _SidebarNavItem extends StatefulWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final String? count;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    this.count,
    this.isActive = false,
    required this.onTap,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isHighlighted = widget.isActive || _isHovered;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 1),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: widget.isActive
                ? colors.primaryLight
                : _isHovered
                    ? colors.hoverBg
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(
                isHighlighted
                    ? (widget.activeIcon ?? widget.icon)
                    : widget.icon,
                size: 16,
                color: widget.isActive
                    ? colors.primary
                    : isHighlighted
                        ? colors.textPrimary
                        : colors.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: widget.isActive ? FontWeight.w500 : FontWeight.w400,
                    color: widget.isActive
                        ? colors.primary
                        : isHighlighted
                            ? colors.textPrimary
                            : colors.textSecondary,
                  ),
                ),
              ),
              if (widget.count != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: widget.isActive
                        ? colors.activeBadgeBg
                        : colors.badgeBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.count!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: widget.isActive
                          ? colors.primary
                          : colors.textHint,
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

/// Goals section with list + add button + context menu
class _GoalsSection extends StatelessWidget {
  final List<Goal> goals;
  final String? selectedGoalId;
  final String currentLocation;
  final ValueChanged<String> onGoalTap;
  final VoidCallback onAddGoal;
  final Function(Goal) onEditGoal;
  final Function(String) onDeleteGoal;

  const _GoalsSection({
    required this.goals,
    required this.selectedGoalId,
    required this.currentLocation,
    required this.onGoalTap,
    required this.onAddGoal,
    required this.onEditGoal,
    required this.onDeleteGoal,
  });

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dotColors = [
      AppTheme.primaryColor,
      AppTheme.successColor,
      AppTheme.accentColor,
      const Color(0xFFF59E0B),
      AppTheme.errorColor,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: l10n.sidebarGoals),
        const SizedBox(height: 4),
        for (int i = 0; i < goals.length; i++)
          _GoalItem(
            goal: goals[i],
            dotColor: dotColors[i % dotColors.length],
            isActive: selectedGoalId == goals[i].id &&
                (currentLocation == '/app/list' ||
                    currentLocation == '/app/schedule'),
            formattedDate: _formatDate(goals[i].dueDate),
            onTap: () => onGoalTap(goals[i].id),
            onEdit: () => onEditGoal(goals[i]),
            onDelete: () => onDeleteGoal(goals[i].id),
          ),
        _AddButton(
          label: l10n.sidebarNewGoal,
          onTap: onAddGoal,
        ),
      ],
    );
  }
}

/// Single goal item with colored dot and due date
class _GoalItem extends StatefulWidget {
  final Goal goal;
  final Color dotColor;
  final bool isActive;
  final String formattedDate;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GoalItem({
    required this.goal,
    required this.dotColor,
    required this.isActive,
    required this.formattedDate,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_GoalItem> createState() => _GoalItemState();
}

class _GoalItemState extends State<_GoalItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTapDown: (details) async {
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
            widget.onEdit();
          } else if (result == 'delete') {
            widget.onDelete();
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 1),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: widget.isActive
                ? colors.primaryLight
                : _isHovered
                    ? colors.hoverBg
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: widget.dotColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.goal.name,
                  style: TextStyle(
                    fontSize: 13,
                    color: widget.isActive
                        ? colors.primary
                        : colors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                widget.formattedDate,
                style: TextStyle(
                  fontSize: 10,
                  color: colors.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tags section with chips + add button
class _TagsSection extends StatelessWidget {
  final List<Tag> tags;
  final String? selectedTagId;
  final String currentLocation;
  final ValueChanged<String> onTagTap;
  final VoidCallback onAddTag;
  final Function(Tag) onEditTag;
  final Function(String) onDeleteTag;

  const _TagsSection({
    required this.tags,
    required this.selectedTagId,
    required this.currentLocation,
    required this.onTagTap,
    required this.onAddTag,
    required this.onEditTag,
    required this.onDeleteTag,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: l10n.sidebarTags),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final tag in tags)
                _TagChip(
                  tag: tag,
                  isActive: selectedTagId == tag.id &&
                      (currentLocation == '/app/list' ||
                          currentLocation == '/app/schedule'),
                  onTap: () => onTagTap(tag.id),
                  onEdit: () => onEditTag(tag),
                  onDelete: () => onDeleteTag(tag.id),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        _AddButton(
          label: l10n.sidebarNewTag,
          onTap: onAddTag,
        ),
      ],
    );
  }
}

/// Tag chip with context menu support
class _TagChip extends StatefulWidget {
  final Tag tag;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TagChip({
    required this.tag,
    required this.isActive,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_TagChip> createState() => _TagChipState();
}

class _TagChipState extends State<_TagChip> {
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

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTapDown: (details) async {
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
            widget.onEdit();
          } else if (result == 'delete') {
            widget.onDelete();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: widget.isActive || _isHovered
                ? colors.primaryLight
                : colors.badgeBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: tagColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                widget.tag.name,
                style: TextStyle(
                  fontSize: 11,
                  color: widget.isActive
                      ? colors.primary
                      : colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small add button (+ 新建目标 / + 新建标签)
class _AddButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _AddButton({
    required this.label,
    required this.onTap,
  });

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
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
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _isHovered ? colors.hoverBg : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              color: _isHovered ? colors.primary : colors.textHint,
            ),
          ),
        ),
      ),
    );
  }
}

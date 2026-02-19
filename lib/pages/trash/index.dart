import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../models/task.dart';
import '../../models/enums.dart';
import '../../providers/task_provider.dart';

/// 垃圾篓页面 — 显示所有软删除的任务，支持按创建时间分组和还原操作
class TrashPage extends StatefulWidget {
  const TrashPage({super.key});

  @override
  State<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadDeletedTasks();
    });
  }

  Future<void> _restoreTask(Task task) async {
    final provider = context.read<TaskProvider>();
    try {
      await provider.restoreTask(task.id);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.trashRestoreSuccess),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        final deletedTasks = provider.deletedTasks;
        final activeTasks = provider.tasks;

        return Container(
          color: colors.background,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 页面标题
              _TrashHeader(),

              // 内容区域
              Expanded(
                child: deletedTasks.isEmpty
                    ? _EmptyTrash()
                    : _TrashContent(
                        deletedTasks: deletedTasks,
                        activeTasks: activeTasks,
                        onRestore: _restoreTask,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 页面标题栏
class _TrashHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: Row(
        children: [
          Icon(Icons.delete_outline, size: 20, color: colors.textSecondary),
          const SizedBox(width: 8),
          Text(
            l10n.trashTitle,
            style: TextStyle(
              fontSize: AppTheme.fontSizeLg,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 空状态
class _EmptyTrash extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_outline, size: 48, color: colors.divider),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            l10n.trashEmpty,
            style: TextStyle(
              fontSize: AppTheme.fontSizeMd,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.trashEmptyHint,
            style: TextStyle(
              fontSize: AppTheme.fontSizeXs,
              color: colors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

/// 垃圾篓内容 — 按创建时间分组展示
class _TrashContent extends StatelessWidget {
  final List<Task> deletedTasks;
  final List<Task> activeTasks;
  final Future<void> Function(Task task) onRestore;

  const _TrashContent({
    required this.deletedTasks,
    required this.activeTasks,
    required this.onRestore,
  });

  /// 将已删除任务分组：
  /// - 独立的父任务（parentTaskId == null）及其已删除的子任务
  /// - 孤立的子任务（父任务未删除）
  List<_TrashGroup> _buildGroups() {
    // 已删除的任务 id 集合
    final deletedIds = deletedTasks.map((t) => t.id).toSet();
    // 活跃任务 id 集合（用于判断父任务是否被删除）
    final activeIds = activeTasks.map((t) => t.id).toSet();

    // 已删除的父任务
    final deletedParents = deletedTasks.where((t) => t.parentTaskId == null).toList();
    // 已删除的子任务（父任务也被删除的）
    final deletedSubtasksWithDeletedParent = deletedTasks
        .where((t) =>
            t.parentTaskId != null && deletedIds.contains(t.parentTaskId))
        .toList();
    // 孤立的子任务（父任务未被删除 — 父任务仍在活跃列表中）
    final orphanSubtasks = deletedTasks
        .where((t) =>
            t.parentTaskId != null &&
            (activeIds.contains(t.parentTaskId) ||
                (!deletedIds.contains(t.parentTaskId) &&
                    !activeIds.contains(t.parentTaskId))))
        .toList();

    final groups = <_TrashGroup>[];

    // 添加父任务组（含其已删除子任务）
    for (final parent in deletedParents) {
      final subtasks = deletedSubtasksWithDeletedParent
          .where((t) => t.parentTaskId == parent.id)
          .toList();
      groups.add(_TrashGroup(
        task: parent,
        subtasks: subtasks,
        parentContextTask: null,
      ));
    }

    // 添加孤立子任务组（带父任务上下文）
    for (final subtask in orphanSubtasks) {
      // 在活跃任务中查找父任务
      final parentTask = activeTasks
          .where((t) => t.id == subtask.parentTaskId)
          .firstOrNull;
      groups.add(_TrashGroup(
        task: subtask,
        subtasks: [],
        parentContextTask: parentTask,
      ));
    }

    return groups;
  }

  /// 按 createdAt 对 groups 进行分组（返回日期 key → groups 列表）
  Map<String, List<_TrashGroup>> _groupByDate(List<_TrashGroup> groups) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final map = <String, List<_TrashGroup>>{};

    for (final group in groups) {
      final date = DateTime(
        group.task.createdAt.year,
        group.task.createdAt.month,
        group.task.createdAt.day,
      );

      final String key;
      if (date == today) {
        key = 'today';
      } else if (date == yesterday) {
        key = 'yesterday';
      } else {
        key = date.toIso8601String().substring(0, 10); // YYYY-MM-DD
      }

      (map[key] ??= []).add(group);
    }

    // 排序：today 最前，yesterday 其次，其余按日期倒序
    final sortedKeys = map.keys.toList()
      ..sort((a, b) {
        if (a == 'today') return -1;
        if (b == 'today') return 1;
        if (a == 'yesterday') return -1;
        if (b == 'yesterday') return 1;
        return b.compareTo(a);
      });

    return {for (final k in sortedKeys) k: map[k]!};
  }

  @override
  Widget build(BuildContext context) {
    final groups = _buildGroups();
    final groupedByDate = _groupByDate(groups);

    return ListView(
      padding: const EdgeInsets.only(
        top: AppTheme.spacingXs,
        bottom: AppTheme.spacingXl,
      ),
      children: [
        for (final entry in groupedByDate.entries) ...[
          _DateGroupHeader(dateKey: entry.key),
          for (final group in entry.value)
            _TrashTaskCard(
              group: group,
              onRestore: onRestore,
            ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

/// 日期分组标题
class _DateGroupHeader extends StatelessWidget {
  final String dateKey;

  const _DateGroupHeader({required this.dateKey});

  String _getLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (dateKey == 'today') {
      return '${l10n.groupToday} · ${DateFormat.MMMd(Localizations.localeOf(context).toString()).format(DateTime.now())}';
    }
    if (dateKey == 'yesterday') {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      return '${l10n.groupYesterday} · ${DateFormat.MMMd(Localizations.localeOf(context).toString()).format(yesterday)}';
    }
    // YYYY-MM-DD
    final date = DateTime.parse(dateKey);
    return DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(
        children: [
          Text(
            _getLabel(context),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 1, color: colors.divider)),
        ],
      ),
    );
  }
}

/// 单个任务卡片（含父任务上下文或子任务列表）
class _TrashTaskCard extends StatelessWidget {
  final _TrashGroup group;
  final Future<void> Function(Task task) onRestore;

  const _TrashTaskCard({
    required this.group,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 3),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.divider, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 父任务上下文（仅孤立子任务时显示）
            if (group.parentContextTask != null)
              _ParentContextRow(parentTask: group.parentContextTask!),

            // 主任务行
            _TaskRow(
              task: group.task,
              isSubtask: group.parentContextTask != null,
              onRestore: () => onRestore(group.task),
            ),

            // 已删除的子任务列表（仅父任务时显示）
            for (final subtask in group.subtasks) ...[
              Divider(height: 1, color: colors.divider, indent: 16),
              _TaskRow(
                task: subtask,
                isSubtask: true,
                onRestore: () => onRestore(subtask),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 父任务上下文显示行（灰色标签，不可操作）
class _ParentContextRow extends StatelessWidget {
  final Task parentTask;

  const _ParentContextRow({required this.parentTask});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      decoration: BoxDecoration(
        color: colors.badgeBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
      ),
      child: Row(
        children: [
          Icon(Icons.subdirectory_arrow_right,
              size: 13, color: colors.textHint),
          const SizedBox(width: 4),
          Text(
            '${l10n.trashParentContext}: ',
            style: TextStyle(fontSize: 11, color: colors.textHint),
          ),
          Expanded(
            child: Text(
              parentTask.title,
              style: TextStyle(
                fontSize: 11,
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// 单行任务（标题 + 优先级 + 还原按钮）
class _TaskRow extends StatefulWidget {
  final Task task;
  final bool isSubtask;
  final Future<void> Function() onRestore;

  const _TaskRow({
    required this.task,
    required this.isSubtask,
    required this.onRestore,
  });

  @override
  State<_TaskRow> createState() => _TaskRowState();
}

class _TaskRowState extends State<_TaskRow> {
  bool _isRestoring = false;

  Future<void> _handleRestore() async {
    if (_isRestoring) return;
    setState(() => _isRestoring = true);
    try {
      await widget.onRestore();
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  Color _priorityColor(TaskPriority priority) {
    switch (priority) {
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
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;
    final priority = widget.task.priority;
    final priorityColor = _priorityColor(priority);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        widget.isSubtask ? 20 : 12,
        8,
        12,
        8,
      ),
      child: Row(
        children: [
          // 优先级指示条
          Container(
            width: 3,
            height: 32,
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),

          // 删除线标题
          Expanded(
            child: Text(
              widget.task.title,
              style: TextStyle(
                fontSize: 13,
                color: colors.textHint,
                decoration: TextDecoration.lineThrough,
                decorationColor: colors.textHint,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),

          // 还原按钮
          _isRestoring
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: colors.primary,
                  ),
                )
              : MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _handleRestore,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: colors.divider),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        l10n.trashRestore,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

/// 数据结构：表示垃圾篓中一个任务及其上下文
class _TrashGroup {
  /// 主任务（可能是父任务或孤立子任务）
  final Task task;

  /// 已删除的子任务（仅当 task 为父任务时有值）
  final List<Task> subtasks;

  /// 非删除的父任务（仅当 task 为孤立子任务时有值）
  final Task? parentContextTask;

  const _TrashGroup({
    required this.task,
    required this.subtasks,
    required this.parentContextTask,
  });
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../../models/focus_session.dart';
import '../../../models/task.dart';
import '../../list/widgets/tips_panel.dart';
import 'session_summary.dart';
import 'session_timeline_item.dart';

/// 日期专注面板 — 右侧滑入，展示选中日期的专注汇总与时间线
class DateFocusPanel extends StatelessWidget {
  final bool isOpen;
  final DateTime selectedDate;
  final List<FocusSession> sessions;
  final Map<String, Task> taskMap;
  final VoidCallback onClose;

  /// 点击专注记录中的任务时回调（用于打开任务详情抽屉）
  final ValueChanged<Task>? onTaskTap;

  const DateFocusPanel({
    super.key,
    required this.isOpen,
    required this.selectedDate,
    required this.sessions,
    required this.taskMap,
    required this.onClose,
    this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      top: 0,
      bottom: 0,
      right: isOpen ? 0 : -TipsPanel.width,
      width: TipsPanel.width,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(
            left: BorderSide(color: colors.divider, width: 1),
          ),
          boxShadow: isOpen
              ? [
                  BoxShadow(
                    color: colors.shadow,
                    blurRadius: 16,
                    offset: const Offset(-4, 0),
                  ),
                ]
              : null,
        ),
        child: isOpen
            ? _DateFocusContent(
                selectedDate: selectedDate,
                sessions: sessions,
                taskMap: taskMap,
                onClose: onClose,
                onTaskTap: onTaskTap,
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

/// 面板内容：标题栏 + 汇总卡 + 时间线列表
class _DateFocusContent extends StatelessWidget {
  final DateTime selectedDate;
  final List<FocusSession> sessions;
  final Map<String, Task> taskMap;
  final VoidCallback onClose;
  final ValueChanged<Task>? onTaskTap;

  const _DateFocusContent({
    required this.selectedDate,
    required this.sessions,
    required this.taskMap,
    required this.onClose,
    this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();

    final dateLabel = DateFormat.MMMEd(locale).format(selectedDate);
    final totalSeconds =
        sessions.fold<int>(0, (sum, s) => sum + s.durationSeconds);

    // 按开始时间倒序排列
    final sorted = List.of(sessions)
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题行
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingMd,
            AppTheme.spacingMd,
            AppTheme.spacingSm,
            AppTheme.spacingMd,
          ),
          child: Row(
            children: [
              Icon(
                Icons.timer_outlined,
                size: 16,
                color: colors.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  dateLabel,
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeMd,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: Icon(
                  Icons.close,
                  size: AppTheme.iconSizeMd,
                  color: colors.textHint,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          ),
        ),

        Divider(height: 1, color: colors.divider),

        // 汇总统计卡
        if (sessions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingMd,
              AppTheme.spacingMd,
              AppTheme.spacingMd,
              AppTheme.spacingSm,
            ),
            child: SessionSummary(
              totalSeconds: totalSeconds,
              sessionCount: sessions.length,
            ),
          ),

        // 时间线列表
        Expanded(
          child: sorted.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.timer_off_outlined,
                        size: 36,
                        color: colors.divider,
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      Text(
                        l10n.scheduleNoSessions,
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeSm,
                          color: colors.textHint,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  itemCount: sorted.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppTheme.spacingSm),
                  itemBuilder: (context, index) {
                    final session = sorted[index];
                    final task = taskMap[session.taskId];
                    return SessionTimelineItem(
                      session: session,
                      task: task,
                      onTap: task != null && onTaskTap != null
                          ? () => onTaskTap!(task)
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

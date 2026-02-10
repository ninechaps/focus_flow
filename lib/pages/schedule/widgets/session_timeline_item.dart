import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../models/focus_session.dart';
import '../../../models/task.dart';

/// 单条专注记录卡片 — 时间段 + 任务名 + 时长 + 完成类型图标
class SessionTimelineItem extends StatelessWidget {
  final FocusSession session;
  final Task? task;

  const SessionTimelineItem({
    super.key,
    required this.session,
    this.task,
  });

  String _formatDuration(int seconds) {
    if (seconds >= 3600) {
      final h = seconds ~/ 3600;
      final m = (seconds % 3600) ~/ 60;
      return '${h}h ${m}m';
    }
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m == 0) return '${s}s';
    return '${m}m';
  }

  IconData _completionIcon(String type) {
    switch (type) {
      case 'completed':
        return Icons.check_circle;
      case 'stopped':
        return Icons.stop_circle;
      default:
        return Icons.circle_outlined;
    }
  }

  Color _completionColor(String type) {
    switch (type) {
      case 'completed':
        return AppTheme.successColor;
      case 'stopped':
        return AppTheme.accentColor;
      default:
        return AppTheme.textHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final timeFormat = DateFormat.Hm();
    final startTime = timeFormat.format(session.startedAt);
    final endTime = session.endedAt != null
        ? timeFormat.format(session.endedAt!)
        : '--:--';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          // Completion type icon
          Icon(
            _completionIcon(session.completionType),
            size: 16,
            color: _completionColor(session.completionType),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          // Time range
          Text(
            '$startTime - $endTime',
            style: TextStyle(
              fontSize: AppTheme.fontSizeXs,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          // Task name
          Expanded(
            child: Text(
              task?.title ?? '—',
              style: TextStyle(
                fontSize: AppTheme.fontSizeSm,
                color: colors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          // Duration
          Text(
            _formatDuration(session.durationSeconds),
            style: TextStyle(
              fontSize: AppTheme.fontSizeSm,
              fontWeight: FontWeight.w600,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

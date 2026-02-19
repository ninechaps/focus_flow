import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../models/focus_session.dart';
import '../../../models/task.dart';

/// 单条专注记录卡片 — 时间段 + 任务名 + 时长 + 完成类型图标
class SessionTimelineItem extends StatefulWidget {
  final FocusSession session;
  final Task? task;

  /// 点击整行时的回调（有任务时可跳转任务详情）
  final VoidCallback? onTap;

  const SessionTimelineItem({
    super.key,
    required this.session,
    this.task,
    this.onTap,
  });

  @override
  State<SessionTimelineItem> createState() => _SessionTimelineItemState();
}

class _SessionTimelineItemState extends State<SessionTimelineItem> {
  bool _isHovered = false;

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
    final startTime = timeFormat.format(widget.session.startedAt);
    final endTime = widget.session.endedAt != null
        ? timeFormat.format(widget.session.endedAt!)
        : '--:--';

    final canTap = widget.onTap != null && widget.task != null;

    return MouseRegion(
      cursor: canTap ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: canTap ? (_) => setState(() => _isHovered = true) : null,
      onExit: canTap ? (_) => setState(() => _isHovered = false) : null,
      child: GestureDetector(
        onTap: canTap ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: AppTheme.spacingSm,
          ),
          decoration: BoxDecoration(
            color: _isHovered
                ? colors.primaryLight
                : colors.background,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Row(
            children: [
              // Completion type icon
              Icon(
                _completionIcon(widget.session.completionType),
                size: 16,
                color: _completionColor(widget.session.completionType),
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
                  widget.task?.title ?? '—',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeSm,
                    color: canTap && _isHovered
                        ? colors.primary
                        : colors.textPrimary,
                    fontWeight: canTap && _isHovered
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              // Duration
              Text(
                _formatDuration(widget.session.durationSeconds),
                style: TextStyle(
                  fontSize: AppTheme.fontSizeSm,
                  fontWeight: FontWeight.w600,
                  color: colors.primary,
                ),
              ),
              // 有任务时显示跳转箭头
              if (canTap) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: _isHovered ? colors.primary : colors.textHint,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

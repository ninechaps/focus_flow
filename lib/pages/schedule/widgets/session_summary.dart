import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';

/// 专注汇总统计 — 总时长 + 专注次数
class SessionSummary extends StatelessWidget {
  final int totalSeconds;
  final int sessionCount;

  const SessionSummary({
    super.key,
    required this.totalSeconds,
    required this.sessionCount,
  });

  String _formatDuration(int seconds) {
    if (seconds >= 3600) {
      final h = seconds ~/ 3600;
      final m = (seconds % 3600) ~/ 60;
      return '${h}h ${m}m';
    }
    final m = seconds ~/ 60;
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              label: l10n.scheduleTotalFocus,
              value: _formatDuration(totalSeconds),
              icon: Icons.timer_outlined,
              color: colors.primary,
            ),
          ),
          Container(
            width: 1,
            height: 32,
            color: colors.divider,
          ),
          Expanded(
            child: _StatItem(
              label: l10n.scheduleFocusCount,
              value: '$sessionCount',
              icon: Icons.bolt_outlined,
              color: AppTheme.accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: AppTheme.fontSizeLg,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: AppTheme.fontSizeXs,
            color: colors.textHint,
          ),
        ),
      ],
    );
  }
}

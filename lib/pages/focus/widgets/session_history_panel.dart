import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/focus_session.dart';
import '../../../theme/app_theme.dart';

/// Shows a dialog with the session history for the current task
void showSessionHistoryDialog({
  required BuildContext context,
  required List<FocusSession> sessions,
}) {
  final colors = context.appColors;
  final l10n = AppLocalizations.of(context)!;
  // Show most recent first
  final displaySessions = sessions.reversed.toList();

  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: colors.dialogSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(color: colors.dialogBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingLg,
                AppTheme.spacingLg,
                AppTheme.spacingMd,
                AppTheme.spacingSm,
              ),
              child: Row(
                children: [
                  Icon(Icons.history, size: 16, color: colors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    l10n.sessionHistoryTitle,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeLg,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, size: 18, color: colors.textHint),
                    splashRadius: 16,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: colors.divider),

            // Session list
            Flexible(
              child: displaySessions.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingXl),
                      child: Text(
                        l10n.noSessionsYet,
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeSm,
                          color: colors.textHint,
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingLg,
                        vertical: AppTheme.spacingMd,
                      ),
                      itemCount: displaySessions.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppTheme.spacingXs),
                      itemBuilder: (context, index) =>
                          _SessionRow(session: displaySessions[index]),
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SessionRow extends StatelessWidget {
  final FocusSession session;

  const _SessionRow({required this.session});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isCompleted = session.completionType == 'completed';
    final isCountUp = session.timerMode == 'countUp';
    final timeFormat = DateFormat('HH:mm');

    final startStr = timeFormat.format(session.startedAt);
    final endStr = session.endedAt != null
        ? timeFormat.format(session.endedAt!)
        : '--:--';
    final durationMin = session.durationSeconds ~/ 60;
    final durationSec = session.durationSeconds % 60;
    final durationStr = durationMin > 0
        ? '${durationMin}m${durationSec > 0 ? ' ${durationSec}s' : ''}'
        : '${durationSec}s';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          // Completion type icon
          Icon(
            isCompleted ? Icons.check_circle : Icons.stop_circle,
            size: 14,
            color: isCompleted ? AppTheme.successColor : colors.textHint,
          ),
          const SizedBox(width: 8),

          // Time range
          Text(
            '$startStr - $endStr',
            style: TextStyle(
              fontSize: AppTheme.fontSizeSm,
              color: colors.textSecondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 10),

          // Duration
          Text(
            durationStr,
            style: TextStyle(
              fontSize: AppTheme.fontSizeSm,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),

          const Spacer(),

          // Timer mode icon
          Icon(
            isCountUp ? Icons.timer : Icons.hourglass_bottom,
            size: 12,
            color: colors.textHint,
          ),
        ],
      ),
    );
  }
}

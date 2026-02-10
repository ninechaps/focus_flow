import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../../models/focus_session.dart';
import '../../../models/task.dart';
import 'session_summary.dart';
import 'session_timeline_item.dart';

/// 回顾面板 — 汇总卡 + 时间线列表
class ReviewPanel extends StatelessWidget {
  final List<FocusSession> sessions;
  final Map<String, Task> taskMap;

  const ReviewPanel({
    super.key,
    required this.sessions,
    required this.taskMap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;

    final totalSeconds =
        sessions.fold<int>(0, (sum, s) => sum + s.durationSeconds);

    // Sort by start time descending
    final sorted = List.of(sessions)
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

    return Column(
      children: [
        // Summary card
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
        // Timeline list
        Expanded(
          child: sorted.isEmpty
              ? Center(
                  child: Text(
                    l10n.scheduleNoSessions,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeMd,
                      color: colors.textHint,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  itemCount: sorted.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppTheme.spacingSm),
                  itemBuilder: (context, index) {
                    final session = sorted[index];
                    return SessionTimelineItem(
                      session: session,
                      task: taskMap[session.taskId],
                    );
                  },
                ),
        ),
      ],
    );
  }
}

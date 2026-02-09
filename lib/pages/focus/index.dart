import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../providers/focus_provider.dart';
import '../../providers/task_provider.dart';
import '../../models/task.dart';
import '../../models/goal.dart';
import '../../models/enums.dart';
import '../../models/pomodoro_preset.dart';
import '../list/widgets/tips_panel.dart';
import 'widgets/session_history_panel.dart';

/// Focus page with Pomodoro-style timer
class FocusPage extends StatefulWidget {
  final String taskId;

  const FocusPage({super.key, required this.taskId});

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  Task? _parentTask;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFocus();
      // Immediately start the timer after initialization
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final focusProvider = context.read<FocusProvider>();
          // Start the timer immediately
          focusProvider.start();
        }
      });
    });
  }

  void _initializeFocus() {
    final taskProvider = context.read<TaskProvider>();
    final focusProvider = context.read<FocusProvider>();

    // Find the task
    final allTasks = taskProvider.tasks;
    final task = allTasks.firstWhere(
      (t) => t.id == widget.taskId,
      orElse: () => throw Exception('Task not found'),
    );

    // Find parent task if exists
    if (task.parentTaskId != null) {
      try {
        _parentTask = allTasks.firstWhere((t) => t.id == task.parentTaskId);
      } catch (_) {
        _parentTask = null;
      }
    }

    // Start focus session
    focusProvider.startFocusSession(task);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Consumer<FocusProvider>(
      builder: (context, focusProvider, child) {
        final task = focusProvider.currentTask;

        if (task == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final taskProvider = context.read<TaskProvider>();

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: colors.background,
          endDrawer: Drawer(
            width: TipsPanel.width,
            shape: const RoundedRectangleBorder(),
            child: TipsPanel(
              goals: taskProvider.goals,
              tasks: taskProvider.tasks,
              selectedTaskId: task.id,
              showFocusButton: false,
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Header with back button, history, and task detail
                _FocusHeader(
                  onBack: () => _handleBack(context, focusProvider),
                  onShowHistory: focusProvider.taskSessions.isNotEmpty
                      ? () => _showSessionHistory(context, focusProvider)
                      : null,
                  onShowTaskDetail: () =>
                      _scaffoldKey.currentState?.openEndDrawer(),
                ),

                const SizedBox(height: AppTheme.spacingMd),

                // Task hierarchy display
                _TaskHierarchyDisplay(
                  task: task,
                  parentTask: _parentTask,
                  goal: task.goal ?? _parentTask?.goal,
                ),

                const SizedBox(height: AppTheme.spacingLg),

                // Timer mode selector - always visible but disabled when running
                _TimerModeSelector(
                  currentMode: focusProvider.timerMode,
                  onModeChanged: focusProvider.setTimerMode,
                ),

                const SizedBox(height: AppTheme.spacingSm),

                // Timer display
                Expanded(
                  child: Center(
                    child: _TimerDisplay(
                      formattedTime: focusProvider.formattedTime,
                      progress: focusProvider.progress,
                      isRunning: focusProvider.isRunning,
                      state: focusProvider.state,
                      timerMode: focusProvider.timerMode,
                    ),
                  ),
                ),

                // Preset selector (for consistent layout between modes)
                SizedBox(
                  height: 52,
                  child: focusProvider.isCountdown
                    ? _PresetSelector(
                        selectedMinutes: focusProvider.targetMinutes,
                        currentPreset: focusProvider.currentPreset,
                        onPresetSelected: focusProvider.selectPreset,
                        onCustomMinutes: (minutes) {
                          focusProvider.clearPreset();
                          focusProvider.setTargetMinutes(minutes);
                        },
                      )
                    : const Offstage(),
                ),

                const SizedBox(height: AppTheme.spacingLg),

                // Timer controls
                _TimerControls(
                  state: focusProvider.state,
                  timerMode: focusProvider.timerMode,
                  onStart: focusProvider.start,
                  onPause: focusProvider.pause,
                  onResume: focusProvider.resume,
                  onStop: () => _handleStop(context, focusProvider),
                  onNextSession: focusProvider.resetForNextSession,
                  onFinish: () => _handleFinish(context, focusProvider),
                  onStartBreak: focusProvider.startBreak,
                  onSkipBreak: focusProvider.skipBreak,
                  hasBreak: focusProvider.hasBreak,
                ),

                const SizedBox(height: AppTheme.spacingLg),

                // Session info
                _SessionInfo(
                  completedSessions: focusProvider.completedSessions,
                  sessionTime: focusProvider.formattedSessionTime,
                  totalTime: focusProvider.formattedElapsedTime,
                  state: focusProvider.state,
                  timerMode: focusProvider.timerMode,
                ),

                const SizedBox(height: AppTheme.spacingXl),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleBack(BuildContext context, FocusProvider focusProvider) async {
    if (focusProvider.isActive) {
      final l10n = AppLocalizations.of(context)!;
      final shouldLeave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.stopFocusTitle),
          content: Text(
            l10n.stopFocusContent,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.stopAndLeave),
            ),
          ],
        ),
      );

      if (shouldLeave == true) {
        await focusProvider.stop();
        if (!context.mounted) return;
        await context.read<TaskProvider>().refresh();
        if (context.mounted) {
          context.go('/app/list');
        }
      }
    } else {
      focusProvider.clearFocus();
      context.go('/app/list');
    }
  }

  Future<void> _handleStop(BuildContext context, FocusProvider focusProvider) async {
    await focusProvider.stop();
    if (!context.mounted) return;
    await context.read<TaskProvider>().refresh();
    if (context.mounted) {
      context.go('/app/list');
    }
  }

  Future<void> _handleFinish(BuildContext context, FocusProvider focusProvider) async {
    await focusProvider.completeSession();
  }

  void _showSessionHistory(BuildContext context, FocusProvider focusProvider) {
    showSessionHistoryDialog(
      context: context,
      sessions: focusProvider.taskSessions,
    );
  }
}

/// Header with back button, history button, and task detail button
class _FocusHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback? onShowHistory;
  final VoidCallback? onShowTaskDetail;

  const _FocusHeader({
    required this.onBack,
    this.onShowHistory,
    this.onShowTaskDetail,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;

    ButtonStyle buttonStyle() => IconButton.styleFrom(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colors.divider),
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, size: 20),
            tooltip: l10n.backToList,
            style: buttonStyle(),
          ),
          const Spacer(),
          Text(
            l10n.focusModeTitle,
            style: TextStyle(
              fontSize: AppTheme.fontSizeMd,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onShowHistory != null) ...[
                IconButton(
                  onPressed: onShowHistory,
                  icon: const Icon(Icons.history, size: 20),
                  tooltip: l10n.sessionHistory,
                  style: buttonStyle(),
                ),
                const SizedBox(width: 4),
              ],
              IconButton(
                onPressed: onShowTaskDetail,
                icon: const Icon(Icons.info_outline, size: 20),
                tooltip: l10n.taskDetail,
                style: buttonStyle(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Minimal task display - focused and clean
class _TaskHierarchyDisplay extends StatelessWidget {
  final Task task;
  final Task? parentTask;
  final Goal? goal;

  const _TaskHierarchyDisplay({
    required this.task,
    this.parentTask,
    this.goal,
  });

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return const Color(0xFFEF4444);
      case TaskPriority.medium:
        return const Color(0xFFF59E0B);
      case TaskPriority.low:
        return const Color(0xFF22C55E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final priorityColor = _getPriorityColor(task.priority);
    final hasGoal = goal != null;
    final hasParent = parentTask != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Breadcrumb (single line, subtle)
          if (hasGoal || hasParent)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                [
                  if (hasGoal) goal!.name,
                  if (hasParent) parentTask!.title,
                ].join(' / '),
                style: TextStyle(
                  fontSize: AppTheme.fontSizeXs,
                  color: colors.textHint,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // Task title with priority indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Priority dot
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: priorityColor,
                  shape: BoxShape.circle,
                ),
              ),
              // Task title
              Flexible(
                child: Text(
                  task.title,
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeLg,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Timer mode selector (Countdown vs Count-up)
class _TimerModeSelector extends StatelessWidget {
  final TimerMode currentMode;
  final ValueChanged<TimerMode> onModeChanged;

  const _TimerModeSelector({
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Consumer<FocusProvider>(
      builder: (context, focusProvider, child) {
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: colors.divider),
          ),
          child: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ModeButton(
                    icon: Icons.hourglass_bottom,
                    label: l10n.timerCountdown,
                    isSelected: currentMode == TimerMode.countdown,
                    onTap: () => onModeChanged(TimerMode.countdown),
                  ),
                  const SizedBox(width: 4),
                  _ModeButton(
                    icon: Icons.timer,
                    label: l10n.timerStopwatch,
                    isSelected: currentMode == TimerMode.countUp,
                    onTap: () => onModeChanged(TimerMode.countUp),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

/// Individual mode button
class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isEnabled = onTap != null;
    return MouseRegion(
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: isEnabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? colors.primary : (isEnabled ? Colors.transparent : colors.surface.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: isEnabled ? null : Border.all(color: colors.divider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? (isEnabled ? Colors.white : colors.textHint) : (isEnabled ? colors.textSecondary : colors.textHint),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppTheme.fontSizeSm,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? (isEnabled ? Colors.white : colors.textHint) : (isEnabled ? colors.textSecondary : colors.textHint),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Circular timer display with progress
class _TimerDisplay extends StatelessWidget {
  final String formattedTime;
  final double progress;
  final bool isRunning;
  final FocusState state;
  final TimerMode timerMode;

  const _TimerDisplay({
    required this.formattedTime,
    required this.progress,
    required this.isRunning,
    required this.state,
    required this.timerMode,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;
    final isCompleted = state == FocusState.completed;
    final isBreak = state == FocusState.breaking;
    final isCountUp = timerMode == TimerMode.countUp;

    // Break uses green/teal, completed uses success, otherwise primary
    final Color displayColor;
    if (isBreak) {
      displayColor = AppTheme.accentColor;
    } else if (isCompleted) {
      displayColor = AppTheme.successColor;
    } else {
      displayColor = colors.primary;
    }

    String statusLabel;
    if (isBreak) {
      statusLabel = l10n.statusBreakTime;
    } else if (isRunning) {
      statusLabel = isCountUp ? l10n.statusTracking : l10n.statusFocusing;
    } else if (state == FocusState.paused) {
      statusLabel = l10n.statusPaused;
    } else {
      statusLabel = l10n.statusTapStart;
    }

    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: displayColor.withValues(alpha: 0.05),
            ),
          ),

          // Progress arc
          SizedBox(
            width: 240,
            height: 240,
            child: CustomPaint(
              painter: _ProgressArcPainter(
                progress: progress,
                color: displayColor,
                backgroundColor: colors.divider,
                isCountUp: isCountUp,
              ),
            ),
          ),

          // Timer text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isCompleted)
                Icon(
                  Icons.check_circle,
                  size: 48,
                  color: AppTheme.successColor,
                ),
              if (isBreak)
                Icon(
                  Icons.coffee,
                  size: 48,
                  color: AppTheme.accentColor,
                ),
              if (isCompleted || isBreak) const SizedBox(height: AppTheme.spacingSm),
              Text(
                isCompleted ? l10n.statusComplete : formattedTime,
                style: TextStyle(
                  fontSize: isCompleted ? AppTheme.fontSizeXl : AppTheme.fontSizeDisplay,
                  fontWeight: FontWeight.w300,
                  color: colors.textPrimary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              if (!isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: displayColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeSm,
                      fontWeight: FontWeight.w500,
                      color: displayColor,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the progress arc
class _ProgressArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final bool isCountUp;

  _ProgressArcPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    this.isCountUp = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 8.0;

    // Background arc
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ProgressArcPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isCountUp != isCountUp;
  }
}

/// Timer control buttons
class _TimerControls extends StatelessWidget {
  final FocusState state;
  final TimerMode timerMode;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;
  final VoidCallback onNextSession;
  final VoidCallback onFinish;
  final VoidCallback onStartBreak;
  final VoidCallback onSkipBreak;
  final bool hasBreak;

  const _TimerControls({
    required this.state,
    required this.timerMode,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    required this.onNextSession,
    required this.onFinish,
    required this.onStartBreak,
    required this.onSkipBreak,
    required this.hasBreak,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isCountUp = timerMode == TimerMode.countUp;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (state == FocusState.ready)
          _ControlButton(
            icon: Icons.play_arrow,
            label: l10n.controlStart,
            onPressed: () {
              onStart();
            },
            isPrimary: true,
            size: 72,
          ),

        if (state == FocusState.running) ...[
          _ControlButton(
            icon: Icons.pause,
            label: l10n.controlPause,
            onPressed: onPause,
            isPrimary: true,
            size: 72,
          ),
          const SizedBox(width: AppTheme.spacingLg),
          if (isCountUp)
            _ControlButton(
              icon: Icons.check,
              label: l10n.controlFinish,
              onPressed: onFinish,
              isPrimary: false,
              size: 60,
            )
          else
            _ControlButton(
              icon: Icons.stop,
              label: l10n.controlStop,
              onPressed: onStop,
              isPrimary: false,
              size: 60,
            ),
        ],

        if (state == FocusState.paused) ...[
          _ControlButton(
            icon: Icons.play_arrow,
            label: l10n.controlResume,
            onPressed: onResume,
            isPrimary: true,
            size: 72,
          ),
          const SizedBox(width: AppTheme.spacingLg),
          if (isCountUp)
            _ControlButton(
              icon: Icons.check,
              label: l10n.controlFinish,
              onPressed: onFinish,
              isPrimary: false,
              size: 60,
            )
          else
            _ControlButton(
              icon: Icons.stop,
              label: l10n.controlStop,
              onPressed: onStop,
              isPrimary: false,
              size: 60,
            ),
        ],

        // Completed with break available
        if (state == FocusState.completed && hasBreak) ...[
          _ControlButton(
            icon: Icons.coffee,
            label: l10n.controlBreak,
            onPressed: onStartBreak,
            isPrimary: true,
            size: 72,
          ),
          const SizedBox(width: AppTheme.spacingLg),
          _ControlButton(
            icon: Icons.skip_next,
            label: l10n.controlSkip,
            onPressed: onNextSession,
            isPrimary: false,
            size: 60,
          ),
          const SizedBox(width: AppTheme.spacingLg),
          _ControlButton(
            icon: Icons.check,
            label: l10n.controlDone,
            onPressed: onStop,
            isPrimary: false,
            size: 60,
          ),
        ],

        // Completed without break
        if (state == FocusState.completed && !hasBreak) ...[
          _ControlButton(
            icon: Icons.replay,
            label: l10n.controlAgain,
            onPressed: onNextSession,
            isPrimary: true,
            size: 72,
          ),
          const SizedBox(width: AppTheme.spacingLg),
          _ControlButton(
            icon: Icons.check,
            label: l10n.controlDone,
            onPressed: onStop,
            isPrimary: false,
            size: 60,
          ),
        ],

        // Breaking state
        if (state == FocusState.breaking)
          _ControlButton(
            icon: Icons.skip_next,
            label: l10n.controlSkip,
            onPressed: onSkipBreak,
            isPrimary: false,
            size: 72,
          ),
      ],
    );
  }
}

/// Individual control button
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final double size;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.isPrimary,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: isPrimary ? colors.primary : colors.surface,
              shape: BoxShape.circle,
              border: isPrimary
                  ? null
                  : Border.all(color: colors.divider, width: 1),
              boxShadow: isPrimary
                  ? [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(size / 2),
                child: Icon(
                  icon,
                  color: isPrimary ? Colors.white : colors.textSecondary,
                  size: size * 0.4,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Text(
          label,
          style: TextStyle(
            fontSize: AppTheme.fontSizeXs,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Preset selector with Pomodoro presets and custom option
class _PresetSelector extends StatefulWidget {
  final int selectedMinutes;
  final PomodoroPreset? currentPreset;
  final ValueChanged<PomodoroPreset> onPresetSelected;
  final ValueChanged<int> onCustomMinutes;

  const _PresetSelector({
    required this.selectedMinutes,
    required this.currentPreset,
    required this.onPresetSelected,
    required this.onCustomMinutes,
  });

  @override
  State<_PresetSelector> createState() => _PresetSelectorState();
}

class _PresetSelectorState extends State<_PresetSelector> {
  bool _showCustom = false;

  bool get _isCustom =>
      widget.currentPreset == null &&
      !PomodoroPreset.defaults.any((p) => p.workMinutes == widget.selectedMinutes);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (_showCustom) {
      return _CustomMinutesPicker(
        selectedMinutes: widget.selectedMinutes,
        onChanged: (minutes) {
          widget.onCustomMinutes(minutes);
          setState(() => _showCustom = false);
        },
        onCancel: () => setState(() => _showCustom = false),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, size: 16, color: colors.textSecondary),
          const SizedBox(width: AppTheme.spacingSm),
          for (final preset in PomodoroPreset.defaults) ...[
            _PresetChip(
              label: '${preset.name} ${preset.workMinutes}m',
              isSelected: widget.currentPreset?.id == preset.id ||
                  (widget.currentPreset == null && widget.selectedMinutes == preset.workMinutes),
              onTap: () => widget.onPresetSelected(preset),
            ),
            const SizedBox(width: 6),
          ],
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return _PresetChip(
                label: _isCustom ? '${widget.selectedMinutes}m' : l10n.custom,
                isSelected: _isCustom,
                onTap: () => setState(() => _showCustom = true),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Single preset chip button
class _PresetChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? colors.primary : colors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(
              color: isSelected ? colors.primary : colors.divider,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppTheme.fontSizeXs,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Inline minute picker for custom duration
class _CustomMinutesPicker extends StatelessWidget {
  final int selectedMinutes;
  final ValueChanged<int> onChanged;
  final VoidCallback onCancel;

  const _CustomMinutesPicker({
    required this.selectedMinutes,
    required this.onChanged,
    required this.onCancel,
  });

  static const _options = [5, 10, 15, 20, 30, 40, 45, 60, 90, 120];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onCancel,
              child: Icon(Icons.arrow_back, size: 16, color: colors.textSecondary),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          for (final minutes in _options) ...[
            _PresetChip(
              label: '${minutes}m',
              isSelected: selectedMinutes == minutes,
              onTap: () => onChanged(minutes),
            ),
            if (minutes != _options.last) const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}

/// Session information display
class _SessionInfo extends StatelessWidget {
  final int completedSessions;
  final String sessionTime;
  final String totalTime;
  final FocusState state;
  final TimerMode timerMode;

  const _SessionInfo({
    required this.completedSessions,
    required this.sessionTime,
    required this.totalTime,
    required this.state,
    required this.timerMode,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: colors.divider),
      ),
      child: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context)!;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _InfoItem(
                icon: Icons.play_arrow,
                label: l10n.infoThisSession,
                value: sessionTime,
              ),
              Container(
                width: 1,
                height: 20,
                color: colors.divider,
              ),
              _InfoItem(
                icon: Icons.hourglass_full,
                label: l10n.infoTotalFocus,
                value: totalTime,
              ),
              Container(
                width: 1,
                height: 20,
                color: colors.divider,
              ),
              _InfoItem(
                icon: Icons.check_circle_outline,
                label: l10n.infoSessions,
                value: '$completedSessions',
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Info item for session info
class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colors.primary),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: AppTheme.fontSizeXs - 1,
                color: colors.textHint,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: AppTheme.fontSizeSm,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

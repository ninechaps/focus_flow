import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/focus_provider.dart';
import '../../providers/task_provider.dart';
import '../../models/task.dart';
import '../../models/goal.dart';
import '../../models/enums.dart';

/// Focus page with Pomodoro-style timer
class FocusPage extends StatefulWidget {
  final String taskId;

  const FocusPage({super.key, required this.taskId});

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> {
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

        return Scaffold(
          backgroundColor: colors.background,
          body: SafeArea(
            child: Column(
              children: [
                // Header with back button
                _FocusHeader(
                  onBack: () => _handleBack(context, focusProvider),
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

                // Duration selector placeholder (for consistent layout between modes)
                SizedBox(
                  height: 52, // Fixed height for both modes
                  child: focusProvider.isCountdown
                    ? _DurationSelector(
                        selectedMinutes: focusProvider.targetMinutes,
                        onChanged: focusProvider.setTargetMinutes,
                      )
                    : const Offstage(), // Hidden but still takes up space
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
      final shouldLeave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Stop focus session?'),
          content: const Text(
            'Your progress will be saved, but the timer will stop.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Stop & Leave'),
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
}

/// Header with back button
class _FocusHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _FocusHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
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
            tooltip: 'Back to list',
            style: IconButton.styleFrom(
              backgroundColor: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: colors.divider),
              ),
            ),
          ),
          const Spacer(),
          Text(
            'Focus Mode',
            style: TextStyle(
              fontSize: AppTheme.fontSizeMd,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 40),
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ModeButton(
                icon: Icons.hourglass_bottom,
                label: 'Countdown',
                isSelected: currentMode == TimerMode.countdown,
                onTap: () => onModeChanged(TimerMode.countdown),
              ),
              const SizedBox(width: 4),
              _ModeButton(
                icon: Icons.timer,
                label: 'Stopwatch',
                isSelected: currentMode == TimerMode.countUp,
                onTap: () => onModeChanged(TimerMode.countUp),
              ),
            ],
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
    final isCompleted = state == FocusState.completed;
    final displayColor = isCompleted ? AppTheme.successColor : colors.primary;
    final isCountUp = timerMode == TimerMode.countUp;

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
              if (isCompleted) const SizedBox(height: AppTheme.spacingSm),
              Text(
                isCompleted ? 'Complete!' : formattedTime,
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
                    isRunning
                        ? (isCountUp ? 'Tracking' : 'Focusing')
                        : (state == FocusState.paused ? 'Paused' : 'Tap Start to Begin'),
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

  const _TimerControls({
    required this.state,
    required this.timerMode,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    required this.onNextSession,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final isCountUp = timerMode == TimerMode.countUp;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (state == FocusState.ready)
          _ControlButton(
            icon: Icons.play_arrow,
            label: 'Start',
            onPressed: () {
              onStart();
            },
            isPrimary: true,
            size: 72,
          ),

        if (state == FocusState.running) ...[
          _ControlButton(
            icon: Icons.pause,
            label: 'Pause',
            onPressed: onPause,
            isPrimary: true,
            size: 72,
          ),
          const SizedBox(width: AppTheme.spacingLg),
          if (isCountUp)
            _ControlButton(
              icon: Icons.check,
              label: 'Finish',
              onPressed: onFinish,
              isPrimary: false,
              size: 60,
            )
          else
            _ControlButton(
              icon: Icons.stop,
              label: 'Stop',
              onPressed: onStop,
              isPrimary: false,
              size: 60,
            ),
        ],

        if (state == FocusState.paused) ...[
          _ControlButton(
            icon: Icons.play_arrow,
            label: 'Resume',
            onPressed: onResume,
            isPrimary: true,
            size: 72,
          ),
          const SizedBox(width: AppTheme.spacingLg),
          if (isCountUp)
            _ControlButton(
              icon: Icons.check,
              label: 'Finish',
              onPressed: onFinish,
              isPrimary: false,
              size: 60,
            )
          else
            _ControlButton(
              icon: Icons.stop,
              label: 'Stop',
              onPressed: onStop,
              isPrimary: false,
              size: 60,
            ),
        ],

        if (state == FocusState.completed) ...[
          _ControlButton(
            icon: Icons.replay,
            label: 'Again',
            onPressed: onNextSession,
            isPrimary: true,
            size: 72,
          ),
          const SizedBox(width: AppTheme.spacingLg),
          _ControlButton(
            icon: Icons.check,
            label: 'Done',
            onPressed: onStop,
            isPrimary: false,
            size: 60,
          ),
        ],
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

/// Duration selector with preset options
class _DurationSelector extends StatelessWidget {
  final int selectedMinutes;
  final ValueChanged<int> onChanged;

  const _DurationSelector({
    required this.selectedMinutes,
    required this.onChanged,
  });

  static const _presets = [15, 25, 45, 60];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Consumer<FocusProvider>(
      builder: (context, focusProvider, child) {
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
              Icon(
                Icons.schedule,
                size: 16,
                color: colors.textSecondary,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              for (final minutes in _presets) ...[
                _DurationChip(
                  minutes: minutes,
                  isSelected: selectedMinutes == minutes,
                  onTap: () => onChanged(minutes),
                ),
                if (minutes != _presets.last) const SizedBox(width: 6),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Individual duration chip
class _DurationChip extends StatelessWidget {
  final int minutes;
  final bool isSelected;
  final VoidCallback? onTap;

  const _DurationChip({
    required this.minutes,
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected 
                ? colors.primary 
                : (isEnabled ? colors.surface : colors.surface.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(
              color: isSelected 
                  ? colors.primary 
                  : (isEnabled ? colors.divider : colors.divider.withValues(alpha: 0.5)),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.access_time,
                size: 14,
                color: isSelected ? (isEnabled ? Colors.white : colors.textHint) : (isEnabled ? colors.textSecondary : colors.textHint),
              ),
              const SizedBox(width: 4),
              Text(
                '$minutes min',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeSm,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _InfoItem(
            icon: Icons.play_arrow,
            label: 'This Session',
            value: sessionTime,
          ),
          Container(
            width: 1,
            height: 20,
            color: colors.divider,
          ),
          _InfoItem(
            icon: Icons.hourglass_full,
            label: 'Total Focus',
            value: totalTime,
          ),
          Container(
            width: 1,
            height: 20,
            color: colors.divider,
          ),
          _InfoItem(
            icon: Icons.check_circle_outline,
            label: 'Sessions',
            value: '$completedSessions',
          ),
        ],
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

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../repositories/interfaces/task_repository_interface.dart';
import '../repositories/repository_provider.dart';

/// States for the focus timer
enum FocusState {
  idle,      // No task selected
  ready,     // Task selected, timer not started
  running,   // Timer actively running
  paused,    // Timer paused
  completed, // Focus session completed
}

/// Timer modes
enum TimerMode {
  countdown, // Count down from target duration
  countUp,   // Count up (stopwatch mode)
}

/// Provider for managing focus timer state
class FocusProvider extends ChangeNotifier {
  static const String _timerModeKey = 'focus_timer_mode';

  final ITaskRepository _taskRepository;

  // Current focus state
  FocusState _state = FocusState.idle;
  Task? _currentTask;

  // Timer state
  int _elapsedSeconds = 0;        // Current elapsed time (includes previous focus time)
  int _sessionStartSeconds = 0;   // Value of elapsedSeconds when session started (for saving only new time)
  int _targetMinutes = 25;        // Default Pomodoro duration
  Timer? _timer;
  TimerMode _timerMode = TimerMode.countdown;
  TimerMode _savedTimerMode = TimerMode.countdown; // Persisted mode (only updated on start)

  // Session tracking
  int _completedSessions = 0;

  FocusProvider({ITaskRepository? taskRepository})
      : _taskRepository = taskRepository ?? RepositoryProvider.instance.taskRepository {
    _loadSavedTimerMode();
  }

  /// Load the saved timer mode from persistent storage
  Future<void> _loadSavedTimerMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_timerModeKey);
      if (savedMode != null) {
        _savedTimerMode = savedMode == 'countUp' ? TimerMode.countUp : TimerMode.countdown;
        _timerMode = _savedTimerMode;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load timer mode: $e');
    }
  }

  /// Save the timer mode to persistent storage
  Future<void> _saveTimerMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_timerModeKey, _timerMode == TimerMode.countUp ? 'countUp' : 'countdown');
      _savedTimerMode = _timerMode;
    } catch (e) {
      debugPrint('Failed to save timer mode: $e');
    }
  }

  // Getters
  FocusState get state => _state;
  Task? get currentTask => _currentTask;
  int get elapsedSeconds => _elapsedSeconds;
  int get targetMinutes => _targetMinutes;
  int get targetSeconds => _targetMinutes * 60;
  int get remainingSeconds => (targetSeconds - _elapsedSeconds).clamp(0, targetSeconds);
  int get completedSessions => _completedSessions;
  TimerMode get timerMode => _timerMode;

  bool get isRunning => _state == FocusState.running;
  bool get isPaused => _state == FocusState.paused;
  bool get isActive => _state == FocusState.running || _state == FocusState.paused;
  bool get isCountdown => _timerMode == TimerMode.countdown;
  bool get isCountUp => _timerMode == TimerMode.countUp;

  /// Time added in this session only
  int get sessionSeconds => _elapsedSeconds - _sessionStartSeconds;

  /// Progress as a percentage (0.0 to 1.0)
  /// For countdown: progress towards target
  /// For count-up: always shows based on elapsed vs target (or 0 if no target)
  double get progress {
    if (_timerMode == TimerMode.countUp) {
      // In count-up mode, show progress based on a reasonable max (e.g., 2 hours)
      // Or cap at 1.0 if elapsed exceeds the reference
      return (_elapsedSeconds / 7200).clamp(0.0, 1.0); // 2 hours max
    }
    return targetSeconds > 0 ? (_elapsedSeconds / targetSeconds).clamp(0.0, 1.0) : 0.0;
  }

  /// Formatted time string based on current mode
  String get formattedTime {
    if (_timerMode == TimerMode.countUp) {
      return formattedElapsedTime;
    }
    // Countdown mode
    final remaining = remainingSeconds.clamp(0, targetSeconds);
    final minutes = remaining ~/ 60;
    final seconds = remaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Formatted elapsed time string (MM:SS or HH:MM:SS)
  String get formattedElapsedTime {
    if (_elapsedSeconds >= 3600) {
      final hours = _elapsedSeconds ~/ 3600;
      final minutes = (_elapsedSeconds % 3600) ~/ 60;
      final seconds = _elapsedSeconds % 60;
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Formatted session time string (time added this session only)
  String get formattedSessionTime {
    final session = sessionSeconds;
    if (session >= 3600) {
      final hours = session ~/ 3600;
      final minutes = (session % 3600) ~/ 60;
      final seconds = session % 60;
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    final minutes = session ~/ 60;
    final seconds = session % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Start focusing on a task - resumes from previous focus time
  void startFocusSession(Task task, {int? durationMinutes}) {
    _currentTask = task;
    _targetMinutes = durationMinutes ?? 25;
    // Resume from previous focus time
    _elapsedSeconds = task.focusDuration;
    _sessionStartSeconds = task.focusDuration;
    _state = FocusState.ready;
    notifyListeners();
  }

  /// Toggle between countdown and count-up modes
  void toggleTimerMode() {
    // Allow changing mode even while running - this will affect the display but not the timer
    _timerMode = _timerMode == TimerMode.countdown
        ? TimerMode.countUp
        : TimerMode.countdown;
    notifyListeners();
  }

  /// Set timer mode directly
  void setTimerMode(TimerMode mode) {
    // Allow changing mode even while running - this will affect the display but not the timer
    _timerMode = mode;
    notifyListeners();
  }

  /// Start or resume the timer
  void start() {
    if (_currentTask == null) return;

    _state = FocusState.running;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);

    // Save the timer mode when actually starting (not just switching)
    _saveTimerMode();

    notifyListeners();
  }

  /// Pause the timer
  void pause() {
    if (_state != FocusState.running) return;

    _timer?.cancel();
    _state = FocusState.paused;
    notifyListeners();
  }

  /// Resume the timer
  void resume() {
    if (_state != FocusState.paused) return;
    start();
  }

  /// Stop the session and save progress
  Future<void> stop() async {
    _timer?.cancel();

    // Save only the NEW time added in this session
    if (_currentTask != null && sessionSeconds > 0) {
      await _saveFocusDuration();
    }

    _state = FocusState.idle;
    _currentTask = null;
    _elapsedSeconds = 0;
    _sessionStartSeconds = 0;
    notifyListeners();
  }

  /// Complete the current session
  Future<void> completeSession() async {
    _timer?.cancel();
    _completedSessions++;

    // Save only the NEW time added in this session
    if (_currentTask != null && sessionSeconds > 0) {
      await _saveFocusDuration();
    }

    _state = FocusState.completed;
    notifyListeners();
  }

  /// Reset for another session with the same task
  void resetForNextSession() {
    // Update session start to current elapsed (so next session tracks new time)
    _sessionStartSeconds = _elapsedSeconds;
    _state = FocusState.ready;
    notifyListeners();
  }

  /// Change target duration (even when running - affects countdown calculations)
  void setTargetMinutes(int minutes) {
    _targetMinutes = minutes.clamp(1, 120);
    notifyListeners();
  }

  /// Clear focus and reset all state
  void clearFocus() {
    _timer?.cancel();
    _state = FocusState.idle;
    _currentTask = null;
    _elapsedSeconds = 0;
    _sessionStartSeconds = 0;
    _completedSessions = 0;
    // Restore to saved timer mode (not reset to countdown)
    _timerMode = _savedTimerMode;
    notifyListeners();
  }

  void _tick(Timer timer) {
    _elapsedSeconds++;

    // Only auto-complete in countdown mode when elapsed reaches target
    if (_timerMode == TimerMode.countdown && _elapsedSeconds >= targetSeconds) {
      completeSession();
    } else {
      notifyListeners();
    }
  }

  Future<void> _saveFocusDuration() async {
    final newTime = sessionSeconds;
    if (_currentTask == null || newTime <= 0) return;

    try {
      // Only save the NEW time added in this session
      await _taskRepository.addFocusDuration(_currentTask!.id, newTime);
    } catch (e) {
      debugPrint('Failed to save focus duration: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

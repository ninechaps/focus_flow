import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/focus_session.dart';
import '../models/pomodoro_preset.dart';
import '../models/task.dart';
import '../repositories/interfaces/focus_session_repository_interface.dart';
import '../repositories/interfaces/task_repository_interface.dart';
import '../repositories/repository_provider.dart';

/// States for the focus timer
enum FocusState {
  idle,      // No task selected
  ready,     // Task selected, timer not started
  running,   // Timer actively running
  paused,    // Timer paused
  completed, // Focus session completed
  breaking,  // Break period active
}

/// Timer modes
enum TimerMode {
  countdown, // Count down from target duration
  countUp,   // Count up (stopwatch mode)
}

/// Provider for managing focus timer state
class FocusProvider extends ChangeNotifier {
  static const String _timerModeKey = 'focus_timer_mode';
  static const _uuid = Uuid();

  final ITaskRepository _taskRepository;
  final IFocusSessionRepository _sessionRepository;

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
  DateTime? _sessionStartTime;

  // Break timer state
  int _breakElapsedSeconds = 0;
  int _breakTargetSeconds = 0;
  Timer? _breakTimer;

  // Today's statistics (from DB)
  int _todayTotalSeconds = 0;
  int _todaySessionCount = 0;

  // Preset
  PomodoroPreset? _currentPreset;

  // Task session history
  List<FocusSession> _taskSessions = [];

  FocusProvider({
    ITaskRepository? taskRepository,
    IFocusSessionRepository? sessionRepository,
  })  : _taskRepository = taskRepository ?? RepositoryProvider.instance.taskRepository,
        _sessionRepository = sessionRepository ?? RepositoryProvider.instance.focusSessionRepository {
    _loadSavedTimerMode();
    _loadTodaySummary();
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

  /// Load today's summary from the database
  Future<void> _loadTodaySummary() async {
    try {
      final response = await _sessionRepository.getTodaySummary();
      if (response.isSuccess && response.data != null) {
        _todayTotalSeconds = response.data!['totalSeconds'] ?? 0;
        _todaySessionCount = response.data!['sessionCount'] ?? 0;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load today summary: $e');
    }
  }

  // Getters
  FocusState get state => _state;
  Task? get currentTask => _currentTask;
  int get elapsedSeconds => _elapsedSeconds;
  int get targetMinutes => _targetMinutes;
  int get targetSeconds => _targetMinutes * 60;
  int get remainingSeconds => (targetSeconds - _elapsedSeconds).clamp(0, targetSeconds);
  TimerMode get timerMode => _timerMode;
  PomodoroPreset? get currentPreset => _currentPreset;

  int get todayTotalSeconds => _todayTotalSeconds;
  int get todaySessionCount => _todaySessionCount;

  /// Completed sessions today (from DB)
  int get completedSessions => _todaySessionCount;

  bool get isRunning => _state == FocusState.running;
  bool get isPaused => _state == FocusState.paused;
  bool get isBreaking => _state == FocusState.breaking;
  bool get isActive => _state == FocusState.running || _state == FocusState.paused || _state == FocusState.breaking;
  bool get isCountdown => _timerMode == TimerMode.countdown;
  bool get isCountUp => _timerMode == TimerMode.countUp;

  /// Whether the current preset has a break period
  bool get hasBreak => _currentPreset != null && _currentPreset!.breakMinutes > 0;

  // Break timer getters
  int get breakRemainingSeconds => (_breakTargetSeconds - _breakElapsedSeconds).clamp(0, _breakTargetSeconds);
  double get breakProgress => _breakTargetSeconds > 0 ? (_breakElapsedSeconds / _breakTargetSeconds).clamp(0.0, 1.0) : 0.0;

  String get formattedBreakTime {
    final remaining = breakRemainingSeconds;
    final minutes = remaining ~/ 60;
    final seconds = remaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Task session history
  List<FocusSession> get taskSessions => _taskSessions;

  /// Time added in this session only
  int get sessionSeconds => _elapsedSeconds - _sessionStartSeconds;

  /// Progress as a percentage (0.0 to 1.0)
  double get progress {
    if (_state == FocusState.breaking) return breakProgress;
    if (_timerMode == TimerMode.countUp) {
      return (_elapsedSeconds / 7200).clamp(0.0, 1.0);
    }
    return targetSeconds > 0 ? (_elapsedSeconds / targetSeconds).clamp(0.0, 1.0) : 0.0;
  }

  /// Formatted time string based on current mode
  String get formattedTime {
    if (_state == FocusState.breaking) return formattedBreakTime;
    if (_timerMode == TimerMode.countUp) {
      return formattedElapsedTime;
    }
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

  /// Formatted today total time string
  String get formattedTodayTotalTime {
    final total = _todayTotalSeconds;
    if (total >= 3600) {
      final hours = total ~/ 3600;
      final minutes = (total % 3600) ~/ 60;
      final seconds = total % 60;
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    final minutes = total ~/ 60;
    final seconds = total % 60;
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
    _loadTaskSessions(task.id);
    notifyListeners();
  }

  /// Toggle between countdown and count-up modes
  void toggleTimerMode() {
    _timerMode = _timerMode == TimerMode.countdown
        ? TimerMode.countUp
        : TimerMode.countdown;
    notifyListeners();
  }

  /// Set timer mode directly
  void setTimerMode(TimerMode mode) {
    _timerMode = mode;
    notifyListeners();
  }

  /// Select a pomodoro preset
  void selectPreset(PomodoroPreset preset) {
    _currentPreset = preset;
    _targetMinutes = preset.workMinutes;
    notifyListeners();
  }

  /// Clear the current preset (switch to custom)
  void clearPreset() {
    _currentPreset = null;
    notifyListeners();
  }

  /// Start or resume the timer
  void start() {
    if (_currentTask == null) return;

    // Record session start time on first start (not resume)
    _sessionStartTime ??= DateTime.now();

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
    _breakTimer?.cancel();

    // Save only the NEW time added in this session
    if (_currentTask != null && sessionSeconds > 0) {
      await _saveFocusDuration();
      await _saveFocusSession('stopped');
    }

    _state = FocusState.idle;
    _currentTask = null;
    _elapsedSeconds = 0;
    _sessionStartSeconds = 0;
    _sessionStartTime = null;
    _currentPreset = null;
    _breakElapsedSeconds = 0;
    _breakTargetSeconds = 0;
    _taskSessions = [];
    notifyListeners();
  }

  /// Complete the current session
  Future<void> completeSession() async {
    _timer?.cancel();

    // Save only the NEW time added in this session
    if (_currentTask != null && sessionSeconds > 0) {
      await _saveFocusDuration();
      await _saveFocusSession('completed');
    }

    _state = FocusState.completed;
    notifyListeners();
  }

  /// Reset for another session with the same task
  void resetForNextSession() {
    // Update session start to current elapsed (so next session tracks new time)
    _sessionStartSeconds = _elapsedSeconds;
    _sessionStartTime = null;
    _state = FocusState.ready;
    notifyListeners();
  }

  /// Change target duration (even when running - affects countdown calculations)
  void setTargetMinutes(int minutes) {
    _targetMinutes = minutes.clamp(1, 120);
    // Clear preset when manually setting minutes (unless it matches)
    if (_currentPreset != null && _currentPreset!.workMinutes != minutes) {
      _currentPreset = null;
    }
    notifyListeners();
  }

  /// Clear focus and reset all state
  void clearFocus() {
    _timer?.cancel();
    _breakTimer?.cancel();
    _state = FocusState.idle;
    _currentTask = null;
    _elapsedSeconds = 0;
    _sessionStartSeconds = 0;
    _sessionStartTime = null;
    _currentPreset = null;
    _breakElapsedSeconds = 0;
    _breakTargetSeconds = 0;
    _taskSessions = [];
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
      await _taskRepository.addFocusDuration(_currentTask!.id, newTime);
    } catch (e) {
      debugPrint('Failed to save focus duration: $e');
    }
  }

  /// Start a break period after completing a focus session
  void startBreak() {
    if (_state != FocusState.completed || _currentPreset == null) return;

    _breakTargetSeconds = _currentPreset!.breakMinutes * 60;
    _breakElapsedSeconds = 0;
    _state = FocusState.breaking;
    _breakTimer?.cancel();
    _breakTimer = Timer.periodic(const Duration(seconds: 1), _breakTick);
    notifyListeners();
  }

  /// Skip the break and go directly back to ready state
  void skipBreak() {
    _breakTimer?.cancel();
    _breakElapsedSeconds = 0;
    _breakTargetSeconds = 0;
    // Reset for next session
    _sessionStartSeconds = _elapsedSeconds;
    _sessionStartTime = null;
    _state = FocusState.ready;
    notifyListeners();
  }

  void _breakTick(Timer timer) {
    _breakElapsedSeconds++;

    if (_breakElapsedSeconds >= _breakTargetSeconds) {
      _breakTimer?.cancel();
      _breakElapsedSeconds = 0;
      _breakTargetSeconds = 0;
      // Reset for next session
      _sessionStartSeconds = _elapsedSeconds;
      _sessionStartTime = null;
      _state = FocusState.ready;
    }

    notifyListeners();
  }

  /// Load session history for a specific task
  Future<void> _loadTaskSessions(String taskId) async {
    try {
      final response = await _sessionRepository.getByTask(taskId);
      if (response.isSuccess && response.data != null) {
        _taskSessions = response.data!;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load task sessions: $e');
    }
  }

  /// Persist a FocusSession record to the database
  Future<void> _saveFocusSession(String completionType) async {
    if (_currentTask == null || sessionSeconds <= 0) return;

    final now = DateTime.now();
    final session = FocusSession(
      id: _uuid.v4(),
      taskId: _currentTask!.id,
      startedAt: _sessionStartTime ?? now,
      endedAt: now,
      durationSeconds: sessionSeconds,
      targetSeconds: _timerMode == TimerMode.countdown ? targetSeconds : 0,
      timerMode: _timerMode.name,
      completionType: completionType,
      createdAt: now,
    );

    try {
      await _sessionRepository.create(session);
      // Refresh today's stats and task sessions after saving
      await _loadTodaySummary();
      if (_currentTask != null) {
        await _loadTaskSessions(_currentTask!.id);
      }
    } catch (e) {
      debugPrint('Failed to save focus session: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breakTimer?.cancel();
    super.dispose();
  }
}

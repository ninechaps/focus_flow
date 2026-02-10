import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../providers/focus_provider.dart';
import '../providers/task_provider.dart';
import 'hotkey_service.dart';
import 'native_tray_service.dart';
import 'notification_service.dart';

/// Localized strings used by the platform integration service.
/// Updated when the locale changes via [updateLocalizedStrings].
class PlatformLocalizedStrings {
  final String trayStartFocus;
  final String trayStart;
  final String trayPause;
  final String trayResume;
  final String traySkipBreak;
  final String trayStop;
  final String trayOpenApp;
  final String trayQuit;
  final String notificationFocusComplete;
  final String Function(String taskName, String duration) notificationFocusBody;
  final String notificationBreakComplete;
  final String notificationBreakBody;
  final String popoverFocusSession;
  final String popoverPause;
  final String popoverStop;
  final String popoverResume;
  final String popoverStart;
  final String popoverThisSession;
  final String popoverTotalFocus;
  final String popoverSessions;
  final String popoverNoActiveFocus;
  final String popoverOpenApp;
  final String popoverFocusing;
  final String popoverPaused;
  final String popoverReady;
  final String popoverCompleted;

  const PlatformLocalizedStrings({
    this.trayStartFocus = '▶ Start Focus',
    this.trayStart = '▶ Start',
    this.trayPause = '⏸ Pause',
    this.trayResume = '▶ Resume',
    this.traySkipBreak = '⏭ Skip Break',
    this.trayStop = '⏹ Stop',
    this.trayOpenApp = 'Open Focus Hut',
    this.trayQuit = 'Quit',
    this.notificationFocusComplete = 'Focus Complete!',
    this.notificationFocusBody = _defaultFocusBody,
    this.notificationBreakComplete = 'Break Over',
    this.notificationBreakBody = 'Ready to start the next focus session',
    this.popoverFocusSession = 'Focus Session',
    this.popoverPause = '⏸ Pause',
    this.popoverStop = '⏹ Stop',
    this.popoverResume = '▶ Resume',
    this.popoverStart = '▶ Start',
    this.popoverThisSession = 'This Session',
    this.popoverTotalFocus = 'Total Focus',
    this.popoverSessions = 'Sessions',
    this.popoverNoActiveFocus = 'No active focus session',
    this.popoverOpenApp = 'Open Focus Hut',
    this.popoverFocusing = 'Focusing',
    this.popoverPaused = 'Paused',
    this.popoverReady = 'Ready',
    this.popoverCompleted = 'Completed',
  });

  static String _defaultFocusBody(String taskName, String duration) =>
      '$taskName — This session: $duration';
}

/// Orchestrator that connects FocusProvider with platform services
/// (tray, hotkeys, notifications). Listens to FocusProvider changes
/// and delegates to the appropriate sub-service.
class PlatformIntegrationService {
  final FocusProvider _focusProvider;
  final TaskProvider _taskProvider;

  final NativeTrayService _trayService;
  final HotkeyService _hotkeyService;
  final NotificationService _notificationService;

  GoRouter? _router;

  /// Localized strings, updated when locale changes
  PlatformLocalizedStrings _strings = const PlatformLocalizedStrings();

  /// Track the previous state to detect transitions
  FocusState _previousState = FocusState.idle;

  PlatformIntegrationService({
    required FocusProvider focusProvider,
    required TaskProvider taskProvider,
    NativeTrayService? trayService,
    HotkeyService? hotkeyService,
    NotificationService? notificationService,
  })  : _focusProvider = focusProvider,
        _taskProvider = taskProvider,
        _trayService = trayService ?? NativeTrayService(),
        _hotkeyService = hotkeyService ?? HotkeyService(),
        _notificationService = notificationService ?? NotificationService();

  /// Set the router for focus page navigation from tray
  void setRouter(GoRouter router) {
    _router = router;
  }

  /// Update the localized strings (call when locale changes)
  void updateLocalizedStrings(PlatformLocalizedStrings strings) {
    _strings = strings;
    // Re-sync tray menu and popover with new strings
    _safeAsync(_updateTrayMenu());
    _safeAsync(_syncPopoverState());
  }

  /// Initialize all platform services and start listening
  Future<void> init() async {
    await _trayService.init();
    await _hotkeyService.init();
    await _notificationService.init();

    // Wire up tray callbacks
    _trayService
      ..onStartPause = _handleStartPause
      ..onStop = _handleStop
      ..onShowWindow = _handleShowWindow
      ..onQuit = _handleQuit;

    // Wire up hotkey callbacks
    _hotkeyService
      ..onStartPause = _handleStartPause
      ..onStop = _handleStop
      ..onShowWindow = _handleShowWindow;

    // Listen to FocusProvider state changes
    _focusProvider.addListener(_onFocusStateChanged);

    // Set initial tray state
    await _updateTrayForCurrentState();
  }

  /// Called every time FocusProvider notifies (every second when running)
  void _onFocusStateChanged() {
    final currentState = _focusProvider.state;
    final stateChanged = currentState != _previousState;

    // Update title and popover on every tick when timer is active
    if (currentState == FocusState.running || currentState == FocusState.breaking) {
      _safeAsync(_updateTrayTitle());
      _safeAsync(_syncPopoverState());
    }

    // Handle state transitions
    if (stateChanged) {
      _safeAsync(_onStateTransition(_previousState, currentState));
      _previousState = currentState;
    }
  }

  /// Handle a state transition (icon, menu, notification, popover)
  Future<void> _onStateTransition(FocusState from, FocusState to) async {
    switch (to) {
      case FocusState.idle:
        await _trayService.setDefaultIcon();
        await _trayService.updateTitle('');
        await _updateTrayMenu();
        await _syncPopoverState();
        break;

      case FocusState.ready:
        await _trayService.setDefaultIcon();
        await _trayService.updateTitle('');
        await _updateTrayMenu();
        await _syncPopoverState();
        // Notify when break ends (transition from breaking → ready)
        if (from == FocusState.breaking) {
          _safeAsync(_notificationService.showBreakComplete(
            title: _strings.notificationBreakComplete,
            body: _strings.notificationBreakBody,
          ));
        }
        break;

      case FocusState.running:
        await _trayService.setActiveIcon();
        await _updateTrayTitle();
        await _updateTrayMenu();
        await _syncPopoverState();
        break;

      case FocusState.paused:
        await _updateTrayTitle();
        await _updateTrayMenu();
        await _syncPopoverState();
        break;

      case FocusState.completed:
        await _trayService.setDefaultIcon();
        await _trayService.updateTitle('✓');
        await _updateTrayMenu();
        await _syncPopoverState();
        _safeAsync(_sendCompletionNotification());
        break;

      case FocusState.breaking:
        await _trayService.setActiveIcon();
        await _updateTrayTitle();
        await _updateTrayMenu();
        await _syncPopoverState();
        break;
    }
  }

  /// Sync the popover state to the native SwiftUI view
  Future<void> _syncPopoverState() async {
    final state = _focusProvider.state;
    final task = _focusProvider.currentTask;

    await _trayService.updatePopoverState(
      focusState: state.name,
      taskName: task?.title,
      formattedTime: _focusProvider.formattedTime,
      progress: _focusProvider.progress,
      timerMode: _focusProvider.timerMode.name,
      sessionTime: _focusProvider.formattedSessionTime,
      totalTime: _focusProvider.formattedTodayTotalTime,
      sessions: _focusProvider.todaySessionCount,
      localizedStrings: {
        'focusSession': _strings.popoverFocusSession,
        'pause': _strings.popoverPause,
        'stop': _strings.popoverStop,
        'resume': _strings.popoverResume,
        'start': _strings.popoverStart,
        'thisSession': _strings.popoverThisSession,
        'totalFocus': _strings.popoverTotalFocus,
        'sessions': _strings.popoverSessions,
        'noActiveFocus': _strings.popoverNoActiveFocus,
        'openApp': _strings.popoverOpenApp,
        'focusing': _strings.popoverFocusing,
        'paused': _strings.popoverPaused,
        'ready': _strings.popoverReady,
        'completed': _strings.popoverCompleted,
      },
    );
  }

  /// Update the menu bar title with current time
  Future<void> _updateTrayTitle() async {
    final state = _focusProvider.state;
    final time = _focusProvider.formattedTime;

    if (state == FocusState.running) {
      await _trayService.updateTitle('🍅 $time');
    } else if (state == FocusState.paused) {
      await _trayService.updateTitle('⏸ $time');
    } else if (state == FocusState.breaking) {
      await _trayService.updateTitle('☕ $time');
    }
  }

  /// Rebuild the tray context menu for current state
  Future<void> _updateTrayMenu() async {
    final state = _focusProvider.state;
    final task = _focusProvider.currentTask;

    String? primaryAction;
    bool showStop = false;

    switch (state) {
      case FocusState.idle:
        primaryAction = _strings.trayStartFocus;
        break;
      case FocusState.ready:
        primaryAction = _strings.trayStart;
        break;
      case FocusState.running:
        primaryAction = _strings.trayPause;
        showStop = true;
        break;
      case FocusState.paused:
        primaryAction = _strings.trayResume;
        showStop = true;
        break;
      case FocusState.completed:
        primaryAction = null;
        break;
      case FocusState.breaking:
        primaryAction = _strings.traySkipBreak;
        break;
    }

    await _trayService.updateContextMenu(
      taskName: task?.title,
      remainingTime:
          (state == FocusState.running || state == FocusState.paused || state == FocusState.breaking)
              ? _focusProvider.formattedTime
              : null,
      primaryActionLabel: primaryAction,
      showStop: showStop,
      stopLabel: _strings.trayStop,
      openAppLabel: _strings.trayOpenApp,
      quitLabel: _strings.trayQuit,
    );
  }

  /// Update tray to reflect current state (used on init)
  Future<void> _updateTrayForCurrentState() async {
    _previousState = _focusProvider.state;

    // Set initial icon and tooltip
    await _trayService.setDefaultIcon();
    await _trayService.setToolTip('Focus Hut');

    await _onStateTransition(FocusState.idle, _focusProvider.state);
  }

  /// Send a macOS notification when session completes
  Future<void> _sendCompletionNotification() async {
    final task = _focusProvider.currentTask;
    if (task == null) return;

    final duration = _focusProvider.formattedSessionTime;
    await _notificationService.showWorkSessionComplete(
      taskName: task.title,
      duration: duration,
      title: _strings.notificationFocusComplete,
      body: _strings.notificationFocusBody(task.title, duration),
    );
  }

  /// Safely run an async operation, logging errors instead of crashing
  void _safeAsync(Future<void> operation) {
    operation.catchError((Object error) {
      debugPrint('PlatformIntegrationService error: $error');
    });
  }

  // --- Action handlers ---

  /// Handle start/pause toggle from hotkey or tray menu
  void _handleStartPause() {
    switch (_focusProvider.state) {
      case FocusState.idle:
        _handleShowWindow();
        break;
      case FocusState.ready:
        _focusProvider.start();
        break;
      case FocusState.running:
        _focusProvider.pause();
        break;
      case FocusState.paused:
        _focusProvider.resume();
        break;
      case FocusState.completed:
        break;
      case FocusState.breaking:
        _focusProvider.skipBreak();
        break;
    }
  }

  /// Handle stop action from hotkey or tray menu
  Future<void> _handleStop() async {
    if (_focusProvider.isActive) {
      await _focusProvider.stop();
      await _taskProvider.refresh();
    }
  }

  /// Show and focus the main window, navigating to focus page if session is active
  void _handleShowWindow() {
    appWindow.show();

    final task = _focusProvider.currentTask;
    if (_focusProvider.isActive && task != null && _router != null) {
      _router!.go('/app/focus/${task.id}');
    }
  }

  /// Quit the application completely, ensuring data is saved first
  Future<void> _handleQuit() async {
    if (_focusProvider.isActive) {
      await _focusProvider.stop();
    }
    await dispose();
    exit(0);
  }

  /// Clean up all services and listeners
  Future<void> dispose() async {
    _focusProvider.removeListener(_onFocusStateChanged);
    await _trayService.dispose();
    await _hotkeyService.dispose();
    await _notificationService.dispose();
  }
}

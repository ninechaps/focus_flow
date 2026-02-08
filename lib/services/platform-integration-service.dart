import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../providers/focus_provider.dart';
import '../providers/task_provider.dart';
import 'hotkey-service.dart';
import 'native_tray_service.dart';
import 'notification-service.dart';

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
    if (currentState == FocusState.running) {
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
      totalTime: _focusProvider.formattedElapsedTime,
      sessions: _focusProvider.completedSessions,
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
        primaryAction = '▶ 开始专注';
        break;
      case FocusState.ready:
        primaryAction = '▶ 开始';
        break;
      case FocusState.running:
        primaryAction = '⏸ 暂停';
        showStop = true;
        break;
      case FocusState.paused:
        primaryAction = '▶ 继续';
        showStop = true;
        break;
      case FocusState.completed:
        primaryAction = null;
        break;
    }

    await _trayService.updateContextMenu(
      taskName: task?.title,
      remainingTime:
          (state == FocusState.running || state == FocusState.paused)
              ? _focusProvider.formattedTime
              : null,
      primaryActionLabel: primaryAction,
      showStop: showStop,
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

    await _notificationService.showWorkSessionComplete(
      taskName: task.title,
      duration: _focusProvider.formattedSessionTime,
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

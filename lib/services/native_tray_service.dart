import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Callback type for tray menu actions
typedef TrayActionCallback = void Function();

/// Manages the macOS system tray via native MethodChannel.
/// Replaces TrayService (tray_manager) with direct NSStatusItem control,
/// adding NSPopover support for left-click focus preview.
class NativeTrayService {
  static const _channel = MethodChannel('com.focusflow/tray');

  /// Callbacks for tray and popover actions
  TrayActionCallback? onStartPause;
  TrayActionCallback? onStop;
  TrayActionCallback? onShowWindow;
  TrayActionCallback? onQuit;

  bool _isInitialized = false;

  /// Initialize the native tray and register callback handler
  Future<void> init() async {
    if (_isInitialized) return;

    _channel.setMethodCallHandler(_handleNativeCall);
    _isInitialized = true;
  }

  /// Set the tray icon from a Flutter asset path
  Future<void> setIcon(String assetPath, {bool isTemplate = true}) async {
    if (!_isInitialized) return;

    try {
      final byteData = await rootBundle.load(assetPath);
      final base64 = base64Encode(
        byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        ),
      );

      await _channel.invokeMethod('setIcon', {
        'base64Icon': base64,
        'isTemplate': isTemplate,
        'iconSize': 18.0,
      });
    } catch (e) {
      debugPrint('NativeTrayService.setIcon error: $e');
    }
  }

  /// Update the menu bar title text (shown next to tray icon)
  Future<void> updateTitle(String title) async {
    if (!_isInitialized) return;

    try {
      await _channel.invokeMethod('setTitle', {'title': title});
    } catch (e) {
      debugPrint('NativeTrayService.updateTitle error: $e');
    }
  }

  /// Set the tray icon tooltip
  Future<void> setToolTip(String toolTip) async {
    if (!_isInitialized) return;

    try {
      await _channel.invokeMethod('setToolTip', {'toolTip': toolTip});
    } catch (e) {
      debugPrint('NativeTrayService.setToolTip error: $e');
    }
  }

  /// Switch to the active (colored) tray icon
  Future<void> setActiveIcon() async {
    await setIcon('assets/tray_icon_active.png', isTemplate: false);
  }

  /// Switch to the default (gray/template) tray icon
  Future<void> setDefaultIcon() async {
    await setIcon('assets/tray_icon.png');
  }

  /// Rebuild the right-click context menu
  Future<void> updateContextMenu({
    String? taskName,
    String? remainingTime,
    String? primaryActionLabel,
    bool showStop = false,
    String? todaySummary,
    String stopLabel = '⏹ Stop',
    String openAppLabel = 'Open Focus Hut',
    String quitLabel = 'Quit',
  }) async {
    if (!_isInitialized) return;

    final items = <Map<String, dynamic>>[];

    // Task info section
    if (taskName != null) {
      items.add({'label': taskName, 'disabled': true, 'type': 'normal'});
    }
    if (remainingTime != null) {
      items.add({'label': remainingTime, 'disabled': true, 'type': 'normal'});
    }
    if (taskName != null || remainingTime != null) {
      items.add({'type': 'separator'});
    }

    // Action buttons
    if (primaryActionLabel != null) {
      items.add({
        'key': 'start_pause',
        'label': primaryActionLabel,
        'type': 'normal',
      });
    }
    if (showStop) {
      items.add({
        'key': 'stop',
        'label': stopLabel,
        'type': 'normal',
      });
    }
    if (primaryActionLabel != null || showStop) {
      items.add({'type': 'separator'});
    }

    // Today summary
    if (todaySummary != null) {
      items.add({'label': todaySummary, 'disabled': true, 'type': 'normal'});
      items.add({'type': 'separator'});
    }

    // Fixed items
    items.add({
      'key': 'show_window',
      'label': openAppLabel,
      'type': 'normal',
    });
    items.add({'type': 'separator'});
    items.add({
      'key': 'quit',
      'label': quitLabel,
      'type': 'normal',
    });

    try {
      await _channel.invokeMethod('setContextMenu', {'items': items});
    } catch (e) {
      debugPrint('NativeTrayService.updateContextMenu error: $e');
    }
  }

  /// Update the popover state for the SwiftUI focus preview
  Future<void> updatePopoverState({
    required String focusState,
    String? taskName,
    String? formattedTime,
    double? progress,
    String? timerMode,
    String? sessionTime,
    String? totalTime,
    int? sessions,
    String? breadcrumb,
    Map<String, String>? localizedStrings,
  }) async {
    if (!_isInitialized) return;

    final args = <String, dynamic>{
      'focusState': focusState,
    };

    if (taskName != null) args['taskName'] = taskName;
    if (formattedTime != null) args['formattedTime'] = formattedTime;
    if (progress != null) args['progress'] = progress;
    if (timerMode != null) args['timerMode'] = timerMode;
    if (sessionTime != null) args['sessionTime'] = sessionTime;
    if (totalTime != null) args['totalTime'] = totalTime;
    if (sessions != null) args['sessions'] = sessions;
    if (breadcrumb != null) args['breadcrumb'] = breadcrumb;
    if (localizedStrings != null) args['localizedStrings'] = localizedStrings;

    try {
      await _channel.invokeMethod('updatePopoverState', args);
    } catch (e) {
      debugPrint('NativeTrayService.updatePopoverState error: $e');
    }
  }

  /// Clean up tray resources
  Future<void> dispose() async {
    if (!_isInitialized) return;

    try {
      await _channel.invokeMethod('destroy');
    } catch (e) {
      debugPrint('NativeTrayService.dispose error: $e');
    }

    _isInitialized = false;
  }

  /// Handle callbacks from native side (popover actions, menu clicks)
  Future<void> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'onPopoverAction':
        _handlePopoverAction(call.arguments as Map?);
        break;
      case 'onMenuItemClick':
        _handleMenuItemClick(call.arguments as Map?);
        break;
    }
  }

  void _handlePopoverAction(Map? args) {
    final action = args?['action'] as String?;
    switch (action) {
      case 'pause':
      case 'resume':
      case 'start':
        onStartPause?.call();
        break;
      case 'stop':
        onStop?.call();
        break;
      case 'showWindow':
        onShowWindow?.call();
        break;
    }
  }

  void _handleMenuItemClick(Map? args) {
    final key = args?['key'] as String?;
    switch (key) {
      case 'start_pause':
        onStartPause?.call();
        break;
      case 'stop':
        onStop?.call();
        break;
      case 'show_window':
        onShowWindow?.call();
        break;
      case 'quit':
        onQuit?.call();
        break;
    }
  }
}

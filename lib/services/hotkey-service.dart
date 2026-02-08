import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

/// Callback types for hotkey actions
typedef HotkeyActionCallback = void Function();

/// Manages global keyboard shortcuts for the application
class HotkeyService {
  HotkeyActionCallback? onStartPause;
  HotkeyActionCallback? onStop;
  HotkeyActionCallback? onShowWindow;

  bool _isInitialized = false;

  /// Register all global hotkeys
  Future<void> init() async {
    if (_isInitialized) return;

    // Cmd+Shift+F — Start/Pause focus
    await hotKeyManager.register(
      HotKey(
        key: PhysicalKeyboardKey.keyF,
        modifiers: [HotKeyModifier.meta, HotKeyModifier.shift],
        scope: HotKeyScope.system,
      ),
      keyDownHandler: (_) => onStartPause?.call(),
    );

    // Cmd+Shift+S — Stop focus
    await hotKeyManager.register(
      HotKey(
        key: PhysicalKeyboardKey.keyS,
        modifiers: [HotKeyModifier.meta, HotKeyModifier.shift],
        scope: HotKeyScope.system,
      ),
      keyDownHandler: (_) => onStop?.call(),
    );

    // Cmd+Shift+O — Open/focus main window
    await hotKeyManager.register(
      HotKey(
        key: PhysicalKeyboardKey.keyO,
        modifiers: [HotKeyModifier.meta, HotKeyModifier.shift],
        scope: HotKeyScope.system,
      ),
      keyDownHandler: (_) => onShowWindow?.call(),
    );

    _isInitialized = true;
  }

  /// Unregister all hotkeys
  Future<void> dispose() async {
    if (!_isInitialized) return;
    await hotKeyManager.unregisterAll();
    _isInitialized = false;
  }
}

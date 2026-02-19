import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Manages macOS system notifications for focus session events
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize the notification plugin and request macOS permissions
  Future<void> init() async {
    if (_isInitialized) return;

    const macOSSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: false,
      requestAlertPermission: true,
    );

    const initSettings = InitializationSettings(
      macOS: macOSSettings,
    );

    final granted = await _plugin.initialize(settings: initSettings);
    _isInitialized = granted ?? false;

    if (!_isInitialized) {
      debugPrint('NotificationService: Failed to initialize or permission denied');
    }
  }

  /// Show notification when a work session (Pomodoro) completes
  Future<void> showWorkSessionComplete({
    required String taskName,
    required String duration,
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) return;

    const details = NotificationDetails(
      macOS: DarwinNotificationDetails(
        sound: 'default',
        presentAlert: true,
        presentSound: true,
      ),
    );

    await _plugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  /// Show notification when a break period ends
  Future<void> showBreakComplete({
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) return;

    const details = NotificationDetails(
      macOS: DarwinNotificationDetails(
        sound: 'default',
        presentAlert: true,
        presentSound: true,
      ),
    );

    await _plugin.show(
      id: 1,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  /// Show a daily task reminder notification
  Future<void> showDailyReminder({
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) return;

    const details = NotificationDetails(
      macOS: DarwinNotificationDetails(
        sound: 'default',
        presentAlert: true,
        presentSound: true,
      ),
    );

    await _plugin.show(
      id: 2,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  /// Cancel all pending notifications
  Future<void> dispose() async {
    await _plugin.cancelAll();
    _isInitialized = false;
  }
}

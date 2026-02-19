import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/enums.dart';
import '../services/notification_service.dart';

/// Stores user preference settings with SharedPreferences persistence.
///
/// Manages:
/// - Startup page selection (list | schedule)
/// - Default task priority
/// - Daily reminder (enabled, time, scheduling)
class UserPreferencesProvider extends ChangeNotifier {
  static const _keyStartupPage = 'pref_startup_page';
  static const _keyDefaultPriority = 'pref_default_priority';
  static const _keyReminderEnabled = 'pref_reminder_enabled';
  static const _keyReminderHour = 'pref_reminder_hour';
  static const _keyReminderMinute = 'pref_reminder_minute';
  static const _keyReminderLastDate = 'pref_reminder_last_date';

  String _startupPage = 'list';
  TaskPriority? _defaultPriority;
  bool _reminderEnabled = false;
  int _reminderHour = 9;
  int _reminderMinute = 0;

  Timer? _reminderTimer;
  NotificationService? _notificationService;

  String _dailyReminderTitle = 'Daily Task Reminder';
  String _dailyReminderBody = 'Open Focus Hut and plan your tasks for today';

  /// The page to open on startup: 'list' or 'schedule'
  String get startupPage => _startupPage;

  /// The default priority for new tasks, or null for no preset
  TaskPriority? get defaultPriority => _defaultPriority;

  /// Whether the daily reminder is enabled
  bool get reminderEnabled => _reminderEnabled;

  /// The time at which the daily reminder fires
  TimeOfDay get reminderTime => TimeOfDay(hour: _reminderHour, minute: _reminderMinute);

  UserPreferencesProvider() {
    _load();
  }

  /// Inject the notification service and start reminder scheduling.
  /// Call this after the notification service has been created.
  void setNotificationService(NotificationService service) {
    _notificationService = service;
    _scheduleReminder();
  }

  /// Update the localized strings for the daily reminder notification.
  void updateReminderStrings({required String title, required String body}) {
    _dailyReminderTitle = title;
    _dailyReminderBody = body;
  }

  Future<void> setStartupPage(String page) async {
    if (_startupPage == page) return;
    _startupPage = page;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyStartupPage, page);
  }

  Future<void> setDefaultPriority(TaskPriority? priority) async {
    _defaultPriority = priority;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (priority == null) {
      await prefs.remove(_keyDefaultPriority);
    } else {
      await prefs.setString(_keyDefaultPriority, priority.name);
    }
  }

  Future<void> setReminderEnabled(bool enabled) async {
    if (_reminderEnabled == enabled) return;
    _reminderEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReminderEnabled, enabled);
    _scheduleReminder();
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    _reminderHour = time.hour;
    _reminderMinute = time.minute;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyReminderHour, time.hour);
    await prefs.setInt(_keyReminderMinute, time.minute);
    // Reset last-sent date so the reminder can fire at the new time today
    await prefs.remove(_keyReminderLastDate);
    _scheduleReminder();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    _startupPage = prefs.getString(_keyStartupPage) ?? 'list';

    final priorityName = prefs.getString(_keyDefaultPriority);
    _defaultPriority = priorityName != null
        ? TaskPriority.values.where((p) => p.name == priorityName).firstOrNull
        : null;

    _reminderEnabled = prefs.getBool(_keyReminderEnabled) ?? false;
    _reminderHour = prefs.getInt(_keyReminderHour) ?? 9;
    _reminderMinute = prefs.getInt(_keyReminderMinute) ?? 0;

    notifyListeners();
    _scheduleReminder();
  }

  /// Schedule (or cancel) the daily reminder timer.
  ///
  /// Strategy:
  /// 1. Cancel any existing timer.
  /// 2. If reminder is disabled, return early.
  /// 3. Check if reminder was already sent today.
  /// 4. Compute the next fire time (today if not yet reached, tomorrow otherwise).
  /// 5. If the fire time is now or in the past and not yet sent today, fire immediately.
  /// 6. Set a timer for the next occurrence.
  void _scheduleReminder() {
    _reminderTimer?.cancel();
    _reminderTimer = null;

    if (!_reminderEnabled) return;

    final now = DateTime.now();
    final todayKey = _dateKey(now);

    // Check if reminder already sent today (done synchronously after load)
    SharedPreferences.getInstance().then((prefs) {
      final lastDate = prefs.getString(_keyReminderLastDate);

      final reminderToday = DateTime(now.year, now.month, now.day, _reminderHour, _reminderMinute);
      final alreadySentToday = lastDate == todayKey;

      // Fire immediately if we passed today's reminder time and haven't sent yet
      if (!alreadySentToday && now.isAfter(reminderToday)) {
        _fireReminder(prefs, todayKey);
      }

      // Schedule next timer
      final nextFire = alreadySentToday || now.isAfter(reminderToday)
          ? DateTime(now.year, now.month, now.day + 1, _reminderHour, _reminderMinute)
          : reminderToday;

      final delay = nextFire.difference(DateTime.now());
      if (delay.isNegative) return;

      _reminderTimer = Timer(delay, () async {
        final p = await SharedPreferences.getInstance();
        final key = _dateKey(DateTime.now());
        await _fireReminder(p, key);
        // Reschedule for the next day
        _scheduleReminder();
      });
    });
  }

  Future<void> _fireReminder(SharedPreferences prefs, String dateKey) async {
    await prefs.setString(_keyReminderLastDate, dateKey);
    await _notificationService?.showDailyReminder(
      title: _dailyReminderTitle,
      body: _dailyReminderBody,
    );
  }

  String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _reminderTimer?.cancel();
    super.dispose();
  }
}

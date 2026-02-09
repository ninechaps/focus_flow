import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for managing app locale (language) with persistence.
/// null locale means follow system default.
class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'locale';

  Locale? _locale;

  Locale? get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_localeKey);
    if (value != null && value != 'system') {
      _locale = Locale(value);
      notifyListeners();
    }
  }

  /// Set locale. Pass null to follow system default.
  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale?.languageCode ?? 'system');
  }
}

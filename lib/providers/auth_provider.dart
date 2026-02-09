import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  // 固定的登录凭据
  static const String _validUsername = 'admin';
  static const String _validPassword = 'admin123';
  static const String _storageKey = 'user_login_info';

  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  User? _currentUser;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;

  AuthProvider() {
    _loadStoredLoginInfo();
  }

  Future<void> _loadStoredLoginInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUserData = prefs.getString(_storageKey);
      
      if (storedUserData != null) {
        final userData = jsonDecode(storedUserData) as Map<String, dynamic>;
        _currentUser = User.fromJson(userData);
        _isAuthenticated = true;
        notifyListeners();
      }
    } catch (e) {
      // 如果读取存储信息失败，清除认证状态
      await _clearStoredLoginInfo();
      debugPrint('Failed to load stored login info: $e');
    }
  }

  Future<void> _saveLoginInfo(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(user.toJson()));
    } catch (e) {
      debugPrint('Failed to save login info: $e');
    }
  }

  Future<void> _clearStoredLoginInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      debugPrint('Failed to clear stored login info: $e');
    }
  }

  Future<bool> login(String username, String password) async {
    if (username.isEmpty || password.isEmpty) {
      _errorMessage = 'empty_credentials';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // 模拟网络延迟
    await Future.delayed(const Duration(seconds: 1));

    // 验证固定的用户凭据
    if (username == _validUsername && password == _validPassword) {
      _currentUser = User(
        username: username,
        email: '$username@example.com',
        lastLoginTime: DateTime.now(),
      );
      
      _isAuthenticated = true;
      _errorMessage = null;
      
      // 将登录信息存储到本地
      await _saveLoginInfo(_currentUser!);
    } else {
      _isAuthenticated = false;
      _currentUser = null;
      _errorMessage = 'invalid_credentials';
    }

    _isLoading = false;
    notifyListeners();
    return _isAuthenticated;
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _currentUser = null;
    _errorMessage = null;
    
    // 清除存储的登录信息
    await _clearStoredLoginInfo();
    
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // 检查登录信息是否存在，如果不存在则退出登录
  Future<void> validateStoredLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUserData = prefs.getString(_storageKey);
    
    if (storedUserData == null && _isAuthenticated) {
      // 如果没有存储的登录信息但当前处于已登录状态，强制退出登录
      await logout();
    }
  }
}
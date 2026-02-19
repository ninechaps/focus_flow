import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api/http_client.dart';
import '../core/auth/auth_interceptor.dart';
import '../core/auth/auth_storage.dart';
import '../core/crypto/rsa_encrypt_service.dart';
import '../database/database_helper.dart';
import '../models/login_request.dart';
import '../models/user.dart';
import '../repositories/interfaces/auth_repository_interface.dart';
import '../services/device_info_service.dart';

/// 主动刷新间隔。应小于 accessToken 实际有效期。
/// accessToken 有效期为 24h，提前 2h 刷新，设为 22h。
const Duration kTokenRefreshInterval = Duration(hours: 22);

/// Manages authentication state for the entire application.
///
/// Handles login (RSA-encrypted), logout, token persistence,
/// startup token validation, and register page navigation.
class AuthProvider extends ChangeNotifier {
  final AuthRepositoryInterface _authRepository;
  final AuthStorage _storage;
  final DeviceInfoService _deviceInfo;

  bool _isAuthenticated = false;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;
  User? _currentUser;
  Timer? _refreshTimer;

  bool get isAuthenticated => _isAuthenticated;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;

  AuthProvider({
    required AuthRepositoryInterface authRepository,
    required AuthStorage storage,
    required DeviceInfoService deviceInfo,
  })  : _authRepository = authRepository,
        _storage = storage,
        _deviceInfo = deviceInfo {
    _setupInterceptor();
    _initAuth();
  }

  /// 启动主动刷新定时器
  void _startRefreshTimer() {
    _stopRefreshTimer();
    _refreshTimer = Timer.periodic(kTokenRefreshInterval, (_) {
      _proactiveRefresh();
    });
  }

  /// 取消定时器
  void _stopRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// 主动刷新 token（静默执行，失败不强退）
  Future<void> _proactiveRefresh() async {
    try {
      final refreshToken = await _storage.readRefreshToken();
      if (refreshToken == null) return;

      final response = await _authRepository.refreshToken(refreshToken);
      if (response.isSuccess && response.data != null) {
        final tokenData = response.data!;
        await _storage.storeTokens(
          accessToken: tokenData.accessToken,
          refreshToken: tokenData.refreshToken,
        );
        debugPrint('[AUTH] Proactive token refresh succeeded.');
      } else {
        debugPrint('[AUTH] Proactive token refresh failed: ${response.message}');
        // 不强退——被动拦截器（AuthInterceptor）作为兜底
      }
    } catch (e) {
      debugPrint('[AUTH] Proactive token refresh error: $e');
    }
  }

  /// Set up the AuthInterceptor with force-logout callback
  void _setupInterceptor() {
    final interceptor = AuthInterceptor(
      storage: _storage,
      onForceLogout: _onForceLogout,
    );
    HttpClient.instance.addInterceptor(interceptor);
  }

  /// Called by AuthInterceptor when token refresh fails
  Future<void> _onForceLogout() async {
    _stopRefreshTimer();
    await _storage.clearAll();
    await DatabaseHelper.instance.closeDatabase();
    _isAuthenticated = false;
    _currentUser = null;
    _errorMessage = 'session_expired';
    notifyListeners();
  }

  /// Restore authentication state from secure storage on app startup
  Future<void> _initAuth() async {
    try {
      debugPrint('[AUTH] _initAuth: Reading access token from storage...');
      final accessToken = await _storage.readAccessToken();
      debugPrint('[AUTH] _initAuth: accessToken=${accessToken != null ? "exists" : "null"}');
      if (accessToken == null) {
        _isInitialized = true;
        notifyListeners();
        return;
      }

      // Token exists — validate by fetching current user
      final response = await _authRepository.getCurrentUser();
      if (response.isSuccess && response.data != null) {
        _currentUser = response.data;
        await DatabaseHelper.instance.initForUser(_currentUser!.id);
        _isAuthenticated = true;
        _startRefreshTimer();
      } else {
        // Token invalid or server unreachable — clear and require re-login
        await _storage.clearAll();
        _isAuthenticated = false;
        _currentUser = null;
      }
    } catch (e) {
      debugPrint('Auth initialization failed: $e');
      await _storage.clearAll();
      _isAuthenticated = false;
      _currentUser = null;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Login with email and password.
  ///
  /// 1. Validate input
  /// 2. Fetch RSA public key
  /// 3. Encrypt password with RSA-OAEP + SHA-256
  /// 4. Call login API with encrypted password + device info
  /// 5. Store tokens and user info in secure storage
  Future<bool> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      _errorMessage = 'empty_credentials';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Step 1: Get RSA public key
      debugPrint('[AUTH] Step 1: Fetching RSA public key...');
      final keyResponse = await _authRepository.getPublicKey();
      if (keyResponse.isError || keyResponse.data == null) {
        debugPrint('[AUTH] Step 1 FAILED: ${keyResponse.message}');
        _errorMessage = 'encryption_error';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      debugPrint('[AUTH] Step 1 OK');

      // Step 2: Encrypt password
      debugPrint('[AUTH] Step 2: Encrypting password...');
      final encryptedPassword = RsaEncryptService.encrypt(
        password,
        keyResponse.data!,
      );
      debugPrint('[AUTH] Step 2 OK');

      // Step 3: Build login request with device info
      debugPrint('[AUTH] Step 3: Building login request (device info)...');
      final request = LoginRequest(
        email: email,
        encryptedPassword: encryptedPassword,
        deviceId: await _deviceInfo.getDeviceId(),
        deviceName: _deviceInfo.getDeviceName(),
        deviceType: _deviceInfo.getDeviceType(),
      );
      debugPrint('[AUTH] Step 3 OK');

      // Step 4: Call login API
      debugPrint('[AUTH] Step 4: Calling login API...');
      final loginResponse = await _authRepository.login(request);
      if (loginResponse.isError || loginResponse.data == null) {
        debugPrint('[AUTH] Step 4 FAILED: ${loginResponse.message}');
        _errorMessage = loginResponse.message ?? 'invalid_credentials';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      debugPrint('[AUTH] Step 4 OK');

      // Step 5: Store tokens and user info
      debugPrint('[AUTH] Step 5: Storing tokens to secure storage...');
      final authData = loginResponse.data!;
      await _storage.storeTokens(
        accessToken: authData.accessToken,
        refreshToken: authData.refreshToken,
        sessionId: authData.sessionId,
      );
      debugPrint('[AUTH] Step 5a: Tokens stored. Storing user info...');
      await _storage.writeUserInfo(authData.user.toJson());
      debugPrint('[AUTH] Step 5 OK');

      _currentUser = authData.user;
      await DatabaseHelper.instance.initForUser(_currentUser!.id);
      _isAuthenticated = true;
      _startRefreshTimer();
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      debugPrint('[AUTH] Login failed at: $e');
      debugPrint('[AUTH] Stack trace: $stackTrace');
      _errorMessage = 'server_error';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout: notify server, clear local tokens, reset state.
  Future<void> logout() async {
    _stopRefreshTimer();
    // Attempt server-side logout (best effort, don't block on failure)
    try {
      final refreshToken = await _storage.readRefreshToken();
      final sessionId = await _storage.readSessionId();
      if (refreshToken != null) {
        await _authRepository.logout(
          refreshToken: refreshToken,
          sessionId: sessionId,
        );
      }
    } catch (e) {
      debugPrint('Server logout failed (non-blocking): $e');
    }

    // Clear local state regardless of server response
    await _storage.clearAll();
    await DatabaseHelper.instance.closeDatabase();
    _isAuthenticated = false;
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Open the registration page in the system browser
  Future<void> openRegisterPage() async {
    final baseUrl = AppHttpConfig.baseUrl;
    final url = Uri.parse('$baseUrl/auth/register/client');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

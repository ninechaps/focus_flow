import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Secure storage key constants for authentication data
abstract class AuthStorageKeys {
  static const accessToken = 'auth_access_token';
  static const refreshToken = 'auth_refresh_token';
  static const sessionId = 'auth_session_id';
  static const userInfo = 'auth_user_info';
  static const deviceId = 'auth_device_id';
  static const tokenIssuedAt = 'auth_token_issued_at';
}

/// Encapsulates flutter_secure_storage for authentication data persistence.
///
/// All tokens and sensitive data are stored in macOS Keychain via
/// flutter_secure_storage, providing OS-level encryption.
class AuthStorage {
  final FlutterSecureStorage _storage;

  AuthStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              mOptions: MacOsOptions(
                useDataProtectionKeyChain: false,
              ),
            );

  // --- Access Token ---

  Future<String?> readAccessToken() async {
    return _storage.read(key: AuthStorageKeys.accessToken);
  }

  Future<void> writeAccessToken(String token) async {
    await _storage.write(key: AuthStorageKeys.accessToken, value: token);
  }

  // --- Refresh Token ---

  Future<String?> readRefreshToken() async {
    return _storage.read(key: AuthStorageKeys.refreshToken);
  }

  Future<void> writeRefreshToken(String token) async {
    await _storage.write(key: AuthStorageKeys.refreshToken, value: token);
  }

  // --- Session ID ---

  Future<String?> readSessionId() async {
    return _storage.read(key: AuthStorageKeys.sessionId);
  }

  Future<void> writeSessionId(String sessionId) async {
    await _storage.write(key: AuthStorageKeys.sessionId, value: sessionId);
  }

  // --- User Info (JSON) ---

  Future<Map<String, dynamic>?> readUserInfo() async {
    final raw = await _storage.read(key: AuthStorageKeys.userInfo);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> writeUserInfo(Map<String, dynamic> userJson) async {
    await _storage.write(
      key: AuthStorageKeys.userInfo,
      value: jsonEncode(userJson),
    );
  }

  // --- Device ID (generated once, persisted) ---

  Future<String> getOrCreateDeviceId() async {
    final existing = await _storage.read(key: AuthStorageKeys.deviceId);
    if (existing != null) return existing;

    final deviceId = const Uuid().v4();
    await _storage.write(key: AuthStorageKeys.deviceId, value: deviceId);
    return deviceId;
  }

  // --- Token Issued At ---

  Future<void> writeTokenIssuedAt(DateTime issuedAt) async {
    await _storage.write(
      key: AuthStorageKeys.tokenIssuedAt,
      value: issuedAt.toIso8601String(),
    );
  }

  Future<DateTime?> readTokenIssuedAt() async {
    final raw = await _storage.read(key: AuthStorageKeys.tokenIssuedAt);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  // --- Batch Operations ---

  /// Store all auth tokens from a login/refresh response.
  /// Automatically records the current time as the issuance timestamp.
  Future<void> storeTokens({
    required String accessToken,
    required String refreshToken,
    String? sessionId,
  }) async {
    await Future.wait([
      writeAccessToken(accessToken),
      writeRefreshToken(refreshToken),
      writeTokenIssuedAt(DateTime.now()),
      if (sessionId != null) writeSessionId(sessionId),
    ]);
  }

  /// Clear all authentication data (used on logout)
  Future<void> clearAll() async {
    await Future.wait([
      _storage.delete(key: AuthStorageKeys.accessToken),
      _storage.delete(key: AuthStorageKeys.refreshToken),
      _storage.delete(key: AuthStorageKeys.sessionId),
      _storage.delete(key: AuthStorageKeys.userInfo),
      _storage.delete(key: AuthStorageKeys.tokenIssuedAt),
    ]);
  }
}

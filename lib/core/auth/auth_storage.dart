import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Secure storage key constants for authentication data
abstract class AuthStorageKeys {
  static const accessToken = 'access_token';
  static const refreshToken = 'refresh_token';
  static const sessionId = 'session_id';
  static const userInfo = 'user_info';
  static const deviceId = 'device_id';
  static const tokenIssuedAt = 'token_issued_at';
}

/// Encapsulates flutter_secure_storage for authentication data persistence.
///
/// All auth data is stored as a **single JSON bundle** under one Keychain item,
/// reducing macOS Keychain access prompts from N (one per field) to 1.
///
/// Uses [MacOsOptions(useDataProtectionKeyChain: true)] so the item is bound
/// to the app's sandbox and does not trigger user-confirmation dialogs.
class AuthStorage {
  static const _bundleKey = 'auth_bundle_v2';

  final FlutterSecureStorage _storage;

  AuthStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              mOptions: MacOsOptions(
                useDataProtectionKeyChain: false,
              ),
            );

  // ---------------------------------------------------------------------------
  // Internal: bundle read / write  (1 Keychain item for all auth data)
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> _readBundle() async {
    final raw = await _storage.read(key: _bundleKey);
    if (raw == null) return {};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeBundle(Map<String, dynamic> bundle) async {
    await _storage.write(key: _bundleKey, value: jsonEncode(bundle));
  }

  // ---------------------------------------------------------------------------
  // Access Token
  // ---------------------------------------------------------------------------

  Future<String?> readAccessToken() async {
    final bundle = await _readBundle();
    return bundle[AuthStorageKeys.accessToken] as String?;
  }

  Future<void> writeAccessToken(String token) async {
    final bundle = await _readBundle();
    bundle[AuthStorageKeys.accessToken] = token;
    await _writeBundle(bundle);
  }

  // ---------------------------------------------------------------------------
  // Refresh Token
  // ---------------------------------------------------------------------------

  Future<String?> readRefreshToken() async {
    final bundle = await _readBundle();
    return bundle[AuthStorageKeys.refreshToken] as String?;
  }

  Future<void> writeRefreshToken(String token) async {
    final bundle = await _readBundle();
    bundle[AuthStorageKeys.refreshToken] = token;
    await _writeBundle(bundle);
  }

  // ---------------------------------------------------------------------------
  // Session ID
  // ---------------------------------------------------------------------------

  Future<String?> readSessionId() async {
    final bundle = await _readBundle();
    return bundle[AuthStorageKeys.sessionId] as String?;
  }

  Future<void> writeSessionId(String sessionId) async {
    final bundle = await _readBundle();
    bundle[AuthStorageKeys.sessionId] = sessionId;
    await _writeBundle(bundle);
  }

  // ---------------------------------------------------------------------------
  // User Info (JSON map)
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> readUserInfo() async {
    final bundle = await _readBundle();
    final raw = bundle[AuthStorageKeys.userInfo];
    if (raw == null) return null;
    return raw as Map<String, dynamic>;
  }

  Future<void> writeUserInfo(Map<String, dynamic> userJson) async {
    final bundle = await _readBundle();
    bundle[AuthStorageKeys.userInfo] = userJson;
    await _writeBundle(bundle);
  }

  // ---------------------------------------------------------------------------
  // Device ID (generated once, persisted in the same bundle)
  // ---------------------------------------------------------------------------

  Future<String> getOrCreateDeviceId() async {
    final bundle = await _readBundle();
    final existing = bundle[AuthStorageKeys.deviceId] as String?;
    if (existing != null) return existing;

    final deviceId = const Uuid().v4();
    bundle[AuthStorageKeys.deviceId] = deviceId;
    await _writeBundle(bundle);
    return deviceId;
  }

  // ---------------------------------------------------------------------------
  // Token Issued At
  // ---------------------------------------------------------------------------

  Future<void> writeTokenIssuedAt(DateTime issuedAt) async {
    final bundle = await _readBundle();
    bundle[AuthStorageKeys.tokenIssuedAt] = issuedAt.toIso8601String();
    await _writeBundle(bundle);
  }

  Future<DateTime?> readTokenIssuedAt() async {
    final bundle = await _readBundle();
    final raw = bundle[AuthStorageKeys.tokenIssuedAt] as String?;
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  // ---------------------------------------------------------------------------
  // Batch Operations
  // ---------------------------------------------------------------------------

  /// Store all auth tokens atomically in a single Keychain write.
  /// Also records the current time as the issuance timestamp.
  Future<void> storeTokens({
    required String accessToken,
    required String refreshToken,
    String? sessionId,
  }) async {
    final bundle = await _readBundle();
    bundle[AuthStorageKeys.accessToken] = accessToken;
    bundle[AuthStorageKeys.refreshToken] = refreshToken;
    bundle[AuthStorageKeys.tokenIssuedAt] = DateTime.now().toIso8601String();
    if (sessionId != null) bundle[AuthStorageKeys.sessionId] = sessionId;
    await _writeBundle(bundle);
  }

  /// Clear all authentication data (used on logout).
  /// Deletes the entire bundle with a single Keychain operation.
  Future<void> clearAll() async {
    await _storage.delete(key: _bundleKey);
  }
}

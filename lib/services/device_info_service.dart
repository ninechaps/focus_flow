import 'dart:io';

import '../core/auth/auth_storage.dart';

/// Provides device identification for authentication requests.
///
/// deviceId is generated once and persisted in secure storage.
/// deviceName and deviceType are derived from the OS.
class DeviceInfoService {
  final AuthStorage _storage;

  DeviceInfoService({required AuthStorage storage}) : _storage = storage;

  /// Get or create a persistent device ID (UUID stored in Keychain)
  Future<String> getDeviceId() async {
    return _storage.getOrCreateDeviceId();
  }

  /// Get the device name (macOS hostname)
  String getDeviceName() {
    return Platform.localHostname;
  }

  /// Get the device type for the API
  String getDeviceType() {
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }
}

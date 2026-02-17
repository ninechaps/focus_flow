import '../../core/api/api_response.dart';
import '../../models/auth_response.dart';
import '../../models/login_request.dart';
import '../../models/user.dart';

/// Abstract interface for authentication operations.
///
/// Implementations may use HTTP (HttpAuthRepository) or mock for testing.
abstract class AuthRepositoryInterface {
  /// Get the RSA public key (PEM format) for password encryption
  Future<ApiResponse<String>> getPublicKey();

  /// Login with encrypted credentials, returns tokens + user
  Future<ApiResponse<AuthResponse>> login(LoginRequest request);

  /// Refresh accessToken using a valid refreshToken.
  /// Old refreshToken is revoked (rotation).
  Future<ApiResponse<TokenRefreshResponse>> refreshToken(String refreshToken);

  /// Get current authenticated user info (validates token)
  Future<ApiResponse<User>> getCurrentUser();

  /// Logout: revoke refreshToken and end session on server
  Future<ApiResponse<void>> logout({
    required String refreshToken,
    String? sessionId,
  });
}

import 'package:dio/dio.dart';

import '../../core/api/api_response.dart';
import '../../models/auth_response.dart';
import '../../models/login_request.dart';
import '../../models/user.dart';
import '../interfaces/auth_repository_interface.dart';

/// HTTP implementation of [AuthRepositoryInterface].
///
/// Calls the external authentication REST API.
/// All responses follow the server's { success, data, message? } format.
class HttpAuthRepository implements AuthRepositoryInterface {
  final Dio _dio;

  HttpAuthRepository({required Dio dio}) : _dio = dio;

  @override
  Future<ApiResponse<String>> getPublicKey() async {
    try {
      final response = await _dio.get('/api/auth/public-key');
      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final publicKey = data['data']['publicKey'] as String;
        return ApiResponse.success(publicKey);
      }

      return ApiResponse.error(
        data['message'] as String? ?? 'Failed to get public key',
        statusCode: response.statusCode ?? 500,
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  @override
  Future<ApiResponse<AuthResponse>> login(LoginRequest request) async {
    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: request.toJson(),
      );
      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final authResponse = AuthResponse.fromJson(
          data['data'] as Map<String, dynamic>,
        );
        return ApiResponse.success(authResponse);
      }

      return ApiResponse.error(
        data['message'] as String? ?? 'Login failed',
        statusCode: response.statusCode ?? 401,
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  @override
  Future<ApiResponse<TokenRefreshResponse>> refreshToken(
    String refreshToken,
  ) async {
    try {
      final response = await _dio.post(
        '/api/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final tokenResponse = TokenRefreshResponse.fromJson(
          data['data'] as Map<String, dynamic>,
        );
        return ApiResponse.success(tokenResponse);
      }

      return ApiResponse.error(
        data['message'] as String? ?? 'Token refresh failed',
        statusCode: response.statusCode ?? 401,
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  @override
  Future<ApiResponse<User>> getCurrentUser() async {
    try {
      final response = await _dio.get('/api/auth/me');
      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final user = User.fromJson(
          data['data']['user'] as Map<String, dynamic>,
        );
        return ApiResponse.success(user);
      }

      return ApiResponse.error(
        data['message'] as String? ?? 'Failed to get user info',
        statusCode: response.statusCode ?? 500,
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  @override
  Future<ApiResponse<void>> logout({
    required String refreshToken,
    String? sessionId,
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/logout',
        data: {
          'refreshToken': refreshToken,
          if (sessionId != null) 'sessionId': sessionId,
        },
      );
      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        return ApiResponse.success(null);
      }

      return ApiResponse.error(
        data['message'] as String? ?? 'Logout failed',
        statusCode: response.statusCode ?? 500,
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  /// Map Dio exceptions to ApiResponse errors with meaningful error codes
  ApiResponse<T> _handleDioError<T>(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return ApiResponse.error('network_error', statusCode: 0);

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode ?? 500;
        final data = e.response?.data;
        String message = 'server_error';

        if (data is Map<String, dynamic>) {
          message = data['message'] as String? ?? message;
        }

        if (statusCode == 401) message = 'invalid_credentials';
        if (statusCode == 403) message = 'email_not_verified';
        if (statusCode == 429) message = 'too_many_requests';

        return ApiResponse.error(message, statusCode: statusCode);

      default:
        return ApiResponse.error('network_error', statusCode: 0);
    }
  }
}

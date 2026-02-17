import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'auth_storage.dart';
import '../api/http_client.dart';

/// Callback invoked when token refresh fails and user must re-login.
typedef OnForceLogout = Future<void> Function();

/// Dio interceptor that handles JWT authentication:
///
/// 1. **onRequest**: Reads accessToken from secure storage and attaches
///    `Authorization: Bearer <token>` header to every request.
///
/// 2. **onError (401)**: Attempts to refresh the token using refreshToken.
///    - Uses a lock to prevent concurrent refresh attempts.
///    - Queues pending requests during refresh.
///    - On success: stores new tokens, retries the original request.
///    - On failure: calls [onForceLogout] to trigger app-wide logout.
class AuthInterceptor extends Interceptor {
  final AuthStorage _storage;
  final OnForceLogout _onForceLogout;

  /// Lock to prevent concurrent token refresh
  bool _isRefreshing = false;

  /// Queue of requests waiting for token refresh to complete
  final List<_PendingRequest> _pendingRequests = [];

  AuthInterceptor({
    required AuthStorage storage,
    required OnForceLogout onForceLogout,
  })  : _storage = storage,
        _onForceLogout = onForceLogout;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.readAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Only handle 401 responses
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // If the failed request was itself a refresh request, don't retry
    if (err.requestOptions.path.contains('/api/auth/refresh')) {
      return handler.next(err);
    }

    if (_isRefreshing) {
      // Another refresh is in progress — queue this request
      _pendingRequests.add(_PendingRequest(
        options: err.requestOptions,
        handler: handler,
      ));
      return;
    }

    _isRefreshing = true;

    try {
      final refreshToken = await _storage.readRefreshToken();
      if (refreshToken == null) {
        // No refresh token available — force logout
        await _forceLogout(err, handler);
        return;
      }

      // Use a plain Dio instance (no auth interceptor) to avoid loops
      final plainDio = HttpClient.instance.createPlainDio();
      final response = await plainDio.post(
        '/api/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final tokenData = data['data'] as Map<String, dynamic>;
        final newAccessToken = tokenData['accessToken'] as String;
        final newRefreshToken = tokenData['refreshToken'] as String;

        // Store new tokens
        await _storage.storeTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );

        // Retry the original failed request with new token
        final retryResponse = await _retryRequest(
          err.requestOptions,
          newAccessToken,
        );
        handler.resolve(retryResponse);

        // Retry all queued requests
        _retryPendingRequests(newAccessToken);
      } else {
        await _forceLogout(err, handler);
      }
    } on DioException catch (_) {
      await _forceLogout(err, handler);
    } finally {
      _isRefreshing = false;
    }
  }

  /// Retry a request with a new access token
  Future<Response> _retryRequest(
    RequestOptions options,
    String accessToken,
  ) {
    final plainDio = HttpClient.instance.createPlainDio();
    return plainDio.request(
      options.path,
      data: options.data,
      queryParameters: options.queryParameters,
      options: Options(
        method: options.method,
        headers: {
          ...options.headers,
          'Authorization': 'Bearer $accessToken',
        },
      ),
    );
  }

  /// Retry all queued requests with the new token
  void _retryPendingRequests(String accessToken) {
    final pending = List<_PendingRequest>.from(_pendingRequests);
    _pendingRequests.clear();

    for (final request in pending) {
      _retryRequest(request.options, accessToken).then(
        (response) => request.handler.resolve(response),
        onError: (error) {
          if (error is DioException) {
            request.handler.reject(error);
          }
        },
      );
    }
  }

  /// Handle refresh failure: reject all pending requests and force logout
  Future<void> _forceLogout(
    DioException originalError,
    ErrorInterceptorHandler handler,
  ) async {
    // Reject the original request
    handler.next(originalError);

    // Reject all pending requests
    for (final request in _pendingRequests) {
      request.handler.reject(DioException(
        requestOptions: request.options,
        error: 'Session expired',
        type: DioExceptionType.cancel,
      ));
    }
    _pendingRequests.clear();

    // Notify the app to logout
    try {
      await _onForceLogout();
    } catch (e) {
      debugPrint('Force logout callback failed: $e');
    }
  }
}

/// A request waiting for token refresh to complete
class _PendingRequest {
  final RequestOptions options;
  final ErrorInterceptorHandler handler;

  _PendingRequest({required this.options, required this.handler});
}

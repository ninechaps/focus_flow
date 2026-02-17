import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Application-wide HTTP client configuration
class AppHttpConfig {
  /// Base URL for the authentication API server.
  /// TODO: Move to environment configuration before production release.
  static const String baseUrl = 'http://localhost:3000';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);
}

/// Singleton Dio HTTP client for all API requests.
///
/// Provides a pre-configured Dio instance with base URL, timeouts,
/// and logging. AuthInterceptor should be added after initialization
/// via [addInterceptor].
class HttpClient {
  HttpClient._();

  static final HttpClient _instance = HttpClient._();
  static HttpClient get instance => _instance;

  late final Dio _dio;

  /// The underlying Dio instance for direct access when needed
  Dio get dio => _dio;

  bool _initialized = false;

  /// Initialize the HTTP client with base configuration.
  /// Must be called once before any API requests.
  void init({String? baseUrl}) {
    if (_initialized) return;

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? AppHttpConfig.baseUrl,
      connectTimeout: AppHttpConfig.connectTimeout,
      receiveTimeout: AppHttpConfig.receiveTimeout,
      sendTimeout: AppHttpConfig.sendTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestHeader: false,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        logPrint: (obj) => debugPrint('[HTTP] $obj'),
      ));
    }

    _initialized = true;
  }

  /// Add an interceptor (e.g. AuthInterceptor) to the Dio instance.
  void addInterceptor(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }

  /// Remove an interceptor from the Dio instance.
  void removeInterceptor(Interceptor interceptor) {
    _dio.interceptors.remove(interceptor);
  }

  /// Create a separate Dio instance without auth interceptor.
  /// Used for token refresh requests to avoid circular interception.
  Dio createPlainDio({String? baseUrl}) {
    return Dio(BaseOptions(
      baseUrl: baseUrl ?? AppHttpConfig.baseUrl,
      connectTimeout: AppHttpConfig.connectTimeout,
      receiveTimeout: AppHttpConfig.receiveTimeout,
      sendTimeout: AppHttpConfig.sendTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
  }
}

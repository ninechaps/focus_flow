/// Standard API response wrapper
/// Simulates a typical REST API response structure
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int statusCode;
  final DateTime timestamp;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode = 200,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create a successful response
  factory ApiResponse.success(T data, {String? message}) {
    return ApiResponse(
      success: true,
      data: data,
      message: message,
      statusCode: 200,
    );
  }

  /// Create an error response
  factory ApiResponse.error(String message, {int statusCode = 500}) {
    return ApiResponse(
      success: false,
      message: message,
      statusCode: statusCode,
    );
  }

  /// Create a not found response
  factory ApiResponse.notFound(String message) {
    return ApiResponse(
      success: false,
      message: message,
      statusCode: 404,
    );
  }

  /// Check if response is successful
  bool get isSuccess => success && statusCode >= 200 && statusCode < 300;

  /// Check if response is error
  bool get isError => !isSuccess;

  @override
  String toString() {
    return 'ApiResponse(success: $success, statusCode: $statusCode, message: $message, data: $data)';
  }
}

/// Paginated response for list queries
class PaginatedResponse<T> {
  final List<T> items;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;

  PaginatedResponse({
    required this.items,
    required this.total,
    this.page = 1,
    this.pageSize = 20,
  }) : hasMore = (page * pageSize) < total;

  /// Total number of pages
  int get totalPages => (total / pageSize).ceil();
}

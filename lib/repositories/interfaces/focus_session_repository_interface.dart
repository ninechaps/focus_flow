import '../../core/api/api_response.dart';
import '../../models/focus_session.dart';

/// Abstract interface for focus session repository operations
abstract class IFocusSessionRepository {
  /// Create a new focus session record
  Future<ApiResponse<FocusSession>> create(FocusSession session);

  /// Get all sessions for a specific task
  Future<ApiResponse<List<FocusSession>>> getByTask(String taskId);

  /// Get sessions within a date range
  Future<ApiResponse<List<FocusSession>>> getByDateRange(
    DateTime start,
    DateTime end,
  );

  /// Get today's summary (total seconds and session count)
  Future<ApiResponse<Map<String, int>>> getTodaySummary();

  /// Delete a session by ID
  Future<ApiResponse<void>> delete(String id);
}

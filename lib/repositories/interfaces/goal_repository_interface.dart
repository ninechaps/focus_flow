import '../../core/api/api_response.dart';
import '../../models/goal.dart';

/// Abstract interface for goal repository operations
abstract class IGoalRepository {
  /// Get all goals
  Future<ApiResponse<List<Goal>>> getAll();

  /// Get goal by ID
  Future<ApiResponse<Goal>> getById(String id);

  /// Create a new goal
  Future<ApiResponse<Goal>> create(Goal goal);

  /// Update an existing goal
  Future<ApiResponse<Goal>> update(Goal goal);

  /// Delete a goal
  Future<ApiResponse<void>> delete(String id);
}

import '../../core/api/api_response.dart';
import '../../models/task.dart';

/// Abstract interface for task repository operations
/// This interface defines the contract that all task repository implementations must follow
/// Whether it's a mock implementation, SQLite, or remote API
abstract class ITaskRepository {
  /// Get all tasks
  Future<ApiResponse<List<Task>>> getAll();

  /// Get task by ID
  Future<ApiResponse<Task>> getById(String id);

  /// Get subtasks for a parent task
  Future<ApiResponse<List<Task>>> getSubtasks(String parentId);

  /// Get all top-level tasks (tasks without parent)
  Future<ApiResponse<List<Task>>> getTopLevelTasks();

  /// Get subtasks map (parentId -> list of subtasks)
  Future<ApiResponse<Map<String, List<Task>>>> getSubtasksMap();

  /// Create a new task
  Future<ApiResponse<Task>> create(Task task);

  /// Update an existing task
  Future<ApiResponse<Task>> update(Task task);

  /// Toggle task completion status
  Future<ApiResponse<Task>> toggleStatus(String id);

  /// Delete a task (and its subtasks)
  Future<ApiResponse<void>> delete(String id);

  /// Search tasks by query
  Future<ApiResponse<List<Task>>> search(String query);

  /// Get tasks by tag
  Future<ApiResponse<List<Task>>> getByTag(String tagId);

  /// Get tasks by goal
  Future<ApiResponse<List<Task>>> getByGoal(String goalId);

  /// Get tasks by due date range
  Future<ApiResponse<List<Task>>> getByDateRange(DateTime start, DateTime end);

  /// Update focus duration for a task (adds to existing duration)
  Future<ApiResponse<Task>> addFocusDuration(String id, int durationInSeconds);

  /// Update sort order for multiple tasks (for drag-and-drop reordering)
  Future<ApiResponse<void>> updateSortOrders(Map<String, int> taskIdToSortOrder);

  /// Get all soft-deleted tasks (status == deleted)
  Future<ApiResponse<List<Task>>> getDeleted();

  /// Restore a soft-deleted task back to pending status
  Future<ApiResponse<Task>> restore(String id);
}

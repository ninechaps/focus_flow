import '../../config/database_config.dart';
import '../../core/api/api_response.dart';
import '../../database/database_helper.dart';
import '../../models/goal.dart';
import '../interfaces/goal_repository_interface.dart';

/// SQLite implementation of IGoalRepository
/// Provides full CRUD operations for goals using local SQLite database
class SqliteGoalRepository implements IGoalRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Convert database map to Goal model
  Goal _mapToGoal(Map<String, dynamic> map) {
    return Goal(
      id: map[DatabaseConfig.colId] as String,
      name: map[DatabaseConfig.colName] as String,
      dueDate: DateTime.parse(map[DatabaseConfig.colDueDate] as String),
      createdAt: DateTime.parse(map[DatabaseConfig.colCreatedAt] as String),
      updatedAt: DateTime.parse(map[DatabaseConfig.colUpdatedAt] as String),
    );
  }

  /// Convert Goal model to database map
  Map<String, dynamic> _goalToMap(Goal goal) {
    return {
      DatabaseConfig.colId: goal.id,
      DatabaseConfig.colName: goal.name,
      DatabaseConfig.colDueDate: goal.dueDate.toIso8601String(),
      DatabaseConfig.colCreatedAt: goal.createdAt.toIso8601String(),
      DatabaseConfig.colUpdatedAt: goal.updatedAt.toIso8601String(),
    };
  }

  @override
  Future<ApiResponse<List<Goal>>> getAll() async {
    try {
      final db = _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseConfig.tableGoal,
        orderBy: '${DatabaseConfig.colDueDate} ASC',
      );

      final goals = maps.map((map) => _mapToGoal(map)).toList();
      return ApiResponse.success(goals);
    } catch (e) {
      return ApiResponse.error('Failed to fetch goals: $e');
    }
  }

  @override
  Future<ApiResponse<Goal>> getById(String id) async {
    try {
      final db = _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseConfig.tableGoal,
        where: '${DatabaseConfig.colId} = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) {
        return ApiResponse.notFound('Goal not found: $id');
      }

      return ApiResponse.success(_mapToGoal(maps.first));
    } catch (e) {
      return ApiResponse.error('Failed to fetch goal: $e');
    }
  }

  @override
  Future<ApiResponse<Goal>> create(Goal goal) async {
    try {
      final db = _dbHelper.database;

      // Check if goal with same name already exists
      final existing = await db.query(
        DatabaseConfig.tableGoal,
        where: '${DatabaseConfig.colName} = ?',
        whereArgs: [goal.name],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        return ApiResponse.error(
          'Goal with name "${goal.name}" already exists',
          statusCode: 409,
        );
      }

      await db.insert(DatabaseConfig.tableGoal, _goalToMap(goal));
      return ApiResponse.success(goal, message: 'Goal created successfully');
    } catch (e) {
      return ApiResponse.error('Failed to create goal: $e');
    }
  }

  @override
  Future<ApiResponse<Goal>> update(Goal goal) async {
    try {
      final db = _dbHelper.database;

      final existing = await db.query(
        DatabaseConfig.tableGoal,
        where: '${DatabaseConfig.colId} = ?',
        whereArgs: [goal.id],
        limit: 1,
      );

      if (existing.isEmpty) {
        return ApiResponse.notFound('Goal not found: ${goal.id}');
      }

      // Check for name conflict with other goals
      final nameConflict = await db.query(
        DatabaseConfig.tableGoal,
        where: '${DatabaseConfig.colName} = ? AND ${DatabaseConfig.colId} != ?',
        whereArgs: [goal.name, goal.id],
        limit: 1,
      );

      if (nameConflict.isNotEmpty) {
        return ApiResponse.error(
          'Goal with name "${goal.name}" already exists',
          statusCode: 409,
        );
      }

      final updatedGoal = goal.copyWith(updatedAt: DateTime.now());
      await db.update(
        DatabaseConfig.tableGoal,
        _goalToMap(updatedGoal),
        where: '${DatabaseConfig.colId} = ?',
        whereArgs: [goal.id],
      );

      return ApiResponse.success(updatedGoal, message: 'Goal updated successfully');
    } catch (e) {
      return ApiResponse.error('Failed to update goal: $e');
    }
  }

  @override
  Future<ApiResponse<void>> delete(String id) async {
    try {
      final db = _dbHelper.database;

      final existing = await db.query(
        DatabaseConfig.tableGoal,
        where: '${DatabaseConfig.colId} = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (existing.isEmpty) {
        return ApiResponse.notFound('Goal not found: $id');
      }

      await db.delete(
        DatabaseConfig.tableGoal,
        where: '${DatabaseConfig.colId} = ?',
        whereArgs: [id],
      );

      return ApiResponse.success(null, message: 'Goal deleted successfully');
    } catch (e) {
      return ApiResponse.error('Failed to delete goal: $e');
    }
  }
}

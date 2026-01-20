import '../../config/database_config.dart';
import '../../core/api/api_response.dart';
import '../../database/database_helper.dart';
import '../../models/task.dart';
import '../../models/tag.dart';
import '../../models/goal.dart';
import '../../models/enums.dart';
import '../interfaces/task_repository_interface.dart';

/// SQLite implementation of ITaskRepository
/// Provides full CRUD operations for tasks using local SQLite database
class SqliteTaskRepository implements ITaskRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Convert database map to Tag model
  Tag _mapToTag(Map<String, dynamic> map) {
    return Tag(
      id: map[DatabaseConfig.colId] as String,
      name: map[DatabaseConfig.colName] as String,
      color: map[DatabaseConfig.colColor] as String,
      createdAt: DateTime.parse(map[DatabaseConfig.colCreatedAt] as String),
      updatedAt: DateTime.parse(map[DatabaseConfig.colUpdatedAt] as String),
    );
  }

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

  /// Get goal for a specific task
  Future<Goal?> _getGoalForTask(String? goalId) async {
    if (goalId == null) return null;

    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseConfig.tableGoal,
      where: '${DatabaseConfig.colId} = ?',
      whereArgs: [goalId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _mapToGoal(maps.first);
  }

  /// Convert database map to Task model (with tags and optional goal)
  Task _mapToTask(Map<String, dynamic> map, List<Tag> tags, {Goal? goal}) {
    return Task(
      id: map[DatabaseConfig.colId] as String,
      title: map[DatabaseConfig.colTitle] as String,
      description: map[DatabaseConfig.colDescription] as String?,
      dueDate: map[DatabaseConfig.colDueDate] != null
          ? DateTime.parse(map[DatabaseConfig.colDueDate] as String)
          : null,
      parentTaskId: map[DatabaseConfig.colParentTaskId] as String?,
      goalId: map[DatabaseConfig.colGoalId] as String?,
      goal: goal,
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == map[DatabaseConfig.colPriority],
        orElse: () => TaskPriority.medium,
      ),
      status: TaskStatus.values.firstWhere(
        (e) => e.name == map[DatabaseConfig.colStatus],
        orElse: () => TaskStatus.pending,
      ),
      tags: tags,
      focusDuration: map[DatabaseConfig.colFocusDuration] as int? ?? 0,
      sortOrder: map[DatabaseConfig.colSortOrder] as int? ?? 0,
      completedAt: map[DatabaseConfig.colCompletedAt] != null
          ? DateTime.parse(map[DatabaseConfig.colCompletedAt] as String)
          : null,
      createdAt: DateTime.parse(map[DatabaseConfig.colCreatedAt] as String),
      updatedAt: DateTime.parse(map[DatabaseConfig.colUpdatedAt] as String),
    );
  }

  /// Convert Task model to database map (without tags)
  Map<String, dynamic> _taskToMap(Task task) {
    return {
      DatabaseConfig.colId: task.id,
      DatabaseConfig.colTitle: task.title,
      DatabaseConfig.colDescription: task.description,
      DatabaseConfig.colDueDate: task.dueDate?.toIso8601String(),
      DatabaseConfig.colParentTaskId: task.parentTaskId,
      DatabaseConfig.colGoalId: task.goalId,
      DatabaseConfig.colPriority: task.priority.name,
      DatabaseConfig.colStatus: task.status.name,
      DatabaseConfig.colFocusDuration: task.focusDuration,
      DatabaseConfig.colSortOrder: task.sortOrder,
      DatabaseConfig.colCompletedAt: task.completedAt?.toIso8601String(),
      DatabaseConfig.colCreatedAt: task.createdAt.toIso8601String(),
      DatabaseConfig.colUpdatedAt: task.updatedAt.toIso8601String(),
    };
  }

  /// Get tags for a specific task
  Future<List<Tag>> _getTagsForTask(String taskId) async {
    final db = await _dbHelper.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT t.* FROM ${DatabaseConfig.tableTag} t
      INNER JOIN ${DatabaseConfig.tableTaskTag} tt ON t.${DatabaseConfig.colId} = tt.${DatabaseConfig.colTagId}
      WHERE tt.${DatabaseConfig.colTaskId} = ?
    ''', [taskId]);

    return maps.map((map) => _mapToTag(map)).toList();
  }

  /// Update task-tag associations
  Future<void> _updateTaskTags(String taskId, List<Tag> tags) async {
    final db = await _dbHelper.database;

    // Delete existing associations
    await db.delete(
      DatabaseConfig.tableTaskTag,
      where: '${DatabaseConfig.colTaskId} = ?',
      whereArgs: [taskId],
    );

    // Insert new associations
    for (final tag in tags) {
      await db.insert(DatabaseConfig.tableTaskTag, {
        DatabaseConfig.colTaskId: taskId,
        DatabaseConfig.colTagId: tag.id,
      });
    }
  }

  @override
  Future<ApiResponse<List<Task>>> getAll() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseConfig.tableTask,
        orderBy: '${DatabaseConfig.colSortOrder} ASC, ${DatabaseConfig.colCreatedAt} DESC',
      );

      final List<Task> tasks = [];
      for (final map in maps) {
        final tags = await _getTagsForTask(map[DatabaseConfig.colId] as String);
        final goal = await _getGoalForTask(map[DatabaseConfig.colGoalId] as String?);
        tasks.add(_mapToTask(map, tags, goal: goal));
      }

      return ApiResponse.success(tasks);
    } catch (e) {
      return ApiResponse.error('Failed to fetch tasks: $e');
    }
  }

  @override
  Future<ApiResponse<Task>> getById(String id) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseConfig.tableTask,
        where: '${DatabaseConfig.colId} = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) {
        return ApiResponse.notFound('Task not found: $id');
      }

      final tags = await _getTagsForTask(id);
      final goal = await _getGoalForTask(maps.first[DatabaseConfig.colGoalId] as String?);
      return ApiResponse.success(_mapToTask(maps.first, tags, goal: goal));
    } catch (e) {
      return ApiResponse.error('Failed to fetch task: $e');
    }
  }

  @override
  Future<ApiResponse<List<Task>>> getSubtasks(String parentId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseConfig.tableTask,
        where: '${DatabaseConfig.colParentTaskId} = ?',
        whereArgs: [parentId],
        orderBy: '${DatabaseConfig.colSortOrder} ASC, ${DatabaseConfig.colCreatedAt} DESC',
      );

      final List<Task> tasks = [];
      for (final map in maps) {
        final tags = await _getTagsForTask(map[DatabaseConfig.colId] as String);
        final goal = await _getGoalForTask(map[DatabaseConfig.colGoalId] as String?);
        tasks.add(_mapToTask(map, tags, goal: goal));
      }

      return ApiResponse.success(tasks);
    } catch (e) {
      return ApiResponse.error('Failed to fetch subtasks: $e');
    }
  }

  @override
  Future<ApiResponse<List<Task>>> getTopLevelTasks() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseConfig.tableTask,
        where: '${DatabaseConfig.colParentTaskId} IS NULL',
        orderBy: '${DatabaseConfig.colSortOrder} ASC, ${DatabaseConfig.colCreatedAt} DESC',
      );

      final List<Task> tasks = [];
      for (final map in maps) {
        final tags = await _getTagsForTask(map[DatabaseConfig.colId] as String);
        final goal = await _getGoalForTask(map[DatabaseConfig.colGoalId] as String?);
        tasks.add(_mapToTask(map, tags, goal: goal));
      }

      return ApiResponse.success(tasks);
    } catch (e) {
      return ApiResponse.error('Failed to fetch top-level tasks: $e');
    }
  }

  @override
  Future<ApiResponse<Map<String, List<Task>>>> getSubtasksMap() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseConfig.tableTask,
        where: '${DatabaseConfig.colParentTaskId} IS NOT NULL',
        orderBy: '${DatabaseConfig.colSortOrder} ASC, ${DatabaseConfig.colCreatedAt} DESC',
      );

      final Map<String, List<Task>> subtasksMap = {};
      for (final map in maps) {
        final parentId = map[DatabaseConfig.colParentTaskId] as String;
        final tags = await _getTagsForTask(map[DatabaseConfig.colId] as String);
        final goal = await _getGoalForTask(map[DatabaseConfig.colGoalId] as String?);
        final task = _mapToTask(map, tags, goal: goal);

        if (subtasksMap.containsKey(parentId)) {
          subtasksMap[parentId]!.add(task);
        } else {
          subtasksMap[parentId] = [task];
        }
      }

      return ApiResponse.success(subtasksMap);
    } catch (e) {
      return ApiResponse.error('Failed to fetch subtasks map: $e');
    }
  }

  @override
  Future<ApiResponse<Task>> create(Task task) async {
    try {
      final db = await _dbHelper.database;

      // Validate: subtasks cannot have further subtasks (single-level only)
      if (task.parentTaskId != null) {
        final parentTask = await db.query(
          DatabaseConfig.tableTask,
          columns: [DatabaseConfig.colParentTaskId],
          where: '${DatabaseConfig.colId} = ?',
          whereArgs: [task.parentTaskId],
          limit: 1,
        );

        if (parentTask.isNotEmpty &&
            parentTask.first[DatabaseConfig.colParentTaskId] != null) {
          return ApiResponse.error(
            'Cannot create a subtask of a subtask. Only one level of nesting is allowed.',
            statusCode: 400,
          );
        }
      }

      await db.insert(DatabaseConfig.tableTask, _taskToMap(task));

      // Insert task-tag associations
      await _updateTaskTags(task.id, task.tags);

      return ApiResponse.success(task, message: 'Task created successfully');
    } catch (e) {
      return ApiResponse.error('Failed to create task: $e');
    }
  }

  @override
  Future<ApiResponse<Task>> update(Task task) async {
    try {
      final db = await _dbHelper.database;

      // Check if task exists
      final existing = await db.query(
        DatabaseConfig.tableTask,
        where: '${DatabaseConfig.colId} = ?',
        whereArgs: [task.id],
        limit: 1,
      );

      if (existing.isEmpty) {
        return ApiResponse.notFound('Task not found: ${task.id}');
      }

      final updatedTask = task.copyWith(updatedAt: DateTime.now());
      await db.update(
        DatabaseConfig.tableTask,
        _taskToMap(updatedTask),
        where: '${DatabaseConfig.colId} = ?',
        whereArgs: [task.id],
      );

      // Update task-tag associations
      await _updateTaskTags(task.id, task.tags);

      return ApiResponse.success(updatedTask, message: 'Task updated successfully');
    } catch (e) {
      return ApiResponse.error('Failed to update task: $e');
    }
  }

  @override
  Future<ApiResponse<Task>> toggleStatus(String id) async {
    try {
      final db = await _dbHelper.database;

      // Get current task
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseConfig.tableTask,
        where: '${DatabaseConfig.colId} = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) {
        return ApiResponse.notFound('Task not found: $id');
      }

      final taskMap = maps.first;
      final parentTaskId = taskMap[DatabaseConfig.colParentTaskId] as String?;
      final currentStatus = TaskStatus.values.firstWhere(
        (e) => e.name == taskMap[DatabaseConfig.colStatus],
        orElse: () => TaskStatus.pending,
      );

      // Check if this is a parent task with subtasks
      final subtasksMaps = await db.query(
        DatabaseConfig.tableTask,
        where: '${DatabaseConfig.colParentTaskId} = ?',
        whereArgs: [id],
      );

      // Rule 2: Prevent parent task from being directly marked as completed if it has incomplete subtasks
      // Only block if: 1) this is a parent task (not a subtask), 2) trying to complete it, 3) has incomplete subtasks
      if (parentTaskId == null && subtasksMaps.isNotEmpty && currentStatus == TaskStatus.pending) {
        // Check if there are any incomplete subtasks
        final hasIncompleteSubtasks = subtasksMaps.any((subtask) {
          final status = TaskStatus.values.firstWhere(
            (e) => e.name == subtask[DatabaseConfig.colStatus],
            orElse: () => TaskStatus.pending,
          );
          return status != TaskStatus.completed;
        });

        if (hasIncompleteSubtasks) {
          return ApiResponse.error(
            'Cannot mark parent task as completed. Please complete all subtasks first.',
            statusCode: 400,
          );
        }
      }

      final newStatus = currentStatus == TaskStatus.completed
          ? TaskStatus.pending
          : TaskStatus.completed;

      final now = DateTime.now();
      await db.update(
        DatabaseConfig.tableTask,
        {
          DatabaseConfig.colStatus: newStatus.name,
          DatabaseConfig.colCompletedAt: newStatus == TaskStatus.completed
              ? now.toIso8601String()
              : null,
          DatabaseConfig.colUpdatedAt: now.toIso8601String(),
        },
        where: '${DatabaseConfig.colId} = ?',
        whereArgs: [id],
      );

      // Rule 3: If this is a parent task being uncompleted, uncomplete all subtasks
      if (parentTaskId == null && newStatus == TaskStatus.pending && subtasksMaps.isNotEmpty) {
        // Uncomplete all subtasks
        await db.update(
          DatabaseConfig.tableTask,
          {
            DatabaseConfig.colStatus: TaskStatus.pending.name,
            DatabaseConfig.colCompletedAt: null,
            DatabaseConfig.colUpdatedAt: DateTime.now().toIso8601String(),
          },
          where: '${DatabaseConfig.colParentTaskId} = ?',
          whereArgs: [id],
        );
      }

      // Rule 1: If this is a subtask, check if parent should be auto-completed
      if (parentTaskId != null && newStatus == TaskStatus.completed) {
        // Get all subtasks of the parent
        final allSubtasksMaps = await db.query(
          DatabaseConfig.tableTask,
          where: '${DatabaseConfig.colParentTaskId} = ?',
          whereArgs: [parentTaskId],
        );

        // Check if all subtasks are now completed
        final allCompleted = allSubtasksMaps.every((subtask) {
          final status = TaskStatus.values.firstWhere(
            (e) => e.name == subtask[DatabaseConfig.colStatus],
            orElse: () => TaskStatus.pending,
          );
          return status == TaskStatus.completed;
        });

        // If all subtasks are completed, auto-complete the parent
        if (allCompleted) {
          final parentCompletedAt = DateTime.now();
          await db.update(
            DatabaseConfig.tableTask,
            {
              DatabaseConfig.colStatus: TaskStatus.completed.name,
              DatabaseConfig.colCompletedAt: parentCompletedAt.toIso8601String(),
              DatabaseConfig.colUpdatedAt: parentCompletedAt.toIso8601String(),
            },
            where: '${DatabaseConfig.colId} = ?',
            whereArgs: [parentTaskId],
          );
        }
      }

      // Rule 1: If this is a subtask being uncompleted, uncomplete the parent as well
      if (parentTaskId != null && newStatus == TaskStatus.pending) {
        final parentMaps = await db.query(
          DatabaseConfig.tableTask,
          where: '${DatabaseConfig.colId} = ?',
          whereArgs: [parentTaskId],
          limit: 1,
        );

        if (parentMaps.isNotEmpty) {
          final parentStatus = TaskStatus.values.firstWhere(
            (e) => e.name == parentMaps.first[DatabaseConfig.colStatus],
            orElse: () => TaskStatus.pending,
          );

          // If parent is completed, uncomplete it
          if (parentStatus == TaskStatus.completed) {
            await db.update(
              DatabaseConfig.tableTask,
              {
                DatabaseConfig.colStatus: TaskStatus.pending.name,
                DatabaseConfig.colCompletedAt: null,
                DatabaseConfig.colUpdatedAt: DateTime.now().toIso8601String(),
              },
              where: '${DatabaseConfig.colId} = ?',
              whereArgs: [parentTaskId],
            );
          }
        }
      }

      // Fetch updated task
      final updatedMaps = await db.query(
        DatabaseConfig.tableTask,
        where: '${DatabaseConfig.colId} = ?',
        whereArgs: [id],
        limit: 1,
      );

      final tags = await _getTagsForTask(id);
      final goal = await _getGoalForTask(updatedMaps.first[DatabaseConfig.colGoalId] as String?);
      return ApiResponse.success(
        _mapToTask(updatedMaps.first, tags, goal: goal),
        message: 'Task status toggled successfully',
      );
    } catch (e) {
      return ApiResponse.error('Failed to toggle task status: $e');
    }
  }

  @override
  Future<ApiResponse<void>> delete(String id) async {
    try {
      final db = await _dbHelper.database;

      // Check if task exists
      final existing = await db.query(
        DatabaseConfig.tableTask,
        where: '${DatabaseConfig.colId} = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (existing.isEmpty) {
        return ApiResponse.notFound('Task not found: $id');
      }

      // Delete subtasks first (cascade should handle this, but being explicit)
      await db.delete(
        DatabaseConfig.tableTask,
        where: '${DatabaseConfig.colParentTaskId} = ?',
        whereArgs: [id],
      );

      // Delete task-tag associations (cascade should handle this)
      await db.delete(
        DatabaseConfig.tableTaskTag,
        where: '${DatabaseConfig.colTaskId} = ?',
        whereArgs: [id],
      );

      // Delete the task
      await db.delete(
        DatabaseConfig.tableTask,
        where: '${DatabaseConfig.colId} = ?',
        whereArgs: [id],
      );

      return ApiResponse.success(null, message: 'Task deleted successfully');
    } catch (e) {
      return ApiResponse.error('Failed to delete task: $e');
    }
  }

  @override
  Future<ApiResponse<List<Task>>> search(String query) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseConfig.tableTask,
        where: '${DatabaseConfig.colTitle} LIKE ? OR ${DatabaseConfig.colDescription} LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: '${DatabaseConfig.colCreatedAt} DESC',
      );

      final List<Task> tasks = [];
      for (final map in maps) {
        final tags = await _getTagsForTask(map[DatabaseConfig.colId] as String);
        final goal = await _getGoalForTask(map[DatabaseConfig.colGoalId] as String?);
        tasks.add(_mapToTask(map, tags, goal: goal));
      }

      return ApiResponse.success(tasks);
    } catch (e) {
      return ApiResponse.error('Failed to search tasks: $e');
    }
  }

  @override
  Future<ApiResponse<List<Task>>> getByTag(String tagId) async {
    try {
      final db = await _dbHelper.database;

      // Get task IDs with this tag
      final List<Map<String, dynamic>> taskTagMaps = await db.query(
        DatabaseConfig.tableTaskTag,
        where: '${DatabaseConfig.colTagId} = ?',
        whereArgs: [tagId],
      );

      final taskIds = taskTagMaps.map((m) => m[DatabaseConfig.colTaskId] as String).toList();

      if (taskIds.isEmpty) {
        return ApiResponse.success([]);
      }

      // Get tasks
      final placeholders = List.generate(taskIds.length, (_) => '?').join(',');
      final List<Map<String, dynamic>> maps = await db.rawQuery(
        'SELECT * FROM ${DatabaseConfig.tableTask} WHERE ${DatabaseConfig.colId} IN ($placeholders) ORDER BY ${DatabaseConfig.colCreatedAt} DESC',
        taskIds,
      );

      final List<Task> tasks = [];
      for (final map in maps) {
        final tags = await _getTagsForTask(map[DatabaseConfig.colId] as String);
        final goal = await _getGoalForTask(map[DatabaseConfig.colGoalId] as String?);
        tasks.add(_mapToTask(map, tags, goal: goal));
      }

      return ApiResponse.success(tasks);
    } catch (e) {
      return ApiResponse.error('Failed to fetch tasks by tag: $e');
    }
  }

  @override
  Future<ApiResponse<List<Task>>> getByGoal(String goalId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseConfig.tableTask,
        where: '${DatabaseConfig.colGoalId} = ?',
        whereArgs: [goalId],
        orderBy: '${DatabaseConfig.colCreatedAt} DESC',
      );

      final List<Task> tasks = [];
      final goal = await _getGoalForTask(goalId);
      for (final map in maps) {
        final tags = await _getTagsForTask(map[DatabaseConfig.colId] as String);
        tasks.add(_mapToTask(map, tags, goal: goal));
      }

      return ApiResponse.success(tasks);
    } catch (e) {
      return ApiResponse.error('Failed to fetch tasks by goal: $e');
    }
  }

  @override
  Future<ApiResponse<List<Task>>> getByDateRange(DateTime start, DateTime end) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseConfig.tableTask,
        where: '${DatabaseConfig.colDueDate} >= ? AND ${DatabaseConfig.colDueDate} <= ?',
        whereArgs: [start.toIso8601String(), end.toIso8601String()],
        orderBy: '${DatabaseConfig.colDueDate} ASC',
      );

      final List<Task> tasks = [];
      for (final map in maps) {
        final tags = await _getTagsForTask(map[DatabaseConfig.colId] as String);
        final goal = await _getGoalForTask(map[DatabaseConfig.colGoalId] as String?);
        tasks.add(_mapToTask(map, tags, goal: goal));
      }

      return ApiResponse.success(tasks);
    } catch (e) {
      return ApiResponse.error('Failed to fetch tasks by date range: $e');
    }
  }

  @override
  Future<ApiResponse<Task>> addFocusDuration(String id, int durationInSeconds) async {
    try {
      final db = await _dbHelper.database;

      // Get current task
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseConfig.tableTask,
        where: '${DatabaseConfig.colId} = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) {
        return ApiResponse.notFound('Task not found: $id');
      }

      final currentDuration = maps.first[DatabaseConfig.colFocusDuration] as int? ?? 0;
      final newDuration = currentDuration + durationInSeconds;

      await db.update(
        DatabaseConfig.tableTask,
        {
          DatabaseConfig.colFocusDuration: newDuration,
          DatabaseConfig.colUpdatedAt: DateTime.now().toIso8601String(),
        },
        where: '${DatabaseConfig.colId} = ?',
        whereArgs: [id],
      );

      // Fetch updated task
      final updatedMaps = await db.query(
        DatabaseConfig.tableTask,
        where: '${DatabaseConfig.colId} = ?',
        whereArgs: [id],
        limit: 1,
      );

      final tags = await _getTagsForTask(id);
      final goal = await _getGoalForTask(updatedMaps.first[DatabaseConfig.colGoalId] as String?);
      return ApiResponse.success(
        _mapToTask(updatedMaps.first, tags, goal: goal),
        message: 'Focus duration updated successfully',
      );
    } catch (e) {
      return ApiResponse.error('Failed to update focus duration: $e');
    }
  }

  @override
  Future<ApiResponse<void>> updateSortOrders(Map<String, int> taskIdToSortOrder) async {
    try {
      final db = await _dbHelper.database;

      // Use transaction for batch updates
      await db.transaction((txn) async {
        for (final entry in taskIdToSortOrder.entries) {
          await txn.update(
            DatabaseConfig.tableTask,
            {
              DatabaseConfig.colSortOrder: entry.value,
              DatabaseConfig.colUpdatedAt: DateTime.now().toIso8601String(),
            },
            where: '${DatabaseConfig.colId} = ?',
            whereArgs: [entry.key],
          );
        }
      });

      return ApiResponse.success(null, message: 'Sort orders updated successfully');
    } catch (e) {
      return ApiResponse.error('Failed to update sort orders: $e');
    }
  }
}

/// Database configuration for the application
/// This file contains all database-related configuration settings
class DatabaseConfig {
  /// Private constructor to prevent instantiation
  DatabaseConfig._();

  /// Current schema version for per-user database files.
  /// Increment this when schema changes are needed for existing user DBs.
  /// Version 1: Initial per-user schema (tasks, goals, tags, task_tags, focus_sessions)
  static const int databaseVersion = 1;

  /// Table names
  static const String tableTask = 'tasks';
  static const String tableTag = 'tags';
  static const String tableGoal = 'goals';
  static const String tableTaskTag = 'task_tags'; // Junction table for many-to-many
  static const String tableFocusSession = 'focus_sessions';

  /// Column names for tasks table
  static const String colId = 'id';
  static const String colTitle = 'title';
  static const String colDescription = 'description';
  static const String colDueDate = 'due_date';
  static const String colParentTaskId = 'parent_task_id';
  static const String colGoalId = 'goal_id';
  static const String colPriority = 'priority';
  static const String colStatus = 'status';
  static const String colFocusDuration = 'focus_duration';
  static const String colSortOrder = 'sort_order';
  static const String colCompletedAt = 'completed_at';
  static const String colCreatedAt = 'created_at';
  static const String colUpdatedAt = 'updated_at';

  /// Column names for tags table
  static const String colName = 'name';
  static const String colColor = 'color';

  /// Column names for task_tags junction table
  static const String colTaskId = 'task_id';
  static const String colTagId = 'tag_id';

  /// Column names for focus_sessions table
  static const String colStartedAt = 'started_at';
  static const String colEndedAt = 'ended_at';
  static const String colDurationSeconds = 'duration_seconds';
  static const String colTargetSeconds = 'target_seconds';
  static const String colTimerMode = 'timer_mode';
  static const String colCompletionType = 'completion_type';

  /// Enable debug mode for development
  /// Set to false in production
  static const bool debugMode = true;
}

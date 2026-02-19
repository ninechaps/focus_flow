import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../config/database_config.dart';

/// Database helper for SQLite operations.
/// Each user gets an independent database file for complete data isolation.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _database;

  DatabaseHelper._internal();

  static bool _ffiInitialized = false;

  static void _ensureFfiInitialized() {
    if (_ffiInitialized) return;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    _ffiInitialized = true;
  }

  /// Get the current database.
  /// Throws [StateError] if [initForUser] has not been called yet.
  Database get database {
    if (_database == null) {
      throw StateError(
        'Database not initialized. Call initForUser() after successful login.',
      );
    }
    return _database!;
  }

  /// Open the user-specific database file.
  ///
  /// Must be called after successful login or token validation.
  /// Closes any existing connection before opening the new one.
  Future<void> initForUser(String userId) async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    _ensureFfiInitialized();

    final Directory documentsDirectory =
        await getApplicationDocumentsDirectory();
    final String dbDir = join(documentsDirectory.path, 'focus_flow');

    await Directory(dbDir).create(recursive: true);

    // Sanitize userId to be safe for filenames
    final sanitizedUserId = userId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final String path = join(dbDir, 'user_$sanitizedUserId.db');

    if (DatabaseConfig.debugMode) {
      debugPrint('[DB] Opening database for user: $userId');
      debugPrint('[DB] Database path: $path');
    }

    _database = await openDatabase(
      path,
      version: DatabaseConfig.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    if (DatabaseConfig.debugMode) {
      debugPrint('[DB] Database ready for user: $userId');
    }
  }

  /// Close the current database connection.
  ///
  /// Call on logout to ensure clean state before the next user logs in.
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      if (DatabaseConfig.debugMode) {
        debugPrint('[DB] Database connection closed');
      }
    }
  }

  /// Create all tables for a fresh user database
  Future<void> _onCreate(Database db, int version) async {
    // tags table
    await db.execute('''
      CREATE TABLE ${DatabaseConfig.tableTag} (
        ${DatabaseConfig.colId} TEXT PRIMARY KEY,
        ${DatabaseConfig.colName} TEXT NOT NULL,
        ${DatabaseConfig.colColor} TEXT NOT NULL,
        ${DatabaseConfig.colCreatedAt} TEXT NOT NULL,
        ${DatabaseConfig.colUpdatedAt} TEXT NOT NULL
      )
    ''');

    // goals table
    await db.execute('''
      CREATE TABLE ${DatabaseConfig.tableGoal} (
        ${DatabaseConfig.colId} TEXT PRIMARY KEY,
        ${DatabaseConfig.colName} TEXT NOT NULL,
        ${DatabaseConfig.colDueDate} TEXT NOT NULL,
        ${DatabaseConfig.colCreatedAt} TEXT NOT NULL,
        ${DatabaseConfig.colUpdatedAt} TEXT NOT NULL
      )
    ''');

    // tasks table
    await db.execute('''
      CREATE TABLE ${DatabaseConfig.tableTask} (
        ${DatabaseConfig.colId} TEXT PRIMARY KEY,
        ${DatabaseConfig.colTitle} TEXT NOT NULL,
        ${DatabaseConfig.colDescription} TEXT,
        ${DatabaseConfig.colDueDate} TEXT,
        ${DatabaseConfig.colParentTaskId} TEXT,
        ${DatabaseConfig.colGoalId} TEXT,
        ${DatabaseConfig.colPriority} TEXT NOT NULL,
        ${DatabaseConfig.colStatus} TEXT NOT NULL,
        ${DatabaseConfig.colFocusDuration} INTEGER NOT NULL DEFAULT 0,
        ${DatabaseConfig.colSortOrder} INTEGER NOT NULL DEFAULT 0,
        ${DatabaseConfig.colCompletedAt} TEXT,
        ${DatabaseConfig.colCreatedAt} TEXT NOT NULL,
        ${DatabaseConfig.colUpdatedAt} TEXT NOT NULL,
        FOREIGN KEY (${DatabaseConfig.colParentTaskId}) REFERENCES ${DatabaseConfig.tableTask}(${DatabaseConfig.colId}) ON DELETE CASCADE,
        FOREIGN KEY (${DatabaseConfig.colGoalId}) REFERENCES ${DatabaseConfig.tableGoal}(${DatabaseConfig.colId}) ON DELETE SET NULL
      )
    ''');

    // task_tags junction table
    await db.execute('''
      CREATE TABLE ${DatabaseConfig.tableTaskTag} (
        ${DatabaseConfig.colTaskId} TEXT NOT NULL,
        ${DatabaseConfig.colTagId} TEXT NOT NULL,
        PRIMARY KEY (${DatabaseConfig.colTaskId}, ${DatabaseConfig.colTagId}),
        FOREIGN KEY (${DatabaseConfig.colTaskId}) REFERENCES ${DatabaseConfig.tableTask}(${DatabaseConfig.colId}) ON DELETE CASCADE,
        FOREIGN KEY (${DatabaseConfig.colTagId}) REFERENCES ${DatabaseConfig.tableTag}(${DatabaseConfig.colId}) ON DELETE CASCADE
      )
    ''');

    // focus_sessions table
    await db.execute('''
      CREATE TABLE ${DatabaseConfig.tableFocusSession} (
        ${DatabaseConfig.colId} TEXT PRIMARY KEY,
        ${DatabaseConfig.colTaskId} TEXT NOT NULL,
        ${DatabaseConfig.colStartedAt} TEXT NOT NULL,
        ${DatabaseConfig.colEndedAt} TEXT,
        ${DatabaseConfig.colDurationSeconds} INTEGER NOT NULL DEFAULT 0,
        ${DatabaseConfig.colTargetSeconds} INTEGER NOT NULL DEFAULT 0,
        ${DatabaseConfig.colTimerMode} TEXT NOT NULL DEFAULT 'countdown',
        ${DatabaseConfig.colCompletionType} TEXT NOT NULL DEFAULT 'stopped',
        ${DatabaseConfig.colCreatedAt} TEXT NOT NULL,
        FOREIGN KEY (${DatabaseConfig.colTaskId}) REFERENCES ${DatabaseConfig.tableTask}(${DatabaseConfig.colId}) ON DELETE CASCADE
      )
    ''');

    // Indexes
    await db.execute(
      'CREATE INDEX idx_tasks_parent ON ${DatabaseConfig.tableTask}(${DatabaseConfig.colParentTaskId})',
    );
    await db.execute(
      'CREATE INDEX idx_tasks_status ON ${DatabaseConfig.tableTask}(${DatabaseConfig.colStatus})',
    );
    await db.execute(
      'CREATE INDEX idx_tasks_due_date ON ${DatabaseConfig.tableTask}(${DatabaseConfig.colDueDate})',
    );
    await db.execute(
      'CREATE INDEX idx_tasks_goal ON ${DatabaseConfig.tableTask}(${DatabaseConfig.colGoalId})',
    );
    await db.execute(
      'CREATE INDEX idx_task_tags_task ON ${DatabaseConfig.tableTaskTag}(${DatabaseConfig.colTaskId})',
    );
    await db.execute(
      'CREATE INDEX idx_task_tags_tag ON ${DatabaseConfig.tableTaskTag}(${DatabaseConfig.colTagId})',
    );
    await db.execute(
      'CREATE INDEX idx_focus_sessions_task ON ${DatabaseConfig.tableFocusSession}(${DatabaseConfig.colTaskId})',
    );
    await db.execute(
      'CREATE INDEX idx_focus_sessions_started_at ON ${DatabaseConfig.tableFocusSession}(${DatabaseConfig.colStartedAt})',
    );

    if (DatabaseConfig.debugMode) {
      debugPrint('[DB] Tables created successfully (v$version)');
    }
  }

  /// Handle schema upgrades for future versions
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (DatabaseConfig.debugMode) {
      debugPrint('[DB] Upgrading from v$oldVersion to v$newVersion');
    }
    // Future upgrade migrations go here.
  }

  /// Clear all user data from the database.
  /// WARNING: This deletes all data. For dev/testing use only.
  Future<void> clearAllData() async {
    final db = database;
    await db.delete(DatabaseConfig.tableFocusSession);
    await db.delete(DatabaseConfig.tableTaskTag);
    await db.delete(DatabaseConfig.tableTask);
    await db.delete(DatabaseConfig.tableGoal);
    await db.delete(DatabaseConfig.tableTag);

    if (DatabaseConfig.debugMode) {
      debugPrint('[DB] All data cleared');
    }
  }
}

import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../config/database_config.dart';

/// Database helper class for SQLite operations
/// Handles database initialization, table creation, and provides utility methods
class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._();

  /// Singleton instance
  static DatabaseHelper get instance {
    _instance ??= DatabaseHelper._();
    return _instance!;
  }

  /// Get database instance
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  Future<Database> _initDatabase() async {
    // Initialize FFI for desktop platforms
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final Directory documentsDirectory =
        await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, DatabaseConfig.databaseName);

    if (DatabaseConfig.debugMode) {
      print('Database path: $path');
    }

    return await openDatabase(
      path,
      version: DatabaseConfig.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    // Create tags table
    await db.execute('''
      CREATE TABLE ${DatabaseConfig.tableTag} (
        ${DatabaseConfig.colId} TEXT PRIMARY KEY,
        ${DatabaseConfig.colName} TEXT NOT NULL,
        ${DatabaseConfig.colColor} TEXT NOT NULL,
        ${DatabaseConfig.colCreatedAt} TEXT NOT NULL,
        ${DatabaseConfig.colUpdatedAt} TEXT NOT NULL
      )
    ''');

    // Create goals table
    await db.execute('''
      CREATE TABLE ${DatabaseConfig.tableGoal} (
        ${DatabaseConfig.colId} TEXT PRIMARY KEY,
        ${DatabaseConfig.colName} TEXT NOT NULL,
        ${DatabaseConfig.colDueDate} TEXT NOT NULL,
        ${DatabaseConfig.colCreatedAt} TEXT NOT NULL,
        ${DatabaseConfig.colUpdatedAt} TEXT NOT NULL
      )
    ''');

    // Create tasks table
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

    // Create task_tags junction table for many-to-many relationship
    await db.execute('''
      CREATE TABLE ${DatabaseConfig.tableTaskTag} (
        ${DatabaseConfig.colTaskId} TEXT NOT NULL,
        ${DatabaseConfig.colTagId} TEXT NOT NULL,
        PRIMARY KEY (${DatabaseConfig.colTaskId}, ${DatabaseConfig.colTagId}),
        FOREIGN KEY (${DatabaseConfig.colTaskId}) REFERENCES ${DatabaseConfig.tableTask}(${DatabaseConfig.colId}) ON DELETE CASCADE,
        FOREIGN KEY (${DatabaseConfig.colTagId}) REFERENCES ${DatabaseConfig.tableTag}(${DatabaseConfig.colId}) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better query performance
    await db.execute('''
      CREATE INDEX idx_tasks_parent ON ${DatabaseConfig.tableTask}(${DatabaseConfig.colParentTaskId})
    ''');
    await db.execute('''
      CREATE INDEX idx_tasks_status ON ${DatabaseConfig.tableTask}(${DatabaseConfig.colStatus})
    ''');
    await db.execute('''
      CREATE INDEX idx_tasks_due_date ON ${DatabaseConfig.tableTask}(${DatabaseConfig.colDueDate})
    ''');
    await db.execute('''
      CREATE INDEX idx_tasks_goal ON ${DatabaseConfig.tableTask}(${DatabaseConfig.colGoalId})
    ''');
    await db.execute('''
      CREATE INDEX idx_task_tags_task ON ${DatabaseConfig.tableTaskTag}(${DatabaseConfig.colTaskId})
    ''');
    await db.execute('''
      CREATE INDEX idx_task_tags_tag ON ${DatabaseConfig.tableTaskTag}(${DatabaseConfig.colTagId})
    ''');

    if (DatabaseConfig.debugMode) {
      print('Database tables created successfully');
    }
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (DatabaseConfig.debugMode) {
      print('Upgrading database from version $oldVersion to $newVersion');
    }

    // Migration to v3: Replace categories with goals, restructure tasks
    // Drop all tables and recreate (user approved database reset)
    if (oldVersion < 3) {
      // Drop all existing tables
      await db.execute('DROP TABLE IF EXISTS ${DatabaseConfig.tableTaskTag}');
      await db.execute('DROP TABLE IF EXISTS ${DatabaseConfig.tableTask}');
      await db.execute('DROP TABLE IF EXISTS categories'); // Old table name
      await db.execute('DROP TABLE IF EXISTS ${DatabaseConfig.tableTag}');

      // Recreate all tables with new schema
      await _onCreate(db, newVersion);

      if (DatabaseConfig.debugMode) {
        print('Database reset for v3 migration - categories replaced with goals');
      }
    }

    // Migration to v4: Add focus_duration column to tasks
    if (oldVersion < 4 && oldVersion >= 3) {
      await db.execute('''
        ALTER TABLE ${DatabaseConfig.tableTask}
        ADD COLUMN ${DatabaseConfig.colFocusDuration} INTEGER NOT NULL DEFAULT 0
      ''');

      if (DatabaseConfig.debugMode) {
        print('Database upgraded to v4 - added focus_duration column');
      }
    }

    // Migration to v5: Add completed_at column to tasks
    if (oldVersion < 5 && oldVersion >= 3) {
      await db.execute('''
        ALTER TABLE ${DatabaseConfig.tableTask}
        ADD COLUMN ${DatabaseConfig.colCompletedAt} TEXT
      ''');

      if (DatabaseConfig.debugMode) {
        print('Database upgraded to v5 - added completed_at column');
      }
    }

    // Migration to v6: Add sort_order column to tasks
    if (oldVersion < 6 && oldVersion >= 3) {
      await db.execute('''
        ALTER TABLE ${DatabaseConfig.tableTask}
        ADD COLUMN ${DatabaseConfig.colSortOrder} INTEGER NOT NULL DEFAULT 0
      ''');

      if (DatabaseConfig.debugMode) {
        print('Database upgraded to v6 - added sort_order column');
      }
    }
  }

  /// Clear all data from the database
  /// This is for testing purposes and should be removed before release
  Future<void> clearAllData() async {
    final db = await database;

    // Delete all data in reverse order of dependencies
    await db.delete(DatabaseConfig.tableTaskTag);
    await db.delete(DatabaseConfig.tableTask);
    await db.delete(DatabaseConfig.tableGoal);
    await db.delete(DatabaseConfig.tableTag);

    if (DatabaseConfig.debugMode) {
      print('All data cleared from database');
    }
  }

  /// Close database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Delete the database file completely and recreate empty tables
  Future<void> deleteAndRecreateDatabase() async {
    await close();

    final Directory documentsDirectory =
        await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, DatabaseConfig.databaseName);

    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      if (DatabaseConfig.debugMode) {
        print('Database file deleted: $path');
      }
    }

    // Reset instance so database will be recreated on next access
    _instance = null;
    _database = null;
  }

  /// Reset singleton (for testing)
  static void resetInstance() {
    _instance = null;
    _database = null;
  }
}

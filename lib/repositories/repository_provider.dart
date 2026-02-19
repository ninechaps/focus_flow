import '../database/database_helper.dart';
import 'interfaces/focus_session_repository_interface.dart';
import 'interfaces/task_repository_interface.dart';
import 'interfaces/tag_repository_interface.dart';
import 'interfaces/goal_repository_interface.dart';
import 'sqlite/sqlite_focus_session_repository.dart';
import 'sqlite/sqlite_task_repository.dart';
import 'sqlite/sqlite_tag_repository.dart';
import 'sqlite/sqlite_goal_repository.dart';

/// Repository provider for dependency injection
/// This class provides repository instances using SQLite database
class RepositoryProvider {
  static RepositoryProvider? _instance;

  late final ITaskRepository _taskRepository;
  late final ITagRepository _tagRepository;
  late final IGoalRepository _goalRepository;
  late final IFocusSessionRepository _focusSessionRepository;

  bool _initialized = false;

  RepositoryProvider._();

  static RepositoryProvider get instance {
    _instance ??= RepositoryProvider._();
    return _instance!;
  }

  /// Initialize repository instances.
  ///
  /// Note: The database connection is NOT opened here.
  /// Call [DatabaseHelper.instance.initForUser] after login to open the DB.
  Future<void> init() async {
    if (_initialized) return;

    _taskRepository = SqliteTaskRepository();
    _tagRepository = SqliteTagRepository();
    _goalRepository = SqliteGoalRepository();
    _focusSessionRepository = SqliteFocusSessionRepository();

    _initialized = true;
  }

  /// Get task repository
  ITaskRepository get taskRepository {
    _ensureInitialized();
    return _taskRepository;
  }

  /// Get tag repository
  ITagRepository get tagRepository {
    _ensureInitialized();
    return _tagRepository;
  }

  /// Get goal repository
  IGoalRepository get goalRepository {
    _ensureInitialized();
    return _goalRepository;
  }

  /// Get focus session repository
  IFocusSessionRepository get focusSessionRepository {
    _ensureInitialized();
    return _focusSessionRepository;
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('RepositoryProvider not initialized. Call init() first.');
    }
  }

  /// Clear all data from the database
  /// This is for testing purposes only - remove before release
  Future<void> clearAllData() async {
    await DatabaseHelper.instance.clearAllData();
  }

  /// Reset instance (for testing)
  static Future<void> reset() async {
    if (_instance != null) {
      await DatabaseHelper.instance.closeDatabase();
    }
    _instance = null;
  }
}

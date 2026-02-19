import '../../config/database_config.dart';
import '../../core/api/api_response.dart';
import '../../database/database_helper.dart';
import '../../models/focus_session.dart';
import '../interfaces/focus_session_repository_interface.dart';

/// SQLite implementation of IFocusSessionRepository
class SqliteFocusSessionRepository implements IFocusSessionRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  FocusSession _mapToSession(Map<String, dynamic> map) {
    return FocusSession(
      id: map[DatabaseConfig.colId] as String,
      taskId: map[DatabaseConfig.colTaskId] as String,
      startedAt: DateTime.parse(map[DatabaseConfig.colStartedAt] as String),
      endedAt: map[DatabaseConfig.colEndedAt] != null
          ? DateTime.parse(map[DatabaseConfig.colEndedAt] as String)
          : null,
      durationSeconds: map[DatabaseConfig.colDurationSeconds] as int,
      targetSeconds: map[DatabaseConfig.colTargetSeconds] as int,
      timerMode: map[DatabaseConfig.colTimerMode] as String,
      completionType: map[DatabaseConfig.colCompletionType] as String,
      createdAt: DateTime.parse(map[DatabaseConfig.colCreatedAt] as String),
    );
  }

  Map<String, dynamic> _sessionToMap(FocusSession session) {
    return {
      DatabaseConfig.colId: session.id,
      DatabaseConfig.colTaskId: session.taskId,
      DatabaseConfig.colStartedAt: session.startedAt.toIso8601String(),
      DatabaseConfig.colEndedAt: session.endedAt?.toIso8601String(),
      DatabaseConfig.colDurationSeconds: session.durationSeconds,
      DatabaseConfig.colTargetSeconds: session.targetSeconds,
      DatabaseConfig.colTimerMode: session.timerMode,
      DatabaseConfig.colCompletionType: session.completionType,
      DatabaseConfig.colCreatedAt: session.createdAt.toIso8601String(),
    };
  }

  @override
  Future<ApiResponse<FocusSession>> create(FocusSession session) async {
    try {
      final db = _dbHelper.database;
      await db.insert(DatabaseConfig.tableFocusSession, _sessionToMap(session));
      return ApiResponse.success(session, message: 'Focus session created');
    } catch (e) {
      return ApiResponse.error('Failed to create focus session: $e');
    }
  }

  @override
  Future<ApiResponse<List<FocusSession>>> getByTask(String taskId) async {
    try {
      final db = _dbHelper.database;
      final maps = await db.query(
        DatabaseConfig.tableFocusSession,
        where: '${DatabaseConfig.colTaskId} = ?',
        whereArgs: [taskId],
        orderBy: '${DatabaseConfig.colStartedAt} DESC',
      );

      final sessions = maps.map(_mapToSession).toList();
      return ApiResponse.success(sessions);
    } catch (e) {
      return ApiResponse.error('Failed to fetch focus sessions: $e');
    }
  }

  @override
  Future<ApiResponse<List<FocusSession>>> getByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final db = _dbHelper.database;
      final maps = await db.query(
        DatabaseConfig.tableFocusSession,
        where: '${DatabaseConfig.colStartedAt} >= ? AND ${DatabaseConfig.colStartedAt} <= ?',
        whereArgs: [start.toIso8601String(), end.toIso8601String()],
        orderBy: '${DatabaseConfig.colStartedAt} DESC',
      );

      final sessions = maps.map(_mapToSession).toList();
      return ApiResponse.success(sessions);
    } catch (e) {
      return ApiResponse.error('Failed to fetch focus sessions by date: $e');
    }
  }

  @override
  Future<ApiResponse<Map<String, int>>> getTodaySummary() async {
    try {
      final db = _dbHelper.database;
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      final result = await db.rawQuery(
        '''
        SELECT
          COALESCE(SUM(${DatabaseConfig.colDurationSeconds}), 0) AS total_seconds,
          COUNT(*) AS session_count
        FROM ${DatabaseConfig.tableFocusSession}
        WHERE ${DatabaseConfig.colStartedAt} >= ? AND ${DatabaseConfig.colStartedAt} < ?
        ''',
        [todayStart.toIso8601String(), todayEnd.toIso8601String()],
      );

      final row = result.first;
      return ApiResponse.success({
        'totalSeconds': row['total_seconds'] as int,
        'sessionCount': row['session_count'] as int,
      });
    } catch (e) {
      return ApiResponse.error('Failed to get today summary: $e');
    }
  }

  @override
  Future<ApiResponse<void>> delete(String id) async {
    try {
      final db = _dbHelper.database;
      final count = await db.delete(
        DatabaseConfig.tableFocusSession,
        where: '${DatabaseConfig.colId} = ?',
        whereArgs: [id],
      );

      if (count == 0) {
        return ApiResponse.notFound('Focus session not found: $id');
      }

      return ApiResponse.success(null, message: 'Focus session deleted');
    } catch (e) {
      return ApiResponse.error('Failed to delete focus session: $e');
    }
  }
}

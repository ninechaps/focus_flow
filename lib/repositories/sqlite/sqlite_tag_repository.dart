import '../../config/database_config.dart';
import '../../core/api/api_response.dart';
import '../../database/database_helper.dart';
import '../../models/tag.dart';
import '../interfaces/tag_repository_interface.dart';

/// SQLite implementation of ITagRepository
/// Provides full CRUD operations for tags using local SQLite database
class SqliteTagRepository implements ITagRepository {
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

  /// Convert Tag model to database map
  Map<String, dynamic> _tagToMap(Tag tag) {
    return {
      DatabaseConfig.colId: tag.id,
      DatabaseConfig.colName: tag.name,
      DatabaseConfig.colColor: tag.color,
      DatabaseConfig.colCreatedAt: tag.createdAt.toIso8601String(),
      DatabaseConfig.colUpdatedAt: tag.updatedAt.toIso8601String(),
    };
  }

  @override
  Future<ApiResponse<List<Tag>>> getAll() async {
    try {
      final db = _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseConfig.tableTag,
        orderBy: '${DatabaseConfig.colCreatedAt} DESC',
      );

      final tags = maps.map((map) => _mapToTag(map)).toList();
      return ApiResponse.success(tags);
    } catch (e) {
      return ApiResponse.error('Failed to fetch tags: $e');
    }
  }

  @override
  Future<ApiResponse<Tag>> getById(String id) async {
    try {
      final db = _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseConfig.tableTag,
        where: '${DatabaseConfig.colId} = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) {
        return ApiResponse.notFound('Tag not found: $id');
      }

      return ApiResponse.success(_mapToTag(maps.first));
    } catch (e) {
      return ApiResponse.error('Failed to fetch tag: $e');
    }
  }

  @override
  Future<ApiResponse<Tag>> create(Tag tag) async {
    try {
      final db = _dbHelper.database;

      // Check if tag with same name already exists
      final existing = await db.query(
        DatabaseConfig.tableTag,
        where: '${DatabaseConfig.colName} = ?',
        whereArgs: [tag.name],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        return ApiResponse.error(
          'Tag with name "${tag.name}" already exists',
          statusCode: 409,
        );
      }

      await db.insert(DatabaseConfig.tableTag, _tagToMap(tag));
      return ApiResponse.success(tag, message: 'Tag created successfully');
    } catch (e) {
      return ApiResponse.error('Failed to create tag: $e');
    }
  }

  @override
  Future<ApiResponse<Tag>> update(Tag tag) async {
    try {
      final db = _dbHelper.database;

      final existing = await db.query(
        DatabaseConfig.tableTag,
        where: '${DatabaseConfig.colId} = ?',
        whereArgs: [tag.id],
        limit: 1,
      );

      if (existing.isEmpty) {
        return ApiResponse.notFound('Tag not found: ${tag.id}');
      }

      // Check for name conflict with other tags
      final nameConflict = await db.query(
        DatabaseConfig.tableTag,
        where: '${DatabaseConfig.colName} = ? AND ${DatabaseConfig.colId} != ?',
        whereArgs: [tag.name, tag.id],
        limit: 1,
      );

      if (nameConflict.isNotEmpty) {
        return ApiResponse.error(
          'Tag with name "${tag.name}" already exists',
          statusCode: 409,
        );
      }

      final updatedTag = tag.copyWith(updatedAt: DateTime.now());
      await db.update(
        DatabaseConfig.tableTag,
        _tagToMap(updatedTag),
        where: '${DatabaseConfig.colId} = ?',
        whereArgs: [tag.id],
      );

      return ApiResponse.success(updatedTag, message: 'Tag updated successfully');
    } catch (e) {
      return ApiResponse.error('Failed to update tag: $e');
    }
  }

  @override
  Future<ApiResponse<void>> delete(String id) async {
    try {
      final db = _dbHelper.database;

      final existing = await db.query(
        DatabaseConfig.tableTag,
        where: '${DatabaseConfig.colId} = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (existing.isEmpty) {
        return ApiResponse.notFound('Tag not found: $id');
      }

      await db.delete(
        DatabaseConfig.tableTag,
        where: '${DatabaseConfig.colId} = ?',
        whereArgs: [id],
      );

      return ApiResponse.success(null, message: 'Tag deleted successfully');
    } catch (e) {
      return ApiResponse.error('Failed to delete tag: $e');
    }
  }

  @override
  Future<ApiResponse<List<Tag>>> search(String query) async {
    try {
      final db = _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseConfig.tableTag,
        where: '${DatabaseConfig.colName} LIKE ?',
        whereArgs: ['%$query%'],
        orderBy: '${DatabaseConfig.colName} ASC',
      );

      final tags = maps.map((map) => _mapToTag(map)).toList();
      return ApiResponse.success(tags);
    } catch (e) {
      return ApiResponse.error('Failed to search tags: $e');
    }
  }
}

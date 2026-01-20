import '../../core/api/api_response.dart';
import '../../models/tag.dart';

/// Abstract interface for tag repository operations
abstract class ITagRepository {
  /// Get all tags
  Future<ApiResponse<List<Tag>>> getAll();

  /// Get tag by ID
  Future<ApiResponse<Tag>> getById(String id);

  /// Create a new tag
  Future<ApiResponse<Tag>> create(Tag tag);

  /// Update an existing tag
  Future<ApiResponse<Tag>> update(Tag tag);

  /// Delete a tag
  Future<ApiResponse<void>> delete(String id);

  /// Search tags by name
  Future<ApiResponse<List<Tag>>> search(String query);
}

import 'package:freezed_annotation/freezed_annotation.dart';
import 'enums.dart';
import 'tag.dart';
import 'goal.dart';

part 'task.freezed.dart';
part 'task.g.dart';

/// Task model - Tasks can belong to a goal (optional for miscellaneous tasks)
@freezed
abstract class Task with _$Task {
  const factory Task({
    required String id,
    required String title,
    String? description,
    DateTime? dueDate,
    String? parentTaskId,
    String? goalId,
    Goal? goal,
    required TaskPriority priority,
    required TaskStatus status,
    @Default([]) List<Tag> tags,
    @Default(0) int focusDuration, // Focus duration in seconds
    @Default(0) int sortOrder, // Sort order for drag-and-drop reordering
    DateTime? completedAt, // Timestamp when task was completed
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Task;

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
}

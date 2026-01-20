import 'package:json_annotation/json_annotation.dart';

/// 任务优先级
enum TaskPriority {
  @JsonValue('high')
  high,
  @JsonValue('medium')
  medium,
  @JsonValue('low')
  low,
}

/// 任务状态
enum TaskStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('completed')
  completed,
  @JsonValue('deleted')
  deleted,
}

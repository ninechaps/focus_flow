// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Task _$TaskFromJson(Map<String, dynamic> json) => _Task(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  dueDate: json['dueDate'] == null
      ? null
      : DateTime.parse(json['dueDate'] as String),
  parentTaskId: json['parentTaskId'] as String?,
  goalId: json['goalId'] as String?,
  goal: json['goal'] == null
      ? null
      : Goal.fromJson(json['goal'] as Map<String, dynamic>),
  priority: $enumDecode(_$TaskPriorityEnumMap, json['priority']),
  status: $enumDecode(_$TaskStatusEnumMap, json['status']),
  tags:
      (json['tags'] as List<dynamic>?)
          ?.map((e) => Tag.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  focusDuration: (json['focusDuration'] as num?)?.toInt() ?? 0,
  sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
  completedAt: json['completedAt'] == null
      ? null
      : DateTime.parse(json['completedAt'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$TaskToJson(_Task instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'dueDate': instance.dueDate?.toIso8601String(),
  'parentTaskId': instance.parentTaskId,
  'goalId': instance.goalId,
  'goal': instance.goal,
  'priority': _$TaskPriorityEnumMap[instance.priority]!,
  'status': _$TaskStatusEnumMap[instance.status]!,
  'tags': instance.tags,
  'focusDuration': instance.focusDuration,
  'sortOrder': instance.sortOrder,
  'completedAt': instance.completedAt?.toIso8601String(),
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

const _$TaskPriorityEnumMap = {
  TaskPriority.high: 'high',
  TaskPriority.medium: 'medium',
  TaskPriority.low: 'low',
};

const _$TaskStatusEnumMap = {
  TaskStatus.pending: 'pending',
  TaskStatus.inProgress: 'in_progress',
  TaskStatus.completed: 'completed',
  TaskStatus.deleted: 'deleted',
};

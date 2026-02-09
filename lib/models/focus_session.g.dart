// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'focus_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FocusSession _$FocusSessionFromJson(Map<String, dynamic> json) =>
    _FocusSession(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] == null
          ? null
          : DateTime.parse(json['endedAt'] as String),
      durationSeconds: (json['durationSeconds'] as num).toInt(),
      targetSeconds: (json['targetSeconds'] as num).toInt(),
      timerMode: json['timerMode'] as String,
      completionType: json['completionType'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$FocusSessionToJson(_FocusSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'taskId': instance.taskId,
      'startedAt': instance.startedAt.toIso8601String(),
      'endedAt': instance.endedAt?.toIso8601String(),
      'durationSeconds': instance.durationSeconds,
      'targetSeconds': instance.targetSeconds,
      'timerMode': instance.timerMode,
      'completionType': instance.completionType,
      'createdAt': instance.createdAt.toIso8601String(),
    };

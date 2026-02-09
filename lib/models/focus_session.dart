import 'package:freezed_annotation/freezed_annotation.dart';

part 'focus_session.freezed.dart';
part 'focus_session.g.dart';

/// Focus session record — persisted to SQLite for history and statistics
@freezed
abstract class FocusSession with _$FocusSession {
  const factory FocusSession({
    required String id,
    required String taskId,
    required DateTime startedAt,
    DateTime? endedAt,
    required int durationSeconds,
    required int targetSeconds,
    required String timerMode,
    required String completionType,
    required DateTime createdAt,
  }) = _FocusSession;

  factory FocusSession.fromJson(Map<String, dynamic> json) =>
      _$FocusSessionFromJson(json);
}

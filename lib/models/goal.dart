import 'package:freezed_annotation/freezed_annotation.dart';

part 'goal.freezed.dart';
part 'goal.g.dart';

/// Goal model - Tasks originate from goals
@freezed
abstract class Goal with _$Goal {
  const factory Goal({
    required String id,
    required String name,
    required DateTime dueDate,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Goal;

  factory Goal.fromJson(Map<String, dynamic> json) => _$GoalFromJson(json);
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// User model aligned with the authentication API response.
///
/// Fields match the server's user object from /api/auth/login and /api/auth/me.
@freezed
abstract class User with _$User {
  const factory User({
    required String id,
    required String email,
    String? username,
    String? fullName,
    String? avatarUrl,
    String? registrationSource,
    DateTime? emailVerifiedAt,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    @Default(0) int totalOnlineTime,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

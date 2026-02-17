// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) =>
    _LoginRequest(
      email: json['email'] as String,
      encryptedPassword: json['encryptedPassword'] as String,
      deviceId: json['deviceId'] as String?,
      deviceName: json['deviceName'] as String?,
      deviceType: json['deviceType'] as String?,
    );

Map<String, dynamic> _$LoginRequestToJson(_LoginRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'encryptedPassword': instance.encryptedPassword,
      'deviceId': instance.deviceId,
      'deviceName': instance.deviceName,
      'deviceType': instance.deviceType,
    };

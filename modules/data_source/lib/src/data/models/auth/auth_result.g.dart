// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthResultDto _$AuthResultDtoFromJson(Map<String, dynamic> json) =>
    AuthResultDto(
      token: UserToken.fromJson(json['token'] as Map<String, dynamic>),
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AuthResultDtoToJson(AuthResultDto instance) =>
    <String, dynamic>{
      'token': instance.token.toJson(),
      'user': instance.user.toJson(),
    };

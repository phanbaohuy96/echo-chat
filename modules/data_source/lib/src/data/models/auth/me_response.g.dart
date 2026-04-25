// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'me_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MeResponseDto _$MeResponseDtoFromJson(Map<String, dynamic> json) =>
    MeResponseDto(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MeResponseDtoToJson(MeResponseDto instance) =>
    <String, dynamic>{'user': instance.user.toJson()};

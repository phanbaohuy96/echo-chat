// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_users_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatUsersResponse _$ChatUsersResponseFromJson(Map<String, dynamic> json) =>
    ChatUsersResponse(
      users: (json['users'] as List<dynamic>)
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ChatUsersResponseToJson(ChatUsersResponse instance) =>
    <String, dynamic>{'users': instance.users.map((e) => e.toJson()).toList()};

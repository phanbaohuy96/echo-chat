import 'package:freezed_annotation/freezed_annotation.dart';

import '../user.dart';

part 'chat_users_response.g.dart';

@JsonSerializable(explicitToJson: true)
class ChatUsersResponse {
  const ChatUsersResponse({required this.users});

  final List<UserModel> users;

  factory ChatUsersResponse.fromJson(Map<String, dynamic> json) =>
      _$ChatUsersResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ChatUsersResponseToJson(this);
}

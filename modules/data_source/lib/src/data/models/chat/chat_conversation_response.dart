import 'package:freezed_annotation/freezed_annotation.dart';

import '../user.dart';
import 'chat_message.dart';

part 'chat_conversation_response.g.dart';

@JsonSerializable(explicitToJson: true)
class ChatConversationResponse {
  const ChatConversationResponse({required this.peer, required this.messages});

  final UserModel peer;
  final List<ChatMessageDto> messages;

  factory ChatConversationResponse.fromJson(Map<String, dynamic> json) =>
      _$ChatConversationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ChatConversationResponseToJson(this);
}

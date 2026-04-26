// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_conversation_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatConversationResponse _$ChatConversationResponseFromJson(
  Map<String, dynamic> json,
) => ChatConversationResponse(
  peer: UserModel.fromJson(json['peer'] as Map<String, dynamic>),
  messages: (json['messages'] as List<dynamic>)
      .map((e) => ChatMessageDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ChatConversationResponseToJson(
  ChatConversationResponse instance,
) => <String, dynamic>{
  'peer': instance.peer.toJson(),
  'messages': instance.messages.map((e) => e.toJson()).toList(),
};

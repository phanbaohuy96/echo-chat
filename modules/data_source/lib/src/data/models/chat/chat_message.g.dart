// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMessageDto _$ChatMessageDtoFromJson(Map<String, dynamic> json) =>
    ChatMessageDto(
      id: json['id'] as String,
      senderUserId: json['sender_user_id'] as String,
      recipientUserId: json['recipient_user_id'] as String,
      clientMessageId: json['client_message_id'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$ChatMessageDtoToJson(ChatMessageDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sender_user_id': instance.senderUserId,
      'recipient_user_id': instance.recipientUserId,
      'client_message_id': instance.clientMessageId,
      'message': instance.message,
      'created_at': instance.createdAt.toIso8601String(),
    };

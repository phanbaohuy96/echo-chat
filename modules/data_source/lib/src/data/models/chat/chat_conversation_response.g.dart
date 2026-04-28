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
  syncMetadata: ChatConversationSyncMetadataDto.fromJson(
    json['sync_metadata'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$ChatConversationResponseToJson(
  ChatConversationResponse instance,
) => <String, dynamic>{
  'peer': instance.peer.toJson(),
  'messages': instance.messages.map((e) => e.toJson()).toList(),
  'sync_metadata': instance.syncMetadata.toJson(),
};

ChatConversationSyncMetadataDto _$ChatConversationSyncMetadataDtoFromJson(
  Map<String, dynamic> json,
) => ChatConversationSyncMetadataDto(
  latestMessageCreatedAt: json['latest_message_created_at'] == null
      ? null
      : DateTime.parse(json['latest_message_created_at'] as String),
  latestMessageUpdatedAt: json['latest_message_updated_at'] == null
      ? null
      : DateTime.parse(json['latest_message_updated_at'] as String),
  oldestMessageCreatedAt: json['oldest_message_created_at'] == null
      ? null
      : DateTime.parse(json['oldest_message_created_at'] as String),
  hasMoreOlder: json['has_more_older'] as bool? ?? false,
);

Map<String, dynamic> _$ChatConversationSyncMetadataDtoToJson(
  ChatConversationSyncMetadataDto instance,
) => <String, dynamic>{
  'latest_message_created_at': instance.latestMessageCreatedAt
      ?.toIso8601String(),
  'latest_message_updated_at': instance.latestMessageUpdatedAt
      ?.toIso8601String(),
  'oldest_message_created_at': instance.oldestMessageCreatedAt
      ?.toIso8601String(),
  'has_more_older': instance.hasMoreOlder,
};

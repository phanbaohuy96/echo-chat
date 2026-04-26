import 'package:freezed_annotation/freezed_annotation.dart';

import '../user.dart';
import 'chat_message.dart';

part 'chat_conversation_response.g.dart';

@JsonSerializable(explicitToJson: true)
class ChatConversationResponse {
  const ChatConversationResponse({
    required this.peer,
    required this.messages,
    required this.syncMetadata,
  });

  final UserModel peer;
  final List<ChatMessageDto> messages;

  @JsonKey(name: 'sync_metadata')
  final ChatConversationSyncMetadataDto syncMetadata;

  factory ChatConversationResponse.fromJson(Map<String, dynamic> json) =>
      _$ChatConversationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ChatConversationResponseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ChatConversationSyncMetadataDto {
  const ChatConversationSyncMetadataDto({
    this.latestMessageCreatedAt,
    this.oldestMessageCreatedAt,
    this.hasMoreOlder = false,
  });

  @JsonKey(name: 'latest_message_created_at')
  final DateTime? latestMessageCreatedAt;

  @JsonKey(name: 'oldest_message_created_at')
  final DateTime? oldestMessageCreatedAt;

  @JsonKey(name: 'has_more_older')
  final bool hasMoreOlder;

  factory ChatConversationSyncMetadataDto.fromJson(Map<String, dynamic> json) =>
      _$ChatConversationSyncMetadataDtoFromJson(json);

  Map<String, dynamic> toJson() =>
      _$ChatConversationSyncMetadataDtoToJson(this);
}

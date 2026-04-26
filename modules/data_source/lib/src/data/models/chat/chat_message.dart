import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.g.dart';

@JsonSerializable(explicitToJson: true)
class ChatMessageDto {
  const ChatMessageDto({
    required this.id,
    required this.senderUserId,
    required this.recipientUserId,
    required this.clientMessageId,
    required this.message,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.version = 1,
  });

  final String id;

  @JsonKey(name: 'sender_user_id')
  final String senderUserId;

  @JsonKey(name: 'recipient_user_id')
  final String recipientUserId;

  @JsonKey(name: 'client_message_id')
  final String clientMessageId;

  final String message;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  @JsonKey(name: 'deleted_at')
  final DateTime? deletedAt;

  final int version;

  factory ChatMessageDto.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ChatMessageDtoToJson(this);
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'send_message_request.g.dart';

@JsonSerializable(explicitToJson: true)
class SendMessageRequest {
  const SendMessageRequest({
    required this.recipientUserId,
    required this.clientMessageId,
    required this.message,
  });

  @JsonKey(name: 'recipient_user_id')
  final String recipientUserId;

  @JsonKey(name: 'client_message_id')
  final String clientMessageId;

  final String message;

  factory SendMessageRequest.fromJson(Map<String, dynamic> json) =>
      _$SendMessageRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SendMessageRequestToJson(this);
}

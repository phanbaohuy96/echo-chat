import 'package:freezed_annotation/freezed_annotation.dart';

import 'chat_message.dart';

part 'send_message_response.g.dart';

@JsonSerializable(explicitToJson: true)
class SendMessageResponse {
  const SendMessageResponse({required this.message});

  final ChatMessageDto message;

  factory SendMessageResponse.fromJson(Map<String, dynamic> json) =>
      _$SendMessageResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SendMessageResponseToJson(this);
}

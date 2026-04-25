import 'package:freezed_annotation/freezed_annotation.dart';

part 'send_message_request.g.dart';

@JsonSerializable(explicitToJson: true)
class SendMessageRequest {
  const SendMessageRequest({required this.message});

  final String message;

  factory SendMessageRequest.fromJson(Map<String, dynamic> json) =>
      _$SendMessageRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SendMessageRequestToJson(this);
}

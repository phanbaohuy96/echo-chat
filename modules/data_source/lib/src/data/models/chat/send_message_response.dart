import 'package:freezed_annotation/freezed_annotation.dart';

part 'send_message_response.g.dart';

@JsonSerializable(explicitToJson: true)
class SendMessageResponse {
  const SendMessageResponse({required this.reply});

  final String reply;

  factory SendMessageResponse.fromJson(Map<String, dynamic> json) =>
      _$SendMessageResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SendMessageResponseToJson(this);
}

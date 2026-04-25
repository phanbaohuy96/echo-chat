import 'package:freezed_annotation/freezed_annotation.dart';

part 'signin_request.g.dart';

@JsonSerializable(explicitToJson: true)
class SigninRequest {
  const SigninRequest({required this.username, required this.password});

  final String username;
  final String password;

  factory SigninRequest.fromJson(Map<String, dynamic> json) =>
      _$SigninRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SigninRequestToJson(this);
}

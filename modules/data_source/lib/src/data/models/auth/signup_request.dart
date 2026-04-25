import 'package:freezed_annotation/freezed_annotation.dart';

part 'signup_request.g.dart';

@JsonSerializable(explicitToJson: true)
class SignupRequest {
  const SignupRequest({
    required this.name,
    required this.username,
    required this.password,
  });

  final String name;
  final String username;
  final String password;

  factory SignupRequest.fromJson(Map<String, dynamic> json) =>
      _$SignupRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SignupRequestToJson(this);
}

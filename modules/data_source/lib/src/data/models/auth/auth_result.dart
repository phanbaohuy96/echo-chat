import 'package:core/core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../user.dart';

part 'auth_result.g.dart';

@JsonSerializable(explicitToJson: true)
class AuthResultDto {
  const AuthResultDto({required this.token, required this.user});

  final UserToken token;
  final UserModel user;

  factory AuthResultDto.fromJson(Map<String, dynamic> json) =>
      _$AuthResultDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AuthResultDtoToJson(this);
}

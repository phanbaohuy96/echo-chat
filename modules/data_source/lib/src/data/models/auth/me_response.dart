import 'package:freezed_annotation/freezed_annotation.dart';

import '../user.dart';

part 'me_response.g.dart';

@JsonSerializable(explicitToJson: true)
class MeResponseDto {
  const MeResponseDto({required this.user});

  final UserModel user;

  factory MeResponseDto.fromJson(Map<String, dynamic> json) =>
      _$MeResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$MeResponseDtoToJson(this);
}

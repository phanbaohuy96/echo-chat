import 'package:json_annotation/json_annotation.dart';

import '../../common/constants/locale/app_locale.dart';
import '../../common/utils.dart';

part 'localization_model.g.dart';

@JsonSerializable(explicitToJson: true)
class LocalizationModel {
  @JsonKey(name: 'en')
  final String? en;
  @JsonKey(name: 'vi')
  final String? vi;

  const LocalizationModel({this.en, this.vi});

  String? localized(String languageCode) {
    if (languageCode == AppLocale.en.languageCode) {
      return en;
    }
    if (languageCode == AppLocale.vi.languageCode) {
      return vi;
    }
    return null;
  }

  factory LocalizationModel.fromValue({required String value}) {
    return LocalizationModel(en: value, vi: value);
  }

  factory LocalizationModel.fromJson(Map<String, dynamic> json) =>
      _$LocalizationModelFromJson(json);

  Map<String, dynamic> toJson() => _$LocalizationModelToJson(this);

  bool isLike(String text) {
    final keywords = text.removeDiacritic.toLowerCase();
    return (en?.toLowerCase().removeDiacritic.contains(keywords) ?? false) ||
        (vi?.toLowerCase().removeDiacritic.contains(keywords) ?? false);
  }
}

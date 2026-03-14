import 'package:freezed_annotation/freezed_annotation.dart';

part 'imx_model.freezed.dart';
part 'imx_model.g.dart';

enum ImxClassification {
  @JsonValue('highRisk')
  highRisk,    // 0 - 30
  @JsonValue('warning')
  warning,     // 31 - 50
  @JsonValue('moderate')
  moderate,    // 51 - 70
  @JsonValue('good')
  good,        // 71 - 85
  @JsonValue('optimal')
  optimal      // 86 - 100
}

@freezed
class ImxModel with _$ImxModel {
  const factory ImxModel({
    required String id,
    required double score,
    required double bodyScore,
    required double metabolicScore,
    required double lifestyleScore,
    required ImxClassification classification,
    required DateTime calculatedAt,
  }) = _ImxModel;

  factory ImxModel.fromJson(Map<String, dynamic> json) => _$ImxModelFromJson(json);
}

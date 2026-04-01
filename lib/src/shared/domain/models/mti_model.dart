import 'package:freezed_annotation/freezed_annotation.dart';

part 'mti_model.freezed.dart';
part 'mti_model.g.dart';

enum MtiClassification {
  @JsonValue('highRisk')
  highRisk, // 0 - 30
  @JsonValue('warning')
  warning, // 31 - 50
  @JsonValue('moderate')
  moderate, // 51 - 70
  @JsonValue('good')
  good, // 71 - 85
  @JsonValue('optimal')
  optimal // 86 - 100
}

@freezed
class MtiModel with _$MtiModel {
  const factory MtiModel({
    required String id,
    required double score,
    required double bodyScore,
    required double metabolicScore,
    required double lifestyleScore,
    required MtiClassification classification,
    required DateTime calculatedAt,
  }) = _MtiModel;

  factory MtiModel.fromJson(Map<String, dynamic> json) =>
      _$MtiModelFromJson(json);
}

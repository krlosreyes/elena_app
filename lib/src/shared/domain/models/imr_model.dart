
import 'package:freezed_annotation/freezed_annotation.dart';
part 'imr_model.freezed.dart';
part 'imr_model.g.dart';

enum ImrClassification {
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
abstract class ImrModel with _$ImrModel {
  const factory ImrModel({
    required String id,
    required double score,
    required double bodyScore,
    required double metabolicScore,
    required double lifestyleScore,
    required ImrClassification classification,
    required DateTime calculatedAt,
  }) = _ImrModel;

  factory ImrModel.fromJson(Map<String, dynamic> json) => _$ImrModelFromJson(json);
}

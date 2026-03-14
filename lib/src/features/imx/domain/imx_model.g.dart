// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'imx_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ImxModelImpl _$$ImxModelImplFromJson(Map<String, dynamic> json) =>
    _$ImxModelImpl(
      id: json['id'] as String,
      score: (json['score'] as num).toDouble(),
      bodyScore: (json['bodyScore'] as num).toDouble(),
      metabolicScore: (json['metabolicScore'] as num).toDouble(),
      lifestyleScore: (json['lifestyleScore'] as num).toDouble(),
      classification:
          $enumDecode(_$ImxClassificationEnumMap, json['classification']),
      calculatedAt: DateTime.parse(json['calculatedAt'] as String),
    );

Map<String, dynamic> _$$ImxModelImplToJson(_$ImxModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'score': instance.score,
      'bodyScore': instance.bodyScore,
      'metabolicScore': instance.metabolicScore,
      'lifestyleScore': instance.lifestyleScore,
      'classification': _$ImxClassificationEnumMap[instance.classification]!,
      'calculatedAt': instance.calculatedAt.toIso8601String(),
    };

const _$ImxClassificationEnumMap = {
  ImxClassification.highRisk: 'highRisk',
  ImxClassification.warning: 'warning',
  ImxClassification.moderate: 'moderate',
  ImxClassification.good: 'good',
  ImxClassification.optimal: 'optimal',
};

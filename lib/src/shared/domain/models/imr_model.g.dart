// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'imr_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ImrModel _$ImrModelFromJson(Map<String, dynamic> json) => _ImrModel(
      id: json['id'] as String,
      score: (json['score'] as num).toDouble(),
      bodyScore: (json['bodyScore'] as num).toDouble(),
      metabolicScore: (json['metabolicScore'] as num).toDouble(),
      lifestyleScore: (json['lifestyleScore'] as num).toDouble(),
      classification:
          $enumDecode(_$ImrClassificationEnumMap, json['classification']),
      calculatedAt: DateTime.parse(json['calculatedAt'] as String),
    );

Map<String, dynamic> _$ImrModelToJson(_ImrModel instance) => <String, dynamic>{
      'id': instance.id,
      'score': instance.score,
      'bodyScore': instance.bodyScore,
      'metabolicScore': instance.metabolicScore,
      'lifestyleScore': instance.lifestyleScore,
      'classification': _$ImrClassificationEnumMap[instance.classification]!,
      'calculatedAt': instance.calculatedAt.toIso8601String(),
    };

const _$ImrClassificationEnumMap = {
  ImrClassification.highRisk: 'highRisk',
  ImrClassification.warning: 'warning',
  ImrClassification.moderate: 'moderate',
  ImrClassification.good: 'good',
  ImrClassification.optimal: 'optimal',
};

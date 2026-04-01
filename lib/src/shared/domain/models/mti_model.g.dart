// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mti_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MtiModelImpl _$$MtiModelImplFromJson(Map<String, dynamic> json) =>
    _$MtiModelImpl(
      id: json['id'] as String,
      score: (json['score'] as num).toDouble(),
      bodyScore: (json['bodyScore'] as num).toDouble(),
      metabolicScore: (json['metabolicScore'] as num).toDouble(),
      lifestyleScore: (json['lifestyleScore'] as num).toDouble(),
      classification:
          $enumDecode(_$MtiClassificationEnumMap, json['classification']),
      calculatedAt: DateTime.parse(json['calculatedAt'] as String),
    );

Map<String, dynamic> _$$MtiModelImplToJson(_$MtiModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'score': instance.score,
      'bodyScore': instance.bodyScore,
      'metabolicScore': instance.metabolicScore,
      'lifestyleScore': instance.lifestyleScore,
      'classification': _$MtiClassificationEnumMap[instance.classification]!,
      'calculatedAt': instance.calculatedAt.toIso8601String(),
    };

const _$MtiClassificationEnumMap = {
  MtiClassification.highRisk: 'highRisk',
  MtiClassification.warning: 'warning',
  MtiClassification.moderate: 'moderate',
  MtiClassification.good: 'good',
  MtiClassification.optimal: 'optimal',
};

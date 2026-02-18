// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metabolic_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MetabolicStateImpl _$$MetabolicStateImplFromJson(Map<String, dynamic> json) =>
    _$MetabolicStateImpl(
      date: DateTime.parse(json['date'] as String),
      sleepHours: (json['sleepHours'] as num).toDouble(),
      sorenessLevel: (json['sorenessLevel'] as num).toInt(),
      nutritionStatus: json['nutritionStatus'] as String,
      energyLevel: (json['energyLevel'] as num).toDouble(),
      insightMessage: json['insightMessage'] as String?,
    );

Map<String, dynamic> _$$MetabolicStateImplToJson(
        _$MetabolicStateImpl instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'sleepHours': instance.sleepHours,
      'sorenessLevel': instance.sorenessLevel,
      'nutritionStatus': instance.nutritionStatus,
      'energyLevel': instance.energyLevel,
      'insightMessage': instance.insightMessage,
    };

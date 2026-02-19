// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'interactive_routine.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$InteractiveExerciseImpl _$$InteractiveExerciseImplFromJson(
        Map<String, dynamic> json) =>
    _$InteractiveExerciseImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      targetRir: json['targetRir'] as String,
      sets: (json['sets'] as List<dynamic>?)
              ?.map((e) => InteractiveSet.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      requiresWeight: json['requiresWeight'] as bool? ?? true,
    );

Map<String, dynamic> _$$InteractiveExerciseImplToJson(
        _$InteractiveExerciseImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'targetRir': instance.targetRir,
      'sets': instance.sets,
      'requiresWeight': instance.requiresWeight,
    };

_$InteractiveSetImpl _$$InteractiveSetImplFromJson(Map<String, dynamic> json) =>
    _$InteractiveSetImpl(
      setIndex: (json['setIndex'] as num).toInt(),
      targetReps: json['targetReps'] as String? ?? '8-12',
      weight: (json['weight'] as num?)?.toDouble() ?? 5.0,
      reps: (json['reps'] as num?)?.toInt(),
      isDone: json['isDone'] as bool? ?? false,
      isBonus: json['isBonus'] as bool? ?? false,
    );

Map<String, dynamic> _$$InteractiveSetImplToJson(
        _$InteractiveSetImpl instance) =>
    <String, dynamic>{
      'setIndex': instance.setIndex,
      'targetReps': instance.targetReps,
      'weight': instance.weight,
      'reps': instance.reps,
      'isDone': instance.isDone,
      'isBonus': instance.isBonus,
    };

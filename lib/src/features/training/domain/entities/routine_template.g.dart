// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine_template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RoutineExercise _$RoutineExerciseFromJson(Map<String, dynamic> json) =>
    _RoutineExercise(
      exerciseId: json['exerciseId'] as String,
      order: (json['order'] as num).toInt(),
      sets: (json['sets'] as num).toInt(),
      repsRange: json['repsRange'] as String,
      targetRir: (json['targetRir'] as num).toInt(),
      restSeconds: (json['restSeconds'] as num).toInt(),
    );

Map<String, dynamic> _$RoutineExerciseToJson(_RoutineExercise instance) =>
    <String, dynamic>{
      'exerciseId': instance.exerciseId,
      'order': instance.order,
      'sets': instance.sets,
      'repsRange': instance.repsRange,
      'targetRir': instance.targetRir,
      'restSeconds': instance.restSeconds,
    };

_RoutineTemplate _$RoutineTemplateFromJson(Map<String, dynamic> json) =>
    _RoutineTemplate(
      id: json['id'] as String,
      goal: json['goal'] as String,
      level: json['level'] as String,
      target: json['target'] as String,
      estimatedMinutes: (json['estimatedMinutes'] as num).toInt(),
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) => RoutineExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$RoutineTemplateToJson(_RoutineTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'goal': instance.goal,
      'level': instance.level,
      'target': instance.target,
      'estimatedMinutes': instance.estimatedMinutes,
      'exercises': instance.exercises.map((e) => e.toJson()).toList(),
    };

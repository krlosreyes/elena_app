// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Exercise _$ExerciseFromJson(Map<String, dynamic> json) => _Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      targetMuscle: json['targetMuscle'] as String,
      mechanics: json['mechanics'] as String,
      description: json['description'] as String,
      videoUrl: json['videoUrl'] as String?,
      requiresWeight: json['requiresWeight'] as bool? ?? true,
    );

Map<String, dynamic> _$ExerciseToJson(_Exercise instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'targetMuscle': instance.targetMuscle,
      'mechanics': instance.mechanics,
      'description': instance.description,
      'videoUrl': instance.videoUrl,
      'requiresWeight': instance.requiresWeight,
    };

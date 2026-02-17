// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ExerciseImpl _$$ExerciseImplFromJson(Map<String, dynamic> json) =>
    _$ExerciseImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      targetMuscle: json['targetMuscle'] as String,
      mechanics: json['mechanics'] as String,
      description: json['description'] as String,
      videoUrl: json['videoUrl'] as String?,
    );

Map<String, dynamic> _$$ExerciseImplToJson(_$ExerciseImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'targetMuscle': instance.targetMuscle,
      'mechanics': instance.mechanics,
      'description': instance.description,
      'videoUrl': instance.videoUrl,
    };

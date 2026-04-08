// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weekly_routine.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ExerciseTemplate _$ExerciseTemplateFromJson(Map<String, dynamic> json) =>
    _ExerciseTemplate(
      exerciseId: json['exerciseId'] as String,
      name: json['name'] as String,
      muscleGroup: json['muscleGroup'] as String,
      targetSets: (json['targetSets'] as num?)?.toInt() ?? 3,
      targetReps: (json['targetReps'] as num?)?.toInt() ?? 10,
      targetMinutes: (json['targetMinutes'] as num?)?.toInt() ?? 0,
      requiresDumbbells: json['requiresDumbbells'] as bool? ?? false,
      completedSets: (json['completedSets'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ExerciseTemplateToJson(_ExerciseTemplate instance) =>
    <String, dynamic>{
      'exerciseId': instance.exerciseId,
      'name': instance.name,
      'muscleGroup': instance.muscleGroup,
      'targetSets': instance.targetSets,
      'targetReps': instance.targetReps,
      'targetMinutes': instance.targetMinutes,
      'requiresDumbbells': instance.requiresDumbbells,
      'completedSets': instance.completedSets,
    };

_WorkoutDay _$WorkoutDayFromJson(Map<String, dynamic> json) => _WorkoutDay(
      dayIndex: (json['dayIndex'] as num).toInt(),
      type: $enumDecode(_$WorkoutDayTypeEnumMap, json['type']),
      completed: json['completed'] as bool? ?? false,
      completedAt:
          const OptionalTimestampConverter().fromJson(json['completedAt']),
      exercises: (json['exercises'] as List<dynamic>?)
              ?.map((e) => ExerciseTemplate.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$WorkoutDayToJson(_WorkoutDay instance) =>
    <String, dynamic>{
      'dayIndex': instance.dayIndex,
      'type': _$WorkoutDayTypeEnumMap[instance.type]!,
      'completed': instance.completed,
      'completedAt':
          const OptionalTimestampConverter().toJson(instance.completedAt),
      'exercises': instance.exercises.map((e) => e.toJson()).toList(),
    };

const _$WorkoutDayTypeEnumMap = {
  WorkoutDayType.strengthUpper: 'strength_upper',
  WorkoutDayType.strengthLower: 'strength_lower',
  WorkoutDayType.strengthFull: 'strength_full',
  WorkoutDayType.zone2: 'zone2',
  WorkoutDayType.hiit: 'hiit',
  WorkoutDayType.rest: 'rest',
};

_WeeklyRoutine _$WeeklyRoutineFromJson(Map<String, dynamic> json) =>
    _WeeklyRoutine(
      weekId: json['weekId'] as String,
      generatedAt:
          const TimestampConverter().fromJson(json['generatedAt'] as Object),
      activityLevelSnapshot: json['activityLevelSnapshot'] as String,
      healthGoalSnapshot: json['healthGoalSnapshot'] as String,
      completed: json['completed'] as bool? ?? false,
      days: (json['days'] as List<dynamic>?)
              ?.map((e) => WorkoutDay.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$WeeklyRoutineToJson(_WeeklyRoutine instance) =>
    <String, dynamic>{
      'weekId': instance.weekId,
      'generatedAt': const TimestampConverter().toJson(instance.generatedAt),
      'activityLevelSnapshot': instance.activityLevelSnapshot,
      'healthGoalSnapshot': instance.healthGoalSnapshot,
      'completed': instance.completed,
      'days': instance.days.map((e) => e.toJson()).toList(),
    };

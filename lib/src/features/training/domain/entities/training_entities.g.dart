// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_entities.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WorkoutSession _$WorkoutSessionFromJson(Map<String, dynamic> json) =>
    _WorkoutSession(
      id: json['id'] as String,
      userId: json['userId'] as String,
      startTime: const TimestampConverter().fromJson(json['startTime']),
      endTime: const TimestampConverter().fromJson(json['endTime']),
      intensityLevel: (json['intensityLevel'] as num).toInt(),
      type: json['type'] as String,
      targetMuscle:
          $enumDecodeNullable(_$TargetMuscleEnumMap, json['targetMuscle']),
      sets: (json['sets'] as List<dynamic>?)
              ?.map((e) => ExerciseSet.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$WorkoutSessionToJson(_WorkoutSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'startTime': const TimestampConverter().toJson(instance.startTime),
      'endTime': const TimestampConverter().toJson(instance.endTime),
      'intensityLevel': instance.intensityLevel,
      'type': instance.type,
      'targetMuscle': _$TargetMuscleEnumMap[instance.targetMuscle],
      'sets': instance.sets.map((e) => e.toJson()).toList(),
    };

const _$TargetMuscleEnumMap = {
  TargetMuscle.chest: 'chest',
  TargetMuscle.back: 'back',
  TargetMuscle.legs: 'legs',
  TargetMuscle.fullBody: 'fullBody',
  TargetMuscle.cardio: 'cardio',
  TargetMuscle.fuerza: 'fuerza',
  TargetMuscle.hiit: 'hiit',
  TargetMuscle.movilidad: 'movilidad',
};

_ExerciseSet _$ExerciseSetFromJson(Map<String, dynamic> json) => _ExerciseSet(
      setIndex: (json['setIndex'] as num).toInt(),
      exerciseName: json['exerciseName'] as String,
      weight: (json['weight'] as num).toDouble(),
      repsCompleted: (json['repsCompleted'] as num).toInt(),
      rir: (json['rir'] as num).toInt(),
      isDone: json['isDone'] as bool? ?? false,
    );

Map<String, dynamic> _$ExerciseSetToJson(_ExerciseSet instance) =>
    <String, dynamic>{
      'setIndex': instance.setIndex,
      'exerciseName': instance.exerciseName,
      'weight': instance.weight,
      'repsCompleted': instance.repsCompleted,
      'rir': instance.rir,
      'isDone': instance.isDone,
    };

_RoutineExercise _$RoutineExerciseFromJson(Map<String, dynamic> json) =>
    _RoutineExercise(
      id: json['id'] as String,
      name: json['name'] as String,
      sets: (json['sets'] as num).toInt(),
      targetReps: json['targetReps'] as String,
      rir: (json['rir'] as num).toInt(),
      restSeconds: (json['restSeconds'] as num).toInt(),
      targetMuscle: json['targetMuscle'] as String? ?? 'Unknown',
      requiresWeight: json['requiresWeight'] as bool? ?? true,
    );

Map<String, dynamic> _$RoutineExerciseToJson(_RoutineExercise instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'sets': instance.sets,
      'targetReps': instance.targetReps,
      'rir': instance.rir,
      'restSeconds': instance.restSeconds,
      'targetMuscle': instance.targetMuscle,
      'requiresWeight': instance.requiresWeight,
    };

_WeeklyTrainingStats _$WeeklyTrainingStatsFromJson(Map<String, dynamic> json) =>
    _WeeklyTrainingStats(
      totalStrengthMins: (json['totalStrengthMins'] as num).toInt(),
      totalHiitMins: (json['totalHiitMins'] as num).toInt(),
      zone2Mins: (json['zone2Mins'] as num).toInt(),
      consecutiveWeeksTrained: (json['consecutiveWeeksTrained'] as num).toInt(),
    );

Map<String, dynamic> _$WeeklyTrainingStatsToJson(
        _WeeklyTrainingStats instance) =>
    <String, dynamic>{
      'totalStrengthMins': instance.totalStrengthMins,
      'totalHiitMins': instance.totalHiitMins,
      'zone2Mins': instance.zone2Mins,
      'consecutiveWeeksTrained': instance.consecutiveWeeksTrained,
    };

_WorkoutRecommendation _$WorkoutRecommendationFromJson(
        Map<String, dynamic> json) =>
    _WorkoutRecommendation(
      type: json['type'] as String,
      targetMuscle:
          $enumDecodeNullable(_$TargetMuscleEnumMap, json['targetMuscle']),
      durationMinutes: (json['durationMinutes'] as num).toInt(),
      intensity: json['intensity'] as String,
      notes: json['notes'] as String,
    );

Map<String, dynamic> _$WorkoutRecommendationToJson(
        _WorkoutRecommendation instance) =>
    <String, dynamic>{
      'type': instance.type,
      'targetMuscle': _$TargetMuscleEnumMap[instance.targetMuscle],
      'durationMinutes': instance.durationMinutes,
      'intensity': instance.intensity,
      'notes': instance.notes,
    };

_TrainingCycle _$TrainingCycleFromJson(Map<String, dynamic> json) =>
    _TrainingCycle(
      sessionCount: (json['sessionCount'] as num).toInt(),
      isDeloadActive: json['isDeloadActive'] as bool,
      cycleNumber: (json['cycleNumber'] as num).toInt(),
      deloadStartDate: json['deloadStartDate'] == null
          ? null
          : DateTime.parse(json['deloadStartDate'] as String),
    );

Map<String, dynamic> _$TrainingCycleToJson(_TrainingCycle instance) =>
    <String, dynamic>{
      'sessionCount': instance.sessionCount,
      'isDeloadActive': instance.isDeloadActive,
      'cycleNumber': instance.cycleNumber,
      'deloadStartDate': instance.deloadStartDate?.toIso8601String(),
    };

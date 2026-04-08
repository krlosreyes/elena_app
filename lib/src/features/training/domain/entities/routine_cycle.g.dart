// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine_cycle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RoutineCycle _$RoutineCycleFromJson(Map<String, dynamic> json) =>
    _RoutineCycle(
      startDate: DateTime.parse(json['startDate'] as String),
      weeks: (json['weeks'] as List<dynamic>)
          .map((e) => RoutineWeek.fromJson(e as Map<String, dynamic>))
          .toList(),
      goalDescriptive: json['goalDescriptive'] as String,
    );

Map<String, dynamic> _$RoutineCycleToJson(_RoutineCycle instance) =>
    <String, dynamic>{
      'startDate': instance.startDate.toIso8601String(),
      'weeks': instance.weeks.map((e) => e.toJson()).toList(),
      'goalDescriptive': instance.goalDescriptive,
    };

_RoutineWeek _$RoutineWeekFromJson(Map<String, dynamic> json) => _RoutineWeek(
      weekNumber: (json['weekNumber'] as num).toInt(),
      isDeload: json['isDeload'] as bool? ?? false,
      days: (json['days'] as List<dynamic>)
          .map((e) => RoutineDay.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$RoutineWeekToJson(_RoutineWeek instance) =>
    <String, dynamic>{
      'weekNumber': instance.weekNumber,
      'isDeload': instance.isDeload,
      'days': instance.days.map((e) => e.toJson()).toList(),
    };

_RoutineDay _$RoutineDayFromJson(Map<String, dynamic> json) => _RoutineDay(
      dayNumber: (json['dayNumber'] as num).toInt(),
      isRestDay: json['isRestDay'] as bool,
      type: json['type'] as String? ?? 'Descanso',
      description: json['description'] as String? ?? '',
      exercises: (json['exercises'] as List<dynamic>?)
              ?.map((e) => RoutineExercise.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$RoutineDayToJson(_RoutineDay instance) =>
    <String, dynamic>{
      'dayNumber': instance.dayNumber,
      'isRestDay': instance.isRestDay,
      'type': instance.type,
      'description': instance.description,
      'exercises': instance.exercises.map((e) => e.toJson()).toList(),
    };

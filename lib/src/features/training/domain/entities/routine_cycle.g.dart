// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine_cycle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RoutineCycleImpl _$$RoutineCycleImplFromJson(Map<String, dynamic> json) =>
    _$RoutineCycleImpl(
      startDate: DateTime.parse(json['startDate'] as String),
      weeks: (json['weeks'] as List<dynamic>)
          .map((e) => RoutineWeek.fromJson(e as Map<String, dynamic>))
          .toList(),
      goalDescriptive: json['goalDescriptive'] as String,
    );

Map<String, dynamic> _$$RoutineCycleImplToJson(_$RoutineCycleImpl instance) =>
    <String, dynamic>{
      'startDate': instance.startDate.toIso8601String(),
      'weeks': instance.weeks,
      'goalDescriptive': instance.goalDescriptive,
    };

_$RoutineWeekImpl _$$RoutineWeekImplFromJson(Map<String, dynamic> json) =>
    _$RoutineWeekImpl(
      weekNumber: (json['weekNumber'] as num).toInt(),
      isDeload: json['isDeload'] as bool? ?? false,
      days: (json['days'] as List<dynamic>)
          .map((e) => RoutineDay.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$RoutineWeekImplToJson(_$RoutineWeekImpl instance) =>
    <String, dynamic>{
      'weekNumber': instance.weekNumber,
      'isDeload': instance.isDeload,
      'days': instance.days,
    };

_$RoutineDayImpl _$$RoutineDayImplFromJson(Map<String, dynamic> json) =>
    _$RoutineDayImpl(
      dayNumber: (json['dayNumber'] as num).toInt(),
      isRestDay: json['isRestDay'] as bool,
      type: json['type'] as String? ?? 'Descanso',
      description: json['description'] as String? ?? '',
      exercises: (json['exercises'] as List<dynamic>?)
              ?.map((e) => RoutineExercise.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$RoutineDayImplToJson(_$RoutineDayImpl instance) =>
    <String, dynamic>{
      'dayNumber': instance.dayNumber,
      'isRestDay': instance.isRestDay,
      'type': instance.type,
      'description': instance.description,
      'exercises': instance.exercises,
    };

import 'package:freezed_annotation/freezed_annotation.dart';
import 'training_entities.dart';

part 'routine_cycle.freezed.dart';
part 'routine_cycle.g.dart';

/// Represents a complete 8-week structured training cycle
@freezed
class RoutineCycle with _$RoutineCycle {
  const factory RoutineCycle({
    required DateTime startDate,
    required List<RoutineWeek> weeks,
    required String goalDescriptive, // e.g. "Recomposición Corporal - Sin Mancuernas"
  }) = _RoutineCycle;

  factory RoutineCycle.fromJson(Map<String, dynamic> json) => _$RoutineCycleFromJson(json);
}

/// Represents a single week within the 8-week cycle
@freezed
class RoutineWeek with _$RoutineWeek {
  const factory RoutineWeek({
    required int weekNumber, // 1 through 8
    @Default(false) bool isDeload, // True if weekNumber == 5
    required List<RoutineDay> days,
  }) = _RoutineWeek;

  factory RoutineWeek.fromJson(Map<String, dynamic> json) => _$RoutineWeekFromJson(json);
}

/// Represents a specific day inside a routine week
@freezed
class RoutineDay with _$RoutineDay {
  const factory RoutineDay({
    required int dayNumber, // 1 through 7
    required bool isRestDay,
    @Default('Descanso') String type, // "Full Body", "Cardio Zona 2", "Descanso Activo"
    @Default('') String description,
    @Default([]) List<RoutineExercise> exercises,
  }) = _RoutineDay;

  factory RoutineDay.fromJson(Map<String, dynamic> json) => _$RoutineDayFromJson(json);
}

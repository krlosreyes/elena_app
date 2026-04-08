import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/converters/timestamp_converter.dart';

part 'weekly_routine.freezed.dart';
part 'weekly_routine.g.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// WEEKLY ROUTINE — Metamorfosis Real Protocol
// Firestore path: users/{uid}/weekly_routines/{weekId}
// ═══════════════════════════════════════════════════════════════════════════════

/// Tipo de sesión para cada día de la semana
enum WorkoutDayType {
  @JsonValue('strength_upper')
  strengthUpper,
  @JsonValue('strength_lower')
  strengthLower,
  @JsonValue('strength_full')
  strengthFull,
  @JsonValue('zone2')
  zone2,
  @JsonValue('hiit')
  hiit,
  @JsonValue('rest')
  rest,
}

/// Plantilla de un ejercicio dentro de un día de entrenamiento
@freezed
sealed class ExerciseTemplate with _$ExerciseTemplate {
  const factory ExerciseTemplate({
    required String exerciseId,
    required String name,
    required String muscleGroup,
    @Default(3) int targetSets,
    @Default(10) int targetReps,
    @Default(0) int targetMinutes,
    @Default(false) bool requiresDumbbells,
    @Default(0) int completedSets,
  }) = _ExerciseTemplate;

  factory ExerciseTemplate.fromJson(Map<String, dynamic> json) =>
      _$ExerciseTemplateFromJson(json);
}

/// Día de entrenamiento individual
@freezed
sealed class WorkoutDay with _$WorkoutDay {
  const factory WorkoutDay({
    required int dayIndex,
    required WorkoutDayType type,
    @Default(false) bool completed,
    @OptionalTimestampConverter() DateTime? completedAt,
    @Default([]) List<ExerciseTemplate> exercises,
  }) = _WorkoutDay;

  factory WorkoutDay.fromJson(Map<String, dynamic> json) =>
      _$WorkoutDayFromJson(json);
}

/// Rutina semanal completa — documento principal
@freezed
sealed class WeeklyRoutine with _$WeeklyRoutine {
  const WeeklyRoutine._();

  const factory WeeklyRoutine({
    required String weekId,
    @TimestampConverter() required DateTime generatedAt,
    required String activityLevelSnapshot,
    required String healthGoalSnapshot,
    @Default(false) bool completed,
    @Default([]) List<WorkoutDay> days,
  }) = _WeeklyRoutine;

  factory WeeklyRoutine.fromJson(Map<String, dynamic> json) =>
      _$WeeklyRoutineFromJson(json);

  /// Obtiene el WorkoutDay para hoy (0=Lunes…6=Domingo)
  WorkoutDay? get todayWorkout {
    final todayIndex = DateTime.now().weekday - 1; // weekday: 1=Mon → 0
    return days.where((d) => d.dayIndex == todayIndex).firstOrNull;
  }

  /// Porcentaje de días completados (0.0 – 1.0)
  double get completionProgress {
    if (days.isEmpty) return 0.0;
    final done = days.where((d) => d.completed).length;
    return done / days.length;
  }

  /// WeekId ISO 8601 para la semana actual
  static String currentWeekId() {
    final now = DateTime.now();
    // ISO 8601 week number
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
    final weekNumber = ((dayOfYear - now.weekday + 10) / 7).floor();
    return '${now.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }
}

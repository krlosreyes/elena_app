import 'package:freezed_annotation/freezed_annotation.dart';
import '../enums/workout_enums.dart';
import 'training_entities.dart';

part 'daily_workout.freezed.dart';

@freezed
sealed class DailyWorkout with _$DailyWorkout {
  const factory DailyWorkout({
    required int dayIndex, // 1 to 7 (Monday to Sunday)
    required WorkoutType type,
    required int durationMinutes,
    required String description,
    required String details, // E.g., "Zona 2" or "FullBody A"
    @Default([]) List<RoutineExercise> exercises,
  }) = _DailyWorkout;
}

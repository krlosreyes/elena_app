import 'package:freezed_annotation/freezed_annotation.dart';

part 'workout_stats.freezed.dart';
part 'workout_stats.g.dart';

@freezed
class WorkoutStats with _$WorkoutStats {
  const WorkoutStats._();

  const factory WorkoutStats({
    required DateTime date,
    required double totalVolume, // kg moved
    required int durationMinutes,
    required int caloriesBurned,
    required String workoutType,
    required int totalSets,
  }) = _WorkoutStats;

  factory WorkoutStats.fromJson(Map<String, dynamic> json) =>
      _$WorkoutStatsFromJson(json);

  /// Standard Calorie Estimation Formula
  /// Formula: (MET * 3.5 * weightInKg) / 200 * durationInMinutes
  /// Strength Training MET: ~6.0
  static int calculateCalories({
    required int durationMinutes,
    double userWeightKg = 70.0, // Default if unknown
    double met = 6.0,
  }) {
    final caloriesPerMinute = (met * 3.5 * userWeightKg) / 200;
    return (caloriesPerMinute * durationMinutes).round();
  }
}

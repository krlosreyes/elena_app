import 'package:freezed_annotation/freezed_annotation.dart';

part 'workout_log.freezed.dart';
part 'workout_log.g.dart';

@freezed
class WorkoutLog with _$WorkoutLog {
  const WorkoutLog._();

  const factory WorkoutLog({
    required String id,
    required String templateId,
    required DateTime date,
    required int sessionRirScore,
    // List of maps is a simplification for now as per instructions
    // In a real app, this might be a list of LoggedExercise objects
    required List<Map<String, dynamic>> completedExercises, 
    int? durationMinutes,
    int? caloriesBurned,
  }) = _WorkoutLog;

  factory WorkoutLog.fromJson(Map<String, dynamic> json) => _$WorkoutLogFromJson(json);
}

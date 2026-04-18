import 'package:freezed_annotation/freezed_annotation.dart';

part 'exercise_log.freezed.dart';
part 'exercise_log.g.dart';

@freezed
class ExerciseLog with _$ExerciseLog {
  const factory ExerciseLog({
    required String id,
    required String userId,
    required int durationMinutes,
    required String activityType,
    required DateTime timestamp,
    @Default(1.0) double intensityMultiplier,
  }) = _ExerciseLog;

  factory ExerciseLog.fromJson(Map<String, dynamic> json) =>
      _$ExerciseLogFromJson(json);
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'routine_template.freezed.dart';
part 'routine_template.g.dart';

@freezed
sealed class RoutineExercise with _$RoutineExercise {
  const factory RoutineExercise({
    required String exerciseId,
    required int order,
    required int sets,
    required String repsRange,
    required int targetRir,
    required int restSeconds,
  }) = _RoutineExercise;

  factory RoutineExercise.fromJson(Map<String, dynamic> json) =>
      _$RoutineExerciseFromJson(json);
}

@freezed
sealed class RoutineTemplate with _$RoutineTemplate {
  const factory RoutineTemplate({
    required String id,
    required String goal,
    required String level,
    required String target, // e.g., "Full Body", "Upper"
    required int estimatedMinutes,
    required List<RoutineExercise> exercises,
  }) = _RoutineTemplate;

  factory RoutineTemplate.fromJson(Map<String, dynamic> json) =>
      _$RoutineTemplateFromJson(json);
}

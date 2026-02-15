import 'package:freezed_annotation/freezed_annotation.dart';

part 'interactive_routine.freezed.dart';
part 'interactive_routine.g.dart';

/// Represents an exercise within an active/interactive workout session.
/// Uses Freezed for immutable state with copyWith support.
@freezed
class InteractiveExercise with _$InteractiveExercise {
  const factory InteractiveExercise({
    required String id,
    required String name,
    @Default(2) int targetRir,
    @Default([]) List<InteractiveSet> sets,
  }) = _InteractiveExercise;

  factory InteractiveExercise.fromJson(Map<String, dynamic> json) =>
      _$InteractiveExerciseFromJson(json);
}

/// Represents a single set within an interactive exercise.
@freezed
class InteractiveSet with _$InteractiveSet {
  const factory InteractiveSet({
    required int setIndex,
    @Default('8-12') String targetReps,
    @Default(5.0) double weight,
    int? reps,
    @Default(false) bool isDone,
  }) = _InteractiveSet;

  factory InteractiveSet.fromJson(Map<String, dynamic> json) =>
      _$InteractiveSetFromJson(json);
}

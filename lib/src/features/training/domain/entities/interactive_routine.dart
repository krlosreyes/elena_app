import 'package:freezed_annotation/freezed_annotation.dart';

part 'interactive_routine.freezed.dart';
part 'interactive_routine.g.dart';

/// Represents an exercise within an active/interactive workout session.
/// Uses Freezed for immutable state with copyWith support.
@freezed
sealed class InteractiveExercise with _$InteractiveExercise {
  const factory InteractiveExercise({
    required String id,
    required String name,
    required String targetRir, // e.g. "2-3"
    @Default([]) List<InteractiveSet> sets,
    @Default(true) bool requiresWeight, // Added for UI logic
  }) = _InteractiveExercise;

  factory InteractiveExercise.fromJson(Map<String, dynamic> json) =>
      _$InteractiveExerciseFromJson(json);
}

/// Represents a single set within an interactive exercise.
@freezed
sealed class InteractiveSet with _$InteractiveSet {
  const factory InteractiveSet({
    required int setIndex,
    @Default('8-12') String targetReps,
    @Default(5.0) double weight,
    int? reps,
    @Default(false) bool isDone,
    @Default(false) bool isBonus, // Track extra sets
  }) = _InteractiveSet;

  factory InteractiveSet.fromJson(Map<String, dynamic> json) =>
      _$InteractiveSetFromJson(json);
}

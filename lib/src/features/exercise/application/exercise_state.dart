import 'package:freezed_annotation/freezed_annotation.dart';

part 'exercise_state.freezed.dart';

@freezed
class ExerciseState with _$ExerciseState {
  const factory ExerciseState({
    @Default(0) int todayMinutes,
    @Default(false) bool isSaving,
    String? error,
  }) = _ExerciseState;
}

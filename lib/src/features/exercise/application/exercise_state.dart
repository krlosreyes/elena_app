import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:elena_app/src/features/exercise/domain/exercise_log.dart';

part 'exercise_state.freezed.dart';

@freezed
class ExerciseState with _$ExerciseState {
  const factory ExerciseState({
    @Default(0) int todayMinutes,
    @Default([]) List<ExerciseLog> history,
    @Default(false) bool isSaving,
    String? error,
  }) = _ExerciseState;
}

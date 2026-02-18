import 'package:freezed_annotation/freezed_annotation.dart';

part 'metabolic_state.freezed.dart';
part 'metabolic_state.g.dart';

@freezed
class MetabolicState with _$MetabolicState {
  const factory MetabolicState({
    required DateTime date,
    required double sleepHours,
    required int sorenessLevel, // 1-5
    required String nutritionStatus, // "fasted", "fed"
    required double energyLevel, // 1-10
    required String? insightMessage,
  }) = _MetabolicState;

  factory MetabolicState.fromJson(Map<String, dynamic> json) => _$MetabolicStateFromJson(json);
}

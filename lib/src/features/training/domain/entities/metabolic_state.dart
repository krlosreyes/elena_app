import 'package:freezed_annotation/freezed_annotation.dart';

part 'metabolic_state.freezed.dart';
part 'metabolic_state.g.dart';

@freezed
sealed class MetabolicState with _$MetabolicState {
  const factory MetabolicState({
    required DateTime date,
    required double sleepHours,
    required int sorenessLevel,
    required String nutritionStatus,
    required double energyLevel,
    required String? insightMessage,
  }) = _MetabolicState;

  factory MetabolicState.fromJson(Map<String, dynamic> json) => _$MetabolicStateFromJson(json);
}

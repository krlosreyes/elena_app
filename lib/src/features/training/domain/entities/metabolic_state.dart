import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/health/domain/user_health_state.dart';

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

  /// Canonical conversion from [UserHealthState].
  ///
  /// Keeps this legacy entity aligned with the single source of truth.
  factory MetabolicState.fromUserHealthState(
    UserHealthState state, {
    DateTime? date,
    double? sleepHoursOverride,
    int? sorenessLevelOverride,
    String? nutritionStatusOverride,
    double? energyLevelOverride,
    String? insightMessage,
  }) {
    final sleepHours = sleepHoursOverride ??
        (state.sleepLog?.hours ?? (state.dailyLog.sleepMinutes / 60.0));
    final soreness = sorenessLevelOverride ??
        _deriveSorenessFromRecovery(
          recoveryScore: state.recoveryScore,
          recentWorkoutCount: state.workouts.length,
        );
    final nutritionStatus =
        nutritionStatusOverride ?? (state.isFastingActive ? 'fasted' : 'fed');
    final energyLevel =
        energyLevelOverride ?? _toTenPointScale(state.energyScore);

    return MetabolicState(
      date: date ?? DateTime.now(),
      sleepHours: sleepHours,
      sorenessLevel: soreness,
      nutritionStatus: nutritionStatus,
      energyLevel: energyLevel,
      insightMessage: insightMessage,
    );
  }

  static int _deriveSorenessFromRecovery({
    required double recoveryScore,
    required int recentWorkoutCount,
  }) {
    if (recentWorkoutCount == 0) return 1;
    if (recoveryScore >= 80) return 1;
    if (recoveryScore >= 65) return 2;
    if (recoveryScore >= 50) return 3;
    if (recoveryScore >= 35) return 4;
    return 5;
  }

  static double _toTenPointScale(double score0to100) {
    return (score0to100 / 10.0).clamp(1.0, 10.0);
  }

  factory MetabolicState.fromJson(Map<String, dynamic> json) =>
      _$MetabolicStateFromJson(json);
}

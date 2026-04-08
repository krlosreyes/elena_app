import 'dart:collection';

/// Domain entity that aggregates health metrics.
///
/// Pure Dart (no Flutter dependencies), immutable, and safe by default.
class HealthState {
  final double fastingScore;
  final double hydrationScore;
  final double sleepScore;
  final double nutritionScore;
  final double trainingScore;
  final List<String> recommendations;
  final DateTime lastUpdated;

  HealthState({
    required double fastingScore,
    required double hydrationScore,
    required double sleepScore,
    required double nutritionScore,
    required double trainingScore,
    List<String> recommendations = const <String>[],
    required DateTime lastUpdated,
  })  : fastingScore = _clampScore(fastingScore),
        hydrationScore = _clampScore(hydrationScore),
        sleepScore = _clampScore(sleepScore),
        nutritionScore = _clampScore(nutritionScore),
        trainingScore = _clampScore(trainingScore),
        recommendations =
            UnmodifiableListView(List<String>.from(recommendations)),
        lastUpdated = lastUpdated;

  factory HealthState.initial() {
    return HealthState(
      fastingScore: 0.0,
      hydrationScore: 0.0,
      sleepScore: 0.0,
      nutritionScore: 0.0,
      trainingScore: 0.0,
      recommendations: const <String>[],
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  HealthState copyWith({
    double? fastingScore,
    double? hydrationScore,
    double? sleepScore,
    double? nutritionScore,
    double? trainingScore,
    List<String>? recommendations,
    DateTime? lastUpdated,
  }) {
    return HealthState(
      fastingScore: fastingScore ?? this.fastingScore,
      hydrationScore: hydrationScore ?? this.hydrationScore,
      sleepScore: sleepScore ?? this.sleepScore,
      nutritionScore: nutritionScore ?? this.nutritionScore,
      trainingScore: trainingScore ?? this.trainingScore,
      recommendations: recommendations ?? this.recommendations,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  static double _clampScore(double value) {
    if (value.isNaN) return 0.0;
    if (value.isInfinite) return value.isNegative ? 0.0 : 100.0;
    if (value < 0.0) return 0.0;
    if (value > 100.0) return 100.0;
    return value;
  }
}

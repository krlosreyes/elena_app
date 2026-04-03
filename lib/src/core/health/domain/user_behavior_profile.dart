import 'dart:collection';

/// Adaptive behavioral profile used by core health decision systems.
///
/// Pure domain model: stores behavioral adherence/tolerance signals and
/// action feedback loops without any UI or framework dependencies.
class UserBehaviorProfile {
  final double fastingTolerance;
  final double trainingRecoveryRate;
  final double sleepConsistency;
  final double hydrationDiscipline;
  final double nutritionCompliance;

  /// How many times each action was triggered.
  final Map<String, int> actionHistoryCounts;

  /// Success ratio for each action in [0.0, 1.0].
  final Map<String, double> actionSuccessRates;

  UserBehaviorProfile({
    this.fastingTolerance = 0.5,
    this.trainingRecoveryRate = 0.5,
    this.sleepConsistency = 0.5,
    this.hydrationDiscipline = 0.5,
    this.nutritionCompliance = 0.5,
    Map<String, int> actionHistoryCounts = const {},
    Map<String, double> actionSuccessRates = const {},
  })  : assert(
          fastingTolerance >= 0.0 && fastingTolerance <= 1.0,
          'fastingTolerance must be in [0,1]',
        ),
        assert(
          trainingRecoveryRate >= 0.0 && trainingRecoveryRate <= 1.0,
          'trainingRecoveryRate must be in [0,1]',
        ),
        assert(
          sleepConsistency >= 0.0 && sleepConsistency <= 1.0,
          'sleepConsistency must be in [0,1]',
        ),
        assert(
          hydrationDiscipline >= 0.0 && hydrationDiscipline <= 1.0,
          'hydrationDiscipline must be in [0,1]',
        ),
        assert(
          nutritionCompliance >= 0.0 && nutritionCompliance <= 1.0,
          'nutritionCompliance must be in [0,1]',
        ),
        actionHistoryCounts =
            UnmodifiableMapView(Map<String, int>.from(actionHistoryCounts)),
        actionSuccessRates = UnmodifiableMapView(
          Map<String, double>.from(actionSuccessRates)
            ..updateAll((_, value) => value.clamp(0.0, 1.0)),
        );

  UserBehaviorProfile copyWith({
    double? fastingTolerance,
    double? trainingRecoveryRate,
    double? sleepConsistency,
    double? hydrationDiscipline,
    double? nutritionCompliance,
    Map<String, int>? actionHistoryCounts,
    Map<String, double>? actionSuccessRates,
  }) {
    return UserBehaviorProfile(
      fastingTolerance: fastingTolerance ?? this.fastingTolerance,
      trainingRecoveryRate: trainingRecoveryRate ?? this.trainingRecoveryRate,
      sleepConsistency: sleepConsistency ?? this.sleepConsistency,
      hydrationDiscipline: hydrationDiscipline ?? this.hydrationDiscipline,
      nutritionCompliance: nutritionCompliance ?? this.nutritionCompliance,
      actionHistoryCounts: actionHistoryCounts ?? this.actionHistoryCounts,
      actionSuccessRates: actionSuccessRates ?? this.actionSuccessRates,
    );
  }

  /// Registers that an action was emitted/applied.
  ///
  /// Increments [actionHistoryCounts[action]] and keeps success rates unchanged.
  UserBehaviorProfile registerAction(String action) {
    final normalized = action.trim();
    if (normalized.isEmpty) return this;

    final updatedCounts = Map<String, int>.from(actionHistoryCounts);
    updatedCounts.update(normalized, (value) => value + 1, ifAbsent: () => 1);

    return copyWith(actionHistoryCounts: updatedCounts);
  }

  /// Registers the observed outcome for an action and updates success rate.
  ///
  /// Uses incremental averaging to keep deterministic bounded ratios in [0,1].
  UserBehaviorProfile registerOutcome(String action, bool success) {
    final normalized = action.trim();
    if (normalized.isEmpty) return this;

    final previousCount = actionHistoryCounts[normalized] ?? 0;
    final newCount = previousCount + 1;

    final previousRate = actionSuccessRates[normalized] ?? 0.0;
    final previousSuccesses = previousRate * previousCount;
    final updatedSuccesses = previousSuccesses + (success ? 1.0 : 0.0);
    final newRate = (updatedSuccesses / newCount).clamp(0.0, 1.0);

    final updatedCounts = Map<String, int>.from(actionHistoryCounts)
      ..[normalized] = newCount;

    final updatedRates = Map<String, double>.from(actionSuccessRates)
      ..[normalized] = newRate;

    return copyWith(
      actionHistoryCounts: updatedCounts,
      actionSuccessRates: updatedRates,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserBehaviorProfile &&
          runtimeType == other.runtimeType &&
          fastingTolerance == other.fastingTolerance &&
          trainingRecoveryRate == other.trainingRecoveryRate &&
          sleepConsistency == other.sleepConsistency &&
          hydrationDiscipline == other.hydrationDiscipline &&
          nutritionCompliance == other.nutritionCompliance &&
          _mapEquals(actionHistoryCounts, other.actionHistoryCounts) &&
          _mapEquals(actionSuccessRates, other.actionSuccessRates);

  @override
  int get hashCode => Object.hash(
        fastingTolerance,
        trainingRecoveryRate,
        sleepConsistency,
        hydrationDiscipline,
        nutritionCompliance,
        Object.hashAll(actionHistoryCounts.entries),
        Object.hashAll(actionSuccessRates.entries),
      );

  static bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}

import '../../../core/health/domain/decision_output.dart';
import '../../../core/health/domain/user_health_state.dart';
import '../../../features/nutrition/domain/entities/metabolic_profile.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DASHBOARD ADAPTER
// ─────────────────────────────────────────────────────────────────────────────
//
// Maps [UserHealthState] (new domain model) → existing dashboard data
// structures consumed by widgets. Zero UI logic, zero widget modifications.
//
// Widgets currently consume:
//   • MetabolicContext.totalIED           ← energyScore
//   • MetabolicPentagonGrid (5 pilars)   ← metabolicScore breakdowns
//   • FastingStatusWidget                 ← fasting state
//   • HabitCard (progress bars)           ← recovery indicators
//   • ElenaDiagnosisCard (text)           ← diagnostic messages
//   • dailyComplianceScoreProvider        ← energyScore
//
// This adapter is framework-agnostic (no Riverpod, no Flutter).
// It can be consumed by providers that bridge to the existing widget tree.
// ─────────────────────────────────────────────────────────────────────────────

class DashboardAdapter {
  const DashboardAdapter();

  /// Full mapping: UserHealthState → DashboardSnapshot
  DashboardSnapshot adapt(
    UserHealthState state, {
    DecisionOutput? decision,
  }) {
    return DashboardSnapshot(
      mainMessage: decision?.primaryAction ?? _defaultMainMessage(state),
      subtitle: decision?.explanation ?? _defaultSubtitle(state),
      energy: _mapEnergy(state),
      metabolic: _mapMetabolic(state, decision: decision),
      recovery: _mapRecovery(state),
      fasting: _mapFasting(state),
      compliance: _mapCompliance(state, decision: decision),
      pentagonScores: _mapPentagonScores(state, decision: decision),
    );
  }

  static String _defaultMainMessage(UserHealthState state) {
    if (state.recoveryScore < 40) return 'Prioriza recuperación hoy';
    if (state.energyScore < 35) return 'Recarga energía con una comida';
    if (state.isFastingActive) return 'Mantén tu ayuno activo';
    return 'Sigue tu plan metabólico';
  }

  static String _defaultSubtitle(UserHealthState state) {
    if (state.recoveryScore < 40) {
      return 'Tu recuperación está baja. Reduce intensidad y prioriza sueño.';
    }
    if (state.energyScore < 35) {
      return 'La energía actual es limitada; prioriza nutrición e hidratación.';
    }
    return 'Tu estado metabólico está siendo monitoreado en tiempo real.';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ENERGY → dashboard energy (totalIED, dailyComplianceScore)
  // ═══════════════════════════════════════════════════════════════════════════

  DashboardEnergy _mapEnergy(UserHealthState state) {
    final score = state.energyScore; // 0–100

    return DashboardEnergy(
      score: score,
      label: _energyLabel(score),
      sleepHours: state.sleepLog?.hours ?? (state.dailyLog.sleepMinutes / 60.0),
      hydrationGlasses: state.dailyLog.waterGlasses,
      caloriesConsumed: state.dailyLog.calories,
      tdeeTarget: state.metabolicProfile.tdee,
    );
  }

  static String _energyLabel(double score) {
    if (score >= 85) return 'Óptima';
    if (score >= 60) return 'Buena';
    if (score >= 30) return 'Moderada';
    return 'Baja';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // METABOLIC → metabolic widget (MetabolicPentagonGrid)
  // ═══════════════════════════════════════════════════════════════════════════

  DashboardMetabolic _mapMetabolic(
    UserHealthState state, {
    DecisionOutput? decision,
  }) {
    final profile = state.metabolicProfile;

    return DashboardMetabolic(
      score: state.metabolicScore, // 0–100
      insulinSensitivity: profile.insulinSensitivity.name,
      metabolicFlexibility: profile.metabolicFlexibility.name,
      adaptationState: profile.adaptationState.name,
      bodyFatPercent: profile.bodyFatPercent,
      bmr: profile.bmr,
      tdee: profile.tdee,
      currentGoal: profile.goal.name,
      estimatedGlucose: profile.estimatedCurrentGlucose,
      estimatedKetones: profile.estimatedCurrentKetones,
      metabolicState: decision?.metabolicState ?? _defaultMetabolicState(state),
      statusBadge: (decision?.metabolicState ?? _defaultMetabolicState(state))
          .toUpperCase(),
    );
  }

  static String _defaultMetabolicState(UserHealthState state) {
    if (state.isFastingActive) return 'fat_burning';
    if (state.recoveryScore < 40) return 'recovery';
    if (state.energyScore >= 75) return 'energy_boost';
    return 'metabolic_balance';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RECOVERY → recovery indicators (HabitCard, readiness)
  // ═══════════════════════════════════════════════════════════════════════════

  DashboardRecovery _mapRecovery(UserHealthState state) {
    final workouts = state.workouts;
    final now = DateTime.now();

    // Recent workouts in last 48h
    final recentCount =
        workouts.where((w) => now.difference(w.date).inHours <= 48).length;

    // Total training minutes in last 48h
    final recentMinutes = workouts
        .where((w) => now.difference(w.date).inHours <= 48)
        .fold<int>(0, (sum, w) => sum + (w.durationMinutes ?? 45));

    // Any fasted training recently?
    final hasFastedTraining = workouts
        .where((w) => now.difference(w.date).inHours <= 48)
        .any((w) => w.isFasted);

    return DashboardRecovery(
      score: state.recoveryScore, // 0–100
      label: _recoveryLabel(state.recoveryScore),
      recentWorkoutCount: recentCount,
      recentTrainingMinutes: recentMinutes,
      hasFastedTraining: hasFastedTraining,
      sleepHours: state.sleepLog?.hours ?? (state.dailyLog.sleepMinutes / 60.0),
      isReadyForIntenseTraining: state.recoveryScore >= 70.0,
    );
  }

  static String _recoveryLabel(double score) {
    if (score >= 85) return 'Recuperado';
    if (score >= 60) return 'Moderado';
    if (score >= 30) return 'Fatigado';
    return 'Agotado';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FASTING → fasting_status_widget
  // ═══════════════════════════════════════════════════════════════════════════

  DashboardFastingStatus _mapFasting(UserHealthState state) {
    final ctx = state.metabolicProfile.fastingContext;
    final log = state.dailyLog;

    // Determine times for the widget
    DateTime? windowStart;
    DateTime? windowEnd;

    if (state.isFastingActive) {
      // Fasting phase: show fasting window
      windowStart = log.fastingStartTime;
      if (windowStart != null) {
        windowEnd = windowStart.add(
          Duration(hours: ctx.fastingWindowHours.round()),
        );
      }
    } else {
      // Feeding phase: show feeding window
      windowStart = log.fastingEndTime ??
          log.fastingStartTime?.add(
            Duration(hours: ctx.fastingWindowHours.round()),
          );
      if (windowStart != null) {
        windowEnd = windowStart.add(
          Duration(hours: ctx.feedingWindowHours.round()),
        );
      }
    }

    return DashboardFastingStatus(
      isFasting: state.isFastingActive,
      isFeeding: state.isInFeedingWindow,
      protocol: ctx.protocol.name,
      fastingWindowHours: ctx.fastingWindowHours,
      feedingWindowHours: ctx.feedingWindowHours,
      elapsedHours: ctx.currentFastingElapsedHours,
      windowStart: windowStart,
      windowEnd: windowEnd,
      metabolicBonus: ctx.fastingMetabolicBonus,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPLIANCE → backward-compatible dailyComplianceScore
  // ═══════════════════════════════════════════════════════════════════════════

  DashboardCompliance _mapCompliance(
    UserHealthState state, {
    DecisionOutput? decision,
  }) {
    final log = state.dailyLog;
    final profile = state.metabolicProfile;

    // 5-pillar IED calculation matching MetabolicHub.build()
    // Pilar 1: Fasting
    final fastingScore = state.isFastingActive ? 0.0 : 100.0;

    // Pilar 2: Nutrition (meals logged vs expected)
    final mealsLogged = log.mealEntries.length;
    final mealsExpected = _expectedMeals(profile.fastingContext);
    final nutritionScore = mealsExpected > 0
        ? (mealsLogged / mealsExpected).clamp(0.0, 1.0) * 100.0
        : 0.0;

    // Pilar 3: Exercise
    const exerciseGoal = 30.0;
    final exerciseScore =
        (log.exerciseMinutes / exerciseGoal * 100.0).clamp(0.0, 100.0);

    // Pilar 4: Sleep
    const sleepGoalMinutes = 8.0 * 60.0;
    final sleepScore =
        (log.sleepMinutes / sleepGoalMinutes * 100.0).clamp(0.0, 100.0);

    // Pilar 5: Hydration
    const hydrationGoal = 8.0;
    final hydrationScore =
        (log.waterGlasses / hydrationGoal * 100.0).clamp(0.0, 100.0);

    final decisionScores = decision?.pillarScores;
    final resolvedFastingScore =
        (decisionScores?[DecisionOutput.fastingPillar] ?? fastingScore)
            .clamp(0.0, 100.0);
    final resolvedNutritionScore =
        (decisionScores?[DecisionOutput.nutritionPillar] ?? nutritionScore)
            .clamp(0.0, 100.0);
    final resolvedExerciseScore =
        (decisionScores?[DecisionOutput.trainingPillar] ?? exerciseScore)
            .clamp(0.0, 100.0);
    final resolvedSleepScore =
        (decisionScores?[DecisionOutput.sleepPillar] ?? sleepScore)
            .clamp(0.0, 100.0);
    final resolvedHydrationScore =
        (decisionScores?[DecisionOutput.hydrationPillar] ?? hydrationScore)
            .clamp(0.0, 100.0);

    final totalIED = (resolvedFastingScore +
            resolvedNutritionScore +
            resolvedExerciseScore +
            resolvedSleepScore +
            resolvedHydrationScore) /
        5.0;

    return DashboardCompliance(
      totalIED: totalIED,
      fastingScore: resolvedFastingScore,
      nutritionScore: resolvedNutritionScore,
      exerciseScore: resolvedExerciseScore,
      sleepScore: resolvedSleepScore,
      hydrationScore: resolvedHydrationScore,
      mealsLogged: mealsLogged,
      mealsExpected: mealsExpected,
    );
  }

  Map<String, double> _mapPentagonScores(
    UserHealthState state, {
    DecisionOutput? decision,
  }) {
    final compliance = _mapCompliance(state, decision: decision);

    return {
      DecisionOutput.fastingPillar: compliance.fastingScore,
      DecisionOutput.nutritionPillar: compliance.nutritionScore,
      DecisionOutput.trainingPillar: compliance.exerciseScore,
      DecisionOutput.hydrationPillar: compliance.hydrationScore,
      DecisionOutput.sleepPillar: compliance.sleepScore,
    };
  }

  /// Derives expected meals from the feeding window size.
  static int _expectedMeals(FastingContext ctx) {
    final feedingHours = ctx.feedingWindowHours;
    if (feedingHours <= 1.5) return 1; // OMAD
    if (feedingHours < 8.0) return 2;
    return 3;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA STRUCTURES — backward-compatible with existing widget contracts
// ─────────────────────────────────────────────────────────────────────────────
// These are pure data classes. Widgets can read them without changes.
// They mirror the fields that MetabolicContext and providers already expose.
// ─────────────────────────────────────────────────────────────────────────────

/// Complete dashboard snapshot built from UserHealthState.
class DashboardSnapshot {
  final String mainMessage;
  final String subtitle;
  final DashboardEnergy energy;
  final DashboardMetabolic metabolic;
  final DashboardRecovery recovery;
  final DashboardFastingStatus fasting;
  final DashboardCompliance compliance;
  final Map<String, double> pentagonScores;

  const DashboardSnapshot({
    required this.mainMessage,
    required this.subtitle,
    required this.energy,
    required this.metabolic,
    required this.recovery,
    required this.fasting,
    required this.compliance,
    required this.pentagonScores,
  });
}

/// Energy panel data (maps to totalIED / dailyComplianceScore).
class DashboardEnergy {
  final double score; // 0–100
  final String label; // 'Óptima', 'Buena', 'Moderada', 'Baja'
  final double sleepHours;
  final int hydrationGlasses;
  final int caloriesConsumed;
  final double tdeeTarget;

  const DashboardEnergy({
    required this.score,
    required this.label,
    required this.sleepHours,
    required this.hydrationGlasses,
    required this.caloriesConsumed,
    required this.tdeeTarget,
  });

  /// Caloric adherence (0.0–1.0) for progress indicators.
  double get caloricAdherence => tdeeTarget > 0
      ? (1.0 - ((caloriesConsumed - tdeeTarget).abs() / tdeeTarget))
          .clamp(0.0, 1.0)
      : 0.0;
}

/// Metabolic widget data (maps to MetabolicPentagonGrid inputs).
class DashboardMetabolic {
  final double score; // 0–100
  final String insulinSensitivity; // enum name
  final String metabolicFlexibility; // enum name
  final String adaptationState; // enum name
  final double bodyFatPercent;
  final double bmr;
  final double tdee;
  final String currentGoal; // MetabolicGoal enum name
  final double? estimatedGlucose;
  final double? estimatedKetones;
  final String metabolicState; // from DecisionOutput.metabolicState
  final String statusBadge; // uppercase badge for status/chips

  const DashboardMetabolic({
    required this.score,
    required this.insulinSensitivity,
    required this.metabolicFlexibility,
    required this.adaptationState,
    required this.bodyFatPercent,
    required this.bmr,
    required this.tdee,
    required this.currentGoal,
    this.estimatedGlucose,
    this.estimatedKetones,
    required this.metabolicState,
    required this.statusBadge,
  });
}

/// Recovery indicators (maps to HabitCard recovery display).
class DashboardRecovery {
  final double score; // 0–100
  final String label; // 'Recuperado', 'Moderado', 'Fatigado', 'Agotado'
  final int recentWorkoutCount;
  final int recentTrainingMinutes;
  final bool hasFastedTraining;
  final double sleepHours;
  final bool isReadyForIntenseTraining;

  const DashboardRecovery({
    required this.score,
    required this.label,
    required this.recentWorkoutCount,
    required this.recentTrainingMinutes,
    required this.hasFastedTraining,
    required this.sleepHours,
    required this.isReadyForIntenseTraining,
  });
}

/// Fasting status data (maps to FastingStatusWidget).
class DashboardFastingStatus {
  final bool isFasting;
  final bool isFeeding;
  final String protocol; // FastingProtocol enum name
  final double fastingWindowHours;
  final double feedingWindowHours;
  final double elapsedHours;
  final DateTime? windowStart;
  final DateTime? windowEnd;
  final double metabolicBonus; // 0.0–0.55

  const DashboardFastingStatus({
    required this.isFasting,
    required this.isFeeding,
    required this.protocol,
    required this.fastingWindowHours,
    required this.feedingWindowHours,
    required this.elapsedHours,
    this.windowStart,
    this.windowEnd,
    required this.metabolicBonus,
  });

  /// Status label matching FastingStatusWidget expectations.
  String get statusLabel => isFasting ? 'ESTÁS AYUNANDO' : 'VENTANA ABIERTA';
}

/// IED compliance data (backward-compatible with MetabolicHub.totalIED).
class DashboardCompliance {
  final double totalIED; // 0–100 (average of 5 pillars)
  final double fastingScore; // 0–100
  final double nutritionScore; // 0–100
  final double exerciseScore; // 0–100
  final double sleepScore; // 0–100
  final double hydrationScore; // 0–100
  final int mealsLogged;
  final int mealsExpected;

  const DashboardCompliance({
    required this.totalIED,
    required this.fastingScore,
    required this.nutritionScore,
    required this.exerciseScore,
    required this.sleepScore,
    required this.hydrationScore,
    required this.mealsLogged,
    required this.mealsExpected,
  });

  /// Pillar progress values (0.0–1.0) matching existing widget contracts.
  double get fastingProgress => fastingScore / 100.0;
  double get nutritionProgress => nutritionScore / 100.0;
  double get exerciseProgress => exerciseScore / 100.0;
  double get sleepProgress => sleepScore / 100.0;
  double get hydrationProgress => hydrationScore / 100.0;
}

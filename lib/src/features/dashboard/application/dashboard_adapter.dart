import '../../../core/health/domain/decision_output.dart';
import '../../../core/health/domain/user_health_state.dart';
import '../../../features/nutrition/domain/entities/metabolic_profile.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DASHBOARD ADAPTER - REPARADO PARA TELEMETRÍA REAL
// ─────────────────────────────────────────────────────────────────────────────

class DashboardAdapter {
  const DashboardAdapter();

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
    return 'Sigue tu plan metabólico';
  }

  static String _defaultSubtitle(UserHealthState state) {
    return 'Tu estado metabólico está siendo monitoreado en tiempo real.';
  }

  DashboardEnergy _mapEnergy(UserHealthState state) {
    final score = state.energyScore;
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
    return 'Moderada';
  }

  DashboardMetabolic _mapMetabolic(
    UserHealthState state, {
    DecisionOutput? decision,
  }) {
    final profile = state.metabolicProfile;
    final status = decision?.metabolicState ?? _defaultMetabolicState(state);

    return DashboardMetabolic(
      score: state.metabolicScore,
      insulinSensitivity: profile.insulinSensitivity.name,
      metabolicFlexibility: profile.metabolicFlexibility.name,
      adaptationState: profile.adaptationState.name,
      bodyFatPercent: profile.bodyFatPercent,
      bmr: profile.bmr,
      tdee: profile.tdee,
      currentGoal: profile.goal.name,
      estimatedGlucose: profile.estimatedCurrentGlucose,
      estimatedKetones: profile.estimatedCurrentKetones,
      metabolicState: status,
      statusBadge: status.toUpperCase(),
    );
  }

  static String _defaultMetabolicState(UserHealthState state) {
    if (state.isFastingActive) return 'fat_burning';
    return 'metabolic_balance';
  }

  DashboardRecovery _mapRecovery(UserHealthState state) {
    return DashboardRecovery(
      score: state.recoveryScore,
      label: _recoveryLabel(state.recoveryScore),
      recentWorkoutCount: state.workouts.length,
      recentTrainingMinutes: state.dailyLog.exerciseMinutes,
      hasFastedTraining: state.workouts.any((w) => w.isFasted),
      sleepHours: state.sleepLog?.hours ?? (state.dailyLog.sleepMinutes / 60.0),
      isReadyForIntenseTraining: state.recoveryScore >= 70.0,
    );
  }

  static String _recoveryLabel(double score) {
    if (score >= 85) return 'Recuperado';
    return 'Moderado';
  }

  DashboardFastingStatus _mapFasting(UserHealthState state) {
    final ctx = state.metabolicProfile.fastingContext;
    return DashboardFastingStatus(
      isFasting: state.isFastingActive,
      isFeeding: state.isInFeedingWindow,
      protocol: ctx.protocol.name,
      fastingWindowHours: ctx.fastingWindowHours,
      feedingWindowHours: ctx.feedingWindowHours,
      elapsedHours: ctx.currentFastingElapsedHours,
      metabolicBonus: ctx.fastingMetabolicBonus,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPLIANCE - AQUÍ SE CORRIGEN LOS MARCADORES TREN / NUTRI
  // ═══════════════════════════════════════════════════════════════════════════

  DashboardCompliance _mapCompliance(
    UserHealthState state, {
    DecisionOutput? decision,
  }) {
    final decisionScores = decision?.pillarScores;

    // Sincronización directa con el DecisionEngine (0.0 - 1.0) -> (0 - 100)
    final resolvedFastingScore = (decisionScores?[DecisionOutput.fastingPillar] ?? 0.0) * 100.0;
    final resolvedNutritionScore = (decisionScores?[DecisionOutput.nutritionPillar] ?? 0.0) * 100.0;
    final resolvedExerciseScore = (decisionScores?[DecisionOutput.trainingPillar] ?? 0.0) * 100.0;
    final resolvedSleepScore = (decisionScores?[DecisionOutput.sleepPillar] ?? 0.0) * 100.0;
    final resolvedHydrationScore = (decisionScores?[DecisionOutput.hydrationPillar] ?? 0.0) * 100.0;

    final totalImr = (resolvedFastingScore +
            resolvedNutritionScore +
            resolvedExerciseScore +
            resolvedSleepScore +
            resolvedHydrationScore) /
        5.0;

    return DashboardCompliance(
      totalImr: totalImr,
      fastingScore: resolvedFastingScore,
      nutritionScore: resolvedNutritionScore,
      exerciseScore: resolvedExerciseScore,
      sleepScore: resolvedSleepScore,
      hydrationScore: resolvedHydrationScore,
      mealsLogged: state.dailyLog.mealEntries.length,
      mealsExpected: _expectedMeals(state.metabolicProfile.fastingContext),
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

  static int _expectedMeals(FastingContext ctx) => ctx.feedingWindowHours < 8.0 ? 2 : 3;
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA STRUCTURES (NO CAMBIAR - MANTIENEN LA UI FUNCIONANDO)
// ─────────────────────────────────────────────────────────────────────────────

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

class DashboardEnergy {
  final double score;
  final String label;
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
}

class DashboardMetabolic {
  final double score;
  final String insulinSensitivity;
  final String metabolicFlexibility;
  final String adaptationState;
  final double bodyFatPercent;
  final double bmr;
  final double tdee;
  final String currentGoal;
  final double? estimatedGlucose;
  final double? estimatedKetones;
  final String metabolicState;
  final String statusBadge;

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

class DashboardRecovery {
  final double score;
  final String label;
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

class DashboardFastingStatus {
  final bool isFasting;
  final bool isFeeding;
  final String protocol;
  final double fastingWindowHours;
  final double feedingWindowHours;
  final double elapsedHours;
  final double metabolicBonus;

  const DashboardFastingStatus({
    required this.isFasting,
    required this.isFeeding,
    required this.protocol,
    required this.fastingWindowHours,
    required this.feedingWindowHours,
    required this.elapsedHours,
    required this.metabolicBonus,
  });
}

class DashboardCompliance {
  final double totalImr;
  final double fastingScore;
  final double nutritionScore;
  final double exerciseScore;
  final double sleepScore;
  final double hydrationScore;
  final int mealsLogged;
  final int mealsExpected;

  const DashboardCompliance({
    required this.totalImr,
    required this.fastingScore,
    required this.nutritionScore,
    required this.exerciseScore,
    required this.sleepScore,
    required this.hydrationScore,
    required this.mealsLogged,
    required this.mealsExpected,
  });
}
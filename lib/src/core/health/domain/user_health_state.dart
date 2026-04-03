import 'dart:math' as math;

import '../../../features/health/domain/daily_log.dart';
import '../../../features/nutrition/domain/entities/metabolic_profile.dart';
import '../../../features/sleep/domain/entities/sleep_log.dart';
import '../../../features/training/domain/entities/workout_log.dart';

// ─────────────────────────────────────────────────────────────────────────────
// USER HEALTH STATE — Single Source of Truth
// ─────────────────────────────────────────────────────────────────────────────
//
// Aggregates the four core health dimensions into one immutable snapshot:
//   1. DailyLog        → nutrition intake, hydration, fasting windows
//   2. MetabolicProfile → body composition, BMR/TDEE, insulin sensitivity
//   3. SleepLog?        → sleep duration (nullable — not always tracked)
//   4. List<WorkoutLog> → recent training sessions
//
// Computed getters derive cross-domain scores WITHOUT any UI logic.
// ─────────────────────────────────────────────────────────────────────────────

class UserHealthState {
  final DailyLog dailyLog;
  final MetabolicProfile metabolicProfile;
  final SleepLog? sleepLog;
  final List<WorkoutLog> workouts;

  const UserHealthState({
    required this.dailyLog,
    required this.metabolicProfile,
    this.sleepLog,
    this.workouts = const [],
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // FASTING GETTERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Whether the user is currently in a fasting window.
  /// Checks both the real-time FastingContext AND the DailyLog timestamps.
  bool get isFastingActive {
    // 1. MetabolicProfile's real-time flag (most reliable)
    if (metabolicProfile.fastingContext.isCurrentlyFasting) return true;

    // 2. Fallback: DailyLog timestamps
    final start = dailyLog.fastingStartTime;
    final end = dailyLog.fastingEndTime;

    if (start == null) return false;

    final now = DateTime.now();

    // Fasting started but no end recorded yet → still fasting
    if (end == null) return now.isAfter(start);

    // End is before start → overnight fast, currently in window
    if (end.isBefore(start)) return now.isAfter(start) || now.isBefore(end);

    // Normal case: fasting ended already
    return false;
  }

  /// Whether the user is currently in their feeding window (inverse of fasting).
  bool get isInFeedingWindow => !isFastingActive;

  // ═══════════════════════════════════════════════════════════════════════════
  // ENERGY SCORE (0 – 100)
  // ═══════════════════════════════════════════════════════════════════════════
  //
  // Weighted composite:
  //   Sleep   → 40%  (hours vs 7–9h ideal range)
  //   Nutrition → 35%  (caloric adherence to TDEE + hydration)
  //   Fasting → 25%  (protocol bonus from MetabolicProfile)
  // ═══════════════════════════════════════════════════════════════════════════

  double get energyScore {
    final sleep = _sleepSubScore;
    final nutrition = _nutritionSubScore;
    final fasting = _fastingSubScore;

    return ((sleep * 0.40) + (nutrition * 0.35) + (fasting * 0.25))
        .clamp(0.0, 100.0);
  }

  /// Sleep sub-score (0–100). 7–9 hours = 100. Degrades linearly outside.
  double get _sleepSubScore {
    final hours = sleepLog?.hours ?? (dailyLog.sleepMinutes / 60.0);
    if (hours <= 0) return 0.0;

    // Ideal range: 7–9 hours
    if (hours >= 7.0 && hours <= 9.0) return 100.0;

    // Below ideal: lose ~14 points per missing hour
    if (hours < 7.0) return (hours / 7.0 * 100.0).clamp(0.0, 100.0);

    // Above ideal (oversleep): mild penalty
    return ((1.0 - ((hours - 9.0) / 5.0)) * 100.0).clamp(0.0, 100.0);
  }

  /// Nutrition sub-score (0–100). Based on caloric adherence + hydration.
  double get _nutritionSubScore {
    final tdee = metabolicProfile.tdee;
    if (tdee <= 0) return 50.0; // Safe default

    // Caloric adherence: how close are consumed cals to TDEE target
    final consumed = dailyLog.calories.toDouble();
    final adherence = consumed > 0
        ? (1.0 - ((consumed - tdee).abs() / tdee)).clamp(0.0, 1.0)
        : 0.0;

    // Hydration bonus: 8 glasses = full bonus (15 points)
    final hydrationBonus = (dailyLog.waterGlasses / 8.0).clamp(0.0, 1.0) * 15.0;

    return (adherence * 85.0 + hydrationBonus).clamp(0.0, 100.0);
  }

  /// Fasting sub-score (0–100). Maps FastingContext metabolic bonus to 0-100.
  double get _fastingSubScore {
    final bonus = metabolicProfile.fastingContext.fastingMetabolicBonus;
    // bonus ranges 0.0 – 0.55 → scale to 0–100
    final scaled = (bonus / 0.55) * 100.0;

    // Extra credit if currently fasting (discipline signal)
    final activeBonus = isFastingActive ? 10.0 : 0.0;

    return (scaled + activeBonus).clamp(0.0, 100.0);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RECOVERY SCORE (0 – 100)
  // ═══════════════════════════════════════════════════════════════════════════
  //
  // Based on:
  //   Sleep quality → 50%
  //   Training load → 50% (inverse — more recent HIIT = lower recovery)
  // ═══════════════════════════════════════════════════════════════════════════

  double get recoveryScore {
    final sleep = _sleepSubScore;
    final training = _trainingRecoverySubScore;

    return ((sleep * 0.50) + (training * 0.50)).clamp(0.0, 100.0);
  }

  /// Training recovery sub-score (0–100).
  /// High recent intensity → lower recovery. No workouts → full recovery.
  double get _trainingRecoverySubScore {
    if (workouts.isEmpty) return 100.0;

    final now = DateTime.now();

    // Only consider workouts in the last 48 hours
    final recent = workouts.where((w) {
      return now.difference(w.date).inHours <= 48;
    }).toList();

    if (recent.isEmpty) return 100.0;

    // Average RIR score across recent sessions (lower RIR = harder workout)
    // RIR 0 = failure, RIR 4+ = easy. Invert for fatigue signal.
    final avgRir = recent
            .map((w) => w.sessionRirScore.toDouble())
            .reduce((a, b) => a + b) /
        recent.length;

    // Duration fatigue: total minutes in last 48h
    final totalMinutes = recent.fold<int>(
      0,
      (sum, w) => sum + (w.durationMinutes ?? 45),
    );
    final durationPenalty = (totalMinutes / 180.0).clamp(0.0, 1.0) * 20.0;

    // Fasted training penalty (extra cortisol stress)
    final fastedCount = recent.where((w) => w.isFasted).length;
    final fastedPenalty = fastedCount * 5.0;

    // RIR-based recovery: RIR 0 → 30 points, RIR 4 → 100 points
    final rirRecovery = ((avgRir / 4.0) * 70.0 + 30.0).clamp(30.0, 100.0);

    return (rirRecovery - durationPenalty - fastedPenalty).clamp(0.0, 100.0);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // METABOLIC SCORE (0 – 100)
  // ═══════════════════════════════════════════════════════════════════════════
  //
  // How well the metabolic engine is running, derived from:
  //   MetabolicProfile state → 50% (insulin sensitivity, flexibility, adaptation)
  //   Fasting state          → 30% (protocol adherence, elapsed hours)
  //   Body composition       → 20% (body fat proximity to healthy range)
  // ═══════════════════════════════════════════════════════════════════════════

  double get metabolicScore {
    final profile = _metabolicProfileSubScore;
    final fasting = _fastingMetabolicSubScore;
    final composition = _bodyCompositionSubScore;

    return ((profile * 0.50) + (fasting * 0.30) + (composition * 0.20))
        .clamp(0.0, 100.0);
  }

  /// Metabolic profile sub-score (0–100).
  double get _metabolicProfileSubScore {
    double score = 50.0; // Baseline

    // Insulin sensitivity bonus
    score += switch (metabolicProfile.insulinSensitivity) {
      InsulinSensitivity.sensitive => 25.0,
      InsulinSensitivity.normal => 15.0,
      InsulinSensitivity.impaired => 0.0,
      InsulinSensitivity.resistant => -15.0,
    };

    // Metabolic flexibility bonus
    score += switch (metabolicProfile.metabolicFlexibility) {
      MetabolicFlexibility.high => 20.0,
      MetabolicFlexibility.medium => 10.0,
      MetabolicFlexibility.low => -5.0,
    };

    // Adaptation state penalty
    score += switch (metabolicProfile.adaptationState) {
      AdaptationState.normal => 5.0,
      AdaptationState.adapted => -5.0,
      AdaptationState.metabolicallyResistant => -15.0,
    };

    return score.clamp(0.0, 100.0);
  }

  /// Fasting contribution to metabolic health (0–100).
  double get _fastingMetabolicSubScore {
    final ctx = metabolicProfile.fastingContext;

    // Protocol score (higher protocol = better metabolic signaling)
    final protocolScore = switch (ctx.protocol) {
      FastingProtocol.none => 10.0,
      FastingProtocol.mild => 30.0,
      FastingProtocol.standard16_8 => 60.0,
      FastingProtocol.extended18_6 => 75.0,
      FastingProtocol.omad => 85.0,
      FastingProtocol.extended24plus => 90.0,
    };

    // Elapsed hours bonus (if actively fasting)
    double elapsedBonus = 0.0;
    if (ctx.isCurrentlyFasting && ctx.currentFastingElapsedHours > 0) {
      // Diminishing returns: each hour less impactful after 16h
      elapsedBonus =
          math.min(ctx.currentFastingElapsedHours / 16.0, 1.0) * 10.0;
    }

    return (protocolScore + elapsedBonus).clamp(0.0, 100.0);
  }

  /// Body composition proximity to healthy range (0–100).
  double get _bodyCompositionSubScore {
    final bf = metabolicProfile.bodyFatPercent;
    final isMale = metabolicProfile.isMale;

    // Healthy BF% ranges
    final idealLow = isMale ? 10.0 : 18.0;
    final idealHigh = isMale ? 20.0 : 28.0;

    if (bf >= idealLow && bf <= idealHigh) return 100.0;

    // Distance from ideal range → penalty
    final distance = bf < idealLow ? (idealLow - bf) : (bf - idealHigh);
    final penalty = (distance / 15.0).clamp(0.0, 1.0) * 60.0;

    return (100.0 - penalty).clamp(0.0, 100.0);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COPY WITH
  // ═══════════════════════════════════════════════════════════════════════════

  UserHealthState copyWith({
    DailyLog? dailyLog,
    MetabolicProfile? metabolicProfile,
    SleepLog? sleepLog,
    List<WorkoutLog>? workouts,
    bool clearSleepLog = false,
  }) {
    return UserHealthState(
      dailyLog: dailyLog ?? this.dailyLog,
      metabolicProfile: metabolicProfile ?? this.metabolicProfile,
      sleepLog: clearSleepLog ? null : (sleepLog ?? this.sleepLog),
      workouts: workouts ?? this.workouts,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserHealthState &&
          runtimeType == other.runtimeType &&
          dailyLog == other.dailyLog &&
          metabolicProfile == other.metabolicProfile &&
          sleepLog == other.sleepLog &&
          _listEquals(workouts, other.workouts);

  @override
  int get hashCode => Object.hash(
        dailyLog,
        metabolicProfile,
        sleepLog,
        Object.hashAll(workouts),
      );

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() => 'UserHealthState('
      'energy: ${energyScore.toStringAsFixed(1)}, '
      'recovery: ${recoveryScore.toStringAsFixed(1)}, '
      'metabolic: ${metabolicScore.toStringAsFixed(1)}, '
      'fasting: $isFastingActive, '
      'workouts: ${workouts.length}'
      ')';
}

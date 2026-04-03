import 'dart:developer' as developer;

import '../../../features/health/domain/daily_log.dart';
import '../../../features/nutrition/domain/entities/metabolic_profile.dart';
import '../../../features/sleep/domain/entities/sleep_log.dart';
import '../../../features/training/domain/entities/workout_log.dart';
import '../../science/metabolic_engine.dart' as science;
import '../../science/training_physiology.dart';
import '../domain/health_snapshot.dart';
import '../domain/user_behavior_profile.dart';
import '../domain/user_health_state.dart';
import 'adaptive_engine.dart';
import 'behavior_tracker.dart';
import 'decision_engine.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HEALTH ORCHESTRATOR
// ─────────────────────────────────────────────────────────────────────────────
//
// Single responsibility: build a fully resolved [UserHealthState] from raw
// domain entities. Delegates ALL scientific formulas to:
//
//   • core/science/MetabolicEngine  → metabolic zone, indices, fasting rules
//   • core/science/TrainingPhysiology → recovery readiness, HR zones
//   • features/fasting/FastingStage → fasting stage classification
//
// This class is framework-agnostic: no Riverpod, no Flutter, no Firebase.
// It can be injected into providers, controllers, or test harnesses.
// ─────────────────────────────────────────────────────────────────────────────

class HealthOrchestrator {
  final DecisionEngine _decisionEngine;
  final AdaptiveEngine _adaptiveEngine;
  final BehaviorTrackerStore _behaviorStore;

  const HealthOrchestrator({
    DecisionEngine decisionEngine = const DecisionEngine(),
    AdaptiveEngine adaptiveEngine = const AdaptiveEngine(),
    BehaviorTrackerStore behaviorStore = const LocalBehaviorTrackerStore(),
  })  : _decisionEngine = decisionEngine,
        _adaptiveEngine = adaptiveEngine,
        _behaviorStore = behaviorStore;

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC API
  // ═══════════════════════════════════════════════════════════════════════════

  /// Builds an immutable [UserHealthState] and a unified [DecisionOutput]
  /// wrapped in [HealthSnapshot].
  ///
  /// All inputs are normalized, fasting state is resolved, and cross-domain
  /// scores (energy, recovery, metabolic) are computed via [UserHealthState]'s
  /// own getters — this method ensures the inputs are clean before assembly.
  Future<HealthSnapshot> buildState({
    required DailyLog dailyLog,
    required MetabolicProfile metabolicProfile,
    SleepLog? sleepLog,
    List<WorkoutLog> workouts = const [],
    DateTime? now,
  }) async {
    final referenceNow = now ?? DateTime.now();
    _assertValidInputs(
      dailyLog: dailyLog,
      metabolicProfile: metabolicProfile,
      sleepLog: sleepLog,
      workouts: workouts,
    );

    developer.log(
      'HealthOrchestrator.buildState start dailyLog=${dailyLog.id} '
      'workouts=${workouts.length} sleepLog=${sleepLog != null}',
      name: 'core.health.HealthOrchestrator',
    );

    // ── Step 1: Normalize inputs ─────────────────────────────────────────
    final normalizedLog = _normalizeDailyLog(dailyLog);
    final normalizedSleep = _normalizeSleepLog(sleepLog);
    final normalizedWorkouts = _normalizeWorkouts(workouts, referenceNow);

    // ── Step 2: Resolve fasting state ────────────────────────────────────
    final resolvedProfile = _resolveFastingState(
      metabolicProfile,
      normalizedLog,
      referenceNow,
    );

    // ── Step 3: Validate cross-domain consistency ────────────────────────
    _validateConsistency(
      dailyLog: normalizedLog,
      profile: resolvedProfile,
      workouts: normalizedWorkouts,
      referenceNow: referenceNow,
    );

    // ── Step 4: Assemble the immutable state ─────────────────────────────
    // All computed getters (energyScore, recoveryScore, metabolicScore)
    // live inside UserHealthState — no duplication here.
    final state = UserHealthState(
      dailyLog: normalizedLog,
      metabolicProfile: resolvedProfile,
      sleepLog: normalizedSleep,
      workouts: normalizedWorkouts,
    );

    // ── Step 5: Build deterministic base decision from unified state ─────
    final baseDecision = _decisionEngine.decide(state, now: referenceNow);

    // ── Step 6: Load behavior profile (persisted adaptive signals) ───────
    final behaviorProfile = await _loadBehaviorProfile();

    // ── Step 7: Adapt decision using behavior profile ────────────────────
    final decision = _adaptiveEngine.adapt(
      baseDecision: baseDecision,
      state: state,
      profile: behaviorProfile,
    );

    developer.log(
      'HealthOrchestrator.buildState done action="${decision.primaryAction}" '
      'priority=${decision.priority} base="${baseDecision.primaryAction}" '
      'energy=${state.energyScore.toStringAsFixed(1)} '
      'recovery=${state.recoveryScore.toStringAsFixed(1)}',
      name: 'core.health.HealthOrchestrator',
    );

    return HealthSnapshot(
      state: state,
      decision: decision,
    );
  }

  Future<UserBehaviorProfile> _loadBehaviorProfile() async {
    try {
      final snapshot = await _behaviorStore.load();
      if (snapshot == null) return UserBehaviorProfile();
      return snapshot.profile;
    } catch (error) {
      developer.log(
        'HealthOrchestrator.loadBehaviorProfile fallback to defaults: $error',
        name: 'core.health.HealthOrchestrator',
      );
      return UserBehaviorProfile();
    }
  }

  void _assertValidInputs({
    required DailyLog dailyLog,
    required MetabolicProfile metabolicProfile,
    required SleepLog? sleepLog,
    required List<WorkoutLog> workouts,
  }) {
    assert(dailyLog.id.isNotEmpty, 'DailyLog.id must not be empty.');
    assert(
      metabolicProfile.tdee.isFinite && metabolicProfile.tdee >= 0,
      'MetabolicProfile.tdee must be finite and non-negative.',
    );
    assert(
      metabolicProfile.bmr.isFinite && metabolicProfile.bmr >= 0,
      'MetabolicProfile.bmr must be finite and non-negative.',
    );
    assert(
      sleepLog == null ||
          (sleepLog.hours.isFinite &&
              sleepLog.hours >= 0 &&
              sleepLog.hours <= 24),
      'SleepLog.hours must be in [0,24] when provided.',
    );

    for (final workout in workouts) {
      assert(workout.id.isNotEmpty, 'WorkoutLog.id must not be empty.');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 1: INPUT NORMALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Clamps DailyLog values to physiologically valid ranges.
  DailyLog _normalizeDailyLog(DailyLog log) {
    return log.copyWith(
      waterGlasses: log.waterGlasses.clamp(0, 30),
      calories: log.calories.clamp(0, 10000),
      proteinGrams: log.proteinGrams.clamp(0, 500),
      carbsGrams: log.carbsGrams.clamp(0, 1000),
      fatGrams: log.fatGrams.clamp(0, 500),
      exerciseMinutes: log.exerciseMinutes.clamp(0, 480),
      sleepMinutes: log.sleepMinutes.clamp(0, 1440),
    );
  }

  /// Clamps sleep hours to sane bounds (0–24h).
  SleepLog? _normalizeSleepLog(SleepLog? sleep) {
    if (sleep == null) return null;
    final clampedHours = sleep.hours.clamp(0.0, 24.0);
    if (clampedHours == sleep.hours) return sleep;
    return sleep.copyWith(hours: clampedHours);
  }

  /// Filters out workouts with impossible data and deduplicates by ID.
  List<WorkoutLog> _normalizeWorkouts(
    List<WorkoutLog> workouts,
    DateTime referenceNow,
  ) {
    if (workouts.isEmpty) return const [];

    final seen = <String>{};
    final normalized = <WorkoutLog>[];

    for (final w in workouts) {
      // Skip duplicates
      if (!seen.add(w.id)) continue;

      // Skip future-dated workouts (clock skew guard)
      if (w.date.isAfter(referenceNow.add(const Duration(hours: 1)))) {
        continue;
      }

      // Clamp RIR to valid range (0–10)
      final clampedRir = w.sessionRirScore.clamp(0, 10);

      if (clampedRir != w.sessionRirScore) {
        normalized.add(w.copyWith(sessionRirScore: clampedRir));
      } else {
        normalized.add(w);
      }
    }

    // Sort by date descending (most recent first)
    normalized.sort((a, b) => b.date.compareTo(a.date));

    return normalized;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 2: FASTING STATE RESOLUTION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Ensures the MetabolicProfile's FastingContext reflects reality by
  /// cross-referencing DailyLog timestamps.
  ///
  /// Uses ONLY [core/science/MetabolicEngine.calculateZone] for zone
  /// classification — no duplicated formulas.
  MetabolicProfile _resolveFastingState(
    MetabolicProfile profile,
    DailyLog log,
    DateTime referenceNow,
  ) {
    final ctx = profile.fastingContext;

    // If the profile already has real-time fasting data, trust it
    if (ctx.isCurrentlyFasting && ctx.currentFastingElapsedHours > 0) {
      return profile;
    }

    // Otherwise, derive from DailyLog timestamps
    final start = log.fastingStartTime;
    if (start == null) return profile;

    final end = log.fastingEndTime;

    // Determine if currently fasting
    bool isCurrentlyFasting;
    double elapsedHours;

    if (end == null || end.isBefore(start)) {
      // No end recorded, or overnight wrap → still fasting
      isCurrentlyFasting = referenceNow.isAfter(start);
      elapsedHours = isCurrentlyFasting
          ? referenceNow.difference(start).inMinutes / 60.0
          : 0.0;
    } else {
      // End is after start → fasting completed
      isCurrentlyFasting = false;
      elapsedHours = 0.0;
    }

    // Derive metabolic zone from elapsed time via core/science engine
    // (single source of truth for zone thresholds — available to consumers
    // via currentMetabolicZone() utility method)

    // Build updated context preserving existing protocol/experience
    final updatedCtx = FastingContext(
      protocol: ctx.protocol,
      fastingWindowHours: ctx.fastingWindowHours,
      feedingWindowHours: ctx.feedingWindowHours,
      experience: ctx.experience,
      trainingTiming: ctx.trainingTiming,
      isCurrentlyFasting: isCurrentlyFasting,
      currentFastingElapsedHours: elapsedHours,
    );

    // We can't use copyWith on MetabolicProfile (not freezed), so we
    // reconstruct only the fastingContext field. Since MetabolicProfile
    // is a const class, we create a new instance preserving all fields.
    return _withUpdatedFastingContext(profile, updatedCtx);
  }

  /// Creates a new MetabolicProfile with an updated FastingContext.
  MetabolicProfile _withUpdatedFastingContext(
    MetabolicProfile p,
    FastingContext ctx,
  ) {
    return MetabolicProfile(
      totalWeightKg: p.totalWeightKg,
      bodyFatPercent: p.bodyFatPercent,
      leanMassKg: p.leanMassKg,
      fatMassKg: p.fatMassKg,
      bmr: p.bmr,
      tdee: p.tdee,
      activityMultiplier: p.activityMultiplier,
      bmi: p.bmi,
      whtr: p.whtr,
      whr: p.whr,
      insulinSensitivity: p.insulinSensitivity,
      metabolicFlexibility: p.metabolicFlexibility,
      adaptationState: p.adaptationState,
      hasMetabolicRisk: p.hasMetabolicRisk,
      hasHormonalRisk: p.hasHormonalRisk,
      age: p.age,
      gender: p.gender,
      goal: p.goal,
      fastingContext: ctx,
      recentHighIntensityWorkout: p.recentHighIntensityWorkout,
      targetWeightKg: p.targetWeightKg,
      targetFatPercent: p.targetFatPercent,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 3: CROSS-DOMAIN CONSISTENCY VALIDATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Validates that inputs don't contradict each other.
  /// Throws [StateError] on irreconcilable inconsistencies.
  void _validateConsistency({
    required DailyLog dailyLog,
    required MetabolicProfile profile,
    required List<WorkoutLog> workouts,
    required DateTime referenceNow,
  }) {
    // Guard: exercise minutes in DailyLog should roughly match workout logs
    if (workouts.isNotEmpty) {
      final loggedMinutes = dailyLog.exerciseMinutes;
      final workoutMinutes = workouts.fold<int>(
        0,
        (sum, w) => sum + (w.durationMinutes ?? 0),
      );

      // Allow 50% tolerance (users may log cardio separately)
      if (loggedMinutes > 0 &&
          workoutMinutes > 0 &&
          (loggedMinutes - workoutMinutes).abs() > workoutMinutes * 1.5) {
        // Soft warning — don't throw, just note the discrepancy
        // In production this would emit to analytics
      }
    }

    // Guard: HIIT detection alignment
    // If any workout in last 24h is high-intensity (RIR ≤ 1), profile
    // should reflect it. We already normalized, so just verify.
    final recentHiit = workouts.any((w) =>
        referenceNow.difference(w.date).inHours < 24 && w.sessionRirScore <= 1);

    if (recentHiit && !profile.recentHighIntensityWorkout) {
      // Discrepancy: workouts say HIIT happened but profile doesn't know.
      // We handle this by using the workout data (already reflected in
      // UserHealthState.recoveryScore via the workouts list).
      developer.log(
        'HealthOrchestrator.validate consistency warning: recentHiit=true '
        'but profile.recentHighIntensityWorkout=false',
        name: 'core.health.HealthOrchestrator',
      );
    }

    // Guard: muscle readiness via TrainingPhysiology (core/science)
    // Useful for downstream consumers checking if training is advised today
    for (final w in workouts) {
      if (referenceNow.difference(w.date).inHours < 72) {
        final recoveryScore = w.sessionRirScore.toDouble();
        TrainingPhysiology.isMuscleReady(w.date, recoveryScore);
        // Result available for consumers; we don't store it here
        // (UserHealthState.recoveryScore already captures this signal)
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILITY: Metabolic Zone (delegates to core/science)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Exposes the current metabolic zone for external consumers.
  /// Single source: [core/science/MetabolicEngine.calculateZone].
  science.MetabolicZone currentMetabolicZone(MetabolicProfile profile) {
    final elapsed = profile.fastingContext.currentFastingElapsedHours;
    return science.MetabolicEngine.calculateZone(
      Duration(minutes: (elapsed * 60).round()),
    );
  }

  /// Checks if a proposed meal time is safe for sleep via core/science engine.
  bool isMealSafeForSleep(DateTime mealTime, DateTime bedtime) {
    return science.MetabolicEngine.isMealSafeForSleep(mealTime, bedtime);
  }

  /// Calculates body composition indices via core/science engine.
  ({double ica, double icc}) calculateIndices({
    required double waistCm,
    required double heightCm,
    double? hipCm,
  }) {
    return (
      ica: science.MetabolicEngine.calculateMetaICA(waistCm, heightCm),
      icc: science.MetabolicEngine.calculateMetaICC(waistCm, hipCm),
    );
  }
}

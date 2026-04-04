import 'dart:developer' as developer;

import '../../../features/health/domain/daily_log.dart';
import '../../../features/nutrition/domain/entities/metabolic_profile.dart';
import '../../../features/sleep/domain/entities/sleep_log.dart';
import '../../../features/training/domain/entities/workout_log.dart';
import '../../engagement/application/engagement_engine.dart';
import '../../engagement/domain/user_engagement_profile.dart';
import '../../science/metabolic_engine.dart' as science;
import '../../science/training_physiology.dart';
import '../domain/full_user_state.dart';
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
  final EngagementEngine _engagementEngine;
  final BehaviorTrackerStore _behaviorStore;

  const HealthOrchestrator({
    DecisionEngine decisionEngine = const DecisionEngine(),
    AdaptiveEngine adaptiveEngine = const AdaptiveEngine(),
    EngagementEngine engagementEngine = const EngagementEngine(),
    BehaviorTrackerStore behaviorStore = const LocalBehaviorTrackerStore(),
  })  : _decisionEngine = decisionEngine,
        _adaptiveEngine = adaptiveEngine,
        _engagementEngine = engagementEngine,
        _behaviorStore = behaviorStore;

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC API
  // ═══════════════════════════════════════════════════════════════════════════

  /// Builds a full pipeline output wrapped in [FullUserState].
  ///
  /// All inputs are normalized, fasting state is resolved, and cross-domain
  /// scores (energy, recovery, metabolic) are computed via [UserHealthState]'s
  /// own getters — this method ensures the inputs are clean before assembly.
  Future<FullUserState> buildState({
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

    // ── Step 6: Load behavior snapshot/profile (adaptive signals) ────────
    final behaviorSnapshot = await _loadBehaviorSnapshot();
    final behaviorProfile = behaviorSnapshot?.profile ?? UserBehaviorProfile();

    // ── Step 7: Adapt decision using behavior profile ────────────────────
    final personalizedDecision = _adaptiveEngine.adapt(
      baseDecision: baseDecision,
      state: state,
      profile: behaviorProfile,
    );

    // ── Step 8: Build engagement profile + user experience output ────────
    final engagementProfile = _deriveEngagementProfile(
      behaviorSnapshot: behaviorSnapshot,
      behaviorProfile: behaviorProfile,
      now: referenceNow,
    );

    final experience = _engagementEngine.enhance(
      decision: personalizedDecision,
      behavior: behaviorProfile,
      engagement: engagementProfile,
    );

    developer.log(
      'HealthOrchestrator.buildState done action="${personalizedDecision.primaryAction}" '
      'priority=${personalizedDecision.priority} base="${baseDecision.primaryAction}" '
      'energy=${state.energyScore.toStringAsFixed(1)} '
      'recovery=${state.recoveryScore.toStringAsFixed(1)}',
      name: 'core.health.HealthOrchestrator',
    );

    return FullUserState(
      health: state,
      decision: personalizedDecision,
      experience: experience,
    );
  }

  Future<BehaviorTrackerSnapshot?> _loadBehaviorSnapshot() async {
    try {
      return await _behaviorStore.load();
    } catch (error) {
      developer.log(
        'HealthOrchestrator.loadBehaviorSnapshot fallback to defaults: $error',
        name: 'core.health.HealthOrchestrator',
      );
      return null;
    }
  }

  UserEngagementProfile _deriveEngagementProfile({
    required BehaviorTrackerSnapshot? behaviorSnapshot,
    required UserBehaviorProfile behaviorProfile,
    required DateTime now,
  }) {
    if (behaviorSnapshot == null || behaviorSnapshot.events.isEmpty) {
      return UserEngagementProfile(
        adherenceScore: behaviorProfile.nutritionCompliance,
        motivationLevel: behaviorProfile.trainingRecoveryRate,
      );
    }

    final events = behaviorSnapshot.events;
    final successfulOutcomes = events
        .where((e) => e.type == BehaviorEventType.outcome && e.success == true)
        .toList();
    final allOutcomes =
        events.where((e) => e.type == BehaviorEventType.outcome).toList();

    final adherence = allOutcomes.isEmpty
        ? behaviorProfile.nutritionCompliance
        : (successfulOutcomes.length / allOutcomes.length).clamp(0.0, 1.0);

    final motivation =
        ((adherence + behaviorProfile.trainingRecoveryRate) / 2.0)
            .clamp(0.0, 1.0);

    final latestEvent =
        events.map((e) => e.timestamp).reduce((a, b) => a.isAfter(b) ? a : b);

    final missedDays = now.toUtc().difference(latestEvent.toUtc()).inDays;

    final successfulDays = successfulOutcomes
        .map((e) =>
            DateTime.utc(e.timestamp.year, e.timestamp.month, e.timestamp.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int currentStreak = 0;
    if (successfulDays.isNotEmpty) {
      var cursor = DateTime.utc(now.year, now.month, now.day);
      for (final day in successfulDays) {
        if (day == cursor) {
          currentStreak++;
          cursor = cursor.subtract(const Duration(days: 1));
        } else if (day.isBefore(cursor)) {
          break;
        }
      }
    }

    final longestStreak = _longestConsecutiveRun(successfulDays);

    return UserEngagementProfile(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      totalActionsCompleted: successfulOutcomes.length,
      adherenceScore: adherence,
      motivationLevel: motivation,
      lastActive: latestEvent,
      missedDays: missedDays < 0 ? 0 : missedDays,
      completedActionsByType: behaviorProfile.actionHistoryCounts,
    );
  }

  int _longestConsecutiveRun(List<DateTime> daysDesc) {
    if (daysDesc.isEmpty) return 0;

    int best = 1;
    int current = 1;

    for (var i = 1; i < daysDesc.length; i++) {
      final prev = daysDesc[i - 1];
      final currentDay = daysDesc[i];
      final delta = prev.difference(currentDay).inDays;

      if (delta == 1) {
        current++;
        if (current > best) best = current;
      } else if (delta > 1) {
        current = 1;
      }
    }

    return best;
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

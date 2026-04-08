import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

import '../../../core/engagement/data/engagement_repository.dart';
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
import '../domain/decision_output.dart'; // 🛡️ Importación vital para la coherencia de tipos
import 'adaptive_engine.dart';
import 'behavior_tracker.dart';
import 'decision_engine.dart';

class HealthOrchestrator {
  EngagementRepository? _engagementRepository;
  String? _cachedUid;

  final DecisionEngine _decisionEngine;
  final AdaptiveEngine _adaptiveEngine;
  final EngagementEngine _engagementEngine;
  final BehaviorTrackerStore _behaviorStore;

  HealthOrchestrator({
    DecisionEngine decisionEngine = const DecisionEngine(),
    AdaptiveEngine adaptiveEngine = const AdaptiveEngine(),
    EngagementEngine engagementEngine = const EngagementEngine(),
    BehaviorTrackerStore behaviorStore = const LocalBehaviorTrackerStore(),
  })  : _decisionEngine = decisionEngine,
        _adaptiveEngine = adaptiveEngine,
        _engagementEngine = engagementEngine,
        _behaviorStore = behaviorStore;

  void setEngagementRepository(EngagementRepository repo, String uid) {
    _engagementRepository = repo;
    _cachedUid = uid;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC API: EL MOTOR DE LA VERDAD
  // ═══════════════════════════════════════════════════════════════════════════

  Future<FullUserState> buildState({
    required DailyLog dailyLog,
    required MetabolicProfile metabolicProfile,
    SleepLog? sleepLog,
    List<WorkoutLog> workouts = const [],
    DateTime? now,
  }) async {
    final referenceNow = now ?? DateTime.now();

    // ── Step 1: Normalización Preventiva ─────────────────────────────────
    // Saneamos datos antes de que lleguen a las capas de cálculo
    final normalizedLog = _normalizeDailyLog(dailyLog);
    final normalizedSleep = _normalizeSleepLog(sleepLog);
    final normalizedWorkouts = _normalizeWorkouts(workouts, referenceNow);

    developer.log(
      'HealthOrchestrator.buildState: start process for ${dailyLog.id}',
      name: 'core.health.HealthOrchestrator',
    );

    // ── Step 2: Resolución de Estado Metabólico ──────────────────────────
    final resolvedProfile = _resolveFastingState(
      metabolicProfile,
      normalizedLog,
      referenceNow,
    );

    // ── Step 3: Ensamblaje del Estado de Salud Inmutable ──────────────────
    final state = UserHealthState(
      dailyLog: normalizedLog,
      metabolicProfile: resolvedProfile,
      sleepLog: normalizedSleep,
      workouts: normalizedWorkouts,
    );

    // ── Step 4: Motor de Decisión Biológica ──────────────────────────────
    // Retorna un DecisionOutput puro basado en fisiología circadiana
    final baseDecision = _decisionEngine.decide(state, now: referenceNow);

    // ── Step 5: Adaptación por Comportamiento (Machine Learning / Heurística)
    final behaviorSnapshot = await _loadBehaviorSnapshot();
    final behaviorProfile = behaviorSnapshot?.profile ?? UserBehaviorProfile();

    final personalizedDecision = _adaptiveEngine.adapt(
      baseDecision: baseDecision, // ✅ Tipos ahora coinciden (DecisionOutput)
      state: state,
      profile: behaviorProfile,
    );

    // ── Step 6: Perfil de Engagement y Experiencia ────────────────────────
    final engagementProfile = _deriveEngagementProfile(
      behaviorSnapshot: behaviorSnapshot,
      behaviorProfile: behaviorProfile,
      now: referenceNow,
    );

    // Persistencia asíncrona del engagement
    if (_engagementRepository != null && _cachedUid != null) {
      _engagementRepository!
          .save(_cachedUid!, engagementProfile)
          .catchError((e) => debugPrint('⚠️ Engagement persist error: $e'));
    }

    final experience = _engagementEngine.enhance(
      decision: personalizedDecision,
      behavior: behaviorProfile,
      engagement: engagementProfile,
    );

    developer.log(
      'HealthOrchestrator: Build complete. Action: ${personalizedDecision.primaryAction}',
      name: 'core.health.HealthOrchestrator',
    );

    return FullUserState(
      health: state,
      decision: personalizedDecision,
      experience: experience,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SANEAMIENTO DE DATOS (PROTECCIÓN DE TELEMETRÍA)
  // ═══════════════════════════════════════════════════════════════════════════

  DailyLog _normalizeDailyLog(DailyLog log) {
    return log.copyWith(
      waterGlasses: log.waterGlasses.clamp(0, 30),
      calories: log.calories.clamp(0, 10000),
      proteinGrams: log.proteinGrams.clamp(0, 500),
      exerciseMinutes: log.exerciseMinutes.clamp(0, 480),
      sleepMinutes: log.sleepMinutes.clamp(0, 1440),
    );
  }

  SleepLog? _normalizeSleepLog(SleepLog? sleep) {
    if (sleep == null) return null;
    // Saneamiento de horas para evitar infinitos o negativos
    final validHours = sleep.hours.isFinite ? sleep.hours.clamp(0.0, 24.0) : 0.0;
    return sleep.copyWith(hours: validHours);
  }

  List<WorkoutLog> _normalizeWorkouts(List<WorkoutLog> workouts, DateTime now) {
    if (workouts.isEmpty) return const [];
    final seen = <String>{};
    final normalized = <WorkoutLog>[];

    for (final w in workouts) {
      if (!seen.add(w.id)) continue;
      // Guardar contra discrepancia de reloj (max 1h al futuro permitido)
      if (w.date.isAfter(now.add(const Duration(hours: 1)))) continue;
      
      normalized.add(w.copyWith(sessionRirScore: w.sessionRirScore.clamp(0, 10)));
    }
    normalized.sort((a, b) => b.date.compareTo(a.date));
    return normalized;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LÓGICA DE NEGOCIO METABÓLICA
  // ═══════════════════════════════════════════════════════════════════════════

  MetabolicProfile _resolveFastingState(MetabolicProfile p, DailyLog log, DateTime now) {
    final ctx = p.fastingContext;
    if (ctx.isCurrentlyFasting && ctx.currentFastingElapsedHours > 0) return p;

    final start = log.fastingStartTime;
    if (start == null) return p;

    final end = log.fastingEndTime;
    bool isCurrentlyFasting = (end == null || end.isBefore(start)) && now.isAfter(start);
    double elapsed = isCurrentlyFasting ? now.difference(start).inMinutes / 60.0 : 0.0;

    // Reconstrucción del perfil con el nuevo contexto de ayuno
    return MetabolicProfile(
      totalWeightKg: p.totalWeightKg, bodyFatPercent: p.bodyFatPercent, leanMassKg: p.leanMassKg,
      fatMassKg: p.fatMassKg, bmr: p.bmr, tdee: p.tdee, activityMultiplier: p.activityMultiplier,
      bmi: p.bmi, whtr: p.whtr, whr: p.whr, insulinSensitivity: p.insulinSensitivity,
      metabolicFlexibility: p.metabolicFlexibility, adaptationState: p.adaptationState,
      hasMetabolicRisk: p.hasMetabolicRisk, hasHormonalRisk: p.hasHormonalRisk,
      age: p.age, gender: p.gender, goal: p.goal,
      fastingContext: FastingContext(
        protocol: ctx.protocol, fastingWindowHours: ctx.fastingWindowHours,
        feedingWindowHours: ctx.feedingWindowHours, experience: ctx.experience,
        trainingTiming: ctx.trainingTiming, isCurrentlyFasting: isCurrentlyFasting,
        currentFastingElapsedHours: elapsed,
      ),
      dailyExerciseGoalMinutes: p.dailyExerciseGoalMinutes,
      recentHighIntensityWorkout: p.recentHighIntensityWorkout,
      targetWeightKg: p.targetWeightKg, targetFatPercent: p.targetFatPercent,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILITARIOS DE COMPORTAMIENTO
  // ═══════════════════════════════════════════════════════════════════════════

  Future<BehaviorTrackerSnapshot?> _loadBehaviorSnapshot() async {
    try { return await _behaviorStore.load(); } catch (_) { return null; }
  }

  UserEngagementProfile _deriveEngagementProfile({
    BehaviorTrackerSnapshot? behaviorSnapshot,
    required UserBehaviorProfile behaviorProfile,
    required DateTime now,
  }) {
    // Si no hay datos, devolvemos un perfil basado en cumplimiento histórico
    if (behaviorSnapshot == null || behaviorSnapshot.events.isEmpty) {
      return UserEngagementProfile(
        adherenceScore: behaviorProfile.nutritionCompliance,
        motivationLevel: behaviorProfile.trainingRecoveryRate,
      );
    }

    // Lógica de cálculo de racha y adherencia
    final events = behaviorSnapshot.events;
    final successCount = events.where((e) => e.type == BehaviorEventType.outcome && e.success == true).length;
    final totalCount = events.where((e) => e.type == BehaviorEventType.outcome).length;

    return UserEngagementProfile(
      currentStreak: 0, // Aquí iría la lógica de iteración de fechas
      totalActionsCompleted: successCount,
      adherenceScore: totalCount == 0 ? 0.0 : successCount / totalCount,
      motivationLevel: 0.8,
      lastActive: now,
    );
  }

  // Delegaciones científicas al MetabolicEngine
  science.MetabolicZone currentMetabolicZone(MetabolicProfile profile) {
    final elapsed = profile.fastingContext.currentFastingElapsedHours;
    return science.MetabolicEngine.calculateZone(Duration(minutes: (elapsed * 60).round()));
  }
}
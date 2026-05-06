// ─────────────────────────────────────────────────────────────────────────────
// SPEC-01 / SPEC-46: OrchestratorEngine — Motor de sincronización determinista
// ─────────────────────────────────────────────────────────────────────────────
//
// Función pura: (MetabolicState, UserModel, StreakState) → OrchestratorState
//
// INVARIANTES SPEC-00:
//   - Sin ref.watch / ref.read / ref.listen
//   - Sin Firestore / repositorios
//   - Sin timers, async, Future, Stream
//   - Sin DateTime.now() (usa state.timestamp como fuente de tiempo)
//   - Sin modificación de notifiers existentes
//   - Sin efectos secundarios
//   - Mismo input → mismo output (determinista)
//
// REUTILIZACIÓN:
//   - FastingPhase: clasificación por horas de ayuno (umbrales 4/8/12h).
//   - CircadianPhase: tabla horaria interna (alineada con CircadianRules).
//     SPEC-51 unificará ambas en CircadianEngine.
//   - metabolicCoherence: usa MetabolicState.metabolicCoherence (ya calculado
//     por MetabolicStateBuilder._calculateCoherence). SPEC-71 unificará la
//     coherencia para evitar doble penalización.
//   - NO duplica fórmulas de ScoreEngine ni MetabolicStateBuilder
// ─────────────────────────────────────────────────────────────────────────────

import 'package:elena_app/src/core/engine/metabolic_state.dart';
import 'package:elena_app/src/core/orchestrator/biological_phases.dart';
import 'package:elena_app/src/core/orchestrator/orchestrator_state.dart';
import 'package:elena_app/src/core/orchestrator/recommendation.dart';
import 'package:elena_app/src/features/streak/application/streak_notifier.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';

/// Motor de sincronización central — lógica pura sin efectos secundarios.
///
/// Consume los 3 modelos de dominio existentes y produce un snapshot
/// determinista del estado metabólico sincronizado.
class OrchestratorEngine {
  const OrchestratorEngine._();

  /// Calcula el estado orquestado completo.
  ///
  /// [state] — snapshot del MetabolicState (del metabolicStateProvider)
  /// [user] — UserModel con perfil circadiano
  /// [streak] — StreakState con adherencia semanal y pilares completados
  ///
  /// Retorna: OrchestratorState determinista. Si `state` es vacío
  /// (`timestamp == null` o `lastMealTime == null` — ver SPEC-60), retorna
  /// `OrchestratorState.initial()` sin invocar lógica de negocio.
  static OrchestratorState calculate({
    required MetabolicState state,
    required UserModel user,
    required StreakState streak,
  }) {
    // SPEC-60: el state vacío no se procesa. Retornamos el initial seguro
    // para no inventar `now` con `DateTime.now()` ni manipular timestamps null.
    final now = state.timestamp;
    final lastMealTime = state.lastMealTime;
    if (now == null || lastMealTime == null) {
      return OrchestratorState.initial();
    }

    // ── 1. Fases biológicas ──────────────────────────────────────────────
    final fastingPhase = _determineFastingPhase(state.fastingHoursRaw);
    final circadianPhase = _determineCircadianPhase(now);

    // ── 2. Ventana nutricional ───────────────────────────────────────────
    final (canEat, isInWindow, minutesToClose) =
        _evaluateNutritionWindow(user, now);

    // ── 3. Seguridad de ejercicio ────────────────────────────────────────
    final canExercise = _canExerciseNow(
      fastingPhase: fastingPhase,
      circadianPhase: circadianPhase,
      sleepQuality: state.sleepQuality,
    );

    // ── 4. Optimalidad de ayuno ──────────────────────────────────────────
    final isOptimalForFasting = _isOptimalForFasting(
      fastingPhase: fastingPhase,
      sleepQuality: state.sleepQuality,
    );

    // ── 5. Multiplicadores ───────────────────────────────────────────────
    final exerciseMultiplier = _exerciseSafetyMultiplier(fastingPhase);
    final nutritionMultiplier = _nutritionPhaseMultiplier(circadianPhase);

    // ── 6. Recomendación de ejercicio ────────────────────────────────────
    final (exerciseType, exerciseIntensity) = _exerciseRecommendation(
      fastingPhase: fastingPhase,
      circadianPhase: circadianPhase,
      sleepQuality: state.sleepQuality,
    );

    // ── 7. Violaciones de sincronización ─────────────────────────────────
    final violations = _detectViolations(
      fastingPhase: fastingPhase,
      circadianPhase: circadianPhase,
      state: state,
    );

    // ── 8. Coherencia metabólica ─────────────────────────────────────────
    // Usa el valor ya calculado por MetabolicStateBuilder._calculateCoherence
    // (NO duplicar la fórmula). Solo ajusta si hay violaciones detectadas
    // por el orchestrator que el builder no conoce.
    final baseCoherence = state.metabolicCoherence;
    final adjustedCoherence =
        (baseCoherence - (violations.length * 0.05)).clamp(0.0, 1.0);

    // ── 9. Horas desde última comida ─────────────────────────────────────
    final hoursSinceLastMeal =
        now.difference(lastMealTime).inMinutes / 60.0;

    // ── 10. Recomendaciones tipadas ──────────────────────────────────────
    final recommendations = _generateRecommendations(
      fastingPhase: fastingPhase,
      circadianPhase: circadianPhase,
      state: state,
      streak: streak,
    );

    return OrchestratorState(
      fastingPhase: fastingPhase,
      circadianPhase: circadianPhase,
      canExerciseNow: canExercise,
      canEatNow: canEat,
      isOptimalForFasting: isOptimalForFasting,
      isInNutritionWindow: isInWindow,
      exerciseSafetyMultiplier: exerciseMultiplier,
      nutritionPhaseMultiplier: nutritionMultiplier,
      recommendations: recommendations,
      exerciseRecommendedType: exerciseType,
      exerciseRecommendedIntensity: exerciseIntensity,
      metabolicCoherence: adjustedCoherence,
      activeSyncViolations: violations,
      fastedHours: state.fastingHoursRaw,
      hoursSinceLastMeal: hoursSinceLastMeal,
      minutesToWindowClose: minutesToClose,
      sourceTimestamp: now,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Métodos privados puros
  // ═══════════════════════════════════════════════════════════════════════════

  /// Determina FastingPhase tipado desde horas de ayuno.
  ///
  /// Umbrales: <4h alerta, 4-8h gluconeogénesis, 8-12h cetosis, ≥12h autofagia.
  static FastingPhase _determineFastingPhase(double fastingHoursRaw) {
    if (fastingHoursRaw < 4) return FastingPhase.alerta;
    if (fastingHoursRaw < 8) return FastingPhase.gluconeogenesis;
    if (fastingHoursRaw < 12) return FastingPhase.cetosis;
    return FastingPhase.autofagia;
  }

  /// Determina CircadianPhase tipado desde timestamp.
  ///
  /// Tabla horaria alineada con CircadianRules. SPEC-51 unificará ambas en
  /// un único `CircadianEngine` para eliminar la duplicación.
  static CircadianPhase _determineCircadianPhase(DateTime now) {
    final current = now.hour + (now.minute / 60.0);

    // SUEÑO: 22:30–06:00 (cruza medianoche)
    if (current >= 22.5 || current < 6.0) return CircadianPhase.sueno;
    // ALERTA: 06:00–09:00
    if (current < 9.0) return CircadianPhase.alerta;
    // COGNITIVO: 09:00–13:00
    if (current < 13.0) return CircadianPhase.cognitivo;
    // RECESO: 13:00–15:00
    if (current < 15.0) return CircadianPhase.receso;
    // MOTOR/FUERZA: 15:00–20:00
    if (current < 20.0) return CircadianPhase.motorFuerza;
    // CREATIVIDAD: 20:00–22:30
    return CircadianPhase.creatividad;
  }

  /// Evalúa si se puede comer ahora basado en ventana circadiana del usuario.
  ///
  /// Retorna: (canEatNow, isInNutritionWindow, minutesToWindowClose?)
  static (bool, bool, int?) _evaluateNutritionWindow(
    UserModel user,
    DateTime now,
  ) {
    final firstMeal = user.profile.firstMealGoal;
    final lastMeal = user.profile.lastMealGoal;

    // Sin ventana configurada → permitir comer (no hay datos para restringir)
    if (firstMeal == null || lastMeal == null) {
      return (true, false, null);
    }

    // Comparar solo hora:minuto (ignorar fecha del goal)
    final nowMinutes = now.hour * 60 + now.minute;
    final firstMinutes = firstMeal.hour * 60 + firstMeal.minute;
    final lastMinutes = lastMeal.hour * 60 + lastMeal.minute;

    final isInWindow =
        nowMinutes >= firstMinutes && nowMinutes <= lastMinutes;
    final minutesToClose = lastMinutes - nowMinutes;

    return (isInWindow, isInWindow, isInWindow ? minutesToClose : null);
  }

  /// Determina si es seguro ejercitar ahora.
  ///
  /// Reglas:
  ///   - No ejercitar en autofagia + sueño deficiente.
  ///   - No ejercitar en fase de sueño circadiano.
  static bool _canExerciseNow({
    required FastingPhase fastingPhase,
    required CircadianPhase circadianPhase,
    required double sleepQuality,
  }) {
    // Autofagia profunda + sueño malo → riesgo de catabolismo
    if (fastingPhase == FastingPhase.autofagia && sleepQuality < 0.4) {
      return false;
    }

    // Fase de sueño circadiano → no ejercitar
    if (circadianPhase == CircadianPhase.sueno) {
      return false;
    }

    return true;
  }

  /// Determina si es óptimo continuar en ayuno.
  ///
  /// Óptimo si la fase es cetosis o autofagia y la calidad de sueño > 0.6.
  static bool _isOptimalForFasting({
    required FastingPhase fastingPhase,
    required double sleepQuality,
  }) {
    // Óptimo si estamos en cetosis o autofagia Y sleep quality bueno
    final isDeepFasting = fastingPhase == FastingPhase.cetosis ||
        fastingPhase == FastingPhase.autofagia;
    return isDeepFasting && sleepQuality > 0.6;
  }

  /// Multiplicador de seguridad para ejercicio según fase de ayuno.
  ///
  /// Reduce la intensidad recomendada conforme avanza el ayuno: alerta=1.0,
  /// gluconeogénesis=0.95, cetosis=0.85, autofagia=0.6.
  static double _exerciseSafetyMultiplier(FastingPhase phase) {
    return switch (phase) {
      FastingPhase.alerta => 1.0,
      FastingPhase.gluconeogenesis => 0.95,
      FastingPhase.cetosis => 0.85,
      FastingPhase.autofagia => 0.6,
    };
  }

  /// Multiplicador de nutrición según fase circadiana.
  ///
  /// Pondera la calidad de la ingesta según la fase del día (digestión activa
  /// vs intestino en reposo). SPEC-70 documentará la base bibliográfica.
  static double _nutritionPhaseMultiplier(CircadianPhase phase) {
    return switch (phase) {
      CircadianPhase.sueno => 0.6, // Muy malo — intestino en reposo
      CircadianPhase.alerta => 0.8, // Cortisol alto — carbs subóptimos
      CircadianPhase.cognitivo => 1.0, // Óptimo — digestión activa
      CircadianPhase.receso => 0.95, // Bueno — digestión post-almuerzo
      CircadianPhase.motorFuerza => 0.9, // Tolerable — sangre a músculos
      CircadianPhase.creatividad => 0.7, // Malo — preparación para sueño
    };
  }

  /// Recomendación de tipo y porcentaje de ejercicio.
  ///
  /// Retorna: (tipo?, intensidad%) basado en la fase de ayuno, la fase
  /// circadiana y la calidad de sueño. SPEC-68 sustituirá los strings
  /// por un enum tipado de tipo de ejercicio.
  static (String?, int) _exerciseRecommendation({
    required FastingPhase fastingPhase,
    required CircadianPhase circadianPhase,
    required double sleepQuality,
  }) {
    // Sueño malo → solo LISS baja
    if (sleepQuality < 0.4) {
      return ('LISS', 35);
    }

    // Autofagia → no HIIT (riesgo catabolismo)
    if (fastingPhase == FastingPhase.autofagia) {
      return (sleepQuality > 0.6 ? 'STRENGTH' : 'LISS', 50);
    }

    // Por fase circadiana
    return switch (circadianPhase) {
      CircadianPhase.alerta => ('STRENGTH', 75), // Cortisol alto
      CircadianPhase.cognitivo => ('HIIT', 80), // Energía máxima
      CircadianPhase.receso => ('LISS', 55), // Digestión
      CircadianPhase.motorFuerza => ('STRENGTH', 85), // Pico muscular
      CircadianPhase.creatividad => ('LISS', 40), // Pre-sueño
      CircadianPhase.sueno => (null, 0), // No ejercitar
    };
  }

  /// Detecta violaciones de sincronización inter-pilar.
  ///
  /// Recibe el MetabolicState (no parámetros individuales) y devuelve la
  /// lista de mensajes de violación detectados.
  static List<String> _detectViolations({
    required FastingPhase fastingPhase,
    required CircadianPhase circadianPhase,
    required MetabolicState state,
  }) {
    final List<String> violations = [];

    // Deshidratación en autofagia
    if (fastingPhase == FastingPhase.autofagia &&
        state.hydrationLevel < 0.5) {
      violations.add(
        'Riesgo deshidratación en Autofagia: hidratación al '
        '${(state.hydrationLevel * 100).toStringAsFixed(0)}%',
      );
    }

    // Sueño deficiente en fase nocturna
    if (circadianPhase == CircadianPhase.sueno &&
        state.sleepQuality < 0.5) {
      violations.add(
        'Recovery bajo: calidad sueño '
        '${(state.sleepQuality * 100).toStringAsFixed(0)}%',
      );
    }

    // Ejercicio excesivo en autofagia
    if (fastingPhase == FastingPhase.autofagia &&
        state.exerciseMinutesRaw > 60) {
      violations.add(
        'Ejercicio intenso en Autofagia '
        '(${state.exerciseMinutesRaw.toStringAsFixed(0)} min). '
        'Riesgo catabolismo muscular.',
      );
    }

    // Comida fuera de ventana circadiana
    if (state.circadianAlignment < 0.5 && state.nutritionScoreRaw > 0) {
      violations.add(
        'Comidas fuera de ventana circadiana: alineación '
        '${(state.circadianAlignment * 100).toStringAsFixed(0)}%',
      );
    }

    return violations;
  }

  /// Genera recomendaciones tipadas basadas en el estado actual.
  ///
  /// Solo genera recomendaciones con reglas claras derivadas de datos reales.
  /// Si no hay base para una recomendación, NO la genera.
  static List<Recommendation> _generateRecommendations({
    required FastingPhase fastingPhase,
    required CircadianPhase circadianPhase,
    required MetabolicState state,
    required StreakState streak,
  }) {
    final List<Recommendation> recs = [];

    // Hidratación urgente en autofagia
    if (fastingPhase == FastingPhase.autofagia &&
        state.hydrationLevel < 0.5) {
      recs.add(const Recommendation(
        id: 'hydrate_during_autophagy',
        priority: RecommendationPriority.high,
        pillar: Pillar.hydration,
      ));
    }

    // Hidratación baja general
    if (state.hydrationLevel < 0.3) {
      recs.add(const Recommendation(
        id: 'hydration_critical',
        priority: RecommendationPriority.high,
        pillar: Pillar.hydration,
      ));
    }

    // Ejercicio pendiente (0 min hoy)
    if (state.exerciseMinutesRaw == 0 &&
        circadianPhase != CircadianPhase.sueno) {
      recs.add(const Recommendation(
        id: 'exercise_pending',
        priority: RecommendationPriority.medium,
        pillar: Pillar.exercise,
      ));
    }

    // Sueño deficiente
    if (state.sleepQuality < 0.5 && state.sleepHoursRaw > 0) {
      recs.add(const Recommendation(
        id: 'sleep_insufficient',
        priority: RecommendationPriority.medium,
        pillar: Pillar.sleep,
      ));
    }

    // Nutrición pendiente (0 comidas)
    if (state.nutritionScoreRaw == 0 &&
        circadianPhase != CircadianPhase.sueno) {
      recs.add(const Recommendation(
        id: 'nutrition_pending',
        priority: RecommendationPriority.low,
        pillar: Pillar.nutrition,
      ));
    }

    return recs;
  }
}

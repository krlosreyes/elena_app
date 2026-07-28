import 'dart:math' as math;

import 'package:elena_app/src/core/engine/coherence_engine.dart';
import 'package:elena_app/src/core/engine/metabolic_state.dart';
import 'package:elena_app/src/core/rules/circadian_rules.dart';
import 'package:elena_app/src/features/hydration/application/hydration_notifier.dart';
import 'package:elena_app/src/features/fasting/domain/fasting_status.dart';
import 'package:elena_app/src/features/sleep/domain/sleep_log.dart';
import 'package:elena_app/src/features/sleep/domain/sleep_quality_calculator.dart';
import 'package:elena_app/src/features/exercise/application/exercise_state.dart';
// Propuesta módulo Ejercicio (2026-07-21) Fase 4: cierra el gap ya
// detectado en la auditoría previa — `ExerciseLoadCalculator` (SPEC-68,
// pondera tipo×intensidad) existía pero no llegaba al IMR; el builder
// alimentaba a `ScoreEngine` con minutos crudos, así que 60 min de yoga
// puntuaban igual que 60 min de HIIT. Ver
// documentacion/propuestas/Propuesta_Modulo_Ejercicio_2026-07-21.docx §5.
import 'package:elena_app/src/features/exercise/domain/exercise_load_calculator.dart';
import 'package:elena_app/src/features/nutrition/application/cociente_a_service.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';

/// Construye un [MetabolicState] a partir de los estados de cada pilar.
///
/// El builder es la FUENTE DE VERDAD de toda normalización.
/// Recibe estados crudos de los providers y calcula internamente:
/// - sleepQuality (desde horas de sueño)
/// - hydrationLevel (desde litros / goal)
/// - glycemicLoad (desde comidas + ventana)
/// - exerciseLoad (desde minutos)
/// - circadianAlignment (desde lastMealTime vs goal)
/// - glycogenLevel (desde horas de ayuno)
/// - metabolicCoherence (desde datos de todos los pilares)
///
/// NO depende del Orchestrator. NO delega normalización a otros providers.
class MetabolicStateBuilder {
  const MetabolicStateBuilder._();

  /// Construye el MetabolicState completo.
  ///
  /// Parámetros:
  /// - [user]: UserModel con perfil circadiano.
  /// - [fasting]: Estado actual del FastingNotifier.
  /// - [sleepHours]: Horas de sueño del día (desde sleepDurationProvider).
  /// - [exercise]: Estado actual del ExerciseNotifier.
  /// - [nutrition]: Estado actual del NutritionNotifier.
  /// - [hydration]: Estado actual del HydrationNotifier.
  /// - [maxFastingHoursToday]: Máximo de horas de ayuno hoy (activo o completado).
  /// - [weeklyAdherence]: Adherencia semanal binaria pre-calculada por StreakEngine.
  /// - [weeklyQualityScore]: SPEC-53. Promedio continuo del dailyQualityScore
  ///   de los últimos 7 días. Si no se pasa, default 0.0 (mismo comportamiento
  ///   que weeklyAdherence para usuario nuevo).
  /// - [lastSleepLog]: SPEC-69. Último ciclo de sueño persistido. Si no es
  ///   null, alimenta dimensiones extra (gap metabólico, latencia, despertares,
  ///   percepción subjetiva) al SleepQualityCalculator.
  /// - [now]: SPEC-72.9. Reloj inyectado. El builder es una factory pura —
  ///   nunca llama a `DateTime.now()` internamente. El provider que lo invoca
  ///   pasa el pulso de `metabolicPulseProvider` (cada 10s); los tests pueden
  ///   pasar valores deterministas. Default omitido a propósito: requerirlo
  ///   forza al caller a pensar en la coordenada temporal de su build.
  static MetabolicState build({
    required UserModel user,
    required FastingState fasting,
    required double sleepHours,
    required ExerciseState exercise,
    required NutritionState nutrition,
    required HydrationState hydration,
    required double maxFastingHoursToday,
    required double weeklyAdherence,
    required DateTime now,
    double weeklyQualityScore = 0.0,
    SleepLog? lastSleepLog,
  }) {
    // ── fastingHours (normalizado via sigmoid) ───────────────────────────
    // Misma sigmoid que ScoreEngine: 1/(1+e^(-(h-14)/1.5))
    final double fastingNormalized =
        1.0 / (1.0 + math.exp(-(maxFastingHoursToday - 14) / 1.5));

    // ── glycogenLevel (inverso de progreso de ayuno) ─────────────────────
    // Derivado directamente de las horas de ayuno.
    // No depende del Orchestrator — usa la misma lógica de fases.
    final double glycogenLevel = _glycogenFromHours(maxFastingHoursToday);

    // ── circadianAlignment ───────────────────────────────────────────────
    // Compara lastMealTime con lastMealGoal del perfil circadiano.
    //
    // SPEC-233: stableLastMeal es nullable cuando no hay ayuno activo ni
    // lastMealGoal configurado. En ese caso retornamos circadianAlignment=1.0
    // (neutral — sin datos reales no penalizamos al usuario).
    // El fallback hardcodeado a 20:00 generaba un circadianAlignment artificial
    // que corrompía el bloque Comportamiento del IMR para usuarios nuevos sin
    // datos. lastMealTime es nullable en MetabolicState y ScoreEngine retorna
    // empty() cuando es null — la cadena ya estaba preparada para este caso.
    final DateTime? stableLastMeal =
        fasting.startTime ?? user.profile.lastMealGoal;
    final double circadianAlignment = stableLastMeal != null
        ? _calculateCircadianAlignment(
            stableLastMeal, user.profile.lastMealGoal)
        : 1.0; // sin dato real → neutral (no penalizar)

    // ── sleepQuality ─────────────────────────────────────────────────────
    // SPEC-69: métrica multidimensional. Si tenemos `lastSleepLog`, alimentamos
    // gap metabólico, latencia, despertares y percepción subjetiva al
    // SleepQualityCalculator. Sin log, degrada graciosamente a la curva
    // piecewise por horas (idéntica al cálculo previo de `_normalizeSleep`).
    final double sleepQuality = SleepQualityCalculator.calculate(
      sleepHours: sleepHours,
      metabolicGapMinutes: lastSleepLog?.metabolicGap.inMinutes,
      sleepLatencyMinutes: lastSleepLog?.sleepLatencyMinutes,
      nightAwakenings: lastSleepLog?.nightAwakenings,
      subjectiveQuality: lastSleepLog?.subjectiveQuality,
    );

    // ── exerciseLoad ─────────────────────────────────────────────────────
    // Normalización: (minutos / 60).clamp(0, 1.0)
    final double exerciseLoad = (exercise.todayMinutes / 60.0).clamp(0.0, 1.0);

    // ── glycemicLoad + nutritionScoreRaw ─────────────────────────────────
    // SPEC-137: el pilar Nutrición pasa de medir "cuántas comidas
    // registraste dentro de la ventana" a medir "qué proporción A:E
    // tuvieron tus platos". La unidad atómica es `MealRatio` y la
    // métrica visible es el Cociente A.
    //
    // Fórmula vigente:
    //   nutritionScoreRaw = 0.70 × cocienteA + 0.30 × windowAdherence
    //
    // Donde cocienteA = porcentaje de platos A-dominantes registrados.
    // El campo `glycemicLoad` del MetabolicState ahora refleja
    // directamente el cocienteA — sigue siendo la "carga glucémica
    // proxy" del día, pero estimada por proporción A:E (proxy
    // hormonal de IG×CG) en lugar de "comidas registradas".
    //
    // Pre-SPEC-137 era:
    //   mealRatio    = mealsLoggedToday / targetMeals (clamp 0-1)
    //   glycemicLoad = 0.60 × mealRatio + 0.40 × windowAdherence
    //   nutritionScoreRaw = glycemicLoad
    //
    // Razón del cambio documentada en NUTRITION_BIBLIOGRAPHY.md §1 y
    // en feedback_pillar_nutrition.md (memoria persistente).
    const cocienteAService = CocienteAService();
    final double cocienteA = cocienteAService.calculate(nutrition.todayLogs);
    final double glycemicLoad = cocienteA;
    final double nutritionScoreRaw =
        (0.70 * cocienteA) + (0.30 * nutrition.windowAdherence);

    // ── hydrationLevel ───────────────────────────────────────────────────
    // Calculado desde litros actuales / goal.
    // NO delegamos a hydration.progressPercentage.
    final double hydrationLevel = hydration.dailyGoalLiters > 0
        ? (hydration.currentAmountLiters / hydration.dailyGoalLiters)
            .clamp(0.0, 1.0)
        : 0.0;

    // ── metabolicCoherence ───────────────────────────────────────────────
    // SPEC-71: delega a CoherenceEngine (fuente única). El builder ya no
    // contiene lógica de penalización propia. OrchestratorEngine usa este
    // valor directamente — sin recalcular con `violations.length * 0.05`.
    final double metabolicCoherence = CoherenceEngine.calculate(
      sleepHours: sleepHours,
      hydrationLevel: hydrationLevel,
      circadianAlignment: circadianAlignment,
      exerciseLoad: exerciseLoad,
      fastingHours: maxFastingHoursToday,
    );

    // SPEC-60: el builder es el único productor de MetabolicState con
    // `lastMealTime` y `timestamp` no nulos. Cualquier consumidor que reciba
    // un state desde aquí puede asumirlos no-null. Para el caso "sin datos"
    // se usa `MetabolicState.empty()` que retorna ambos como null.
    return MetabolicState(
      // Normalizados
      fastingHours: fastingNormalized,
      glycogenLevel: glycogenLevel,
      circadianAlignment: circadianAlignment,
      sleepQuality: sleepQuality,
      exerciseLoad: exerciseLoad,
      glycemicLoad: glycemicLoad,
      hydrationLevel: hydrationLevel,
      metabolicCoherence: metabolicCoherence,
      // Crudos (para ScoreEngine)
      fastingHoursRaw: maxFastingHoursToday,
      sleepHoursRaw: sleepHours,
      // Fase 4 (2026-07-21): antes `exercise.todayMinutes.toDouble()` —
      // minutos crudos, sin distinguir tipo/intensidad. Ahora usamos la
      // carga ponderada de ExerciseLoadCalculator (tipo×intensidad,
      // SPEC-68) reexpresada en "minutos equivalentes" (× 60) para
      // preservar la escala que ScoreEngine ya normaliza
      // (`exerciseMin / 60`, ver _kExerciseMinutesNormalization).
      // Backward-compat exacta para logs legacy sin `type`/`intensity`:
      // ExerciseLoadCalculator usa multiplicador neutro 1.0 en ese caso,
      // así que el resultado es idéntico a los minutos crudos de antes.
      exerciseMinutesRaw:
          ExerciseLoadCalculator.sumDailyLoad(exercise.history) * 60.0,
      // SPEC-137: ya no es == glycemicLoad. El builder sigue siendo la
      // fuente de verdad — calculamos ambos arriba de manera explícita.
      nutritionScoreRaw: nutritionScoreRaw,
      weeklyAdherence: weeklyAdherence,
      weeklyQualityScore: weeklyQualityScore,
      lastMealTime: stableLastMeal, // nullable: null = sin dato real
      timestamp: now,
    );
  }

  // ── Helpers privados ─────────────────────────────────────────────────────

  /// Estima nivel de glucógeno directamente desde horas de ayuno.
  /// Mapeo biológico:
  /// - 0-4h (post-absorción): glucógeno casi lleno → 0.9
  /// - 4-8h (gluconeogénesis): depleción parcial → 0.6
  /// - 8-12h (cetosis temprana): depleción significativa → 0.3
  /// - 12h+ (autofagia): reservas mínimas → 0.1
  static double _glycogenFromHours(double hours) {
    if (hours < 4) return 0.9;
    if (hours < 8) return 0.6;
    if (hours < 12) return 0.3;
    return 0.1;
  }

  // SPEC-69: `_normalizeSleep` eliminado. La normalización de calidad de
  // sueño vive ahora en `SleepQualityCalculator.calculate` (función pura,
  // multidimensional, con degradación graciosa). El comportamiento para el
  // caso "solo horas, sin log" coincide con la curva piecewise anterior.

  /// Calcula circadianAlignment: penalización gradual (SPEC-26).
  static double _calculateCircadianAlignment(
    DateTime lastMealTime,
    DateTime? lastMealGoal,
  ) {
    if (lastMealGoal != null) {
      if (lastMealTime.isAfter(lastMealGoal)) {
        final minutesLate = lastMealTime.difference(lastMealGoal).inMinutes;
        return (1.0 - (minutesLate / 120.0)).clamp(0.0, 1.0);
      } else if (lastMealTime.isBefore(lastMealGoal)) {
        return 1.0; // Bonus eTRF se aplica en ScoreEngine, aquí es 1.0
      }
      return 1.0;
    }

    // Sin goal: penalización por ingesta nocturna (en o después de 21:30, SPEC-70.5).
    // SPEC-59: comparación normalizada en minutos totales desde la medianoche
    // para evitar expresiones `hour`/`minute` separadas con `&&/||`.
    final int mealMinutes = lastMealTime.hour * 60 + lastMealTime.minute;
    if (mealMinutes >= CircadianRules.intestinalLockMinutes) {
      return 0.5;
    }
    return 1.0;
  }

  // SPEC-71: _calculateCoherence eliminado. La lógica vive ahora en
  // CoherenceEngine.calculate (core/engine/coherence_engine.dart).
}

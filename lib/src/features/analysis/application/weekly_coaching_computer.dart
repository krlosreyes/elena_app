// SPEC-153: motor puro del WeeklyCoachingCard.
//
// Dado los daily_summary de la ventana actual y los de la ventana
// inmediatamente anterior, computa promedios por pilar + deltas +
// pilar débil.
//
// SPEC-192.3b (2026-06-05): agregado `fromCycleComparison` para que
// el widget consuma la versión cycle-aware sin cambiar su firma.
// La función `compute(current, previous, ...)` queda como ruta legacy
// para retrocompatibilidad con consumidores que aún usen daily_summary.
//
// Pure Dart — sin Flutter ni Riverpod. Testeable 100%.

import 'package:elena_app/src/features/analysis/data/daily_summary_doc.dart';
import 'package:elena_app/src/features/analysis/domain/cycle_comparison.dart';
import 'package:elena_app/src/features/analysis/domain/weekly_coaching_insight.dart';

class WeeklyCoachingComputer {
  WeeklyCoachingComputer._();

  /// Umbral mínimo de caída vs período anterior para considerar a un
  /// pilar como "el débil" por deterioro (10%).
  static const double kCriticalDropThreshold = -0.10;

  /// Umbral mínimo de promedio absoluto para considerar un pilar como
  /// "sostenido" — todos ≥ esto → estado motivacional sin acción.
  static const double kSustainedThreshold = 0.80;

  /// `current`: docs de la ventana semanal actual (últimos 7 días).
  /// `previous`: docs de la ventana inmediatamente anterior.
  /// `rangeStart/rangeEnd`: rango calendárico de la ventana actual,
  ///                       para mostrar en el header.
  static WeeklyCoachingInsight compute({
    required List<DailySummaryDoc> current,
    required List<DailySummaryDoc> previous,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    if (current.isEmpty) {
      return WeeklyCoachingInsight.empty(
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      );
    }

    final fastingAvg = _avg(current, (d) => d.fastingProgress);
    final sleepAvg = _avg(current, (d) => d.sleepProgress);
    final hydrationAvg = _avg(current, (d) => d.hydrationProgress);
    final exerciseAvg = _avg(current, (d) => d.exerciseProgress);
    final mealsAvg = _avg(current, (d) => d.mealsProgress);

    double? fastingDelta;
    double? sleepDelta;
    double? hydrationDelta;
    double? exerciseDelta;
    double? mealsDelta;

    if (previous.isNotEmpty) {
      fastingDelta = fastingAvg - _avg(previous, (d) => d.fastingProgress);
      sleepDelta = sleepAvg - _avg(previous, (d) => d.sleepProgress);
      hydrationDelta =
          hydrationAvg - _avg(previous, (d) => d.hydrationProgress);
      exerciseDelta = exerciseAvg - _avg(previous, (d) => d.exerciseProgress);
      mealsDelta = mealsAvg - _avg(previous, (d) => d.mealsProgress);
    }

    final weakest = pickWeakPillar(
      fastingAvg: fastingAvg,
      sleepAvg: sleepAvg,
      hydrationAvg: hydrationAvg,
      exerciseAvg: exerciseAvg,
      mealsAvg: mealsAvg,
      fastingDelta: fastingDelta,
      sleepDelta: sleepDelta,
      hydrationDelta: hydrationDelta,
      exerciseDelta: exerciseDelta,
      mealsDelta: mealsDelta,
    );

    return WeeklyCoachingInsight(
      fastingAvg: fastingAvg,
      sleepAvg: sleepAvg,
      hydrationAvg: hydrationAvg,
      exerciseAvg: exerciseAvg,
      mealsAvg: mealsAvg,
      fastingDelta: fastingDelta,
      sleepDelta: sleepDelta,
      hydrationDelta: hydrationDelta,
      exerciseDelta: exerciseDelta,
      mealsDelta: mealsDelta,
      weakest: weakest,
      daysWithData: current.length,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
  }

  /// Algoritmo del pilar débil (SPEC-153 §2.4):
  ///
  ///   1. Si hay un pilar con caída ≥ |10%| vs anterior → ese (la peor caída).
  ///   2. Si no hay caídas críticas, el débil es el de menor promedio actual.
  ///   3. Si todos ≥80% → null (estado sostenido).
  static WeakPillar? pickWeakPillar({
    required double fastingAvg,
    required double sleepAvg,
    required double hydrationAvg,
    required double exerciseAvg,
    required double mealsAvg,
    required double? fastingDelta,
    required double? sleepDelta,
    required double? hydrationDelta,
    required double? exerciseDelta,
    required double? mealsDelta,
  }) {
    // Estado sostenido — todos están bien.
    if (fastingAvg >= kSustainedThreshold &&
        sleepAvg >= kSustainedThreshold &&
        hydrationAvg >= kSustainedThreshold &&
        exerciseAvg >= kSustainedThreshold &&
        mealsAvg >= kSustainedThreshold) {
      return null;
    }

    // Paso 1: caídas críticas.
    final drops = <WeakPillar, double>{};
    if (fastingDelta != null && fastingDelta <= kCriticalDropThreshold) {
      drops[WeakPillar.fasting] = fastingDelta;
    }
    if (sleepDelta != null && sleepDelta <= kCriticalDropThreshold) {
      drops[WeakPillar.sleep] = sleepDelta;
    }
    if (hydrationDelta != null && hydrationDelta <= kCriticalDropThreshold) {
      drops[WeakPillar.hydration] = hydrationDelta;
    }
    if (exerciseDelta != null && exerciseDelta <= kCriticalDropThreshold) {
      drops[WeakPillar.exercise] = exerciseDelta;
    }
    if (mealsDelta != null && mealsDelta <= kCriticalDropThreshold) {
      drops[WeakPillar.meals] = mealsDelta;
    }
    if (drops.isNotEmpty) {
      // La peor caída (delta más negativo).
      final worst = drops.entries.reduce(
        (a, b) => a.value < b.value ? a : b,
      );
      return worst.key;
    }

    // Paso 2: pilar con menor promedio actual.
    final averages = <WeakPillar, double>{
      WeakPillar.fasting: fastingAvg,
      WeakPillar.sleep: sleepAvg,
      WeakPillar.hydration: hydrationAvg,
      WeakPillar.exercise: exerciseAvg,
      WeakPillar.meals: mealsAvg,
    };
    final lowest = averages.entries.reduce(
      (a, b) => a.value < b.value ? a : b,
    );
    return lowest.key;
  }

  /// Promedio aritmético de una métrica sobre la lista de docs.
  /// Retorna 0 si la lista está vacía. Clamp [0, 1] por defensa contra
  /// docs corruptos con valores fuera de rango.
  static double _avg(
    List<DailySummaryDoc> docs,
    double Function(DailySummaryDoc) selector,
  ) {
    if (docs.isEmpty) return 0;
    double sum = 0;
    for (final d in docs) {
      sum += selector(d).clamp(0.0, 1.0);
    }
    return sum / docs.length;
  }

  /// SPEC-192.3b: construye el insight semanal desde una
  /// `CycleComparison` cycle-aware. Mapea los pilares uno a uno y
  /// reutiliza `pickWeakPillar` para mantener el algoritmo idéntico.
  ///
  /// Mapeo:
  ///   - `fastingMagnitude.current`  → fastingAvg
  ///   - `fastingMagnitude.delta`    → fastingDelta (null si no hay
  ///                                   ciclos en la ventana previa)
  ///   - idem para sleep/hydration/exercise/nutrition (→ meals).
  ///
  /// `daysWithData` se mapea a `currentCount` (cantidad de ciclos
  /// cerrados en la ventana actual) — el widget muestra "N ciclos"
  /// en lugar de "N días" como copy. El campo conserva el nombre
  /// por retrocompatibilidad con el widget.
  static WeeklyCoachingInsight fromCycleComparison(CycleComparison comparison) {
    if (comparison.currentCount == 0) {
      return WeeklyCoachingInsight.empty(
        rangeStart: comparison.currentRangeStart ?? DateTime.now(),
        rangeEnd: comparison.currentRangeEnd ?? DateTime.now(),
      );
    }

    final hasPrevious = comparison.previousCount > 0;
    final fastingAvg = comparison.fastingMagnitude.current;
    final sleepAvg = comparison.sleepQualityScore.current;
    final hydrationAvg = comparison.hydrationMagnitude.current;
    final exerciseAvg = comparison.exerciseMagnitude.current;
    final mealsAvg = comparison.nutritionMagnitude.current;

    final fastingDelta = hasPrevious ? comparison.fastingMagnitude.delta : null;
    final sleepDelta = hasPrevious ? comparison.sleepQualityScore.delta : null;
    final hydrationDelta =
        hasPrevious ? comparison.hydrationMagnitude.delta : null;
    final exerciseDelta =
        hasPrevious ? comparison.exerciseMagnitude.delta : null;
    final mealsDelta = hasPrevious ? comparison.nutritionMagnitude.delta : null;

    final weakest = pickWeakPillar(
      fastingAvg: fastingAvg,
      sleepAvg: sleepAvg,
      hydrationAvg: hydrationAvg,
      exerciseAvg: exerciseAvg,
      mealsAvg: mealsAvg,
      fastingDelta: fastingDelta,
      sleepDelta: sleepDelta,
      hydrationDelta: hydrationDelta,
      exerciseDelta: exerciseDelta,
      mealsDelta: mealsDelta,
    );

    return WeeklyCoachingInsight(
      fastingAvg: fastingAvg,
      sleepAvg: sleepAvg,
      hydrationAvg: hydrationAvg,
      exerciseAvg: exerciseAvg,
      mealsAvg: mealsAvg,
      fastingDelta: fastingDelta,
      sleepDelta: sleepDelta,
      hydrationDelta: hydrationDelta,
      exerciseDelta: exerciseDelta,
      mealsDelta: mealsDelta,
      weakest: weakest,
      // SPEC-192.3b: `daysWithData` ahora cuenta CICLOS, no días.
      daysWithData: comparison.currentCount,
      rangeStart: comparison.currentRangeStart ?? DateTime.now(),
      rangeEnd: comparison.currentRangeEnd ?? DateTime.now(),
    );
  }
}

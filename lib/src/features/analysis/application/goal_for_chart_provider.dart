// SPEC-168.0.D (2026-06-03): helper puente entre Goals y Charts.
//
// Los charts del Análisis muestran cada métrica en una unidad de
// visualización que no siempre coincide con la unidad del UserGoal:
//   - Hidratación: chart = % vs 2.5 L meta, goal = L/día → convertir.
//   - Resto: identidad (días, %, kg, min, h).
//
// Este provider centraliza el acceso. Los charts (SPEC-168.2 línea de
// objetivo, SPEC-168.8 color por estado) llaman `goalForChartProvider`
// y reciben el valor ya en la unidad correcta, o `null` si el usuario
// no activó el goal correspondiente.
//
// El IMR es excepción: no tiene UserGoal (es operacional, hard-coded
// en 75 según SPEC-141). Por convención devolvemos 75 directamente.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/analysis/domain/chart_metric.dart';
// SPEC-168.5.2: el target del chart de Ayuno viene del protocolo
// activo (fastingProvider.targetHours), no del goal del usuario.
import 'package:elena_app/src/features/dashboard/application/fasting_notifier.dart'
    show fastingProvider;
import 'package:elena_app/src/features/goals/application/goal_notifier.dart';
import 'package:elena_app/src/features/goals/domain/user_goal.dart';

/// Litros diarios base que define el 100 % en los charts de hidratación.
/// Coincide con `_hydrationHabitSeriesProvider` en
/// `analysis_series_providers.dart` (línea 215 al momento de SPEC-168.0.D).
const double _kHydrationBaseLiters = 2.5;

/// Valor operacional del IMR según SPEC-141. No es editable por el
/// usuario — es el techo de zona OPTIMIZADO.
const double _kImrOperationalTarget = 75.0;

/// Devuelve el target del usuario para una métrica de chart,
/// expresado en la unidad de visualización (no en la unidad del UserGoal).
/// `null` cuando el usuario no activó el goal correspondiente, lo cual
/// indica al chart que NO debe pintar línea de objetivo.
final goalForChartProvider =
    Provider.family<double?, ChartMetric>((ref, metric) {
  // SPEC-168.5.2: Ayuno necesita observar el protocolo activo, no los
  // goals del usuario. Para el resto basta con goalsMap.
  if (metric == ChartMetric.fastingHours) {
    final hours = ref.watch(fastingProvider).targetHours;
    return hours <= 0 ? null : hours.toDouble();
  }
  final goalsMap = ref.watch(goalsProvider);
  return _goalForMetric(metric, goalsMap);
});

/// Label formateado del objetivo para mostrar junto a la línea dashed
/// (SPEC-168.2). Misma family que el provider de valor; devuelve `null`
/// si el target lo es.
final goalLabelForChartProvider =
    Provider.family<String?, ChartMetric>((ref, metric) {
  final value = ref.watch(goalForChartProvider(metric));
  if (value == null) return null;
  return _formatLabel(metric, value);
});

// ─── Helpers internos ────────────────────────────────────────────────────────

double? _goalForMetric(ChartMetric m, Map<GoalType, UserGoal> goals) {
  UserGoal? find(GoalType t) {
    final g = goals[t];
    if (g == null || !g.isActive) return null;
    return g;
  }

  switch (m) {
    case ChartMetric.imr:
      // Operacional SPEC-141, no editable.
      return _kImrOperationalTarget;
    case ChartMetric.weight:
      return find(GoalType.weightTarget)?.targetValue;
    case ChartMetric.fastingHours:
      // No debería llegar acá (handled arriba), defensivo.
      return null;
    case ChartMetric.nutritionAPct:
      return find(GoalType.nutritionADominantPercent)?.targetValue;
    case ChartMetric.hydrationPct:
      // Conversión clave: goal es L/día, chart es % vs 2.5 L.
      final goal = find(GoalType.hydrationLitersPerDay)?.targetValue;
      if (goal == null) return null;
      return (goal * 100 / _kHydrationBaseLiters).clamp(0.0, 200.0);
    case ChartMetric.exerciseMin:
      return find(GoalType.exerciseMinPerDay)?.targetValue;
    case ChartMetric.sleepHours:
      return find(GoalType.sleepHoursPerNight)?.targetValue;
  }
}

String _formatLabel(ChartMetric m, double value) {
  switch (m) {
    case ChartMetric.imr:
      return value.toStringAsFixed(0);
    case ChartMetric.weight:
      return '${value.toStringAsFixed(1)} kg';
    case ChartMetric.fastingHours:
      return '${value.toStringAsFixed(0)} h';
    case ChartMetric.nutritionAPct:
      return '${value.toStringAsFixed(0)} %';
    case ChartMetric.hydrationPct:
      return '${value.toStringAsFixed(0)} %';
    case ChartMetric.exerciseMin:
      return '${value.toStringAsFixed(0)} min';
    case ChartMetric.sleepHours:
      return '${value.toStringAsFixed(1)} h';
  }
}

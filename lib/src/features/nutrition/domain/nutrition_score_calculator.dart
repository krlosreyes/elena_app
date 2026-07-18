import 'package:elena_app/src/features/nutrition/domain/nutrition_log.dart';

/// Auditoría 2026-07-11 (CODE-02): la fórmula de `nutritionScore` vivía
/// inline en `NutritionNotifier._recalculate` con los pesos 0.60/0.40
/// escritos como literales sin nombre. Esta clase extrae la fórmula tal
/// cual — MISMOS valores numéricos, MISMA lógica — solo con nombre y
/// aislada del notifier para poder testearla y leerla sin el ruido de
/// suscripciones/estado.
///
/// `nutritionScore` es el score 0.0-1.0 que el ScoreEngine consume para
/// el bloque Conducta del pilar Nutrición (ver comentario original en
/// `NutritionState.nutritionScore`).
class NutritionScoreCalculator {
  const NutritionScoreCalculator._();

  /// Peso de la adherencia de CANTIDAD (comidas registradas hoy / meta de
  /// comidas del usuario) dentro del `nutritionScore` final.
  static const double _kMealCountWeight = 0.60;

  /// Peso de la adherencia de VENTANA circadiana (% de comidas registradas
  /// dentro de la ventana firstMealGoal/lastMealGoal del usuario) dentro
  /// del `nutritionScore` final.
  static const double _kWindowAdherenceWeight = 0.40;

  /// % de comidas registradas respecto a la meta diaria de comidas,
  /// clamped a [0.0, 1.0]. `target` se clampa a [1, 10] para evitar
  /// división por cero o metas fuera de rango razonable.
  static double mealCountScore(int loggedCount, int target) {
    return (loggedCount / target.clamp(1, 10)).clamp(0.0, 1.0);
  }

  /// % de logs registrados dentro de la ventana circadiana sobre el total
  /// de logs del día. 0.0 si no hay logs (evita división por cero).
  static double windowAdherence(List<NutritionLog> logs) {
    if (logs.isEmpty) return 0.0;
    return logs.where((l) => l.withinCircadianWindow).length / logs.length;
  }

  /// Combina ambas adherencias con sus pesos y clampea a [0.0, 1.0].
  static double score({
    required double mealCountScore,
    required double windowAdherence,
  }) {
    return ((_kMealCountWeight * mealCountScore) +
            (_kWindowAdherenceWeight * windowAdherence))
        .clamp(0.0, 1.0);
  }
}

import 'package:elena_app/src/features/nutrition/application/cociente_a_service.dart';
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
/// `NutritionState.nutritionScore`), y es también la señal que
/// `StreakNotifier` reempaqueta como `nutritionMagnitude` para el
/// `dailyQualityScore` del Score del Día (ver `streak_entry.dart`).
///
/// REDISEÑO 2026-07-25 (diagnóstico "Pilar Nutrición: dos métricas
/// paralelas"): hasta esta fecha, la fórmula SOLO combinaba conteo de
/// comidas (`mealCountScore`) y ventana circadiana (`windowAdherence`)
/// — CERO peso a la composición real del plato. Un usuario podía
/// registrar 3 platos 100% Tipo E (baja calidad, `MealRatio.allE`) y
/// obtener el mismo `nutritionScore` (1.0) que registrando 3 platos
/// perfectos. La calidad real SÍ se calculaba (`CocienteAService`,
/// SPEC-137) pero solo alimentaba el IMR de la pantalla de Análisis con
/// peso marginal (~3% del IMR final vía `metabolic_state_builder.dart`),
/// nunca el Score del Día / anillo del Dashboard / racha que el usuario
/// ve a diario (`nutritionMagnitude`, peso 0.18 en `dailyQualityScore`).
///
/// Fix: `plateQualityScore` (reutiliza `CocienteAService`, MISMO criterio
/// que ya usa el IMR — porcentaje de platos A-dominantes) pasa a ser el
/// componente dominante. `mealCountScore` baja a condición de entrada +
/// peso residual (sin registro, `plateQualityScore` ya es 0.0 — el gate
/// real sigue siendo "no hay logs = no hay señal"). No se tocó
/// `metabolic_state_builder.dart` (el otro pipeline, IMR) ni
/// `streak_engine.dart` (`evaluateNutrition`, el gate binario de racha
/// "¿registró al menos 1 comida?" — se deja igual a propósito, es
/// consistente con cómo se evalúan los otros 4 pilares: umbral de
/// actividad, no de calidad; la calidad continua vive en la magnitud).
class NutritionScoreCalculator {
  const NutritionScoreCalculator._();

  static const CocienteAService _cocienteAService = CocienteAService();

  /// Peso de la CALIDAD del plato (Cociente A — % de platos A-dominantes
  /// registrados hoy) dentro del `nutritionScore` final. Componente
  /// dominante desde el rediseño 2026-07-25.
  static const double _kPlateQualityWeight = 0.60;

  /// Peso de la adherencia de CANTIDAD (comidas registradas hoy / meta de
  /// comidas del usuario) dentro del `nutritionScore` final.
  static const double _kMealCountWeight = 0.20;

  /// Peso de la adherencia de VENTANA circadiana (% de comidas registradas
  /// dentro de la ventana firstMealGoal/lastMealGoal del usuario) dentro
  /// del `nutritionScore` final.
  static const double _kWindowAdherenceWeight = 0.20;

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

  /// Calidad de composición del día: % de platos A-dominantes
  /// (`MealRatio.isADominant`) sobre los platos registrados hoy.
  ///
  /// Delega en `CocienteAService` — MISMO criterio que ya usa el IMR de
  /// Análisis (RF-137-05), para que "Score del Día" y el mini-stat
  /// "Cociente A" de la card de Nutrición nunca vuelvan a mostrar
  /// señales contradictorias. 0.0 si no hay logs (sin registro no hay
  /// señal que evaluar — no penaliza, tampoco aporta; mismo criterio
  /// que `mealCountScore`/`windowAdherence`).
  static double plateQualityScore(List<NutritionLog> logs) {
    return _cocienteAService.calculate(logs);
  }

  /// Combina las tres adherencias con sus pesos y clampea a [0.0, 1.0].
  static double score({
    required double mealCountScore,
    required double windowAdherence,
    required double plateQualityScore,
  }) {
    return ((_kPlateQualityWeight * plateQualityScore) +
            (_kMealCountWeight * mealCountScore) +
            (_kWindowAdherenceWeight * windowAdherence))
        .clamp(0.0, 1.0);
  }
}

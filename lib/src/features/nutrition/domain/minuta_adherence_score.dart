// SPEC-274 — Score del pilar Nutrición desde la ADHERENCIA a la Minuta.
//
// Decisión de Carlos (§9): la Minuta reemplaza al MealRatio como métrica
// visible. Este calculador PURO define cómo la adherencia diaria (los taps
// "Comí esto / Lo cambié / Me lo salté") se vuelve un score 0..1.
//
// `AdherenceMark.isAdherent` (SPEC-271) ya fija el criterio: "Comí" y
// "Cambié" cuentan como cumplido; "Me salté" no.
//
// GUARDARRAÍL DE NO-REGRESIÓN: `effective()` solo usa la adherencia cuando
// existe una minuta del día con al menos una comida marcada. Si no hay
// minuta (usuario que aún no la adoptó) o no ha marcado nada, devuelve el
// score actual por calidad de plato SIN cambios — comportamiento
// byte-idéntico para todos los usuarios existentes.

import 'package:elena_app/src/features/nutrition/domain/meal_plan.dart';

class MinutaAdherenceScore {
  const MinutaAdherenceScore._();

  /// Adherencia 0..1 = comidas cumplidas (Comí|Cambié) / comidas propuestas.
  /// Todas las comidas de la minuta están dentro de la ventana por
  /// construcción (SPEC-272), así que la ponderación por ventana es
  /// implícita. 0.0 si el plan no tiene comidas.
  static double adherence(MealPlan plan) {
    if (plan.meals.isEmpty) return 0.0;
    return (plan.adherentCount / plan.meals.length).clamp(0.0, 1.0);
  }

  /// Score efectivo del pilar para el Score del Día / anillo / racha.
  ///
  /// - Con minuta marcada (`markedCount > 0`) → adherencia a la minuta.
  /// - Sin minuta o sin marcar → [fallbackScore] (el score actual por
  ///   calidad de plato), clamped. Cero cambio para no adoptantes.
  static double effective({required double fallbackScore, MealPlan? plan}) {
    if (plan == null || plan.markedCount == 0) {
      return fallbackScore.clamp(0.0, 1.0);
    }
    return adherence(plan);
  }
}

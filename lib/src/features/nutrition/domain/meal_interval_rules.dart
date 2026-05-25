// SPEC-137 E.5: reglas del intervalo entre comidas.
//
// Fundamento científico (documentado en NUTRITION_BIBLIOGRAPHY.md §15):
// - El pico de insulina post-prandial dura 30-60 min; retorno a baseline
//   en personas sanas alrededor de las 2-3h (Crapo 1976, Diabetes).
// - Comer cada <2h sostiene hiperinsulinemia crónica incluso con carga
//   glucémica baja (Wolever 2003, Br J Nutr).
// - Periodos sin ingesta ≥3h permiten el cambio metabólico de glucosa
//   a grasa como combustible (Galgani 2008; Mattson 2017).
//
// Operacionalización en ElenaApp:
// - < 2h desde última comida → BLOQUEADO (hiperinsulinemia crónica).
// - 2-3h → WARNING (zona gris; insulina aún elevada).
// - ≥ 3h → OK (cambio metabólico habilitado).
// - Notificación 30 min antes de la próxima comida sugerida.
//
// Día de permitidos (cheat day) suspende todas las reglas — es decisión
// consciente del usuario y debemos respetarla.

import 'package:elena_app/src/features/nutrition/domain/nutrition_log.dart';

/// Resultado de evaluar si una comida puede registrarse en este momento.
enum MealIntervalCheck {
  /// Intervalo ≥ 3h. Sin restricción.
  ok,

  /// Intervalo 2-3h. Permitido con warning (usuario decide continuar).
  warning,

  /// Intervalo < 2h. Bloqueado — la insulina todavía está alta.
  blocked,

  /// Primera comida del día (no hay anterior). OK por defecto.
  firstMeal,

  /// Día de permitidos activo. Reglas suspendidas, OK siempre.
  cheatDayBypass,
}

/// Constantes del intervalo. Centralizadas para que las decisiones del
/// equipo médico de SPEC futura (revisión clínica) puedan ajustarlas
/// en un solo lugar.
class MealIntervalRules {
  const MealIntervalRules._();

  /// Intervalo mínimo entre comidas. Por debajo se bloquea el registro.
  static const Duration minInterval = Duration(hours: 2);

  /// Intervalo recomendado. A partir de aquí, OK sin warning.
  static const Duration recommendedInterval = Duration(hours: 3);

  /// Ventana antes de la próxima comida sugerida en la que aparece la
  /// notificación "alístate".
  static const Duration notificationLeadTime = Duration(minutes: 30);

  /// Evalúa el intervalo desde [lastMealAt] hasta [attemptAt].
  ///
  /// Si [lastMealAt] es null → [MealIntervalCheck.firstMeal].
  /// Si [cheatDayActive] → [MealIntervalCheck.cheatDayBypass].
  /// Si los logs son del DÍA ANTERIOR (más de 18h atrás) → tratado como
  /// "primera comida del día" — el ayuno nocturno reseteó la insulina.
  static MealIntervalCheck check({
    required DateTime? lastMealAt,
    required DateTime attemptAt,
    required bool cheatDayActive,
  }) {
    if (cheatDayActive) return MealIntervalCheck.cheatDayBypass;
    if (lastMealAt == null) return MealIntervalCheck.firstMeal;

    final delta = attemptAt.difference(lastMealAt);

    // Si el último registro es de hace más de 18h, asumimos que el
    // ayuno nocturno reseteó la insulina baseline (no es relevante para
    // la siguiente comida del día actual).
    if (delta >= const Duration(hours: 18)) {
      return MealIntervalCheck.firstMeal;
    }

    // Caso defensivo: timestamp en el futuro (no debería ocurrir, pero
    // si el usuario edita la hora con TimePicker mal, lo tratamos como
    // OK — el lado UI debe haber filtrado este caso antes).
    if (delta.isNegative) return MealIntervalCheck.ok;

    if (delta < minInterval) return MealIntervalCheck.blocked;
    if (delta < recommendedInterval) return MealIntervalCheck.warning;
    return MealIntervalCheck.ok;
  }

  /// Computa el timestamp de la próxima comida sugerida.
  /// Es `lastMealAt + recommendedInterval`.
  /// Null si [lastMealAt] es null.
  static DateTime? nextSuggestedAt(DateTime? lastMealAt) {
    if (lastMealAt == null) return null;
    return lastMealAt.add(recommendedInterval);
  }

  /// True si estamos dentro de la ventana de "30 min antes" de la
  /// próxima comida sugerida. Útil para que el banner del Dashboard
  /// decida si mostrarse.
  ///
  /// Devuelve true si:
  ///   nextSuggestedAt - notificationLeadTime ≤ now ≤ nextSuggestedAt
  static bool isInNotificationWindow({
    required DateTime? lastMealAt,
    required DateTime now,
  }) {
    final next = nextSuggestedAt(lastMealAt);
    if (next == null) return false;
    final windowOpen = next.subtract(notificationLeadTime);
    return !now.isBefore(windowOpen) && !now.isAfter(next);
  }

  /// Conveniencia: encuentra la última comida de la lista de logs.
  /// Null si la lista está vacía.
  static DateTime? lastMealOf(List<NutritionLog> logs) {
    if (logs.isEmpty) return null;
    var latest = logs.first.timestamp;
    for (final l in logs) {
      if (l.timestamp.isAfter(latest)) latest = l.timestamp;
    }
    return latest;
  }
}

// ── Excepciones tipadas ──────────────────────────────────────────────

/// Lanzada por `NutritionNotifier.logMeal` cuando el intervalo desde la
/// última comida es < 2h (regla "blocked"). La UI debe mostrar un
/// dialog explicativo y bloquear el registro hasta `canRegisterAt`.
class MealTooSoonException implements Exception {
  final DateTime lastMealAt;
  final DateTime attemptedAt;
  final DateTime canRegisterAt;

  const MealTooSoonException({
    required this.lastMealAt,
    required this.attemptedAt,
    required this.canRegisterAt,
  });

  Duration get sinceLastMeal => attemptedAt.difference(lastMealAt);
  Duration get untilCanRegister => canRegisterAt.difference(attemptedAt);

  @override
  String toString() => 'MealTooSoonException(since: $sinceLastMeal, '
      'wait: $untilCanRegister)';
}

/// Lanzada por `NutritionNotifier.logMeal` cuando el intervalo está en
/// la zona warning (2-3h). La UI debe mostrar dialog con dos botones:
/// "Esperar" (cancela) o "Registrar igual" (reintenta con forceLog=true).
class MealIntervalWarning implements Exception {
  final DateTime lastMealAt;
  final DateTime attemptedAt;
  final DateTime recommendedAt;

  const MealIntervalWarning({
    required this.lastMealAt,
    required this.attemptedAt,
    required this.recommendedAt,
  });

  Duration get sinceLastMeal => attemptedAt.difference(lastMealAt);
  Duration get untilRecommended =>
      recommendedAt.difference(attemptedAt);

  @override
  String toString() => 'MealIntervalWarning(since: $sinceLastMeal, '
      'recommended in: $untilRecommended)';
}

// SPEC-162: insights causa-efecto detectados por el motor.
//
// Pure Dart.

enum CausalInsightType {
  sustainedImprovement,
  criticalDrop,
  bestPeriod,
  convergence,
  dissociation,
  weeklyDrop,
}

class CausalInsight {
  /// Tipo del patrón detectado.
  final CausalInsightType type;

  /// Encabezado corto (1-2 líneas). El widget lo muestra bold.
  final String headline;

  /// Detalle / explicación (2-4 líneas).
  final String detail;

  /// Cita científica que respalda el coaching.
  final String citation;

  /// Inicio del período donde se observa el patrón.
  final DateTime periodStart;

  /// Fin del período donde se observa el patrón.
  final DateTime periodEnd;

  /// Fuerza del patrón (0..1). El detector ordena descendente por esta.
  /// Combina magnitud del cambio + relevancia clínica del hábito/outcome.
  final double strength;

  const CausalInsight({
    required this.type,
    required this.headline,
    required this.detail,
    required this.citation,
    required this.periodStart,
    required this.periodEnd,
    required this.strength,
  });
}

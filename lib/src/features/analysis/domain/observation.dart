// SPEC-201: observación honesta y accionable de Análisis.
//
// Reemplaza al `CausalInsight` causal-espurio. Es auto-referencial (tú vs tu
// base/meta/racha), NO afirma causa-efecto y NO lleva cita pegada. Cada una
// puede terminar en una micro-acción concreta.
//
// Pure Dart.

enum ObservationType {
  /// Una métrica esta semana vs tu propio promedio del período.
  baseline,

  /// Días consecutivos cumpliendo un pilar (refuerzo positivo).
  streak,

  /// Qué tan cerca estás de una meta diaria los últimos días.
  goalProximity,
}

class Observation {
  final ObservationType type;

  /// Encabezado corto (bold).
  final String headline;

  /// Detalle de 1-2 líneas con los números reales.
  final String detail;

  /// Micro-acción concreta. `null` si la observación es puro refuerzo.
  final String? action;

  /// Relevancia 0..1 — para ordenar y recortar a los más útiles.
  final double strength;

  /// Clave de deduplicación (pilar/métrica) — evita repetir el mismo sujeto.
  final String subject;

  const Observation({
    required this.type,
    required this.headline,
    required this.detail,
    required this.strength,
    required this.subject,
    this.action,
  });
}

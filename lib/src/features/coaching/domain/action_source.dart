// SPEC-194: fuente que generó una recomendación. Útil para telemetría
// (qué fuente convierte mejor) y para la futura personalización (SPEC-195).
//
// Dart puro (CONSTITUTION §3.1).

enum ActionSource {
  /// Orchestrator: acción apropiada a la fase biológica.
  orchestrator,

  /// AdaptiveEngine: subir/bajar de protocolo.
  adaptive,

  /// Regla de pilar más débil de la semana.
  weakPillar,

  /// Disparador sensible al tiempo (ventana, autofagia, eTRF).
  timeSensitive,

  /// Feedback de cierre de ciclo.
  cycleClose,

  /// Generador circadiano (menú fase → acción óptima).
  circadian,
}

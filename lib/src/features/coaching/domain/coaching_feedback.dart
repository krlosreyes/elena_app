// SPEC-194 RF-194-05 — feedback de cierre: refleja si el usuario siguió la
// acción que el coach recomendó durante el ciclo. Distinto de CycleFeedback
// (SPEC-149), que evalúa las magnitudes de los pilares.
//
// Dart puro (CONSTITUTION §3.1).

/// Resultado del seguimiento de la recomendación del ciclo anterior.
enum CoachingOutcome {
  /// La siguió y el pilar mejoró.
  completedImproved,

  /// La siguió, sin mejora visible aún (los cambios toman días).
  completedSteady,

  /// No la siguió.
  notCompleted,
}

class CoachingFeedback {
  const CoachingFeedback({
    required this.outcome,
    required this.message,
  });

  final CoachingOutcome outcome;

  /// Mensaje humano-cercano para mostrar al usuario al abrir el nuevo ciclo.
  final String message;
}

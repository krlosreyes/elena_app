// SPEC-262: acciones que otorgan estrellas y XP.
//
// Gamificación estilo Fastic (estrellas como moneda, XP/niveles, congeladores
// y tienda) PERO sobre datos reales y persistentes — cada recompensa nace de
// una acción que el usuario realmente registró, no de un contador inventado.
//
// La tabla de recompensas vive acá, en un solo lugar, para poder calibrarla y
// testearla sin tocar la lógica de estado ni la UI.

/// Cada acción registrable que la app premia.
enum StarAction {
  water,
  meal,
  fastingStarted,
  fastingCompleted,
  sleepLogged,
  exerciseLogged,
  lessonRead,
  weightLogged,

  /// Bonus del día: el día calificó para la racha (≥3 pilares con ancla).
  dayQualified,
}

/// Recompensa de una acción: estrellas (moneda) + XP (progreso de nivel).
class ActionReward {
  final int stars;
  final int xp;
  const ActionReward({required this.stars, required this.xp});
}

extension StarActionReward on StarAction {
  /// Tabla única de recompensas. Calibrable; los cócteles de una noche no
  /// aplican acá — esto premia hábitos saludables.
  ActionReward get reward => switch (this) {
        StarAction.water => const ActionReward(stars: 2, xp: 5),
        StarAction.meal => const ActionReward(stars: 3, xp: 8),
        StarAction.fastingStarted => const ActionReward(stars: 5, xp: 10),
        StarAction.fastingCompleted => const ActionReward(stars: 15, xp: 40),
        StarAction.sleepLogged => const ActionReward(stars: 5, xp: 12),
        StarAction.exerciseLogged => const ActionReward(stars: 5, xp: 15),
        StarAction.lessonRead => const ActionReward(stars: 4, xp: 10),
        StarAction.weightLogged => const ActionReward(stars: 3, xp: 8),
        StarAction.dayQualified => const ActionReward(stars: 10, xp: 30),
      };
}

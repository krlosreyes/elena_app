// SPEC-194 RF-194-05 + Adenda §7 — generador puro del feedback de cierre.
//
// Tono humano-cercano (memoria notification-tone-human-not-clinical):
// segunda persona, sin culpa, celebra el esfuerzo. Determinista.

import 'package:elena_app/src/core/orchestrator/biological_phases.dart';
import 'package:elena_app/src/features/coaching/domain/coaching_feedback.dart';

class CoachingFeedbackGenerator {
  const CoachingFeedbackGenerator._();

  /// Genera el feedback según si el usuario completó la acción recomendada
  /// para el pilar y si ese pilar mejoró respecto al ciclo anterior.
  ///
  /// [completed]: el usuario hizo la actividad del pilar recomendado.
  /// [improved]: el pilar subió vs el ciclo previo (null = desconocido → steady).
  /// [circadianClosedBeforeLock] (Adenda §7): si el ciclo cerró su ventana de
  /// comida ANTES del bloqueo intestinal (21:30) → true; después → false;
  /// desconocido / no aplica → null (no se agrega lectura circadiana).
  static CoachingFeedback generate({
    required Pillar recommendedPillar,
    required bool completed,
    bool? improved,
    bool? circadianClosedBeforeLock,
  }) {
    final x = _pillarPhrase(recommendedPillar);

    final CoachingOutcome outcome;
    final String base;
    if (!completed) {
      outcome = CoachingOutcome.notCompleted;
      base = 'Ayer te propuse enfocarte en $x. '
          'Sin culpa — hoy lo intentamos de nuevo, a tu ritmo.';
    } else if (improved == true) {
      outcome = CoachingOutcome.completedImproved;
      base = 'Ayer priorizaste $x y se notó. '
          'Vas en la dirección correcta — hoy mantengámoslo.';
    } else {
      outcome = CoachingOutcome.completedSteady;
      base = 'Ayer trabajaste $x. '
          'Los cambios reales toman unos días; seguí así.';
    }

    final note = _circadianNote(circadianClosedBeforeLock);
    return CoachingFeedback(
      outcome: outcome,
      message: note == null ? base : '$base $note',
    );
  }

  /// Adenda §7 — lectura circadiana del cierre, cuantificada contra el IMR.
  /// El circadiano es el 38% del bloque de conducta del IMR ("el eje"),
  /// por eso el coach reporta su efecto explícitamente.
  static String? _circadianNote(bool? closedBeforeLock) {
    if (closedBeforeLock == null) return null;
    if (closedBeforeLock) {
      return 'Además, cerraste tu ventana antes de las 21:30: tu factor '
          'circadiano se mantuvo en 1.0 — así se sostiene el IMR.';
    }
    return 'Una cosa: hoy cerraste después de las 21:30 y tu factor circadiano '
        'bajó a 0.5. Mañana, cerrar antes recupera ese punto (el circadiano '
        'es el 38% de tu conducta).';
  }

  /// Frase del pilar en segunda persona ("tu …").
  static String _pillarPhrase(Pillar p) => switch (p) {
        Pillar.fasting => 'tu ayuno',
        Pillar.sleep => 'tu sueño',
        Pillar.hydration => 'tu hidratación',
        Pillar.exercise => 'tu ejercicio',
        Pillar.nutrition => 'tu nutrición',
      };
}

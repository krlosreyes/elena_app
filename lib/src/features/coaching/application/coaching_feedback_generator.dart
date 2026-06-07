// SPEC-194 RF-194-05 — generador puro del feedback de cierre.
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
  static CoachingFeedback generate({
    required Pillar recommendedPillar,
    required bool completed,
    bool? improved,
  }) {
    final x = _pillarPhrase(recommendedPillar);

    if (!completed) {
      return CoachingFeedback(
        outcome: CoachingOutcome.notCompleted,
        message: 'Ayer te propuse enfocarte en $x. '
            'Sin culpa — hoy lo intentamos de nuevo, a tu ritmo.',
      );
    }
    if (improved == true) {
      return CoachingFeedback(
        outcome: CoachingOutcome.completedImproved,
        message: 'Ayer priorizaste $x y se notó. '
            'Vas en la dirección correcta — hoy mantengámoslo.',
      );
    }
    return CoachingFeedback(
      outcome: CoachingOutcome.completedSteady,
      message: 'Ayer trabajaste $x. '
          'Los cambios reales toman unos días; seguí así.',
    );
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

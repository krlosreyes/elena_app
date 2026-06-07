// SPEC-194 inc2/next — genera un candidato de coaching desde la sugerencia
// del AdaptiveEngine (subir/bajar protocolo de ayuno o meta de ejercicio).
// Pura: mapea AdaptiveSuggestion → CoachingAction. El input lo provee
// `adaptiveProvider` (ya existente) en el wiring.

import 'package:elena_app/src/core/orchestrator/biological_phases.dart';
import 'package:elena_app/src/features/adaptive/application/adaptive_engine.dart';
import 'package:elena_app/src/features/coaching/domain/action_source.dart';
import 'package:elena_app/src/features/coaching/domain/coaching_action.dart';
import 'package:elena_app/src/features/coaching/domain/confidence_level.dart';

class AdaptiveGenerator {
  const AdaptiveGenerator._();

  static List<CoachingAction> generate(AdaptiveSuggestion? suggestion) {
    if (suggestion == null) return const [];

    // El ajuste de protocolo es de ayuno; si solo cambia la meta de
    // ejercicio, el pilar es ejercicio.
    final Pillar pillar = suggestion.newProtocol != null
        ? Pillar.fasting
        : (suggestion.newExerciseGoal != null
            ? Pillar.exercise
            : Pillar.fasting);

    return [
      CoachingAction(
        id: 'adaptive_${suggestion.type.name}',
        title: suggestion.title,
        actionText: suggestion.description,
        reason: suggestion.reason,
        pillar: pillar,
        confidence: ConfidenceLevel.medium,
        // No es una cita bibliográfica: es una sugerencia derivada de la
        // estabilidad de TU IMR + adherencia (SPEC-08). Honesto al respecto.
        citation: '· Basado en tu progreso',
        source: ActionSource.adaptive,
        urgencyKind: ActionUrgencyKind.protocol,
        circadianImpact: 0.5,
      ),
    ];
  }
}

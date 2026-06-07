// SPEC-194 — genera candidatos desde las Recommendation del Orchestrator.
//
// `Recommendation` (core) es solo id semántico + priority + pillar, SIN texto
// (por diseño: la presentación mapea id → texto). Este generador es ese mapeo:
// id → título/acción/razón/cita + impacto circadiano. Pura y testeable.

import 'package:elena_app/src/core/orchestrator/biological_phases.dart';
import 'package:elena_app/src/core/orchestrator/recommendation.dart';
import 'package:elena_app/src/features/coaching/domain/action_source.dart';
import 'package:elena_app/src/features/coaching/domain/coaching_action.dart';
import 'package:elena_app/src/features/coaching/domain/confidence_level.dart';

typedef _Copy = ({
  String title,
  String action,
  String reason,
  String citation,
  ConfidenceLevel confidence,
  double circadian,
});

class OrchestratorGenerator {
  const OrchestratorGenerator._();

  static List<CoachingAction> generate(List<Recommendation> recs) {
    final out = <CoachingAction>[];
    for (final r in recs) {
      final c = _copyFor(r.id);
      if (c == null) continue; // id desconocido → no inventamos copy
      out.add(CoachingAction(
        id: 'orchestrator_${r.id}',
        title: c.title,
        actionText: c.action,
        reason: c.reason,
        pillar: r.pillar,
        confidence: c.confidence,
        citation: c.citation,
        source: ActionSource.orchestrator,
        urgencyKind: r.priority == RecommendationPriority.high
            ? ActionUrgencyKind.phaseOpportunity
            : ActionUrgencyKind.habit,
        circadianImpact: c.circadian,
      ));
    }
    return out;
  }

  static _Copy? _copyFor(String id) {
    switch (id) {
      case 'hydrate_during_autophagy':
        return (
          title: 'Hidrátate mientras ayunas',
          action: 'Toma agua ahora — acompaña a tu cuerpo durante el ayuno.',
          reason: 'Durante el ayuno la hidratación sostiene la limpieza celular.',
          citation: '· Mattson 2017',
          confidence: ConfidenceLevel.medium,
          circadian: 0.4,
        );
      case 'hydration_critical':
        return (
          title: 'Te falta agua hoy',
          action: 'Bebe un vaso de agua ahora.',
          reason: 'Vas por debajo de tu base de hidratación del día.',
          citation: '· EFSA 2010',
          confidence: ConfidenceLevel.low,
          circadian: 0.3,
        );
      case 'exercise_pending':
        return (
          title: 'Aún no te moviste',
          action: 'Suma 20 min de movimiento — una caminata cuenta.',
          reason: 'El movimiento ayuda a regular tu insulina.',
          citation: '· AHA 2018',
          confidence: ConfidenceLevel.medium,
          circadian: 0.65,
        );
      case 'sleep_insufficient':
        return (
          title: 'Dormiste poco',
          action: 'Intenta acostarte un poco antes esta noche.',
          reason: 'Menos de 7h compromete tu reparación metabólica.',
          citation: '· Walker 2017',
          confidence: ConfidenceLevel.medium,
          circadian: 0.8,
        );
      case 'nutrition_pending':
        return (
          title: 'No registraste comida',
          action: 'Registra tu última comida para cerrar bien el día.',
          reason: 'Mantener el registro mantiene tu coaching alineado.',
          citation: '· Basado en tu progreso',
          confidence: ConfidenceLevel.low,
          circadian: 0.5,
        );
      default:
        return null;
    }
  }
}

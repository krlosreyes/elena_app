// SPEC-194 inc2: genera la acción de coaching del pilar más débil de la
// semana, reusando el copy + cita ya curados en `WeakPillar`
// (SPEC-153). Sin Riverpod — función estática testeable.

import 'package:elena_app/src/core/orchestrator/biological_phases.dart';
import 'package:elena_app/src/features/analysis/domain/weekly_coaching_insight.dart';
import 'package:elena_app/src/features/coaching/application/coaching_mappers.dart';
import 'package:elena_app/src/features/coaching/domain/action_source.dart';
import 'package:elena_app/src/features/coaching/domain/coaching_action.dart';
import 'package:elena_app/src/features/coaching/domain/confidence_level.dart';

class WeakPillarGenerator {
  const WeakPillarGenerator._();

  /// Impacto circadiano por pilar (Adenda §3): cuánto mejora/protege el eje.
  static double _circadianImpact(Pillar p) => switch (p) {
        Pillar.sleep => 0.80,
        Pillar.exercise => 0.75,
        Pillar.nutrition => 0.70,
        Pillar.fasting => 0.60,
        Pillar.hydration => 0.30,
      };

  /// Devuelve 0 o 1 candidato: la acción sobre el pilar más débil.
  static List<CoachingAction> generate(WeeklyCoachingInsight insight) {
    final weak = insight.weakest;
    if (weak == null) return const [];

    final pillar = CoachingMappers.fromWeakPillar(weak);
    return [
      CoachingAction(
        id: 'weak_pillar_${weak.name}',
        title: 'Tu siguiente paso',
        actionText: weak.suggestedAction,
        reason: weak.insightHeadline,
        pillar: pillar,
        confidence: ConfidenceLevel.medium,
        citation: '· ${weak.citation}',
        source: ActionSource.weakPillar,
        urgencyKind: ActionUrgencyKind.habit,
        circadianImpact: _circadianImpact(pillar),
      ),
    ];
  }
}

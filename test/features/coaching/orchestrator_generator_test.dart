// SPEC-194 — tests del OrchestratorGenerator (Recommendation → CoachingAction).

import 'package:flutter_test/flutter_test.dart';
import 'package:elena_app/src/core/orchestrator/biological_phases.dart';
import 'package:elena_app/src/core/orchestrator/recommendation.dart';
import 'package:elena_app/src/features/coaching/application/orchestrator_generator.dart';
import 'package:elena_app/src/features/coaching/domain/action_source.dart';
import 'package:elena_app/src/features/coaching/domain/coaching_action.dart';

void main() {
  group('OrchestratorGenerator (SPEC-194)', () {
    test('mapea ids conocidos a acciones con texto y cita', () {
      final actions = OrchestratorGenerator.generate(const [
        Recommendation(
          id: 'hydrate_during_autophagy',
          priority: RecommendationPriority.high,
          pillar: Pillar.hydration,
        ),
        Recommendation(
          id: 'sleep_insufficient',
          priority: RecommendationPriority.medium,
          pillar: Pillar.sleep,
        ),
      ]);
      expect(actions, hasLength(2));
      final hydrate = actions.firstWhere((a) => a.id.contains('hydrate'));
      expect(hydrate.pillar, Pillar.hydration);
      expect(hydrate.source, ActionSource.orchestrator);
      expect(hydrate.citation.isNotEmpty, isTrue);
      expect(hydrate.actionText.isNotEmpty, isTrue);
    });

    test('priority high → phaseOpportunity; otras → habit', () {
      final high = OrchestratorGenerator.generate(const [
        Recommendation(
          id: 'hydration_critical',
          priority: RecommendationPriority.high,
          pillar: Pillar.hydration,
        ),
      ]).first;
      final low = OrchestratorGenerator.generate(const [
        Recommendation(
          id: 'nutrition_pending',
          priority: RecommendationPriority.low,
          pillar: Pillar.nutrition,
        ),
      ]).first;
      expect(high.urgencyKind, ActionUrgencyKind.phaseOpportunity);
      expect(low.urgencyKind, ActionUrgencyKind.habit);
    });

    test('id desconocido se ignora (no inventa copy)', () {
      final actions = OrchestratorGenerator.generate(const [
        Recommendation(
          id: 'id_inexistente_xyz',
          priority: RecommendationPriority.medium,
          pillar: Pillar.fasting,
        ),
      ]);
      expect(actions, isEmpty);
    });
  });
}

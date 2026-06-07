// SPEC-194 — tests del AdaptiveGenerator (AdaptiveSuggestion → CoachingAction).

import 'package:flutter_test/flutter_test.dart';
import 'package:elena_app/src/core/orchestrator/biological_phases.dart';
import 'package:elena_app/src/features/adaptive/application/adaptive_engine.dart';
import 'package:elena_app/src/features/coaching/application/adaptive_generator.dart';
import 'package:elena_app/src/features/coaching/domain/action_source.dart';
import 'package:elena_app/src/features/coaching/domain/coaching_action.dart';

void main() {
  group('AdaptiveGenerator (SPEC-194)', () {
    test('null → sin candidatos', () {
      expect(AdaptiveGenerator.generate(null), isEmpty);
    });

    test('levelUp con nuevo protocolo → 1 acción de ayuno', () {
      const s = AdaptiveSuggestion(
        type: SuggestionType.levelUp,
        title: 'Sube a 16:8',
        description: 'Tu IMR está estable; probá 16:8.',
        newProtocol: '16:8',
        reason: '6 de 7 días con IMR ≥ 75.',
      );
      final actions = AdaptiveGenerator.generate(s);
      expect(actions, hasLength(1));
      expect(actions.first.pillar, Pillar.fasting);
      expect(actions.first.id, 'adaptive_levelUp');
      expect(actions.first.source, ActionSource.adaptive);
      expect(actions.first.urgencyKind, ActionUrgencyKind.protocol);
      expect(actions.first.actionText, s.description);
    });

    test('sugerencia solo de ejercicio → pilar ejercicio', () {
      const s = AdaptiveSuggestion(
        type: SuggestionType.levelUp,
        title: 'Sube tu meta de ejercicio',
        description: 'Subí a 30 min diarios.',
        newExerciseGoal: 30,
        reason: 'Vas muy bien.',
      );
      final actions = AdaptiveGenerator.generate(s);
      expect(actions.first.pillar, Pillar.exercise);
    });

    test('simplify → id adaptive_simplify', () {
      const s = AdaptiveSuggestion(
        type: SuggestionType.simplify,
        title: 'Bajemos el ritmo',
        description: 'Volvé a 14:10 unos días.',
        newProtocol: '14:10',
        reason: 'Tu adherencia cayó; sin culpa.',
      );
      expect(AdaptiveGenerator.generate(s).first.id, 'adaptive_simplify');
    });
  });
}

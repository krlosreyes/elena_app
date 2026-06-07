// SPEC-194 — tests de la correlación recomendación → registro de pilar.

import 'package:flutter_test/flutter_test.dart';
import 'package:elena_app/src/core/orchestrator/biological_phases.dart';
import 'package:elena_app/src/features/coaching/application/coaching_completion_service.dart';
import 'package:elena_app/src/features/coaching/domain/action_source.dart';
import 'package:elena_app/src/features/coaching/domain/coaching_action.dart';
import 'package:elena_app/src/features/coaching/domain/confidence_level.dart';

CoachingAction _a(Pillar p, {String id = 'x'}) => CoachingAction(
      id: id,
      title: 't',
      actionText: 'a',
      reason: 'r',
      pillar: p,
      confidence: ConfidenceLevel.medium,
      citation: '· c',
      source: ActionSource.weakPillar,
      urgencyKind: ActionUrgencyKind.habit,
      circadianImpact: 0.5,
    );

void main() {
  group('CoachingCompletionService (SPEC-194)', () {
    test('actividad en el pilar recomendado cuenta una vez (dedup)', () {
      final s = CoachingCompletionService()..setActive(_a(Pillar.sleep, id: 's1'));
      expect(s.onPillarActivity(Pillar.sleep), isTrue);
      expect(s.onPillarActivity(Pillar.sleep), isFalse); // ya contada
    });

    test('actividad en otro pilar no cuenta', () {
      final s = CoachingCompletionService()..setActive(_a(Pillar.sleep));
      expect(s.onPillarActivity(Pillar.hydration), isFalse);
    });

    test('una nueva acción (otro id) puede contar de nuevo', () {
      final s = CoachingCompletionService()..setActive(_a(Pillar.sleep, id: 's1'));
      expect(s.onPillarActivity(Pillar.sleep), isTrue);
      s.setActive(_a(Pillar.sleep, id: 's2'));
      expect(s.onPillarActivity(Pillar.sleep), isTrue);
    });

    test('sin acción activa no cuenta', () {
      final s = CoachingCompletionService()..setActive(null);
      expect(s.onPillarActivity(Pillar.sleep), isFalse);
    });
  });
}

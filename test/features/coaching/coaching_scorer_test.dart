// SPEC-194 §6 — tests del scorer puro. Determinista y explicable.

import 'package:flutter_test/flutter_test.dart';
import 'package:elena_app/src/core/orchestrator/biological_phases.dart';
import 'package:elena_app/src/features/coaching/domain/action_source.dart';
import 'package:elena_app/src/features/coaching/domain/coaching_action.dart';
import 'package:elena_app/src/features/coaching/domain/coaching_snapshot.dart';
import 'package:elena_app/src/features/coaching/domain/confidence_level.dart';
import 'package:elena_app/src/features/coaching/domain/scoring/coaching_scorer.dart';

CoachingAction _action({
  required String id,
  required Pillar pillar,
  ActionUrgencyKind urgency = ActionUrgencyKind.habit,
  ConfidenceLevel confidence = ConfidenceLevel.medium,
  double circadianImpact = 0.3,
  int? minutesToDeadline,
  bool actionableNow = true,
  ActionSource source = ActionSource.weakPillar,
}) {
  return CoachingAction(
    id: id,
    title: id,
    actionText: id,
    reason: id,
    pillar: pillar,
    confidence: confidence,
    citation: '· test',
    source: source,
    urgencyKind: urgency,
    circadianImpact: circadianImpact,
    minutesToDeadline: minutesToDeadline,
    actionableNow: actionableNow,
  );
}

void main() {
  group('CoachingScorer (SPEC-194)', () {
    test('override: deadline duro inminente es siempre la principal', () {
      final closeWindow = _action(
        id: 'close_window',
        pillar: Pillar.nutrition,
        urgency: ActionUrgencyKind.deadlineHard,
        minutesToDeadline: 30, // urgency ≈ 0.95 ≥ 0.90
        circadianImpact: 1.0,
        source: ActionSource.timeSensitive,
      );
      final weakHabit = _action(
        id: 'exercise_habit',
        pillar: Pillar.exercise,
        circadianImpact: 0.75,
      );
      const s = CoachingSnapshot(
        currentPhase: CircadianPhase.creatividad,
        weakestPillar: Pillar.exercise,
      );

      final sel = CoachingScorer.select([weakHabit, closeWindow], s);
      expect(sel.primary?.id, 'close_window');
    });

    test('sin override: gana la acción del pilar más débil', () {
      final sleep = _action(
        id: 'sleep_winddown',
        pillar: Pillar.sleep,
        circadianImpact: 0.8,
      );
      final hydration = _action(
        id: 'hydrate',
        pillar: Pillar.hydration,
        confidence: ConfidenceLevel.low,
        circadianImpact: 0.3,
      );
      const s = CoachingSnapshot(
        currentPhase: CircadianPhase.creatividad,
        weakestPillar: Pillar.sleep,
      );

      final sel = CoachingScorer.select([hydration, sleep], s);
      expect(sel.primary?.pillar, Pillar.sleep);
    });

    test('período de gracia → sin recomendación', () {
      final a = _action(id: 'x', pillar: Pillar.sleep);
      const s = CoachingSnapshot(
        currentPhase: CircadianPhase.alerta,
        isGracePeriod: true,
      );
      expect(CoachingScorer.select([a], s).isEmpty, isTrue);
    });

    test('anti-fatiga: una acción ignorada 3x no se elige si hay alternativa',
        () {
      final ignored = _action(
        id: 'ignored',
        pillar: Pillar.sleep,
        circadianImpact: 0.8,
      );
      final fresh = _action(
        id: 'fresh',
        pillar: Pillar.sleep,
        circadianImpact: 0.8,
      );
      const s = CoachingSnapshot(
        currentPhase: CircadianPhase.creatividad,
        weakestPillar: Pillar.sleep,
        ignoredStreakByActionId: {'ignored': 3},
      );
      final sel = CoachingScorer.select([ignored, fresh], s);
      expect(sel.primary?.id, 'fresh');
    });

    test('determinismo: misma entrada → misma principal', () {
      final a = _action(id: 'a', pillar: Pillar.sleep, circadianImpact: 0.8);
      final b =
          _action(id: 'b', pillar: Pillar.nutrition, circadianImpact: 0.5);
      const s = CoachingSnapshot(
        currentPhase: CircadianPhase.creatividad,
        weakestPillar: Pillar.sleep,
      );
      final first = CoachingScorer.select([a, b], s).primary?.id;
      final second = CoachingScorer.select([a, b], s).primary?.id;
      expect(first, second);
    });

    test('secundaria: se muestra si es de pilar distinto y supera el umbral',
        () {
      final sleep = _action(
        id: 'sleep_primary',
        pillar: Pillar.sleep,
        confidence: ConfidenceLevel.high,
        circadianImpact: 0.8,
      );
      final nutrition = _action(
        id: 'etrf',
        pillar: Pillar.nutrition,
        confidence: ConfidenceLevel.medium,
        circadianImpact: 0.7,
      );
      const s = CoachingSnapshot(
        currentPhase: CircadianPhase.creatividad,
        weakestPillar: Pillar.sleep,
        secondWeakestPillar: Pillar.nutrition,
      );
      final sel = CoachingScorer.select([sleep, nutrition], s);
      expect(sel.primary?.pillar, Pillar.sleep);
      expect(sel.secondary?.pillar, Pillar.nutrition);
    });

    test('sin secundaria cuando solo hay alternativas del mismo pilar', () {
      final a = _action(id: 'a', pillar: Pillar.sleep, circadianImpact: 0.8);
      final b = _action(id: 'b', pillar: Pillar.sleep, circadianImpact: 0.7);
      const s = CoachingSnapshot(
        currentPhase: CircadianPhase.creatividad,
        weakestPillar: Pillar.sleep,
      );
      final sel = CoachingScorer.select([a, b], s);
      expect(sel.secondary, isNull);
    });

    test('urgency escala con la proximidad del deadline', () {
      final near = _action(
        id: 'near',
        pillar: Pillar.nutrition,
        urgency: ActionUrgencyKind.deadlineHard,
        minutesToDeadline: 15,
      );
      final far = _action(
        id: 'far',
        pillar: Pillar.nutrition,
        urgency: ActionUrgencyKind.deadlineHard,
        minutesToDeadline: 110,
      );
      expect(CoachingScorer.urgency(near),
          greaterThan(CoachingScorer.urgency(far)));
    });
  });
}

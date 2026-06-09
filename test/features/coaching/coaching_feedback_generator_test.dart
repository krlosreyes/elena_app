// SPEC-194 RF-194-05 — tests del generador de feedback de cierre.

import 'package:flutter_test/flutter_test.dart';
import 'package:elena_app/src/core/orchestrator/biological_phases.dart';
import 'package:elena_app/src/features/coaching/application/coaching_feedback_generator.dart';
import 'package:elena_app/src/features/coaching/domain/coaching_feedback.dart';

void main() {
  group('CoachingFeedbackGenerator (SPEC-194 RF-05)', () {
    test('completó y mejoró → outcome completedImproved + tono celebratorio',
        () {
      final f = CoachingFeedbackGenerator.generate(
        recommendedPillar: Pillar.sleep,
        completed: true,
        improved: true,
      );
      expect(f.outcome, CoachingOutcome.completedImproved);
      expect(f.message, contains('tu sueño'));
    });

    test('completó sin mejora visible → completedSteady', () {
      final f = CoachingFeedbackGenerator.generate(
        recommendedPillar: Pillar.hydration,
        completed: true,
        improved: false,
      );
      expect(f.outcome, CoachingOutcome.completedSteady);
    });

    test('improved null se trata como steady', () {
      final f = CoachingFeedbackGenerator.generate(
        recommendedPillar: Pillar.exercise,
        completed: true,
      );
      expect(f.outcome, CoachingOutcome.completedSteady);
    });

    test('no completó → notCompleted, sin culpa', () {
      final f = CoachingFeedbackGenerator.generate(
        recommendedPillar: Pillar.fasting,
        completed: false,
      );
      expect(f.outcome, CoachingOutcome.notCompleted);
      expect(f.message.toLowerCase(), contains('sin culpa'));
    });

    test('determinismo: misma entrada → mismo mensaje', () {
      CoachingFeedback g() => CoachingFeedbackGenerator.generate(
            recommendedPillar: Pillar.nutrition,
            completed: true,
            improved: true,
          );
      expect(g().message, g().message);
    });
  });

  group('Lectura circadiana del cierre (Adenda §7)', () {
    test('sin dato circadiano (null) → NO agrega lectura', () {
      final f = CoachingFeedbackGenerator.generate(
        recommendedPillar: Pillar.sleep,
        completed: true,
        improved: true,
      );
      expect(f.message, isNot(contains('circadiano')));
    });

    test('cerró antes de 21:30 → factor se mantuvo en 1.0', () {
      final f = CoachingFeedbackGenerator.generate(
        recommendedPillar: Pillar.nutrition,
        completed: true,
        improved: true,
        circadianClosedBeforeLock: true,
      );
      expect(f.message, contains('antes de las 21:30'));
      expect(f.message, contains('1.0'));
      // No cambia el outcome base; solo enriquece el mensaje.
      expect(f.outcome, CoachingOutcome.completedImproved);
    });

    test('cerró después de 21:30 → correctivo, sin culpa, cuantificado', () {
      final f = CoachingFeedbackGenerator.generate(
        recommendedPillar: Pillar.nutrition,
        completed: false,
        circadianClosedBeforeLock: false,
      );
      expect(f.message, contains('después de las 21:30'));
      expect(f.message, contains('0.5'));
      expect(f.message, contains('38%'));
      expect(f.outcome, CoachingOutcome.notCompleted);
    });

    test('la lectura circadiana es additiva: conserva el mensaje base', () {
      final base = CoachingFeedbackGenerator.generate(
        recommendedPillar: Pillar.sleep,
        completed: true,
        improved: true,
      );
      final withNote = CoachingFeedbackGenerator.generate(
        recommendedPillar: Pillar.sleep,
        completed: true,
        improved: true,
        circadianClosedBeforeLock: true,
      );
      expect(withNote.message, startsWith(base.message));
      expect(withNote.message.length, greaterThan(base.message.length));
    });
  });
}

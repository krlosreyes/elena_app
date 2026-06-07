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
}

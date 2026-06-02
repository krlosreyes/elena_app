// SPEC-149 §8.2: tests del CycleFeedbackGenerator.

import 'package:elena_app/src/features/metabolic_cycle/domain/cycle_feedback.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';
import 'package:flutter_test/flutter_test.dart';

CycleMagnitudes _uniform(double q) => CycleMagnitudes(
      fastingMagnitude: q,
      sleepQualityScore: q,
      hydrationMagnitude: q,
      exerciseMagnitude: q,
      nutritionMagnitude: q,
    );

void main() {
  group('SPEC-149 §8.2 — Achievements', () {
    test('Magnitudes uniformes 1.0 → ≥4 achievements + ventana temprana', () {
      final feedback = CycleFeedbackGenerator.generate(
        magnitudes: _uniform(1.0),
        fastingDurationHours: 16,
        feedingWindowHours: 8,
        windowClosedAt: DateTime(2026, 6, 1, 18, 30),
      );
      // Ayuno + Sueño + Hidratación + Ejercicio + Nutrición + ventana temprana = 6.
      expect(feedback.achievements.length, 6);
      expect(
        feedback.achievements.any((a) => a.contains('autofagia')),
        isTrue,
      );
      expect(
        feedback.achievements.any((a) => a.contains('eTRF')),
        isTrue,
      );
    });

    test('Magnitudes uniformes 0.5 → 0 achievements', () {
      final feedback = CycleFeedbackGenerator.generate(
        magnitudes: _uniform(0.5),
        fastingDurationHours: 8,
        feedingWindowHours: 16,
        windowClosedAt: DateTime(2026, 6, 1, 22, 0),
      );
      expect(feedback.achievements, isEmpty);
    });

    test('Ayuno corto (<12h) no genera achievement aunque magnitud sea alta',
        () {
      final feedback = CycleFeedbackGenerator.generate(
        magnitudes: CycleMagnitudes(
          fastingMagnitude: 1.0,
          sleepQualityScore: 0.5,
          hydrationMagnitude: 0.5,
          exerciseMagnitude: 0.5,
          nutritionMagnitude: 0.5,
        ),
        fastingDurationHours: 10, // <12
        feedingWindowHours: 14,
        windowClosedAt: null,
      );
      expect(
        feedback.achievements.any((a) => a.contains('Ayuno')),
        isFalse,
        reason: 'ayuno <12h no aporta autofagia',
      );
    });
  });

  group('SPEC-149 §8.2 — Gaps', () {
    test('Magnitudes uniformes 0.5 → 5 gaps ordenados', () {
      final feedback = CycleFeedbackGenerator.generate(
        magnitudes: _uniform(0.5),
        fastingDurationHours: 10,
        feedingWindowHours: 14,
        windowClosedAt: DateTime(2026, 6, 1, 22, 0),
      );
      expect(feedback.gaps.length, 5);
    });

    test('Mix: gap más grande aparece primero', () {
      final feedback = CycleFeedbackGenerator.generate(
        magnitudes: CycleMagnitudes(
          fastingMagnitude: 0.9,
          sleepQualityScore: 0.7,
          hydrationMagnitude: 0.3, // PEOR
          exerciseMagnitude: 0.6,
          nutritionMagnitude: 0.5,
        ),
        fastingDurationHours: 16,
        feedingWindowHours: 8,
        windowClosedAt: DateTime(2026, 6, 1, 19, 0),
      );
      expect(feedback.gaps.first, contains('Hidratación'));
    });

    test('Magnitudes ≥0.80 no aparecen como gaps', () {
      final feedback = CycleFeedbackGenerator.generate(
        magnitudes: CycleMagnitudes(
          fastingMagnitude: 0.85,
          sleepQualityScore: 0.90,
          hydrationMagnitude: 0.40, // Solo este es gap
          exerciseMagnitude: 0.95,
          nutritionMagnitude: 0.85,
        ),
        fastingDurationHours: 16,
        feedingWindowHours: 8,
        windowClosedAt: null,
      );
      expect(feedback.gaps.length, 1);
      expect(feedback.gaps.first, contains('Hidratación'));
    });
  });

  group('SPEC-149 §8.2 — Insight adaptativo', () {
    test('Ayuno alto + sueño bajo → insight de autofagia no consolidada', () {
      final feedback = CycleFeedbackGenerator.generate(
        magnitudes: CycleMagnitudes(
          fastingMagnitude: 0.95,
          sleepQualityScore: 0.5,
          hydrationMagnitude: 0.7,
          exerciseMagnitude: 0.7,
          nutritionMagnitude: 0.7,
        ),
        fastingDurationHours: 18,
        feedingWindowHours: 6,
        windowClosedAt: DateTime(2026, 6, 1, 21, 0),
      );
      expect(feedback.insight, contains('autofagia'));
      expect(feedback.citation, contains('Mattson 2017'));
    });

    test('Ciclo todo ≥0.80 → insight de ciclo óptimo', () {
      final feedback = CycleFeedbackGenerator.generate(
        magnitudes: _uniform(0.90),
        fastingDurationHours: 16,
        feedingWindowHours: 8,
        windowClosedAt: DateTime(2026, 6, 1, 19, 0),
      );
      expect(feedback.insight, contains('óptimo'));
    });

    test('Insight evita repetir uno reciente si hay alternativas', () {
      final magnitudes = CycleMagnitudes(
        fastingMagnitude: 0.95,
        sleepQualityScore: 0.5,
        hydrationMagnitude: 0.7,
        exerciseMagnitude: 0.7,
        nutritionMagnitude: 0.7,
      );
      final first = CycleFeedbackGenerator.generate(
        magnitudes: magnitudes,
        fastingDurationHours: 18,
        feedingWindowHours: 6,
        windowClosedAt: DateTime(2026, 6, 1, 21, 0),
      );
      final second = CycleFeedbackGenerator.generate(
        magnitudes: magnitudes,
        fastingDurationHours: 18,
        feedingWindowHours: 6,
        windowClosedAt: DateTime(2026, 6, 1, 21, 0),
        recentInsightIds: const {'insight-fasting-high-sleep-low'},
      );
      expect(first.insight, isNot(equals(second.insight)));
    });

    test('Generador retorna insight por defecto si todo está en recentIds', () {
      final feedback = CycleFeedbackGenerator.generate(
        magnitudes: _uniform(0.5),
        fastingDurationHours: 10,
        feedingWindowHours: 14,
        windowClosedAt: null,
        recentInsightIds: const {
          'insight-fasting-high-sleep-low',
          'insight-fasting-good-nutrition-e',
          'insight-early-window-high-nutrition',
          'insight-low-hydration-high-exercise',
          'insight-perfect-cycle',
          'insight-low-sleep-low-nutrition',
          'insight-short-fasting',
          'insight-general-motivational',
        },
      );
      expect(feedback.insight, isNotEmpty);
    });
  });

  group('SPEC-149 — kAchievementThreshold semántica', () {
    test('Umbral es 0.80 — magnitud 0.79 NO es achievement', () {
      final feedback = CycleFeedbackGenerator.generate(
        magnitudes: CycleMagnitudes(
          fastingMagnitude: 0.79,
          sleepQualityScore: 0.79,
          hydrationMagnitude: 0.79,
          exerciseMagnitude: 0.79,
          nutritionMagnitude: 0.79,
        ),
        fastingDurationHours: 16,
        feedingWindowHours: 8,
        windowClosedAt: null,
      );
      // Ningún achievement de pilar (solo posible: bonus ventana, pero null).
      expect(
        feedback.achievements.where((a) => !a.contains('Ventana')).length,
        0,
      );
    });
  });
}

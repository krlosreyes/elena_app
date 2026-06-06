// SPEC-192.3a: tests del dominio CycleComparison + CycleComparisonService.

import 'package:elena_app/src/features/analysis/domain/cycle_comparison.dart';
import 'package:elena_app/src/features/analysis/domain/cycle_summary.dart';
import 'package:flutter_test/flutter_test.dart';

CycleSummaryDoc _summary({
  String id = 'c',
  int imr = 75,
  double fasting = 0.8,
  double sleep = 0.75,
  double hydration = 0.7,
  double exercise = 0.65,
  double nutrition = 0.85,
  DateTime? startedAt,
  DateTime? closedAt,
}) =>
    CycleSummaryDoc(
      cycleId: id,
      startedAt: startedAt ?? DateTime(2026, 6, 5, 8, 0),
      closedAt: closedAt ?? DateTime(2026, 6, 5, 20, 0),
      imrScore: imr,
      fastingMagnitude: fasting,
      sleepQualityScore: sleep,
      hydrationMagnitude: hydration,
      exerciseMagnitude: exercise,
      nutritionMagnitude: nutrition,
      fastingProtocol: '16:8',
    );

void main() {
  group('SPEC-192.3a — CyclePillarDelta', () {
    test('delta = current - previous', () {
      const d = CyclePillarDelta(current: 0.8, previous: 0.6);
      expect(d.delta, closeTo(0.2, 1e-9));
    });

    test('isStableWithin: false fuera del epsilon', () {
      const d = CyclePillarDelta(current: 0.85, previous: 0.6);
      expect(d.isStableWithin(0.1), isFalse);
    });

    test('isStableWithin: true dentro del epsilon', () {
      const d = CyclePillarDelta(current: 0.62, previous: 0.6);
      expect(d.isStableWithin(0.05), isTrue);
    });
  });

  group('SPEC-192.3a — CycleComparisonService.compute', () {
    test('ambas listas vacías → comparison.empty()', () {
      final c = CycleComparisonService.compute(
        currentSummaries: const [],
        previousSummaries: const [],
      );
      expect(c.isEmpty, isTrue);
      expect(c.hasBothWindows, isFalse);
      expect(c.currentCount, 0);
      expect(c.previousCount, 0);
    });

    test('solo current con data → previous = 0, delta = current', () {
      final c = CycleComparisonService.compute(
        currentSummaries: [_summary(imr: 80, fasting: 0.9)],
        previousSummaries: const [],
      );
      expect(c.currentCount, 1);
      expect(c.previousCount, 0);
      expect(c.hasBothWindows, isFalse);
      expect(c.imrScore.current, 80.0);
      expect(c.imrScore.previous, 0.0);
      expect(c.imrScore.delta, 80.0);
    });

    test('promedio correcto de 3 summaries en current', () {
      final c = CycleComparisonService.compute(
        currentSummaries: [
          _summary(imr: 60, fasting: 0.6),
          _summary(imr: 75, fasting: 0.8),
          _summary(imr: 90, fasting: 1.0),
        ],
        previousSummaries: const [],
      );
      expect(c.imrScore.current, closeTo(75.0, 1e-9));
      expect(c.fastingMagnitude.current, closeTo(0.8, 1e-9));
    });

    test('mejora real: current promedia más alto que previous', () {
      final c = CycleComparisonService.compute(
        currentSummaries: [
          _summary(imr: 85, sleep: 0.9),
          _summary(imr: 85, sleep: 0.9),
        ],
        previousSummaries: [
          _summary(imr: 60, sleep: 0.5),
          _summary(imr: 60, sleep: 0.5),
        ],
      );
      expect(c.imrScore.delta, closeTo(25.0, 1e-9));
      expect(c.sleepQualityScore.delta, closeTo(0.4, 1e-9));
      expect(c.hasBothWindows, isTrue);
    });

    test('rango temporal: tomado del current', () {
      final c = CycleComparisonService.compute(
        currentSummaries: [
          _summary(
            id: 'newest',
            startedAt: DateTime(2026, 6, 5, 8),
            closedAt: DateTime(2026, 6, 5, 20),
          ),
          _summary(
            id: 'oldest',
            startedAt: DateTime(2026, 6, 1, 8),
            closedAt: DateTime(2026, 6, 1, 20),
          ),
        ],
        previousSummaries: const [],
      );
      // El service espera el orden desc (más reciente primero).
      expect(c.currentRangeEnd, DateTime(2026, 6, 5, 20));
      expect(c.currentRangeStart, DateTime(2026, 6, 1, 8));
    });

    test('pillarDeltas expone los 5 pilares en orden canónico', () {
      final c = CycleComparisonService.compute(
        currentSummaries: [_summary()],
        previousSummaries: [_summary()],
      );
      expect(c.pillarDeltas.length, 5);
      expect(c.pillarDeltas.map((p) => p.label).toList(),
          ['Ayuno', 'Sueño', 'Hidratación', 'Ejercicio', 'Nutrición']);
    });
  });
}

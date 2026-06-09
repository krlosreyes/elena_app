// SPEC-192.1: tests del CycleSummaryComputer.

import 'package:elena_app/src/features/analysis/application/cycle_summary_computer.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';
import 'package:flutter_test/flutter_test.dart';

MetabolicCycle _closedCycle({
  String cycleId = 'test-cycle-1',
  DateTime? startedAt,
  DateTime? closedAt,
  int imrScore = 75,
  CycleMagnitudes? magnitudes,
  String protocol = '16:8',
}) {
  // SPEC-192.1: closureReason es opcional; lo omitimos para no
  // requerir importar el enum en los tests.
  return MetabolicCycle(
    cycleId: cycleId,
    startedAt: startedAt ?? DateTime(2026, 6, 5, 8, 0),
    closedAt: closedAt ?? DateTime(2026, 6, 5, 20, 0),
    fastingDurationHours: 16.0,
    feedingWindowHours: 8.0,
    dailyScore: imrScore,
    magnitudes: magnitudes ??
        const CycleMagnitudes(
          fastingMagnitude: 0.9,
          sleepQualityScore: 0.8,
          hydrationMagnitude: 0.7,
          exerciseMagnitude: 0.6,
          nutritionMagnitude: 0.85,
        ),
    fastingProtocol: protocol,
    tzOffsetMinutes: -300,
  );
}

void main() {
  group('SPEC-192.1 — CycleSummaryComputer.fromCycle', () {
    test('ciclo cerrado completo → CycleSummaryDoc con magnitudes correctas',
        () {
      final cycle = _closedCycle();
      final summary = CycleSummaryComputer.fromCycle(cycle);

      expect(summary, isNotNull);
      expect(summary!.cycleId, 'test-cycle-1');
      expect(summary.imrScore, 75);
      expect(summary.fastingMagnitude, 0.9);
      expect(summary.sleepQualityScore, 0.8);
      expect(summary.hydrationMagnitude, 0.7);
      expect(summary.exerciseMagnitude, 0.6);
      expect(summary.nutritionMagnitude, 0.85);
      expect(summary.fastingProtocol, '16:8');
    });

    test('ciclo abierto (closedAt null) → null', () {
      final open = MetabolicCycle.open(
        startedAt: DateTime(2026, 6, 5, 20, 0),
        fastingProtocol: '16:8',
        tzOffsetMinutes: -300,
      );
      expect(CycleSummaryComputer.fromCycle(open), isNull);
    });

    test('ciclo cerrado sin magnitudes (cierre forzado) → null', () {
      final partial = MetabolicCycle(
        cycleId: 'partial',
        startedAt: DateTime(2026, 6, 5, 8, 0),
        closedAt: DateTime(2026, 6, 5, 20, 0),
        magnitudes: null,
        dailyScore: 75,
        fastingProtocol: '16:8',
        tzOffsetMinutes: -300,
      );
      expect(CycleSummaryComputer.fromCycle(partial), isNull);
    });

    test('ciclo cerrado sin dailyScore → null', () {
      final partial = MetabolicCycle(
        cycleId: 'partial',
        startedAt: DateTime(2026, 6, 5, 8, 0),
        closedAt: DateTime(2026, 6, 5, 20, 0),
        magnitudes: const CycleMagnitudes(
          fastingMagnitude: 0.9,
          sleepQualityScore: 0.8,
          hydrationMagnitude: 0.7,
          exerciseMagnitude: 0.6,
          nutritionMagnitude: 0.85,
        ),
        dailyScore: null,
        fastingProtocol: '16:8',
        tzOffsetMinutes: -300,
      );
      expect(CycleSummaryComputer.fromCycle(partial), isNull);
    });

    test('cycleDurationHours = closedAt - startedAt en horas', () {
      final cycle = _closedCycle(
        startedAt: DateTime(2026, 6, 5, 8, 0),
        closedAt: DateTime(2026, 6, 5, 20, 30),
      );
      final summary = CycleSummaryComputer.fromCycle(cycle)!;
      expect(summary.cycleDurationHours, closeTo(12.5, 0.01));
    });
  });

  group('SPEC-192.1 — CycleSummaryComputer.fromCycles', () {
    test('lista vacía → lista vacía', () {
      expect(CycleSummaryComputer.fromCycles(const []), isEmpty);
    });

    test('mix de cerrados y abiertos → solo los cerrados con data', () {
      final c1 = _closedCycle(cycleId: 'a');
      final c2 = MetabolicCycle.open(
        startedAt: DateTime(2026, 6, 5, 20, 0),
        fastingProtocol: '16:8',
        tzOffsetMinutes: -300,
      );
      final c3 = _closedCycle(cycleId: 'c');
      final result = CycleSummaryComputer.fromCycles([c1, c2, c3]);
      expect(result.length, 2);
      expect(result.map((s) => s.cycleId), containsAll(['a', 'c']));
    });

    test('preserva el orden de input', () {
      final c1 = _closedCycle(cycleId: 'older');
      final c2 = _closedCycle(cycleId: 'middle');
      final c3 = _closedCycle(cycleId: 'newer');
      final result = CycleSummaryComputer.fromCycles([c1, c2, c3]);
      expect(result.map((s) => s.cycleId).toList(),
          ['older', 'middle', 'newer']);
    });
  });
}

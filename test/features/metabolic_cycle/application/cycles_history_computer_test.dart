// SPEC-156: tests del CyclesHistoryComputer (pure Dart).

import 'package:elena_app/src/features/metabolic_cycle/application/cycles_history_computer.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/closure_reason.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';
import 'package:flutter_test/flutter_test.dart';

MetabolicCycle _closedCycle({
  required DateTime startedAt,
  required DateTime closedAt,
  int? score,
  String protocol = '16:8',
}) {
  return MetabolicCycle(
    cycleId: MetabolicCycle.buildCycleId(startedAt),
    startedAt: startedAt,
    closedAt: closedAt,
    closureReason: ClosureReason.manualNextFasting,
    fastingDurationHours: 16,
    feedingWindowHours: 8,
    dailyScore: score,
    pillarsCompleted: null,
    magnitudes: null,
    feedback: null,
    fastingProtocol: protocol,
    tzOffsetMinutes: 0,
  );
}

MetabolicCycle _openCycle() {
  return MetabolicCycle.open(
    startedAt: DateTime(2026, 6, 1, 21, 0),
    fastingProtocol: '16:8',
    tzOffsetMinutes: 0,
  );
}

void main() {
  group('SPEC-156 — CyclesHistoryComputer.compute', () {
    test('empty cuando la lista de entrada está vacía', () {
      final summary = CyclesHistoryComputer.compute(closedCycles: const []);
      expect(summary.isEmpty, isTrue);
      expect(summary.bestCycle, isNull);
      expect(summary.worstCycle, isNull);
    });

    test('descarta ciclos abiertos (closedAt null)', () {
      final summary = CyclesHistoryComputer.compute(closedCycles: [
        _openCycle(),
      ]);
      expect(summary.isEmpty, isTrue);
    });

    test('ordena por closedAt descendente (más reciente arriba)', () {
      final c1 = _closedCycle(
        startedAt: DateTime(2026, 6, 1, 21),
        closedAt: DateTime(2026, 6, 2, 21),
        score: 70,
      );
      final c2 = _closedCycle(
        startedAt: DateTime(2026, 6, 2, 21),
        closedAt: DateTime(2026, 6, 3, 21),
        score: 80,
      );
      final summary = CyclesHistoryComputer.compute(closedCycles: [c1, c2]);
      // El más reciente (c2) debe estar primero.
      expect(summary.visibleCycles.first.dailyScore, 80);
      expect(summary.visibleCycles.last.dailyScore, 70);
    });

    test('limita a maxToShow', () {
      final cycles = List.generate(10, (i) {
        return _closedCycle(
          startedAt: DateTime(2026, 5, 25 + i, 21),
          closedAt: DateTime(2026, 5, 26 + i, 21),
          score: 50 + i,
        );
      });
      final summary = CyclesHistoryComputer.compute(
        closedCycles: cycles,
        maxToShow: 5,
      );
      expect(summary.visibleCycles.length, 5);
    });
  });

  group('SPEC-156 — pickBestCycle / pickWorstCycle', () {
    test('best es el de mayor score', () {
      final cs = [
        _closedCycle(
            startedAt: DateTime(2026, 6, 1),
            closedAt: DateTime(2026, 6, 2),
            score: 60),
        _closedCycle(
            startedAt: DateTime(2026, 6, 2),
            closedAt: DateTime(2026, 6, 3),
            score: 90),
        _closedCycle(
            startedAt: DateTime(2026, 6, 3),
            closedAt: DateTime(2026, 6, 4),
            score: 75),
      ];
      expect(CyclesHistoryComputer.pickBestCycle(cs)?.dailyScore, 90);
    });

    test('worst es el de menor score', () {
      final cs = [
        _closedCycle(
            startedAt: DateTime(2026, 6, 1),
            closedAt: DateTime(2026, 6, 2),
            score: 60),
        _closedCycle(
            startedAt: DateTime(2026, 6, 2),
            closedAt: DateTime(2026, 6, 3),
            score: 90),
        _closedCycle(
            startedAt: DateTime(2026, 6, 3),
            closedAt: DateTime(2026, 6, 4),
            score: 75),
      ];
      expect(CyclesHistoryComputer.pickWorstCycle(cs)?.dailyScore, 60);
    });

    test('empate de score: gana el más reciente', () {
      final older = _closedCycle(
          startedAt: DateTime(2026, 6, 1),
          closedAt: DateTime(2026, 6, 2),
          score: 80);
      final newer = _closedCycle(
          startedAt: DateTime(2026, 6, 3),
          closedAt: DateTime(2026, 6, 4),
          score: 80);
      final best = CyclesHistoryComputer.pickBestCycle([older, newer]);
      expect(best?.closedAt, DateTime(2026, 6, 4));
    });

    test('ignora ciclos con score null', () {
      final cs = [
        _closedCycle(
            startedAt: DateTime(2026, 6, 1),
            closedAt: DateTime(2026, 6, 2),
            score: null),
        _closedCycle(
            startedAt: DateTime(2026, 6, 2),
            closedAt: DateTime(2026, 6, 3),
            score: 65),
      ];
      expect(CyclesHistoryComputer.pickBestCycle(cs)?.dailyScore, 65);
    });

    test('lista vacía → null', () {
      expect(CyclesHistoryComputer.pickBestCycle(const []), isNull);
      expect(CyclesHistoryComputer.pickWorstCycle(const []), isNull);
    });
  });

  group('SPEC-156 — worst no se destaca con <3 ciclos', () {
    test('1 ciclo → worst es null pero best existe', () {
      final c = _closedCycle(
          startedAt: DateTime(2026, 6, 1),
          closedAt: DateTime(2026, 6, 2),
          score: 60);
      final summary = CyclesHistoryComputer.compute(closedCycles: [c]);
      expect(summary.bestCycle?.dailyScore, 60);
      expect(summary.worstCycle, isNull);
    });

    test('2 ciclos → worst sigue siendo null', () {
      final c1 = _closedCycle(
          startedAt: DateTime(2026, 6, 1),
          closedAt: DateTime(2026, 6, 2),
          score: 60);
      final c2 = _closedCycle(
          startedAt: DateTime(2026, 6, 2),
          closedAt: DateTime(2026, 6, 3),
          score: 80);
      final summary = CyclesHistoryComputer.compute(closedCycles: [c1, c2]);
      expect(summary.bestCycle?.dailyScore, 80);
      expect(summary.worstCycle, isNull);
    });

    test('3 ciclos → worst aparece', () {
      final cs = [
        _closedCycle(
            startedAt: DateTime(2026, 6, 1),
            closedAt: DateTime(2026, 6, 2),
            score: 60),
        _closedCycle(
            startedAt: DateTime(2026, 6, 2),
            closedAt: DateTime(2026, 6, 3),
            score: 80),
        _closedCycle(
            startedAt: DateTime(2026, 6, 3),
            closedAt: DateTime(2026, 6, 4),
            score: 90),
      ];
      final summary = CyclesHistoryComputer.compute(closedCycles: cs);
      expect(summary.bestCycle?.dailyScore, 90);
      expect(summary.worstCycle?.dailyScore, 60);
    });
  });
}

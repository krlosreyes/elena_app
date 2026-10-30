// Fix números (2026-10-30): "Tu semana" = últimos 7 días del calendario.

import 'package:elena_app/src/features/analysis/application/weekly_window.dart';
import 'package:elena_app/src/features/analysis/domain/cycle_summary.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';
import 'package:flutter_test/flutter_test.dart';

MetabolicCycle _cycle(String id, DateTime? closedAt) => MetabolicCycle(
      cycleId: id,
      startedAt: (closedAt ?? DateTime(2026, 10, 30))
          .subtract(const Duration(hours: 20)),
      closedAt: closedAt,
      fastingProtocol: '16:8',
      tzOffsetMinutes: -300,
    );

CycleSummaryDoc _summary(
  DateTime closedAt, {
  double fasting = 0,
  double sleep = 0,
  double hydration = 0,
  double exercise = 0,
  double nutrition = 0,
}) =>
    CycleSummaryDoc(
      cycleId: closedAt.toIso8601String(),
      startedAt: closedAt.subtract(const Duration(hours: 20)),
      closedAt: closedAt,
      imrScore: 50,
      fastingMagnitude: fasting,
      sleepQualityScore: sleep,
      hydrationMagnitude: hydration,
      exerciseMagnitude: exercise,
      nutritionMagnitude: nutrition,
      fastingProtocol: '16:8',
    );

void main() {
  final now = DateTime(2026, 10, 30, 17, 0);

  group('ventana semanal', () {
    test('va de hace 6 días a hoy', () {
      expect(weeklyWindowStart(now), DateTime(2026, 10, 24));
      expect(weeklyWindowEnd(now), DateTime(2026, 10, 30));
    });

    test('separa actual / anterior y descarta lo viejo', () {
      final cycles = [
        _cycle('hoy', DateTime(2026, 10, 30, 9)),
        _cycle('limite-actual', DateTime(2026, 10, 24, 0, 1)),
        _cycle('anterior', DateTime(2026, 10, 20, 9)),
        _cycle('limite-anterior', DateTime(2026, 10, 17, 0, 1)),
        _cycle('viejo', DateTime(2026, 10, 1, 9)), // el caso "AGO 21 – OCT 1"
        _cycle('abierto', null),
      ];
      final split = splitCyclesByWeeklyWindow(cycles, now);
      expect(split.current.map((c) => c.cycleId),
          ['hoy', 'limite-actual']);
      expect(split.previous.map((c) => c.cycleId),
          ['anterior', 'limite-anterior']);
    });

    test('sin ciclos recientes la semana queda vacía (no trae datos viejos)',
        () {
      final split = splitCyclesByWeeklyWindow(
        [_cycle('viejo', DateTime(2026, 8, 21, 9))],
        now,
      );
      expect(split.current, isEmpty);
      expect(split.previous, isEmpty);
    });
  });

  group('X de 7 días por pilar', () {
    test('cuenta días distintos que cumplen el umbral', () {
      final days = computeWeeklyPillarDays([
        _summary(DateTime(2026, 10, 30, 9), fasting: 1.0, sleep: 0.5),
        // mismo día, otro ciclo: no suma un segundo día
        _summary(DateTime(2026, 10, 30, 20), fasting: 0.9),
        _summary(DateTime(2026, 10, 28, 9), fasting: 0.8, sleep: 0.85),
        _summary(DateTime(2026, 10, 25, 9), fasting: 0.79),
        // fuera de la ventana
        _summary(DateTime(2026, 10, 20, 9), fasting: 1.0),
      ], now);
      expect(days.fasting, 2);
      expect(days.sleep, 1);
      expect(days.hydration, 0);
      expect(days.exercise, 0);
      expect(days.nutrition, 0);
    });

    test('vacío = 0 de 7 en todo', () {
      final days = computeWeeklyPillarDays(const [], now);
      expect(days.fasting, 0);
      expect(days.nutrition, 0);
    });
  });
}

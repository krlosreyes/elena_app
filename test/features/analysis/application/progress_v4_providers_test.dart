// Progreso v4: tests de countClosedByYou y GlucoseProgress (Dart puro).

import 'package:elena_app/src/features/analysis/application/progress_v4_providers.dart';
import 'package:elena_app/src/features/glucose/domain/glucose_reading.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/closure_reason.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 11, 5, 9);

MetabolicCycle _cycle(int daysAgo, ClosureReason reason) {
  final start = _now.subtract(Duration(days: daysAgo));
  return MetabolicCycle(
    cycleId: MetabolicCycle.buildCycleId(start),
    startedAt: start,
    closedAt: start.add(const Duration(hours: 24)),
    closureReason: reason,
    fastingDurationHours: 16,
    feedingWindowHours: 8,
    dailyScore: null,
    pillarsCompleted: null,
    magnitudes: null,
    feedback: null,
    fastingProtocol: '16:8',
    tzOffsetMinutes: 0,
  );
}

GlucoseReading _g(int daysAgo, int value,
    {GlucoseReadingContext ctx = GlucoseReadingContext.ayunas}) {
  final at = _now.subtract(Duration(days: daysAgo));
  return GlucoseReading(
    id: 'r-$daysAgo-$value',
    userId: 'u1',
    valueMgDl: value,
    context: ctx,
    measuredAt: at,
    symptomsReported: const [],
    createdAt: at,
    updatedAt: at,
  );
}

void main() {
  test('countClosedByYou cuenta solo los últimos 30 días', () {
    final r = countClosedByYou([
      _cycle(2, ClosureReason.manualNextFasting),
      _cycle(5, ClosureReason.manualNextFasting),
      _cycle(8, ClosureReason.fallbackAbsolute),
      _cycle(40, ClosureReason.manualNextFasting),
    ], _now);
    expect(r, (2, 3));
  });

  group('GlucoseProgress.from', () {
    test('promedios de 14 días y cambio vs. los 14 anteriores', () {
      final p = GlucoseProgress.from([
        _g(1, 100),
        _g(5, 110),
        _g(3, 200,
            ctx: GlucoseReadingContext.values
                .firstWhere((c) => c != GlucoseReadingContext.ayunas)),
        _g(20, 120),
        _g(25, 130),
        _g(40, 300),
      ], const [], _now);
      expect(p.avg14, 105);
      expect(p.prevAvg14, 125);
      expect(p.delta, -20);
      expect(p.recent, [110, 100]);
      expect(p.insight, isNull);
    });

    test('sin lecturas → todo null', () {
      final p = GlucoseProgress.from(const [], const [], _now);
      expect(p.avg14, isNull);
      expect(p.delta, isNull);
      expect(p.recent, isEmpty);
    });
  });
}

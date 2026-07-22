// SPEC-161: tests del HydrationWeeklyComputer (pure Dart).

import 'package:elena_app/src/features/hydration/application/hydration_weekly_computer.dart';
import 'package:elena_app/src/features/hydration/domain/hydration_log.dart';
import 'package:elena_app/src/features/hydration/domain/hydration_weekly_insight.dart';
import 'package:flutter_test/flutter_test.dart';

HydrationLog _log({required double liters, required DateTime at}) =>
    HydrationLog(amountInLiters: liters, timestamp: at);

DateTime _d(int day) => DateTime(2026, 6, day, 12, 0);

void main() {
  final rs = DateTime(2026, 5, 28);
  final re = DateTime(2026, 6, 3);

  group('SPEC-161 — HydrationWeeklyComputer.compute', () {
    test('empty cuando no hay logs', () {
      final b = HydrationWeeklyComputer.compute(
        logs: const [],
        targetLitersPerDay: 2.5,
        rangeStart: rs,
        rangeEnd: re,
      );
      expect(b.isEmpty, isTrue);
      expect(b.tier, HydrationInsightTier.empty);
    });

    test('agrupa logs por día calendárico', () {
      final b = HydrationWeeklyComputer.compute(
        logs: [
          _log(liters: 0.25, at: _d(1)),
          _log(liters: 0.50, at: _d(1)),
          _log(liters: 1.0, at: _d(2)),
        ],
        targetLitersPerDay: 2.5,
        rangeStart: rs,
        rangeEnd: re,
      );
      expect(b.days.length, 2);
      expect(b.days.first.liters, 0.75);
      expect(b.days.last.liters, 1.0);
    });

    test('promedios litros sobre días con logs (no rellena 0s)', () {
      final b = HydrationWeeklyComputer.compute(
        logs: [
          _log(liters: 2.0, at: _d(1)),
          _log(liters: 3.0, at: _d(2)),
        ],
        targetLitersPerDay: 2.5,
        rangeStart: rs,
        rangeEnd: re,
      );
      expect(b.litersAvg, 2.5);
      expect(b.percentAvg, 1.0);
    });

    test('ordena días ascendente', () {
      final b = HydrationWeeklyComputer.compute(
        logs: [
          _log(liters: 1.0, at: _d(3)),
          _log(liters: 1.0, at: _d(1)),
          _log(liters: 1.0, at: _d(2)),
        ],
        targetLitersPerDay: 2.5,
        rangeStart: rs,
        rangeEnd: re,
      );
      expect(b.days[0].date, _d(1).copyWith(hour: 0, minute: 0, second: 0));
      expect(b.days.last.date.day, 3);
    });
  });

  group('SPEC-161 — pickTier', () {
    test('<60% → severelyLow', () {
      expect(HydrationWeeklyComputer.pickTier(0.40),
          HydrationInsightTier.severelyLow);
      expect(HydrationWeeklyComputer.pickTier(0.59),
          HydrationInsightTier.severelyLow);
    });

    test('60-80% → low', () {
      expect(HydrationWeeklyComputer.pickTier(0.60), HydrationInsightTier.low);
      expect(HydrationWeeklyComputer.pickTier(0.79), HydrationInsightTier.low);
    });

    test('80-100% → adequate', () {
      expect(
          HydrationWeeklyComputer.pickTier(0.80), HydrationInsightTier.adequate);
      expect(
          HydrationWeeklyComputer.pickTier(0.99), HydrationInsightTier.adequate);
    });

    test('>=100% → optimal', () {
      expect(HydrationWeeklyComputer.pickTier(1.0), HydrationInsightTier.optimal);
      expect(HydrationWeeklyComputer.pickTier(1.5), HydrationInsightTier.optimal);
    });
  });

  group('SPEC-161 — HydrationCoachingMessage', () {
    test('cada tier no-vacío tiene mensaje completo', () {
      for (final t in HydrationInsightTier.values) {
        if (t == HydrationInsightTier.empty) continue;
        final m = HydrationCoachingMessage.forTier(t);
        expect(m, isNotNull);
        expect(m!.headline, isNotEmpty);
        expect(m.action, isNotEmpty);
        expect(m.citation, isNotEmpty);
      }
    });

    test('citas mencionan EFSA o Popkin (bibliografía SPEC-150)', () {
      for (final t in HydrationInsightTier.values) {
        if (t == HydrationInsightTier.empty) continue;
        final m = HydrationCoachingMessage.forTier(t)!;
        final hasEFSA = m.citation.contains('EFSA');
        final hasPopkin = m.citation.contains('Popkin');
        expect(hasEFSA || hasPopkin, isTrue, reason: 'tier=$t');
      }
    });
  });
}

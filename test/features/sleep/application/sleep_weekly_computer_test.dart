// SPEC-159: tests del SleepWeeklyComputer (pure Dart).

import 'package:elena_app/src/features/sleep/application/sleep_weekly_computer.dart';
import 'package:elena_app/src/features/sleep/domain/sleep_log.dart';
import 'package:elena_app/src/features/sleep/domain/sleep_weekly_insight.dart';
import 'package:flutter_test/flutter_test.dart';

SleepLog _log({
  required int hours,
  int? quality,
  int? latency,
  int? awakenings,
  DateTime? wokeUp,
}) {
  final woke = wokeUp ?? DateTime(2026, 6, 1, 7, 0);
  final fell = woke.subtract(Duration(hours: hours));
  return SleepLog(
    id: 'l-${woke.toIso8601String()}',
    fellAsleep: fell,
    wokeUp: woke,
    lastMealTime: fell.subtract(const Duration(hours: 3)),
    subjectiveQuality: quality,
    sleepLatencyMinutes: latency,
    nightAwakenings: awakenings,
  );
}

void main() {
  group('SPEC-159 — SleepWeeklyComputer.compute', () {
    test('empty cuando no hay logs', () {
      final i = SleepWeeklyComputer.compute(const []);
      expect(i.isEmpty, isTrue);
      expect(i.tier, SleepInsightTier.empty);
    });

    test('durationAvg promedia las horas de los logs', () {
      final i = SleepWeeklyComputer.compute([
        _log(hours: 8),
        _log(hours: 6),
      ]);
      expect(i.durationAvgHours, 7.0);
    });

    test('qualityAvg ignora logs sin rating', () {
      final i = SleepWeeklyComputer.compute([
        _log(hours: 7, quality: 4),
        _log(hours: 7, quality: 2),
        _log(hours: 7), // sin rating
      ]);
      expect(i.qualityRatingCount, 2);
      expect(i.qualityAvg, 3.0);
    });

    test('qualityAvg es null si nadie registró', () {
      final i = SleepWeeklyComputer.compute([
        _log(hours: 7),
        _log(hours: 7),
      ]);
      expect(i.qualityAvg, isNull);
      expect(i.qualityRatingCount, 0);
    });

    test('nightsWithHighLatency cuenta logs con latencia >30', () {
      final i = SleepWeeklyComputer.compute([
        _log(hours: 7, latency: 32),
        _log(hours: 7, latency: 45),
        _log(hours: 7, latency: 20), // no
        _log(hours: 7), // null no cuenta
      ]);
      expect(i.nightsWithHighLatency, 2);
    });

    test('nightsWithFragmentation cuenta awakenings ≥3', () {
      final i = SleepWeeklyComputer.compute([
        _log(hours: 7, awakenings: 3),
        _log(hours: 7, awakenings: 4),
        _log(hours: 7, awakenings: 1), // no
        _log(hours: 7), // null no cuenta
      ]);
      expect(i.nightsWithFragmentation, 2);
    });
  });

  group('SPEC-159 — pickTier prioridad', () {
    test('duration <6h → deprivation (prioridad máxima)', () {
      final i = SleepWeeklyComputer.compute([
        _log(hours: 5, quality: 5),  // calidad alta no rescata
        _log(hours: 5, quality: 5),
      ]);
      expect(i.tier, SleepInsightTier.deprivation);
    });

    test('latencia alta en ≥3 noches → latencyHigh (después de deprivation)',
        () {
      final i = SleepWeeklyComputer.compute([
        _log(hours: 7, latency: 35),
        _log(hours: 7, latency: 40),
        _log(hours: 7, latency: 33),
      ]);
      expect(i.tier, SleepInsightTier.latencyHigh);
    });

    test('fragmentación en ≥2 noches → fragmented', () {
      final i = SleepWeeklyComputer.compute([
        _log(hours: 7, awakenings: 3),
        _log(hours: 7, awakenings: 4),
        _log(hours: 7),
      ]);
      expect(i.tier, SleepInsightTier.fragmented);
    });

    test('calidad <3 con ≥3 ratings → lowQuality', () {
      final i = SleepWeeklyComputer.compute([
        _log(hours: 7, quality: 2),
        _log(hours: 7, quality: 2),
        _log(hours: 7, quality: 2),
      ]);
      expect(i.tier, SleepInsightTier.lowQuality);
    });

    test('calidad <3 pero solo 1 rating → neutral (no lowQuality)', () {
      final i = SleepWeeklyComputer.compute([
        _log(hours: 7, quality: 1),
        _log(hours: 7),
        _log(hours: 7),
      ]);
      expect(i.tier, SleepInsightTier.neutral);
    });

    test('duration ≥7h && quality ≥4 → sustained', () {
      final i = SleepWeeklyComputer.compute([
        _log(hours: 8, quality: 5),
        _log(hours: 7, quality: 4),
      ]);
      expect(i.tier, SleepInsightTier.sustained);
    });

    test('caso intermedio → neutral', () {
      final i = SleepWeeklyComputer.compute([
        _log(hours: 7, quality: 3),
        _log(hours: 7, quality: 3),
      ]);
      expect(i.tier, SleepInsightTier.neutral);
    });
  });

  group('SPEC-159 — SleepCoachingMessage', () {
    test('cada tier no-vacío tiene headline + action + citation', () {
      for (final t in SleepInsightTier.values) {
        if (t == SleepInsightTier.empty) continue;
        final m = SleepCoachingMessage.forTier(t);
        expect(m, isNotNull, reason: 'tier=$t');
        expect(m!.headline, isNotEmpty);
        expect(m.action, isNotEmpty);
        expect(m.citation, isNotEmpty);
      }
    });

    test('citas usan Walker o AASM (bibliografía canónica)', () {
      for (final t in SleepInsightTier.values) {
        if (t == SleepInsightTier.empty) continue;
        final m = SleepCoachingMessage.forTier(t)!;
        final hasWalker = m.citation.contains('Walker');
        final hasAasm = m.citation.contains('AASM');
        expect(
          hasWalker || hasAasm,
          isTrue,
          reason: 'tier=$t citation=${m.citation}',
        );
      }
    });
  });
}

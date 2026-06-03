// SPEC-161: tests del ExerciseWeeklyComputer (pure Dart).

import 'package:elena_app/src/features/exercise/application/exercise_weekly_computer.dart';
import 'package:elena_app/src/features/exercise/domain/exercise_log.dart';
import 'package:elena_app/src/features/exercise/domain/exercise_weekly_insight.dart';
import 'package:flutter_test/flutter_test.dart';

ExerciseLog _log({
  required int minutes,
  required DateTime at,
  ExerciseType? type,
  String activityType = 'Caminata',
}) =>
    ExerciseLog(
      id: 'l-${at.toIso8601String()}-$minutes',
      userId: 'u1',
      durationMinutes: minutes,
      activityType: activityType,
      timestamp: at,
      type: type,
    );

DateTime _d(int day) => DateTime(2026, 6, day, 12, 0);

void main() {
  final rs = DateTime(2026, 5, 28);
  final re = DateTime(2026, 6, 3);

  group('SPEC-161 — ExerciseWeeklyComputer.compute', () {
    test('empty cuando no hay logs', () {
      final b = ExerciseWeeklyComputer.compute(
        logs: const [],
        targetMinutesPerDay: 30,
        rangeStart: rs,
        rangeEnd: re,
      );
      expect(b.isEmpty, isTrue);
      expect(b.tier, ExerciseInsightTier.empty);
    });

    test('agrupa logs por día y suma minutos', () {
      final b = ExerciseWeeklyComputer.compute(
        logs: [
          _log(minutes: 20, at: _d(1)),
          _log(minutes: 10, at: _d(1)),
          _log(minutes: 30, at: _d(2)),
        ],
        targetMinutesPerDay: 30,
        rangeStart: rs,
        rangeEnd: re,
      );
      expect(b.days.length, 2);
      expect(b.days.first.minutes, 30);
      expect(b.days.last.minutes, 30);
    });

    test('promedio sobre días con logs (no rellena 0s)', () {
      final b = ExerciseWeeklyComputer.compute(
        logs: [
          _log(minutes: 20, at: _d(1)),
          _log(minutes: 40, at: _d(2)),
        ],
        targetMinutesPerDay: 30,
        rangeStart: rs,
        rangeEnd: re,
      );
      expect(b.minutesAvg, 30);
      expect(b.percentAvg, 1.0);
    });

    test('predominantType es el tipo con más minutos del día', () {
      final b = ExerciseWeeklyComputer.compute(
        logs: [
          _log(minutes: 30, at: _d(1), type: ExerciseType.liss),
          _log(minutes: 20, at: _d(1), type: ExerciseType.hiit),
          _log(minutes: 15, at: _d(1), type: ExerciseType.liss),
        ],
        targetMinutesPerDay: 30,
        rangeStart: rs,
        rangeEnd: re,
      );
      // LISS: 30+15=45, HIIT: 20 → LISS gana.
      expect(b.days.first.predominantType, ExerciseType.liss);
    });

    test('predominantType null si ningún log tiene type (logs legacy)', () {
      final b = ExerciseWeeklyComputer.compute(
        logs: [
          _log(minutes: 30, at: _d(1)),
          _log(minutes: 20, at: _d(1)),
        ],
        targetMinutesPerDay: 30,
        rangeStart: rs,
        rangeEnd: re,
      );
      expect(b.days.first.predominantType, isNull);
    });
  });

  group('SPEC-161 — pickTier', () {
    test('<50% → sedentary', () {
      expect(ExerciseWeeklyComputer.pickTier(0.30),
          ExerciseInsightTier.sedentary);
      expect(ExerciseWeeklyComputer.pickTier(0.49),
          ExerciseInsightTier.sedentary);
    });

    test('50-80% → low', () {
      expect(ExerciseWeeklyComputer.pickTier(0.50), ExerciseInsightTier.low);
      expect(ExerciseWeeklyComputer.pickTier(0.79), ExerciseInsightTier.low);
    });

    test('80-120% → meetsTarget', () {
      expect(ExerciseWeeklyComputer.pickTier(0.80),
          ExerciseInsightTier.meetsTarget);
      expect(ExerciseWeeklyComputer.pickTier(1.0),
          ExerciseInsightTier.meetsTarget);
      expect(ExerciseWeeklyComputer.pickTier(1.20),
          ExerciseInsightTier.meetsTarget);
    });

    test('>120% → aboveTarget', () {
      expect(ExerciseWeeklyComputer.pickTier(1.5),
          ExerciseInsightTier.aboveTarget);
    });
  });

  group('SPEC-161 — ExerciseCoachingMessage', () {
    test('cada tier no-vacío tiene mensaje completo con cita', () {
      for (final t in ExerciseInsightTier.values) {
        if (t == ExerciseInsightTier.empty) continue;
        final m = ExerciseCoachingMessage.forTier(t);
        expect(m, isNotNull);
        expect(m!.headline, isNotEmpty);
        expect(m.action, isNotEmpty);
        expect(m.citation, isNotEmpty);
      }
    });

    test('citas mencionan OMS, AHA o Mattson (bibliografía SPEC-153)', () {
      for (final t in ExerciseInsightTier.values) {
        if (t == ExerciseInsightTier.empty) continue;
        final m = ExerciseCoachingMessage.forTier(t)!;
        final ok = m.citation.contains('OMS') ||
            m.citation.contains('AHA') ||
            m.citation.contains('Mattson');
        expect(ok, isTrue, reason: 'tier=$t citation=${m.citation}');
      }
    });
  });
}

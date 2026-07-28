// SPEC-201: tests del ObservationDetector (observaciones honestas).

import 'package:elena_app/src/features/analysis/application/observation_detector.dart';
import 'package:elena_app/src/features/analysis/domain/metric_series.dart';
import 'package:elena_app/src/features/analysis/domain/observation.dart';
import 'package:elena_app/src/features/analysis/domain/time_series_point.dart';
import 'package:elena_app/src/features/streak/domain/streak_entry.dart';
import 'package:flutter_test/flutter_test.dart';

StreakEntry _entry(
  String date, {
  bool fasting = false,
  bool sleep = false,
  bool hydration = false,
  bool exercise = false,
  bool nutrition = false,
  double? hydrationMag,
}) =>
    StreakEntry(
      date: date,
      fastingCompleted: fasting,
      sleepCompleted: sleep,
      hydrationCompleted: hydration,
      exerciseLogged: exercise,
      nutritionLogged: nutrition,
      imrScore: 50,
      hydrationMagnitude: hydrationMag,
    );

MetricSeries _series(String label, String unit, List<double> values) {
  final base = DateTime(2026, 5, 4); // un lunes
  return MetricSeries(
    label: label,
    unit: unit,
    points: [
      for (int i = 0; i < values.length; i++)
        TimeSeriesPoint(
          weekStart: base.add(Duration(days: 7 * i)),
          value: values[i],
          sampleCount: 5,
        ),
    ],
  );
}

void main() {
  group('RF-05 — piso de datos', () {
    test('con < 4 días de data devuelve vacío', () {
      final entries = [
        _entry('2026-06-01', fasting: true),
        _entry('2026-06-02', fasting: true),
        _entry('2026-06-03', fasting: true),
      ];
      expect(
        ObservationDetector.detect(
            habitWeekly: const [], dailyEntries: entries),
        isEmpty,
      );
    });
  });

  group('RF-02 — racha', () {
    test('5 días consecutivos cerrando ayuno → observación de racha', () {
      final entries = [
        for (int d = 1; d <= 5; d++) _entry('2026-06-0$d', fasting: true),
      ];
      final obs = ObservationDetector.detect(
        habitWeekly: const [],
        dailyEntries: entries,
      );
      final streak =
          obs.where((o) => o.type == ObservationType.streak).toList();
      expect(streak, isNotEmpty);
      expect(streak.first.headline, contains('5 días'));
      expect(streak.first.subject, 'racha-Ayuno');
    });

    test('un hueco corta la racha', () {
      final entries = [
        _entry('2026-06-01', fasting: true),
        _entry('2026-06-02', fasting: true),
        // falta 03
        _entry('2026-06-04', fasting: true),
        _entry('2026-06-05', fasting: true),
      ];
      final obs = ObservationDetector.detect(
        habitWeekly: const [],
        dailyEntries: entries,
      );
      // Racha vigente = 2 (04-05) < kMinStreakDays → sin observación de racha.
      expect(obs.where((o) => o.type == ObservationType.streak), isEmpty);
    });
  });

  group('RF-01 — baseline (tú vs tu promedio)', () {
    test('última semana por debajo del promedio → baseline con acción', () {
      final entries = [
        for (int d = 1; d <= 6; d++) _entry('2026-06-0$d', sleep: true),
      ];
      final sleep = _series('Sueño', 'h', [7.0, 7.0, 7.0, 5.0]);
      final obs = ObservationDetector.detect(
        habitWeekly: [sleep],
        dailyEntries: entries,
      );
      final baseline =
          obs.where((o) => o.type == ObservationType.baseline).toList();
      expect(baseline, isNotEmpty);
      expect(baseline.first.headline, contains('por debajo'));
      expect(baseline.first.action, isNotNull);
    });

    test('serie estable (sin desvío) → sin baseline', () {
      final entries = [
        for (int d = 1; d <= 6; d++) _entry('2026-06-0$d', sleep: true),
      ];
      final sleep = _series('Sueño', 'h', [7.0, 7.0, 7.0, 7.0]);
      final obs = ObservationDetector.detect(
        habitWeekly: [sleep],
        dailyEntries: entries,
      );
      expect(obs.where((o) => o.type == ObservationType.baseline), isEmpty);
    });
  });

  group('RF-03 — cercanía a meta de agua', () {
    test('promedio reciente ~80% → "cerca de tu meta"', () {
      final entries = [
        for (int d = 1; d <= 5; d++)
          _entry('2026-06-0$d', hydration: true, hydrationMag: 0.8),
      ];
      final obs = ObservationDetector.detect(
        habitWeekly: const [],
        dailyEntries: entries,
      );
      final goal =
          obs.where((o) => o.type == ObservationType.goalProximity).toList();
      expect(goal, isNotEmpty);
      expect(goal.first.headline, contains('cerca'));
      expect(goal.first.action, isNotNull);
    });
  });
}

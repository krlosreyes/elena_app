// SPEC-153: tests del WeeklyCoachingComputer (pure Dart).

import 'package:elena_app/src/features/analysis/application/weekly_coaching_computer.dart';
import 'package:elena_app/src/features/analysis/data/daily_summary_doc.dart';
import 'package:elena_app/src/features/analysis/domain/weekly_coaching_insight.dart';
import 'package:flutter_test/flutter_test.dart';

DailySummaryDoc _doc({
  String date = '2026-06-01',
  double fasting = 0.5,
  double sleep = 0.5,
  double hydration = 0.5,
  double exercise = 0.5,
  double meals = 0.5,
  int imrScore = 50,
}) {
  return DailySummaryDoc(
    date: date,
    imrScore: imrScore,
    fastingProgress: fasting,
    sleepProgress: sleep,
    hydrationProgress: hydration,
    exerciseProgress: exercise,
    mealsProgress: meals,
    updatedAt: DateTime(2026, 6, 1),
  );
}

DateTime _start = DateTime(2026, 5, 28);
DateTime _end = DateTime(2026, 6, 3);

void main() {
  group('SPEC-153 — WeeklyCoachingComputer.compute', () {
    test('empty cuando current está vacío', () {
      final insight = WeeklyCoachingComputer.compute(
        current: const [],
        previous: const [],
        rangeStart: _start,
        rangeEnd: _end,
      );
      expect(insight.isEmpty, isTrue);
      expect(insight.weakest, isNull);
      expect(insight.fastingAvg, 0);
      expect(insight.daysWithData, 0);
    });

    test('calcula promedios con un solo doc', () {
      final insight = WeeklyCoachingComputer.compute(
        current: [_doc(fasting: 0.5, sleep: 0.7, hydration: 0.9)],
        previous: const [],
        rangeStart: _start,
        rangeEnd: _end,
      );
      expect(insight.fastingAvg, 0.5);
      expect(insight.sleepAvg, 0.7);
      expect(insight.hydrationAvg, 0.9);
      expect(insight.daysWithData, 1);
    });

    test('deltas son null cuando no hay previous', () {
      final insight = WeeklyCoachingComputer.compute(
        current: [_doc(fasting: 0.5)],
        previous: const [],
        rangeStart: _start,
        rangeEnd: _end,
      );
      expect(insight.fastingDelta, isNull);
      expect(insight.sleepDelta, isNull);
    });

    test('deltas se calculan vs previous correctamente', () {
      final insight = WeeklyCoachingComputer.compute(
        current: [_doc(fasting: 0.6)],
        previous: [_doc(fasting: 0.4)],
        rangeStart: _start,
        rangeEnd: _end,
      );
      expect(insight.fastingDelta, closeTo(0.2, 0.0001));
    });

    test('clampea valores fuera de rango', () {
      final insight = WeeklyCoachingComputer.compute(
        current: [_doc(fasting: 1.5, sleep: -0.3)],
        previous: const [],
        rangeStart: _start,
        rangeEnd: _end,
      );
      expect(insight.fastingAvg, 1.0);
      expect(insight.sleepAvg, 0.0);
    });
  });

  group('SPEC-153 — pickWeakPillar', () {
    test('todos ≥80% → null (estado sostenido)', () {
      final weak = WeeklyCoachingComputer.pickWeakPillar(
        fastingAvg: 0.85,
        sleepAvg: 0.90,
        hydrationAvg: 0.85,
        exerciseAvg: 0.82,
        mealsAvg: 0.88,
        fastingDelta: null,
        sleepDelta: null,
        hydrationDelta: null,
        exerciseDelta: null,
        mealsDelta: null,
      );
      expect(weak, isNull);
    });

    test('caída crítica gana sobre promedio bajo absoluto', () {
      // Sleep tiene promedio alto (0.85) pero cayó -15% — gana.
      // Fasting tiene promedio bajo (0.40) pero estable — pierde.
      final weak = WeeklyCoachingComputer.pickWeakPillar(
        fastingAvg: 0.40,
        sleepAvg: 0.85,
        hydrationAvg: 0.70,
        exerciseAvg: 0.70,
        mealsAvg: 0.70,
        fastingDelta: 0.0,
        sleepDelta: -0.15,
        hydrationDelta: 0.0,
        exerciseDelta: 0.0,
        mealsDelta: 0.0,
      );
      expect(weak, WeakPillar.sleep);
    });

    test('múltiples caídas críticas: gana la peor', () {
      final weak = WeeklyCoachingComputer.pickWeakPillar(
        fastingAvg: 0.50,
        sleepAvg: 0.50,
        hydrationAvg: 0.50,
        exerciseAvg: 0.50,
        mealsAvg: 0.50,
        fastingDelta: -0.12,
        sleepDelta: -0.25, // la peor
        hydrationDelta: -0.11,
        exerciseDelta: 0.0,
        mealsDelta: 0.0,
      );
      expect(weak, WeakPillar.sleep);
    });

    test('sin caídas críticas: gana el de menor promedio', () {
      final weak = WeeklyCoachingComputer.pickWeakPillar(
        fastingAvg: 0.27,
        sleepAvg: 0.48,
        hydrationAvg: 0.83,
        exerciseAvg: 0.71,
        mealsAvg: 0.71,
        fastingDelta: 0.0,
        sleepDelta: 0.0,
        hydrationDelta: 0.0,
        exerciseDelta: 0.0,
        mealsDelta: 0.0,
      );
      expect(weak, WeakPillar.fasting);
    });

    test('caída exactamente -10% es crítica (≤ -0.10)', () {
      final weak = WeeklyCoachingComputer.pickWeakPillar(
        fastingAvg: 0.50,
        sleepAvg: 0.50,
        hydrationAvg: 0.50,
        exerciseAvg: 0.50,
        mealsAvg: 0.50,
        fastingDelta: -0.10,
        sleepDelta: -0.05,
        hydrationDelta: 0.0,
        exerciseDelta: 0.0,
        mealsDelta: 0.0,
      );
      expect(weak, WeakPillar.fasting);
    });

    test('caída leve (-5%) NO es crítica — gana menor promedio', () {
      final weak = WeeklyCoachingComputer.pickWeakPillar(
        fastingAvg: 0.27,
        sleepAvg: 0.70,
        hydrationAvg: 0.50,
        exerciseAvg: 0.50,
        mealsAvg: 0.50,
        fastingDelta: 0.0,
        sleepDelta: -0.05,
        hydrationDelta: 0.0,
        exerciseDelta: 0.0,
        mealsDelta: 0.0,
      );
      expect(weak, WeakPillar.fasting);
    });
  });

  group('SPEC-153 — WeakPillar copy', () {
    test('cada pilar tiene insight + acción + cita NO vacíos', () {
      for (final p in WeakPillar.values) {
        expect(p.insightHeadline, isNotEmpty);
        expect(p.suggestedAction, isNotEmpty);
        expect(p.citation, isNotEmpty);
      }
    });

    test('ayuno cita Mattson 2017', () {
      expect(WeakPillar.fasting.citation, contains('Mattson 2017'));
    });

    test('sueño cita Walker 2017', () {
      expect(WeakPillar.sleep.citation, contains('Walker 2017'));
    });

    test('comidas cita Lopez-Minguez 2018', () {
      expect(WeakPillar.meals.citation, contains('Lopez-Minguez 2018'));
    });

    test('acciones son concretas y empiezan con verbo', () {
      // Auditoría 2026-07-27 (C-02): este test afirmaba imperativos del
      // Río de la Plata, blindando el voseo en vez de impedirlo. El
      // estándar del proyecto es español neutro LatAm (ver
      // intro_screens.dart §Reglas de copy).
      const accionables = ['Marca', 'Apunta', 'Bebe', 'Suma', 'Cierra'];
      for (final p in WeakPillar.values) {
        final hasVerb = accionables.any((v) => p.suggestedAction.startsWith(v));
        expect(
          hasVerb,
          isTrue,
          reason: 'Acción de ${p.name} no empieza con imperativo: ${p.suggestedAction}',
        );
      }
    });
  });

  group('SPEC-153 — WeeklyCoachingInsight estados', () {
    test('isFullySustained true cuando todos ≥80% y weakest null', () {
      final insight = WeeklyCoachingComputer.compute(
        current: [
          _doc(
            fasting: 0.85,
            sleep: 0.85,
            hydration: 0.85,
            exercise: 0.85,
            meals: 0.85,
          ),
        ],
        previous: const [],
        rangeStart: _start,
        rangeEnd: _end,
      );
      expect(insight.weakest, isNull);
      expect(insight.isFullySustained, isTrue);
      expect(insight.isEmpty, isFalse);
    });

    test('isFullySustained false cuando hay un pilar débil', () {
      final insight = WeeklyCoachingComputer.compute(
        current: [_doc(fasting: 0.27)],
        previous: const [],
        rangeStart: _start,
        rangeEnd: _end,
      );
      expect(insight.weakest, isNotNull);
      expect(insight.isFullySustained, isFalse);
    });
  });
}

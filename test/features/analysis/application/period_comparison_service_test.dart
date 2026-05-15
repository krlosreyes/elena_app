// SPEC-113: tests puros del PeriodComparisonService.

import 'package:elena_app/src/features/analysis/application/period_comparison_service.dart';
import 'package:elena_app/src/features/analysis/data/daily_summary_doc.dart';
import 'package:flutter_test/flutter_test.dart';

DailySummaryDoc _doc(String date, int imr) {
  return DailySummaryDoc(
    date: date,
    imrScore: imr,
    fastingProgress: 0,
    sleepProgress: 0,
    hydrationProgress: 0,
    exerciseProgress: 0,
    mealsProgress: 0,
    updatedAt: DateTime(2026, 5, 15),
  );
}

void main() {
  group('PeriodComparisonService.compute', () {
    test('Docs vacíos → PeriodComparison.empty', () {
      final c = PeriodComparisonService.compute(
        currentDocs: const [],
        previousDocs: const [],
        daysInPeriod: 7,
      );
      expect(c.imrAverage, 0);
      expect(c.imrAveragePrevious, isNull);
      expect(c.bestDayDate, isNull);
      expect(c.daysInPeriod, 7);
    });

    test('Promedio del período actual se calcula correcto', () {
      final c = PeriodComparisonService.compute(
        currentDocs: [
          _doc('2026-05-09', 60),
          _doc('2026-05-10', 70),
          _doc('2026-05-11', 80),
        ],
        previousDocs: const [],
        daysInPeriod: 7,
      );
      expect(c.imrAverage, 70);
    });

    test('Promedio del período anterior cuando hay data', () {
      final c = PeriodComparisonService.compute(
        currentDocs: [_doc('2026-05-15', 72)],
        previousDocs: [
          _doc('2026-05-08', 60),
          _doc('2026-05-09', 70),
        ],
        daysInPeriod: 7,
      );
      expect(c.imrAveragePrevious, 65);
      expect(c.delta, 7);
    });

    test('Mejor y peor día reflejan extremos del período actual', () {
      final c = PeriodComparisonService.compute(
        currentDocs: [
          _doc('2026-05-09', 50),
          _doc('2026-05-10', 80),
          _doc('2026-05-11', 60),
        ],
        previousDocs: const [],
        daysInPeriod: 7,
      );
      expect(c.bestDayImr, 80);
      expect(c.bestDayDate, DateTime(2026, 5, 10));
      expect(c.worstDayImr, 50);
      expect(c.worstDayDate, DateTime(2026, 5, 9));
    });

    test('Empate de mejor día → gana el más reciente', () {
      final c = PeriodComparisonService.compute(
        currentDocs: [
          _doc('2026-05-09', 80),
          _doc('2026-05-10', 70),
          _doc('2026-05-11', 80),
        ],
        previousDocs: const [],
        daysInPeriod: 7,
      );
      expect(c.bestDayDate, DateTime(2026, 5, 11));
    });

    test('Delta positivo / negativo / nulo según data', () {
      final positive = PeriodComparisonService.compute(
        currentDocs: [_doc('2026-05-15', 80)],
        previousDocs: [_doc('2026-05-08', 60)],
        daysInPeriod: 7,
      );
      expect(positive.delta, 20);

      final negative = PeriodComparisonService.compute(
        currentDocs: [_doc('2026-05-15', 50)],
        previousDocs: [_doc('2026-05-08', 60)],
        daysInPeriod: 7,
      );
      expect(negative.delta, -10);

      final nullDelta = PeriodComparisonService.compute(
        currentDocs: [_doc('2026-05-15', 60)],
        previousDocs: const [],
        daysInPeriod: 7,
      );
      expect(nullDelta.delta, isNull);
    });
  });
}

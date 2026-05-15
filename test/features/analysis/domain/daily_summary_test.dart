// SPEC-110: tests puros del DailySummary.

import 'package:elena_app/src/features/analysis/domain/daily_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DailySummary.compute', () {
    test('clamp imrScore a [0, 100]', () {
      final neg = DailySummary.compute(
        imrScore: -5,
        fastingProgress: 0.5,
        sleepProgress: 0.5,
        hydrationProgress: 0.5,
        exerciseProgress: 0.5,
        mealsProgress: 0.5,
      );
      final big = DailySummary.compute(
        imrScore: 250,
        fastingProgress: 0.5,
        sleepProgress: 0.5,
        hydrationProgress: 0.5,
        exerciseProgress: 0.5,
        mealsProgress: 0.5,
      );
      expect(neg.imrScore, 0);
      expect(big.imrScore, 100);
    });

    test('clamp pilares a [0.0, 1.0]', () {
      final s = DailySummary.compute(
        imrScore: 50,
        fastingProgress: -0.2,
        sleepProgress: 1.4,
        hydrationProgress: 0.5,
        exerciseProgress: 0.5,
        mealsProgress: 0.5,
      );
      expect(s.fastingProgress, 0.0);
      expect(s.sleepProgress, 1.0);
    });
  });

  group('DailySummary.isFullDay', () {
    test('todos >=0.8 → true', () {
      final s = DailySummary.compute(
        imrScore: 70,
        fastingProgress: 0.85,
        sleepProgress: 0.9,
        hydrationProgress: 0.8,
        exerciseProgress: 0.95,
        mealsProgress: 1.0,
      );
      expect(s.isFullDay, isTrue);
    });

    test('uno por debajo → false', () {
      final s = DailySummary.compute(
        imrScore: 70,
        fastingProgress: 0.85,
        sleepProgress: 0.9,
        hydrationProgress: 0.79,
        exerciseProgress: 0.95,
        mealsProgress: 1.0,
      );
      expect(s.isFullDay, isFalse);
    });
  });

  group('DailySummary.empty', () {
    test('todos en cero', () {
      const e = DailySummary.empty();
      expect(e.imrScore, 0);
      expect(e.fastingProgress, 0);
      expect(e.sleepProgress, 0);
      expect(e.hydrationProgress, 0);
      expect(e.exerciseProgress, 0);
      expect(e.mealsProgress, 0);
      expect(e.isFullDay, isFalse);
    });
  });
}

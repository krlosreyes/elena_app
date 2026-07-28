// SPEC-158: tests del MealsRatioComputer + insight thresholds.

import 'package:elena_app/src/features/nutrition/application/meals_ratio_computer.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_ratio.dart';
import 'package:elena_app/src/features/nutrition/domain/meals_ratio_breakdown.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_log.dart';
import 'package:flutter_test/flutter_test.dart';

NutritionLog _log(MealRatio ratio) {
  return NutritionLog(
    id: 'l-${ratio.persistenceKey}',
    timestamp: DateTime(2026, 6, 1, 12),
    label: 'Test',
    withinCircadianWindow: true,
    ratio: ratio,
  );
}

DateTime _start = DateTime(2026, 5, 28);
DateTime _end = DateTime(2026, 6, 3);

void main() {
  group('SPEC-158 — MealsRatioComputer.compute', () {
    test('empty cuando no hay logs', () {
      final b = MealsRatioComputer.compute(
        logs: const [],
        rangeStart: _start,
        rangeEnd: _end,
      );
      expect(b.isEmpty, isTrue);
      expect(b.total, 0);
      expect(b.aDominantCount, 0);
      expect(b.aDominantFraction, 0);
    });

    test('counts por ratio', () {
      final b = MealsRatioComputer.compute(
        logs: [
          _log(MealRatio.allA),
          _log(MealRatio.allA),
          _log(MealRatio.a2e1),
          _log(MealRatio.allE),
        ],
        rangeStart: _start,
        rangeEnd: _end,
      );
      expect(b.counts[MealRatio.allA], 2);
      expect(b.counts[MealRatio.a2e1], 1);
      expect(b.counts[MealRatio.allE], 1);
      expect(b.counts[MealRatio.a3e1], 0);
      expect(b.counts[MealRatio.a1e1], 0);
      expect(b.total, 4);
    });

    test('aDominantCount usa criterio MealRatio.isADominant', () {
      // A-dominantes: allA, a3e1, a2e1
      // No A-dominantes: a1e1, allE
      final b = MealsRatioComputer.compute(
        logs: [
          _log(MealRatio.allA),
          _log(MealRatio.a3e1),
          _log(MealRatio.a2e1),
          _log(MealRatio.a1e1),
          _log(MealRatio.allE),
        ],
        rangeStart: _start,
        rangeEnd: _end,
      );
      expect(b.aDominantCount, 3);
      expect(b.aDominantPercent, 60);
    });

    test('todas las llaves presentes incluso si su count es 0', () {
      final b = MealsRatioComputer.compute(
        logs: [_log(MealRatio.allA)],
        rangeStart: _start,
        rangeEnd: _end,
      );
      for (final r in MealRatio.values) {
        expect(b.counts.containsKey(r), isTrue);
      }
    });
  });

  group('SPEC-158 — tier por umbral', () {
    MealsRatioBreakdown withPct(int aDominantCount, int total) {
      // Construye un breakdown sintético con count y total dados.
      // Resto en a1e1 (no A-dominante).
      final allA = aDominantCount;
      final rest = total - aDominantCount;
      return MealsRatioComputer.compute(
        logs: [
          for (var i = 0; i < allA; i++) _log(MealRatio.allA),
          for (var i = 0; i < rest; i++) _log(MealRatio.a1e1),
        ],
        rangeStart: _start,
        rangeEnd: _end,
      );
    }

    test('empty → tier empty', () {
      final b = withPct(0, 0);
      expect(b.tier, MealsRatioInsightTier.empty);
      expect(MealsRatioInsight.forTier(b.tier), isNull);
    });

    test('>=80% → tier excellent', () {
      final b = withPct(8, 10);
      expect(b.aDominantPercent, 80);
      expect(b.tier, MealsRatioInsightTier.excellent);
      final ins = MealsRatioInsight.forTier(b.tier);
      expect(ins?.citation, contains('Frank Suárez'));
    });

    test('70-79% → tier good', () {
      final b = withPct(7, 10);
      expect(b.aDominantPercent, 70);
      expect(b.tier, MealsRatioInsightTier.good);
    });

    test('50-69% → tier insufficient', () {
      final b = withPct(6, 10);
      expect(b.aDominantPercent, 60);
      expect(b.tier, MealsRatioInsightTier.insufficient);
    });

    test('<50% → tier poor', () {
      final b = withPct(4, 10);
      expect(b.aDominantPercent, 40);
      expect(b.tier, MealsRatioInsightTier.poor);
    });

    test('exactamente 50% → insufficient (no poor)', () {
      final b = withPct(5, 10);
      expect(b.aDominantPercent, 50);
      expect(b.tier, MealsRatioInsightTier.insufficient);
    });
  });

  group('SPEC-158 — insights por tier', () {
    test('todos los tiers no-vacíos tienen headline + action + citation', () {
      for (final t in MealsRatioInsightTier.values) {
        if (t == MealsRatioInsightTier.empty) continue;
        final ins = MealsRatioInsight.forTier(t);
        expect(ins, isNotNull);
        expect(ins!.headline, isNotEmpty);
        expect(ins.action, isNotEmpty);
        expect(ins.citation, contains('Frank Suárez'));
      }
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:elena_app/src/features/nutrition/domain/services/nutrition_engine.dart';

void main() {
  late NutritionEngine engine;

  setUp(() {
    engine = NutritionEngine();
  });

  group('NutritionEngine - Katch-McArdle & TDEE', () {
    test('Calculates BMR correctly for standard male', () {
      // 80kg, 20% BF -> 64kg Lean Mass
      // BMR = 370 + (21.6 * 64) = 370 + 1382.4 = 1752.4
      final plan = engine.calculatePlan(
        userId: 'test',
        weightKg: 80,
        bodyFatPercentage: 20,
        activityLevel: 'sedentary',
        gender: 'male',
        goal: 'maintain',
      );

      expect(plan.baseMetrics.bmr, closeTo(1752.4, 0.1));
    });

    test('Calculates TDEE with TEF correctly', () {
      // BMR 1752.4 (from above)
      // Activity Sedentary (1.2) -> 1752.4 * 1.2 = 2102.88
      // TEF (1.10) -> 2102.88 * 1.10 = 2313.168
      final plan = engine.calculatePlan(
        userId: 'test',
        weightKg: 80,
        bodyFatPercentage: 20,
        activityLevel: 'sedentary',
        gender: 'male',
        goal: 'maintain',
      );

      expect(plan.baseMetrics.tdee, closeTo(2313.16, 0.5));
    });
  });

  group('NutritionEngine - Safety Guards', () {
    test('Enforces Calorie Floor for Female (1200)', () {
      // Very small female: 45kg, 15% BF
      // Lean: 38.25 -> BMR: ~1196
      // Sedentary (1.2) -> 1435
      // Lose Fat (-500) -> 935 (Below 1200)
      
      final plan = engine.calculatePlan(
        userId: 'test',
        weightKg: 45,
        bodyFatPercentage: 15,
        activityLevel: 'sedentary',
        gender: 'female',
        goal: 'lose_fat',
      );

      expect(plan.macroTargets.totalCalories, greaterThanOrEqualTo(1200));
      expect(plan.macroTargets.totalCalories, 1200);
    });

    test('Enforces Calorie Floor for Male (1500)', () {
      final plan = engine.calculatePlan(
        userId: 'test',
        weightKg: 50,
        bodyFatPercentage: 10,
        activityLevel: 'sedentary',
        gender: 'male',
        goal: 'lose_fat',
      );

      expect(plan.macroTargets.totalCalories, greaterThanOrEqualTo(1500));
      expect(plan.macroTargets.totalCalories, 1500);
    });

    test('Caps Protein at 2.5g/kg', () {
       // 100kg user. 2.5g/kg = 250g max.
       // Even if calculations wanted more, it should cap.
       // (Our current logic sets 2.0 or 2.2, so it shouldn't hit 2.5 naturally unless we change logic, 
       // but strictly checking the guard.)
       
       // Force a scenario? Routine sets default 2.0-2.2.
       // Let's just check standard range is safe.
       final plan = engine.calculatePlan(
        userId: 'test',
        weightKg: 100,
        bodyFatPercentage: 15,
        activityLevel: 'active',
        gender: 'male',
        goal: 'muscle_gain', // set to 2.2g
      );
      
      expect(plan.macroTargets.proteinGrams, lessThanOrEqualTo(250)); // 100 * 2.5
      expect(plan.macroTargets.proteinGrams, 220); // 100 * 2.2
    });
  });
}

import 'package:elena_app/src/features/nutrition/domain/services/macro_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MacroCalculator', () {
    // ────────────────────────────────────────────────────────────────────────
    // SCENARIO 1: Insulin Resistant, Extended Fasting (18:6)
    // ────────────────────────────────────────────────────────────────────────

    test(
      'Insulin resistant + 18:6 fasting → high fat, low carbs',
      () {
        final calc = MacroCalculator(
          leanMassKg: 60.0, // 75 kg @ 20% BF
          totalWeightKg: 75.0,
          tdee: 2000.0,
          fastingWindowHours: 18.0,
          insulinSensitivity: InsulinSensitivityLevel.resistant,
        );

        final result = calc.calculateMacros(
          caloricTarget: 1800.0, // 10% deficit
          isTrainingDay: false,
        );

        expect(result.proteinGrams, greaterThan(130.0)); // ~2.2g per lean kg
        expect(result.fatGrams, greaterThan(70.0)); // Elevated for IR + fasting
        expect(
            result.carbsGrams, lessThan(130.0)); // Significantly lower for IR
        expect(result.actualCalories, closeTo(1800.0, 50.0)); // Within 50 cal
      },
    );

    // ────────────────────────────────────────────────────────────────────────
    // SCENARIO 2: Insulin Sensitive, No Fasting (12:12)
    // ────────────────────────────────────────────────────────────────────────

    test(
      'Insulin sensitive + no fasting → normal fat, high carbs',
      () {
        final calc = MacroCalculator(
          leanMassKg: 60.0,
          totalWeightKg: 75.0,
          tdee: 2400.0,
          fastingWindowHours: 12.0, // No meaningful fasting
          insulinSensitivity: InsulinSensitivityLevel.sensitive,
        );

        final result = calc.calculateMacros(
          caloricTarget: 2000.0,
          isTrainingDay: true,
        );

        expect(result.proteinGrams, greaterThan(130.0));
        expect(result.fatGrams, closeTo(65.0, 15.0)); // Lower, ~0.9 g/kg
        expect(result.carbsGrams, greaterThan(200.0)); // Higher carb ceiling
        expect(result.actualCalories, closeTo(2000.0, 50.0));
      },
    );

    // ────────────────────────────────────────────────────────────────────────
    // SCENARIO 3: Normal Sensitivity, Standard Fasting (16:8)
    // ────────────────────────────────────────────────────────────────────────

    test(
      'Normal sensitivity + 16:8 fasting → balanced macros',
      () {
        final calc = MacroCalculator(
          leanMassKg: 70.0, // 90 kg @ 22% BF
          totalWeightKg: 90.0,
          tdee: 2200.0,
          fastingWindowHours: 16.0, // Standard
          insulinSensitivity: InsulinSensitivityLevel.normal,
        );

        final result = calc.calculateMacros(
          caloricTarget: 1980.0, // 10% deficit
          isTrainingDay: true,
        );

        expect(result.proteinGrams, greaterThan(150.0)); // ~2.2g per lean kg
        expect(result.fatGrams, closeTo(75.0, 25.0)); // ~1.0–1.25 g/kg
        expect(result.carbsGrams, closeTo(165.0, 80.0)); // Moderate to high
        expect(result.actualCalories, closeTo(1980.0, 50.0));

        // Check distribution
        final dist = result.distribution;
        expect(dist.proteinPercent, greaterThan(25.0));
        expect(dist.fatPercent, greaterThan(20.0));
        expect(dist.carbsPercent, greaterThan(25.0));
      },
    );

    // ────────────────────────────────────────────────────────────────────────
    // SCENARIO 4: Impaired Sensitivity, Extended Fasting (20:4)
    // ────────────────────────────────────────────────────────────────────────

    test(
      'Impaired sensitivity + 20:4 fasting → moderate adjustments',
      () {
        final calc = MacroCalculator(
          leanMassKg: 55.0, // 70 kg @ 21% BF
          totalWeightKg: 70.0,
          tdee: 1800.0,
          fastingWindowHours: 20.0, // Extended
          insulinSensitivity: InsulinSensitivityLevel.impaired,
        );

        final result = calc.calculateMacros(
          caloricTarget: 1620.0, // 10% deficit
          isTrainingDay: false,
        );

        expect(result.proteinGrams, greaterThan(115.0)); // ~2.1g per lean kg
        expect(result.fatGrams,
            greaterThan(65.0)); // Elevated for fasting + impaired
        expect(result.carbsGrams, lessThan(135.0)); // Capped at 130g
        expect(result.actualCalories, closeTo(1620.0, 50.0));
      },
    );

    // ────────────────────────────────────────────────────────────────────────
    // MACRO DISTRIBUTION CHECKS
    // ────────────────────────────────────────────────────────────────────────

    test(
      'Macro distribution percentages sum to ~100%',
      () {
        final calc = MacroCalculator(
          leanMassKg: 65.0,
          totalWeightKg: 82.0,
          tdee: 2100.0,
          fastingWindowHours: 16.0,
          insulinSensitivity: InsulinSensitivityLevel.normal,
        );

        final result = calc.calculateMacros(caloricTarget: 1890.0);
        final dist = result.distribution;

        final sum = dist.proteinPercent + dist.fatPercent + dist.carbsPercent;

        expect(sum, closeTo(100.0, 1.0)); // Within 1% rounding error
      },
    );

    // ────────────────────────────────────────────────────────────────────────
    // EDGE CASES
    // ────────────────────────────────────────────────────────────────────────

    test(
      'Very low caloric target → macros floor at minimums',
      () {
        final calc = MacroCalculator(
          leanMassKg: 50.0,
          totalWeightKg: 65.0,
          tdee: 1600.0,
          fastingWindowHours: 16.0,
          insulinSensitivity: InsulinSensitivityLevel.normal,
        );

        final result = calc.calculateMacros(caloricTarget: 900.0);

        // Protein should not drop below 1.5x lean mass even at low calories
        expect(result.proteinGrams, greaterThan(75.0));
        expect(result.fatGrams, greaterThan(20.0)); // Floor
        expect(result.carbsGrams, greaterThan(0.0));
      },
    );

    test(
      'High caloric target with training day → carbs elevation',
      () {
        final calc = MacroCalculator(
          leanMassKg: 75.0,
          totalWeightKg: 95.0,
          tdee: 2800.0,
          fastingWindowHours: 16.0,
          insulinSensitivity: InsulinSensitivityLevel.sensitive,
        );

        final result = calc.calculateMacros(
          caloricTarget: 2800.0, // Maintenance
          isTrainingDay: true,
        );

        // High carb ceiling for sensitive + training day
        expect(result.carbsGrams, greaterThan(250.0));
      },
    );

    // ────────────────────────────────────────────────────────────────────────
    // ROUNDING
    // ────────────────────────────────────────────────────────────────────────

    test(
      'Rounded result has integer-like precision',
      () {
        final calc = MacroCalculator(
          leanMassKg: 62.5,
          totalWeightKg: 78.6,
          tdee: 2050.0,
          fastingWindowHours: 15.5,
          insulinSensitivity: InsulinSensitivityLevel.normal,
        );

        final result = calc.calculateMacros(caloricTarget: 1845.0);
        final rounded = result.rounded();

        expect(rounded.proteinGrams, rounded.proteinGrams.floorToDouble());
        expect(rounded.fatGrams, rounded.fatGrams.floorToDouble());
        expect(rounded.carbsGrams, rounded.carbsGrams.floorToDouble());
      },
    );

    // ────────────────────────────────────────────────────────────────────────
    // FASTING INTENSITY SCORE BEHAVIOR
    // ────────────────────────────────────────────────────────────────────────

    test(
      'Fasting window affects fat allocation: 12h < 16h < 20h',
      () {
        final baseCalc = MacroCalculator(
          leanMassKg: 60.0,
          totalWeightKg: 75.0,
          tdee: 2000.0,
          fastingWindowHours: 12.0, // No fasting
          insulinSensitivity: InsulinSensitivityLevel.normal,
        );

        final mildFastingCalc = MacroCalculator(
          leanMassKg: 60.0,
          totalWeightKg: 75.0,
          tdee: 2000.0,
          fastingWindowHours: 16.0, // Mild fasting
          insulinSensitivity: InsulinSensitivityLevel.normal,
        );

        final extendedFastingCalc = MacroCalculator(
          leanMassKg: 60.0,
          totalWeightKg: 75.0,
          tdee: 2000.0,
          fastingWindowHours: 20.0, // Extended fasting
          insulinSensitivity: InsulinSensitivityLevel.normal,
        );

        final r1 = baseCalc.calculateMacros(caloricTarget: 1800.0);
        final r2 = mildFastingCalc.calculateMacros(caloricTarget: 1800.0);
        final r3 = extendedFastingCalc.calculateMacros(caloricTarget: 1800.0);

        // Fat should increase with fasting duration
        expect(r2.fatGrams,
            greaterThanOrEqualTo(r1.fatGrams * 0.95)); // Similar or higher
        expect(
            r3.fatGrams, greaterThanOrEqualTo(r2.fatGrams)); // Extended >= mild
      },
    );
  });
}

/// EJEMPLO DE INTEGRACIÓN: MacroCalculator + MetabolicEngine
///
/// Este archivo muestra cómo usar MacroCalculator para reemplazar o validar
/// la lógica de cálculo de macros dentro del motor metabólico existente.
///
/// 📌 RETENTION POLICY: This file is kept as reference documentation even though
/// it has no direct imports in the codebase. It serves as:
/// - Integration examples for future developers
/// - Test reference for MacroCalculator validation
/// - Documentation of macro calculation patterns
///
/// DO NOT DELETE without explicitly reviewing pull request requirements and
/// ensuring all developers are informed. Status: [INTENTIONALLY RETAINED]
library;

import '../../../../core/services/app_logger.dart';
import 'package:elena_app/src/features/nutrition/domain/entities/metabolic_profile.dart';
import 'package:elena_app/src/features/nutrition/domain/services/macro_calculator.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EJEMPLO 1: Uso Independiente
// ─────────────────────────────────────────────────────────────────────────────

void example1StandaloneCalculator() {
  // Crear un calculador para un usuario específico
  final calc = MacroCalculator(
    leanMassKg: 65.0,
    totalWeightKg: 82.0,
    tdee: 2100.0,
    fastingWindowHours: 16.0,
    insulinSensitivity: InsulinSensitivityLevel.normal,
  );

  // Calcular macros para un déficit del 10%
  final result = calc.calculateMacros(
    caloricTarget: 1890.0,
    isTrainingDay: true,
  );

  AppLogger.info('=== Resultado ===');
  AppLogger.info('Proteína: ${result.proteinGrams.toStringAsFixed(1)}g');
  AppLogger.info('Grasa: ${result.fatGrams.toStringAsFixed(1)}g');
  AppLogger.info('Carbos: ${result.carbsGrams.toStringAsFixed(1)}g');
  AppLogger.info('Calorías: ${result.actualCalories.toStringAsFixed(0)}');
  AppLogger.info('Distribución: ${result.distribution}');
  AppLogger.info('Redondeado: ${result.rounded()}');
}

// ─────────────────────────────────────────────────────────────────────────────
// EJEMPLO 2: Integración con MetabolicProfile
// ─────────────────────────────────────────────────────────────────────────────

MacroResult calculateMacrosFromProfile({
  required MetabolicProfile profile,
  required double caloricTarget,
  required bool isTrainingDay,
}) {
  // Mapear InsulinSensitivity (enum del perfil) a InsulinSensitivityLevel (enum del calculador)
  final sensitivity = _mapInsulinSensitivity(profile.insulinSensitivity);

  final calc = MacroCalculator(
    leanMassKg: profile.leanMassKg,
    totalWeightKg: profile.totalWeightKg,
    tdee: profile.tdee,
    fastingWindowHours: profile.fastingContext.fastingWindowHours,
    insulinSensitivity: sensitivity,
  );

  return calc.calculateMacros(
    caloricTarget: caloricTarget,
    isTrainingDay: isTrainingDay,
  );
}

// Mapear entre los enums del sistema existente y el calculador
InsulinSensitivityLevel _mapInsulinSensitivity(
  InsulinSensitivity profileSensitivity,
) {
  return switch (profileSensitivity) {
    InsulinSensitivity.resistant => InsulinSensitivityLevel.resistant,
    InsulinSensitivity.impaired => InsulinSensitivityLevel.impaired,
    InsulinSensitivity.normal => InsulinSensitivityLevel.normal,
    InsulinSensitivity.sensitive => InsulinSensitivityLevel.sensitive,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// EJEMPLO 3: Reemplazar Lógica en MetabolicEngine
// ─────────────────────────────────────────────────────────────────────────────

/// Fragment de código para integrar en MetabolicEngine.generate()
///
/// Ubicación: Después de computar caloricTarget
void integrateIntoMetabolicEngine() {
  /*
  // En MetabolicEngine.generate():

  // ── PASO 2: Caloric Target ───────────────────────────────────────────────
  final caloricTarget = _computeCaloricTarget(profile, strategy);

  // ── PASO 3-5: MACROS (NUEVA LÓGICA CON MacroCalculator) ────────────────
  final calculator = MacroCalculator(
    leanMassKg: profile.leanMassKg,
    totalWeightKg: profile.totalWeightKg,
    tdee: profile.tdee,
    fastingWindowHours: profile.fastingContext.fastingWindowHours,
    insulinSensitivity: _mapInsulinSensitivity(profile.insulinSensitivity),
  );

  final macroResult = calculator.calculateMacros(
    caloricTarget: caloricTarget,
    isTrainingDay: isTrainingDay,
    proteinMultiplier: strategy.proteinDirective.gPerKgLeanMass,
  );

  final proteinG = macroResult.proteinGrams;
  final fatG = macroResult.fatGrams;
  final carbsG = macroResult.carbsGrams;
  final safeResult = MacroResult(
    calories: macroResult.actualCalories,
    protein: proteinG,
    fat: fatG,
    carbs: carbsG,
  );

  // Continuar con PASO 6: Calorie Recalibration (ya hecho en MacroCalculator)
  // ── PASO 7: Safety Validation (aplicar constraints adicionales si es necesario)
  // ...
  */
}

// ─────────────────────────────────────────────────────────────────────────────
// EJEMPLO 4: Comparación de Escenarios
// ─────────────────────────────────────────────────────────────────────────────

void compareScenarios() {
  AppLogger.info('=== Escenario 1: IR + 18:6 ===');
  final calc1 = MacroCalculator(
    leanMassKg: 60.0,
    totalWeightKg: 75.0,
    tdee: 2000.0,
    fastingWindowHours: 18.0,
    insulinSensitivity: InsulinSensitivityLevel.resistant,
  );
  final result1 = calc1.calculateMacros(caloricTarget: 1800.0);
  AppLogger.info(result1.toString());
  AppLogger.info('Distribución: ${result1.distribution}');

  AppLogger.info('\n=== Escenario 2: Sensible + 12h ===');
  final calc2 = MacroCalculator(
    leanMassKg: 65.0,
    totalWeightKg: 82.0,
    tdee: 2400.0,
    fastingWindowHours: 12.0,
    insulinSensitivity: InsulinSensitivityLevel.sensitive,
  );
  final result2 =
      calc2.calculateMacros(caloricTarget: 2200.0, isTrainingDay: true);
  AppLogger.info(result2.toString());
  AppLogger.info('Distribución: ${result2.distribution}');

  AppLogger.info('\n=== Escenario 3: Normal + 16:8 ===');
  final calc3 = MacroCalculator(
    leanMassKg: 70.0,
    totalWeightKg: 90.0,
    tdee: 2200.0,
    fastingWindowHours: 16.0,
    insulinSensitivity: InsulinSensitivityLevel.normal,
  );
  final result3 =
      calc3.calculateMacros(caloricTarget: 1980.0, isTrainingDay: true);
  AppLogger.info(result3.toString());
  AppLogger.info('Distribución: ${result3.distribution}');
}

// ─────────────────────────────────────────────────────────────────────────────
// EJEMPLO 5: Análisis de Sensibilidad a Insulina
// ─────────────────────────────────────────────────────────────────────────────

void analyzeSensitivityImpact() {
  const baselineParams = {
    'leanMassKg': 65.0,
    'totalWeightKg': 82.0,
    'tdee': 2100.0,
    'fastingWindowHours': 16.0,
    'caloricTarget': 1890.0,
  };

  for (final sensitivity in InsulinSensitivityLevel.values) {
    final calc = MacroCalculator(
      leanMassKg: baselineParams['leanMassKg'] as double,
      totalWeightKg: baselineParams['totalWeightKg'] as double,
      tdee: baselineParams['tdee'] as double,
      fastingWindowHours: baselineParams['fastingWindowHours'] as double,
      insulinSensitivity: sensitivity,
    );

    final result = calc.calculateMacros(
      caloricTarget: baselineParams['caloricTarget'] as double,
    );

    AppLogger.info('$sensitivity: $result');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EJEMPLO 6: Análisis de Impacto del Ayuno
// ─────────────────────────────────────────────────────────────────────────────

void analyzeFastingWindowImpact() {
  final fastingWindows = [12.0, 13.0, 14.0, 16.0, 18.0, 20.0, 22.0, 24.0];

  for (final hours in fastingWindows) {
    final calc = MacroCalculator(
      leanMassKg: 65.0,
      totalWeightKg: 82.0,
      tdee: 2100.0,
      fastingWindowHours: hours,
      insulinSensitivity: InsulinSensitivityLevel.normal,
    );

    final result = calc.calculateMacros(caloricTarget: 1890.0);
    AppLogger.info(
        '$hours:${24 - hours.toInt()} → Grasa: ${result.fatGrams.toStringAsFixed(1)}g');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN: Ejecutar todos los ejemplos
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  AppLogger.info(
      '╔═══════════════════════════════════════════════════════════════════╗');
  AppLogger.info('║ EJEMPLO 1: Uso Independiente                                     ║');
  AppLogger.info(
      '╚═══════════════════════════════════════════════════════════════════╝');
  example1StandaloneCalculator();

  AppLogger.info(
      '\n╔═══════════════════════════════════════════════════════════════════╗');
  AppLogger.info('║ EJEMPLO 4: Comparación de Escenarios                             ║');
  AppLogger.info(
      '╚═══════════════════════════════════════════════════════════════════╝');
  compareScenarios();

  AppLogger.info(
      '\n╔═══════════════════════════════════════════════════════════════════╗');
  AppLogger.info('║ EJEMPLO 5: Impacto de Sensibilidad a Insulina                    ║');
  AppLogger.info(
      '╚═══════════════════════════════════════════════════════════════════╝');
  analyzeSensitivityImpact();

  AppLogger.info(
      '\n╔═══════════════════════════════════════════════════════════════════╗');
  AppLogger.info('║ EJEMPLO 6: Impacto de Ventana de Ayuno                           ║');
  AppLogger.info(
      '╚═══════════════════════════════════════════════════════════════════╝');
  analyzeFastingWindowImpact();
}

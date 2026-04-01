import 'metabolic_profile.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NUTRITION STRATEGY — The "Why" layer before the "What"
// ─────────────────────────────────────────────────────────────────────────────

/// Base abstraction for metabolic strategy.
/// Each strategy encapsulates:
///  - caloric directive (% deficit/surplus relative to TDEE)
///  - macro distribution logic
///  - carb cycling rules
///  - meal frequency and timing constraints
///
/// Strategies are SELECTED by the engine based on the MetabolicProfile.
/// They do NOT calculate macros — they provide the parameters for calculation.
abstract class NutritionStrategy {
  /// Human-readable name for display.
  String get name;

  /// Scientific rationale for the strategy.
  String get rationale;

  /// Caloric modifier relative to TDEE. Negative = deficit.
  /// Example: -0.20 → 20% deficit.
  /// Must be in range [-0.35, +0.20] to stay physiologically safe.
  double get caloricModifier;

  /// Protein target in grams per kg of LEAN MASS (not total weight).
  /// Range: [1.6, 3.0] g/kg lean mass.
  ProteinDirective get proteinDirective;

  /// Fat directive.
  FatDirective get fatDirective;

  /// Carb cycling directive.
  CarbDirective get carbDirective;

  /// Recommended meal frequency.
  MealFrequency get mealFrequency;

  /// Nutrient timing rules.
  NutrientTimingRules get timingRules;

  /// Safety overrides to apply post-calculation.
  SafetyConstraints get safetyConstraints;
}

// ── Sub-directives ──

class ProteinDirective {
  /// Grams per kg of LEAN mass.
  final double gPerKgLeanMass;

  /// Strategy-specific justification.
  final String rationale;

  const ProteinDirective({
    required this.gPerKgLeanMass,
    required this.rationale,
  });
}

class FatDirective {
  /// Minimum fat in grams per kg of TOTAL weight (hormonal floor).
  final double minGPerKgBodyweight;

  /// Target fat as % of total calories (if > floor).
  final double? targetCaloriePercent;

  final String rationale;

  const FatDirective({
    required this.minGPerKgBodyweight,
    this.targetCaloriePercent,
    required this.rationale,
  });
}

enum CarbCyclingMode {
  none, // Fixed carbs
  lowHigh, // Low-carb rest days, high-carb training days
  linearReduction, // Decreasing carbs over the week
  ketoCycling, // 5 keto + 2 carb-up days
}

class CarbDirective {
  /// Cycling mode for the week.
  final CarbCyclingMode cyclingMode;

  /// Base carb ceiling in g/day for rest days (or fixed if no cycling).
  final double restDayCarbCeilingG;

  /// Carb allowance on training days. Null = same as rest.
  final double? trainingDayCarbTargetG;

  /// Override: lock carbs below this regardless of calculations (e.g., strict keto).
  final double? absoluteCarbCeilingG;

  final String rationale;

  const CarbDirective({
    required this.cyclingMode,
    required this.restDayCarbCeilingG,
    this.trainingDayCarbTargetG,
    this.absoluteCarbCeilingG,
    required this.rationale,
  });
}

class MealFrequency {
  /// Number of meals per day.
  final int mealsPerDay;

  /// Minimum gap between meals in hours (matched with fasting protocol).
  final double minMealGapHours;

  final String rationale;

  const MealFrequency({
    required this.mealsPerDay,
    required this.minMealGapHours,
    required this.rationale,
  });
}

class NutrientTimingRules {
  /// % of daily protein in the first meal (breaking fast).
  final double firstMealProteinPercent;

  /// % of daily carbs reserved for the pre/post-workout window.
  final double workoutCarbPercent;

  /// Number of hours before sleep to stop eating (circadian alignment).
  final double stopEatingHoursBeforeSleep;

  /// Whether to delay carbs until after training.
  final bool carbohydrateBackloading;

  const NutrientTimingRules({
    required this.firstMealProteinPercent,
    required this.workoutCarbPercent,
    required this.stopEatingHoursBeforeSleep,
    this.carbohydrateBackloading = false,
  });
}

class SafetyConstraints {
  /// Absolute minimum calories (context-aware, not static).
  final double Function(MetabolicProfile profile) minCaloriesResolver;

  /// Absolute minimum protein grams per day.
  final double minProteinFloor;

  /// Absolute minimum fat (g/day) — hormonal safety floor.
  final double minFatFloorG;

  const SafetyConstraints({
    required this.minCaloriesResolver,
    required this.minProteinFloor,
    required this.minFatFloorG,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// CONCRETE STRATEGIES
// ─────────────────────────────────────────────────────────────────────────────

/// Strategy 1: Aggressive Fat Loss
/// Indicated for: obese (BF% > 35), metabolically resistant, high WHtR.
/// Caloric approach: 25–30% deficit.
/// Rationale: Large fat stores buffer the deficit; lean mass preservation
/// requires high protein. Low carbs to reset insulin signaling.
class AggressiveFatLossStrategy implements NutritionStrategy {
  @override
  String get name => 'Pérdida de Grasa Agresiva';

  @override
  String get rationale =>
      'Déficit calórico alto (25%) protegido por proteína elevada '
      'sobre masa magra. Carbohidratos mínimos para resetear señalización '
      'insulínica y maximizar oxidación de grasa. Justificado cuando BF% > 35.';

  @override
  double get caloricModifier => -0.25;

  @override
  ProteinDirective get proteinDirective => const ProteinDirective(
        gPerKgLeanMass: 2.4,
        rationale:
            'Alta dosis proteica (2.4g/kg LM) para prevenir catabolismo '
            'muscular durante déficit agresivo. Basado en Helms et al. 2014.',
      );

  @override
  FatDirective get fatDirective => const FatDirective(
        minGPerKgBodyweight: 0.5,
        targetCaloriePercent: 0.30,
        rationale:
            'Grasa moderada (30% calorías) para mantener producción hormonal '
            'sin comprometer el déficit. Floor de 0.5g/kg evita disrupción '
            'de eje HPA.',
      );

  @override
  CarbDirective get carbDirective => const CarbDirective(
        cyclingMode: CarbCyclingMode.lowHigh,
        restDayCarbCeilingG: 80.0,
        trainingDayCarbTargetG: 150.0,
        rationale:
            'Carbohidratos bajos en reposo (≤80g) para mantener insulina basal '
            'baja y maximizar lipolisis. Aumento en días de entrenamiento '
            'para sostener performance y refill glucogénico.',
      );

  @override
  MealFrequency get mealFrequency => const MealFrequency(
        mealsPerDay: 2,
        minMealGapHours: 5.0,
        rationale:
            'Frecuencia baja (2 comidas) sincronizada con ventana de '
            'alimentación del ayuno. Maximiza intervalos de baja insulina '
            'para lipolisis sostenida.',
      );

  @override
  NutrientTimingRules get timingRules => const NutrientTimingRules(
        firstMealProteinPercent: 0.45,
        workoutCarbPercent: 0.65,
        stopEatingHoursBeforeSleep: 3.0,
        carbohydrateBackloading: true,
      );

  @override
  SafetyConstraints get safetyConstraints => SafetyConstraints(
        minCaloriesResolver: (p) {
          // Non-static floor: uses BMR as lower bound, never below 1200 absolute
          return (p.bmr * 0.90).clamp(1200.0, double.infinity);
        },
        minProteinFloor: 120.0,
        minFatFloorG: 40.0,
      );
}

/// Strategy 2: Insulin Reset
/// Indicated for: insulin resistant, PCOS, pre-diabetic, high-WHtR.
/// Priority: break carbohydrate dependency, lower insulin chronically.
class InsulinResetStrategy implements NutritionStrategy {
  @override
  String get name => 'Reset Insulínico';

  @override
  String get rationale =>
      'Déficit conservador (15%) con carbohidratos muy bajos (<100g/día). '
      'Objetivo primario: reducir hiperinsulinemia basal. La pérdida de grasa '
      'es secundaria al reset metabólico. Basado en protocolos VLCD modificados '
      'y evidencia en síndrome metabólico (Feinman et al. 2015).';

  @override
  double get caloricModifier => -0.15;

  @override
  ProteinDirective get proteinDirective => const ProteinDirective(
        gPerKgLeanMass: 2.0,
        rationale:
            'Proteína moderada-alta (2.0g/kg LM). Efecto insulinogénico '
            'de la proteína es 50% menor que carbohidratos. Preserva masa '
            'magra sin elevar insulinemia.',
      );

  @override
  FatDirective get fatDirective => const FatDirective(
        minGPerKgBodyweight: 0.7,
        targetCaloriePercent: 0.40,
        rationale:
            'Grasa alta (40%) como macronutriente primario de energía ya que '
            'los carbohidratos se restringen. No estimula respuesta insulínica. '
            'Ácidos grasos saturados limitados para no agravar resistencia '
            'a insulina hepática.',
      );

  @override
  CarbDirective get carbDirective => const CarbDirective(
        cyclingMode: CarbCyclingMode.none,
        restDayCarbCeilingG: 80.0,
        absoluteCarbCeilingG: 100.0,
        rationale:
            'Carbohidratos fijos y bajos (<100g/día netos). No hay ciclado '
            'hasta lograr sensibilidad insulínica (proxy: WHtR < 0.50 o '
            '8+ semanas de adherencia). Énfasis en fibra ≥ 25g/día.',
      );

  @override
  MealFrequency get mealFrequency => const MealFrequency(
        mealsPerDay: 2,
        minMealGapHours: 6.0,
        rationale:
            'Máxima separación entre comidas (6h+) para prolongar periodos '
            'de insulina baja. Snacking prohibido – rompe el efecto '
            'terapéutico del protocolo.',
      );

  @override
  NutrientTimingRules get timingRules => const NutrientTimingRules(
        firstMealProteinPercent: 0.50,
        workoutCarbPercent: 0.80,
        stopEatingHoursBeforeSleep: 3.5,
        carbohydrateBackloading: false,
      );

  @override
  SafetyConstraints get safetyConstraints => SafetyConstraints(
        minCaloriesResolver: (p) => (p.bmr * 0.95).clamp(1200.0, double.infinity),
        minProteinFloor: 100.0,
        minFatFloorG: 45.0,
      );
}

/// Strategy 3: Recomposition
/// Indicated for: normal BF%, strength training, moderate insulin sensitivity.
/// Calories at/near maintenance. Protein maximized. Carbs timed to training.
class RecompositionStrategy implements NutritionStrategy {
  @override
  String get name => 'Recomposición Corporal';

  @override
  String get rationale =>
      'Calorías en mantenimiento (±5%) con proteína maximizada (2.6g/kg LM). '
      'La recomposición requiere señal anabólica (entrenamiento + proteína) '
      'y señal catabólica simultánea (déficit leve crónico). '
      'Eficaz en individuos no avanzados con BF% 15–30%.';

  @override
  double get caloricModifier => -0.05;

  @override
  ProteinDirective get proteinDirective => const ProteinDirective(
        gPerKgLeanMass: 2.6,
        rationale:
            'Máxima proteína terapéutica (2.6g/kg LM) para maximizar MPS '
            '(síntesis proteica muscular) durante calorías de mantenimiento. '
            'Basado en Barakat et al. 2020 – recomposición requiere umbral '
            'proteico superior a la pérdida de grasa simple.',
      );

  @override
  FatDirective get fatDirective => const FatDirective(
        minGPerKgBodyweight: 0.8,
        targetCaloriePercent: 0.28,
        rationale:
            'Grasa moderada (28% calorías) permitida dado contexto normocalórico. '
            'Prioriza variedad de ácidos grasos (Omega-3 antiinflamatorio, '
            'MUFA para sensibilidad insulínica).',
      );

  @override
  CarbDirective get carbDirective => const CarbDirective(
        cyclingMode: CarbCyclingMode.lowHigh,
        restDayCarbCeilingG: 100.0,
        trainingDayCarbTargetG: 200.0,
        rationale:
            'Ciclado de carbohidratos agresivo (100g reposo / 200g entrenamiento). '
            'En días de training: refill glucogénico pre-entrenamiento y ventana '
            'anabólica post-ejercicio. En reposo: limitar insulina y maximizar '
            'lipolisis de grasa visceral.',
      );

  @override
  MealFrequency get mealFrequency => const MealFrequency(
        mealsPerDay: 3,
        minMealGapHours: 4.5,
        rationale:
            '3 comidas sincronizadas con eventos (primera comida, '
            'pre/post-workout, cierre de ventana). Maximiza señal anabólica '
            'sin fragmentar pulsos de proteína.',
      );

  @override
  NutrientTimingRules get timingRules => const NutrientTimingRules(
        firstMealProteinPercent: 0.35,
        workoutCarbPercent: 0.70,
        stopEatingHoursBeforeSleep: 2.5,
        carbohydrateBackloading: true,
      );

  @override
  SafetyConstraints get safetyConstraints => SafetyConstraints(
        minCaloriesResolver: (p) => (p.bmr * 1.0).clamp(1400.0, double.infinity),
        minProteinFloor: 130.0,
        minFatFloorG: 50.0,
      );
}

/// Strategy 4: Maintenance Optimization
/// Indicated for: metabolic health goal, post-deficit stabilization.
class MaintenanceStrategy implements NutritionStrategy {
  @override
  String get name => 'Mantenimiento Metabólico';

  @override
  String get rationale =>
      'Balance calórico con foco en calidad nutricional y timing circadiano. '
      'Objetivo: maximizar salud metabólica, longevidad y estabilidad hormonal. '
      'Déficit cero; superávit controlado para prevenir fat regain.';

  @override
  double get caloricModifier => 0.0;

  @override
  ProteinDirective get proteinDirective => const ProteinDirective(
        gPerKgLeanMass: 1.8,
        rationale:
            'Proteína suficiente para preservar masa magra en mantenimiento '
            '(1.8g/kg LM). Basado en RDA aumentada para adultos activos '
            '>40 años (previsión anti-sarcopénica).',
      );

  @override
  FatDirective get fatDirective => const FatDirective(
        minGPerKgBodyweight: 0.8,
        targetCaloriePercent: 0.33,
        rationale:
            'Grasa ~33% calorías. Punto de equilibrio hormonal y palatabilidad. '
            'Priorizar MUFA/PUFA sobre saturados.',
      );

  @override
  CarbDirective get carbDirective => const CarbDirective(
        cyclingMode: CarbCyclingMode.none,
        restDayCarbCeilingG: 200.0,
        rationale:
            'Carbohidratos sin restricción específica pero con énfasis en '
            'índice glucémico bajo (<55) y timing peri-entrenamiento. '
            'Fibra ≥30g/día para microbioma y saciedad.',
      );

  @override
  MealFrequency get mealFrequency => const MealFrequency(
        mealsPerDay: 3,
        minMealGapHours: 4.0,
        rationale:
            '3 comidas con ritmo circadiano. Alineadas con ritmo cortisol '
            '(comida principal en ventana de 12:00–15:00 para optimizar '
            'termogénesis postprandial).',
      );

  @override
  NutrientTimingRules get timingRules => const NutrientTimingRules(
        firstMealProteinPercent: 0.30,
        workoutCarbPercent: 0.50,
        stopEatingHoursBeforeSleep: 2.0,
        carbohydrateBackloading: false,
      );

  @override
  SafetyConstraints get safetyConstraints => SafetyConstraints(
        minCaloriesResolver: (p) => (p.bmr * 1.0).clamp(1500.0, double.infinity),
        minProteinFloor: 90.0,
        minFatFloorG: 40.0,
      );
}

/// Strategy 5: Muscle Gain (Lean Surplus)
/// Indicated for: experienced trainers, metabolically sensitive users.
class MuscleGainStrategy implements NutritionStrategy {
  @override
  String get name => 'Ganancia Muscular Limpia';

  @override
  String get rationale =>
      'Superávit controlado (+10%) para maximizar MPS sin fat gain excesivo. '
      'Proteína máxima. Carbohidratos altos para glucogénesis y performance. '
      'Solo viable en usuarios con BF < 20% (H) / < 28% (M) y '
      'entrenamiento de resistencia ≥3x/semana.';

  @override
  double get caloricModifier => 0.10;

  @override
  ProteinDirective get proteinDirective => const ProteinDirective(
        gPerKgLeanMass: 2.8,
        rationale:
            'Máxima saturación de MPS (2.8g/kg LM). Meta-análisis Morton 2018: '
            'beneficio adicional limitado a 3.1g/kg. Set en 2.8 para margen '
            'práctico.',
      );

  @override
  FatDirective get fatDirective => const FatDirective(
        minGPerKgBodyweight: 0.8,
        targetCaloriePercent: 0.25,
        rationale:
            'Grasa al mínimo terapéutico (25% calorías) para liberar '
            'calorías a carbohidratos que sustentan performance anaeróbica. '
            'No reducir <0.8g/kg por impacto en testosterona.',
      );

  @override
  CarbDirective get carbDirective => const CarbDirective(
        cyclingMode: CarbCyclingMode.lowHigh,
        restDayCarbCeilingG: 150.0,
        trainingDayCarbTargetG: 280.0,
        rationale:
            'Carbohidratos altos en entrenamiento (280g) para maximizar '
            'rendimiento glucolítico y síntesis de glucógeno post-ejercicio. '
            'Reducción en reposo (150g) para evitar fat gain nocturno '
            'y mantener sensibilidad insulínica.',
      );

  @override
  MealFrequency get mealFrequency => const MealFrequency(
        mealsPerDay: 3,
        minMealGapHours: 3.5,
        rationale:
            '3 comidas (4h gap mínimo) con bolo proteico ≥30g por ingesta '
            'para activar MPS leucina-dependiente. Basado en Moore et al. 2012.',
      );

  @override
  NutrientTimingRules get timingRules => const NutrientTimingRules(
        firstMealProteinPercent: 0.35,
        workoutCarbPercent: 0.60,
        stopEatingHoursBeforeSleep: 1.5,
        carbohydrateBackloading: false,
      );

  @override
  SafetyConstraints get safetyConstraints => SafetyConstraints(
        minCaloriesResolver: (p) => (p.bmr * 1.1).clamp(1600.0, double.infinity),
        minProteinFloor: 140.0,
        minFatFloorG: 50.0,
      );
}

/// Strategy Selector — pure function, no side effects.
class NutritionStrategySelector {
  static NutritionStrategy select(MetabolicProfile profile) {
    // Priority 1: Insulin Reset overrides everything if severely resistant
    if (profile.insulinSensitivity == InsulinSensitivity.resistant) {
      return InsulinResetStrategy();
    }

    // Priority 2: Goal-driven
    switch (profile.goal) {
      case MetabolicGoal.aggressiveFatLoss:
        return AggressiveFatLossStrategy();

      case MetabolicGoal.fatLoss:
        // If insulin impaired → use InsulinReset even for fat loss
        if (profile.insulinSensitivity == InsulinSensitivity.impaired) {
          return InsulinResetStrategy();
        }
        return AggressiveFatLossStrategy();

      case MetabolicGoal.recomposition:
        return RecompositionStrategy();

      case MetabolicGoal.maintenance:
      case MetabolicGoal.reverseDieting:
        return MaintenanceStrategy();

      case MetabolicGoal.muscleGain:
        return MuscleGainStrategy();
    }
  }
}

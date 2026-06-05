// SPEC-64: NutritionLog v2 con macronutrientes.
//
// Antes (v1): solo `id, timestamp, label, withinCircadianWindow`. Eso
// permitía contar comidas pero no medir nutrición real — la promesa
// "fundamento científico verificable" se quedaba en eslogan.
//
// Ahora (v2): añade `calories, protein, carbs, fat, fiber, glycemicIndex`
// como campos OPCIONALES. La nullabilidad es semántica (RF-64-04):
//   - null = "no se midió" (comida pre-SPEC-64 o registro rápido sin
//     desglose nutricional).
//   - 0 = "no consumió de ese macro" (es información válida).
//
// Las invariantes (>= 0 cuando presente) se validan en el constructor
// para que cualquier instancia del modelo sea consistente desde su origen.
// SPEC-62: las violaciones lanzan ValidationError tipado (NegativeValue,
// OutOfRange) en lugar de FormatException con mensaje string.
//
// SPEC-137: extendido con `ratio` (MealRatio, default a2e1) y
// `isCheatDay` (bool, default false). El `ratio` se vuelve la unidad
// atómica del registro — los macros opcionales de SPEC-64 sobreviven
// para usuarios power y para integración futura con HealthKit Dietary
// (Fase 2), pero ya no son la métrica primaria del pilar Nutrición.
// Ver `docs/NUTRITION_BIBLIOGRAPHY.md §1.2` para el criterio "simple".

import 'package:elena_app/src/core/errors/validation_error.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_ratio.dart';

class NutritionLog {
  /// Identificador único.
  final String id;

  /// Timestamp del registro.
  final DateTime timestamp;

  /// Etiqueta semántica: "Desayuno", "Almuerzo", "Cena", "Snack".
  final String label;

  /// True si la comida se registró dentro de la ventana
  /// [firstMealGoal, lastMealGoal] del CircadianProfile del usuario.
  final bool withinCircadianWindow;

  // ── SPEC-64: macronutrientes opcionales ─────────────────────────────────

  /// Calorías totales en kcal. `null` si no se midió.
  final double? calories;

  /// Proteína en gramos. `null` si no se midió.
  final double? protein;

  /// Carbohidratos en gramos. `null` si no se midió.
  final double? carbs;

  /// Grasa en gramos. `null` si no se midió.
  final double? fat;

  /// Fibra en gramos. Opcional dentro de macros (no afecta calorías).
  final double? fiber;

  /// Índice glucémico estimado (0-100). `null` si no se conoce.
  final int? glycemicIndex;

  /// Origen del dato nutricional para trazabilidad de SPEC-70.
  final NutritionLogSource source;

  // ── SPEC-137: clasificación operacional del plato ─────────────────────

  /// Proporción Tipo A : Tipo E del plato (Frank Suárez).
  ///
  /// Es la unidad atómica del registro nutricional desde SPEC-137.
  /// Default `MealRatio.a2e1` (2x1) para:
  /// 1. Retrocompatibilidad con tests pre-SPEC-137 que construyen
  ///    NutritionLog sin pasar ratio.
  /// 2. Logs históricos en Firestore sin el campo (ver mapper).
  final MealRatio ratio;

  /// True si el log se registró durante un "día de permitidos"
  /// (cheat day, RF-137-07). Default false.
  ///
  /// Los logs con isCheatDay=true cuentan normal hacia el Cociente A
  /// del día, pero el día completo se excluye del cálculo
  /// `weeklyAdherence`.
  final bool isCheatDay;

  // ── SPEC-138: ultra-procesados (NOVA 4) ─────────────────────────────

  /// Slots del plato ocupados por alimentos NOVA 4 (ultraprocesados).
  ///
  /// `null` para logs pre-SPEC-138 que no traen el dato. Combinado con
  /// [totalSlots] permite calcular `% UPF` diario/semanal sin recalcular
  /// desde la composición del plato (que no se persiste a nivel de
  /// item, solo se persiste el `ratio` derivado).
  ///
  /// Referencia: Monteiro et al. 2019. Ver `docs/NUTRITION_BIBLIOGRAPHY.md §16`.
  final int? upfSlots;

  /// Total de slots del plato (suma de `FoodCategory.slots` por item).
  ///
  /// `null` para logs pre-SPEC-138. Denominador del `upfSharePercent`
  /// del log. Se persiste explícitamente porque la "intensidad" del
  /// plato (número de items) no es derivable del `MealRatio`.
  final int? totalSlots;

  NutritionLog({
    required this.id,
    required this.timestamp,
    required this.label,
    required this.withinCircadianWindow,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.fiber,
    this.glycemicIndex,
    this.source = NutritionLogSource.userInput,
    this.ratio = MealRatio.a2e1,
    this.isCheatDay = false,
    this.upfSlots,
    this.totalSlots,
  }) {
    _validateNonNegative('calories', calories);
    _validateNonNegative('protein', protein);
    _validateNonNegative('carbs', carbs);
    _validateNonNegative('fat', fat);
    _validateNonNegative('fiber', fiber);
    if (glycemicIndex != null) {
      if (glycemicIndex! < 0 || glycemicIndex! > 100) {
        throw OutOfRange(
          field: 'NutritionLog.glycemicIndex',
          value: glycemicIndex!,
          min: 0,
          max: 100,
        );
      }
    }
    // SPEC-138 (hotfix 2026-06-05): las invariantes de upfSlots/totalSlots
    // se NORMALIZAN en el mapper (`fromMap` descarta ambos si están
    // inconsistentes) en lugar de THROW desde el constructor. Razón
    // crítica: el stream del nutrition_notifier tiene `onError` que
    // silencia excepciones — un solo log corrupto detenía el stream
    // entero y dejaba TODOS los pilares en 0 sin error visible.
    // Política: dominio tolerante en lectura, estricto en validación
    // de UI antes de escribir.
  }

  /// True si el log tiene macronutrientes registrados (al menos calorías).
  bool get hasMacros => calories != null;

  /// Crea una copia con campos opcionales modificados.
  NutritionLog copyWith({
    String? id,
    DateTime? timestamp,
    String? label,
    bool? withinCircadianWindow,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    int? glycemicIndex,
    NutritionLogSource? source,
    MealRatio? ratio,
    bool? isCheatDay,
    int? upfSlots,
    int? totalSlots,
  }) {
    return NutritionLog(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      label: label ?? this.label,
      withinCircadianWindow:
          withinCircadianWindow ?? this.withinCircadianWindow,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      glycemicIndex: glycemicIndex ?? this.glycemicIndex,
      source: source ?? this.source,
      ratio: ratio ?? this.ratio,
      isCheatDay: isCheatDay ?? this.isCheatDay,
      upfSlots: upfSlots ?? this.upfSlots,
      totalSlots: totalSlots ?? this.totalSlots,
    );
  }

  static void _validateNonNegative(String fieldName, double? value) {
    if (value != null && value < 0) {
      throw NegativeValue(
        field: 'NutritionLog.$fieldName',
        value: value,
      );
    }
  }
}

/// Origen del dato nutricional. Sirve para SPEC-70 (trazabilidad
/// bibliográfica) y para que el usuario sepa cuán confiable es el dato.
enum NutritionLogSource {
  /// El usuario lo escribió manualmente.
  userInput,

  /// Vino del catálogo `NutritionFactsLookup` interno.
  catalog,

  /// Estimado heurístico (ej. derivado del label sin desglose explícito).
  estimated,
}

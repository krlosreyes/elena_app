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
// SPEC-62 (R3) reemplazará FormatException por ValidationException tipada.

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
  }) {
    _validateNonNegative('calories', calories);
    _validateNonNegative('protein', protein);
    _validateNonNegative('carbs', carbs);
    _validateNonNegative('fat', fat);
    _validateNonNegative('fiber', fiber);
    if (glycemicIndex != null) {
      if (glycemicIndex! < 0 || glycemicIndex! > 100) {
        throw FormatException(
          'NutritionLog.glycemicIndex inválido: $glycemicIndex. '
          'Debe estar entre 0 y 100.',
        );
      }
    }
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
    );
  }

  static void _validateNonNegative(String fieldName, double? value) {
    if (value != null && value < 0) {
      throw FormatException(
        'NutritionLog.$fieldName inválido: $value. Debe ser >= 0.',
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

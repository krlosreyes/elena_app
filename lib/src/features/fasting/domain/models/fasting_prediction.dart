import 'package:freezed_annotation/freezed_annotation.dart';

part 'fasting_prediction.freezed.dart';
part 'fasting_prediction.g.dart';

/// Predicción del momento óptimo para romper ayuno
/// SPEC-35: Predictor de Fin de Ayuno
@freezed
class FastingPrediction with _$FastingPrediction {
  const factory FastingPrediction({
    /// ID único de la predicción
    required String id,
    /// ID del usuario
    required String userId,
    /// Cuándo se generó esta predicción
    required DateTime generatedAt,
    /// Duración actual del ayuno en horas
    required int fastedHours,
    /// Glucógeno estimado en gramos (0-500)
    required double estimatedGlycogen,
    /// Fase de ayuno actual (ALERTA, GLUCONEOGÉNESIS, CETOSIS, AUTOFAGIA)
    required String currentFastingPhase,
    /// Fase circadiana actual (ALERTA, ENERGÍA, CREPÚSCULO, SUEÑO, LIMPIEZA)
    required String currentCircadianPhase,
    /// Momento recomendado para romper el ayuno
    required DateTime optimalBreakTime,
    /// Opción macro sugerida: 'A' (low-carb), 'B' (balanced), 'C' (high-carb)
    required String suggestedMacroProfile,
    /// Respuesta glucémica estimada: BAJA, MEDIA, ALTA
    required String glucemicResponse,
    /// Confianza del predictor basada en historial (0.0-1.0)
    required double confidence,
    /// Minutos hasta el momento óptimo
    required int minutesUntilOptimal,
    /// Detalles de las 3 opciones macro
    required List<MacroOption> macroOptions,
    /// Si el usuario ya rompió el ayuno (feedback)
    @Default(false) bool hasBeenBroken,
    /// Cuándo se rompió realmente (si hasBeenBroken = true)
    DateTime? actualBreakTime,
    /// Opción macro elegida por usuario (A, B, C)
    String? actualMacroChoice,
    /// Cómo se sintió el usuario post-ruptura (1-10)
    int? userEnergyLevel,
    /// Notas del usuario sobre la ruptura
    String? userNotes,
  }) = _FastingPrediction;

  factory FastingPrediction.fromJson(Map<String, dynamic> json) =>
      _$FastingPredictionFromJson(json);
}

/// Opciones macro para ruptura de ayuno
@freezed
class MacroOption with _$MacroOption {
  const factory MacroOption({
    /// A = low-carb, B = balanced, C = high-carb
    required String profile,
    /// Carbohidratos sugeridos en gramos
    required double suggestedCarbs,
    /// Proteína sugerida en gramos
    required double suggestedProtein,
    /// Grasas sugeridas en gramos
    required double suggestedFat,
    /// Calorías totales estimadas
    required int estimatedCalories,
    /// Respuesta glucémica: BAJA, MEDIA, ALTA
    required String glucemicResponse,
    /// Descripción legible para usuario
    required String description,
    /// Ejemplos de alimentos para esta opción
    @Default([]) List<String> foodExamples,
    /// Confianza en esta recomendación (0.0-1.0)
    @Default(0.8) double confidence,
  }) = _MacroOption;

  factory MacroOption.fromJson(Map<String, dynamic> json) =>
      _$MacroOptionFromJson(json);
}

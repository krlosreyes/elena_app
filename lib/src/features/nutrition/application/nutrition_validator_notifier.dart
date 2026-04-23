import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_validator.dart';
import 'package:elena_app/src/core/orchestrator/orchestrator_provider.dart';

/// Provider del estado de validación de nutrición
final nutritionValidatorNotifierProvider =
    StateNotifierProvider<NutritionValidatorNotifier, NutritionValidationState?>((ref) {
  return NutritionValidatorNotifier(ref: ref);
});

/// Selector: Obtener validaciones actuales
final currentNutritionValidationProvider =
    StateProvider.autoDispose<NutritionValidationState?>((ref) {
  return ref.watch(nutritionValidatorNotifierProvider);
});

/// Selector: Obtener respuesta glucémica estimada
final estimatedGlycemicResponseProvider =
    StateProvider.autoDispose<String>((ref) {
  return ref.watch(nutritionValidatorNotifierProvider)?.glycemicResponse ?? 'MEDIA';
});

/// Selector: Obtener advertencias de validación
final nutritionValidationWarningsProvider =
    StateProvider.autoDispose<String?>((ref) {
  return ref.watch(nutritionValidatorNotifierProvider)?.validationWarning;
});

/// Estado de validación de nutrición
class NutritionValidationState {
  final double carbsG;
  final double proteinG;
  final double fatG;
  final double fiberG;
  final double totalCalories;
  final String glycemicResponse;
  final bool isValid;
  final String? validationWarning;
  final double carbPercent;
  final double proteinPercent;
  final double fatPercent;
  final DateTime lastValidated;

  NutritionValidationState({
    required this.carbsG,
    required this.proteinG,
    required this.fatG,
    required this.fiberG,
    required this.totalCalories,
    required this.glycemicResponse,
    required this.isValid,
    required this.validationWarning,
    required this.carbPercent,
    required this.proteinPercent,
    required this.fatPercent,
    required this.lastValidated,
  });

  NutritionValidationState copyWith({
    double? carbsG,
    double? proteinG,
    double? fatG,
    double? fiberG,
    double? totalCalories,
    String? glycemicResponse,
    bool? isValid,
    String? validationWarning,
    double? carbPercent,
    double? proteinPercent,
    double? fatPercent,
    DateTime? lastValidated,
  }) {
    return NutritionValidationState(
      carbsG: carbsG ?? this.carbsG,
      proteinG: proteinG ?? this.proteinG,
      fatG: fatG ?? this.fatG,
      fiberG: fiberG ?? this.fiberG,
      totalCalories: totalCalories ?? this.totalCalories,
      glycemicResponse: glycemicResponse ?? this.glycemicResponse,
      isValid: isValid ?? this.isValid,
      validationWarning: validationWarning ?? this.validationWarning,
      carbPercent: carbPercent ?? this.carbPercent,
      proteinPercent: proteinPercent ?? this.proteinPercent,
      fatPercent: fatPercent ?? this.fatPercent,
      lastValidated: lastValidated ?? this.lastValidated,
    );
  }
}

/// Notifier que valida macronutrientes contra estado metabólico
/// SPEC-36: Validación de Macronutrientes
class NutritionValidatorNotifier extends StateNotifier<NutritionValidationState?> {
  final Ref _ref;

  NutritionValidatorNotifier({required Ref ref})
      : _ref = ref,
        super(null);

  /// Valida una composición de macronutrientes
  void validateMacroComposition({
    required double carbsG,
    required double proteinG,
    required double fatG,
    required double fiberG,
  }) {
    try {
      // Validar sensatez básica
      final compositionError = NutritionValidator.validateMacroComposition(
        carbsG: carbsG,
        proteinG: proteinG,
        fatG: fatG,
      );

      // Estimar respuesta glucémica
      final glycemicResponse = NutritionValidator.estimateGlycemicResponse(
        carbsG: carbsG,
        proteinG: proteinG,
        fatG: fatG,
        fiberG: fiberG,
      );

      // Calcular totales
      final totalCalories = NutritionValidator.calculateTotalCalories(
        carbsG: carbsG,
        proteinG: proteinG,
        fatG: fatG,
      );

      // Calcular porcentajes
      final carbPercent = totalCalories > 0 ? (carbsG * 4) / totalCalories : 0;
      final proteinPercent = totalCalories > 0 ? (proteinG * 4) / totalCalories : 0;
      final fatPercent = totalCalories > 0 ? (fatG * 9) / totalCalories : 0;

      // Obtener estado del orchestrator (SPEC-01: OrchestratorStateV2)
      final orchestratorState = _ref.read(orchestratorProvider);

      // Validar contra estado metabólico
      final (isValid, warning) = NutritionValidator.validateMacrosAgainstFastingState(
        carbsG: carbsG,
        proteinG: proteinG,
        fatG: fatG,
        currentFastingPhase: orchestratorState.fastingPhase,
        hoursIntoCurrent: orchestratorState.fastedHours,
        currentCircadianPhase: orchestratorState.circadianPhase,
      );

      // Determinar si hay error de composición o advertencia del orchestrator
      final finalWarning = compositionError ?? warning;

      state = NutritionValidationState(
        carbsG: carbsG,
        proteinG: proteinG,
        fatG: fatG,
        fiberG: fiberG,
        totalCalories: totalCalories,
        glycemicResponse: glycemicResponse,
        isValid: isValid && compositionError == null,
        validationWarning: finalWarning,
        carbPercent: carbPercent,
        proteinPercent: proteinPercent,
        fatPercent: fatPercent,
        lastValidated: DateTime.now(),
      );

      debugPrint(
        '🥗 SPEC-36: Macros validados.\n'
        'Carbos: ${carbsG.toStringAsFixed(0)}g (${(carbPercent * 100).toStringAsFixed(0)}%) | '
        'Proteína: ${proteinG.toStringAsFixed(0)}g (${(proteinPercent * 100).toStringAsFixed(0)}%) | '
        'Grasas: ${fatG.toStringAsFixed(0)}g (${(fatPercent * 100).toStringAsFixed(0)}%)\n'
        'Glucemia: $glycemicResponse | Total: ${totalCalories.toStringAsFixed(0)} kcal\n'
        'Válido: $isValid | Advertencia: ${finalWarning ?? "Ninguna"}',
      );
    } catch (e) {
      debugPrint('❌ Error en NutritionValidatorNotifier: $e');
    }
  }

  /// API pública: Obtener estado actual
  NutritionValidationState? getState() => state;

  /// API pública: Obtener respuesta glucémica
  String? getGlycemicResponse() => state?.glycemicResponse;

  /// API pública: Obtener calorías totales
  double? getTotalCalories() => state?.totalCalories;

  /// API pública: Obtener advertencia
  String? getValidationWarning() => state?.validationWarning;

  /// API pública: Obtener si es válido
  bool isValid() => state?.isValid ?? false;

  /// API pública: Obtener porcentajes
  ({double carbs, double protein, double fat}) getMacroPercentages() {
    if (state == null) return (carbs: 0, protein: 0, fat: 0);
    return (
      carbs: state!.carbPercent,
      protein: state!.proteinPercent,
      fat: state!.fatPercent,
    );
  }
}

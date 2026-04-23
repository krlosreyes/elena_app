import 'package:elena_app/src/core/orchestrator/biological_phases.dart';

/// SPEC-01: Validador de macronutrientes y nutrición (Tipado)
/// Utiliza el motor orquestador central para validaciones coherentes
class NutritionValidator {
  /// RF-36-01: Estima respuesta glucémica basada en composición macro
  /// Retorna: BAJA, MEDIA, ALTA
  static String estimateGlycemicResponse({
    required double carbsG,
    required double proteinG,
    required double fatG,
    required double fiberG,
  }) {
    final totalCalories = (carbsG * 4) + (proteinG * 4) + (fatG * 9);
    if (totalCalories == 0) return 'MEDIA';

    final carbPercentage = (carbsG * 4) / totalCalories;
    final netCarbs = (carbsG - fiberG).clamp(0, double.infinity);

    // BAJA: <40% carbs O (40-60% carbs + fiber >=10g)
    if (carbPercentage < 0.4) {
      return 'BAJA';
    }
    if (carbPercentage >= 0.4 && carbPercentage <= 0.6 && fiberG >= 10) {
      return 'BAJA';
    }

    // ALTA: >60% carbs AND fiber <10g
    if (carbPercentage > 0.6 && fiberG < 10) {
      return 'ALTA';
    }

    // MEDIA: Resto de casos
    return 'MEDIA';
  }

  /// RF-36-02: Valida macros contra estado de ayuno actual
  /// Retorna (isValid, warningMessage)
  static (bool isValid, String? warning) validateMacrosAgainstFastingState({
    required double carbsG,
    required double proteinG,
    required double fatG,
    required FastingPhase currentFastingPhase,
    required double hoursIntoCurrent,
    required CircadianPhase currentCircadianPhase,
  }) {
    final glycemicResponse = estimateGlycemicResponse(
      carbsG: carbsG,
      proteinG: proteinG,
      fatG: fatG,
      fiberG: 0, // Simplificado, asumir 0 si no se proporciona
    );

    // Regla 1: Romper ayuno largo con muchos carbs sin fibra
    if (hoursIntoCurrent > 18 && carbsG > 80 && glycemicResponse == 'ALTA') {
      return (
        true, // Permitir pero advertir
        '⚠️  ALERTA: Rompiste un ayuno largo (${hoursIntoCurrent.toStringAsFixed(0)}h) '
            'con muchos carbos sin fibra. Riesgo de picos de glucosa. '
            'Considera: Proteína + grasa primero, luego carbos.'
      );
    }

    // Regla 2: Extremo en AUTOFAGIA
    if (currentFastingPhase == FastingPhase.autofagia && carbsG > 100) {
      return (
        true,
        '⚠️  En Autofagia profunda con >100g carbos. '
            'Esto rompe el ayuno. ¿Es intencional?'
      );
    }

    // Regla 3: Proteína insuficiente
    if (proteinG < 15) {
      return (
        true,
        '⚠️  Proteína muy baja (${proteinG.toStringAsFixed(0)}g). '
            'Mínimo 20g recomendado para preservar músculo.'
      );
    }

    // Regla 4: Proporción grasa/carbs desbalanceada
    final totalCalories = (carbsG * 4) + (proteinG * 4) + (fatG * 9);
    final fatPercentage = totalCalories > 0 ? (fatG * 9) / totalCalories : 0;
    if (fatPercentage > 0.7) {
      return (
        true,
        '⚠️  Muy alta proporción de grasas (${(fatPercentage * 100).toStringAsFixed(0)}%). '
            'Puede ser muy saciante. Asegúrate de que es intencional.'
      );
    }

    // Regla 5: Tiempo circadiano desfavorable (Fase SUEÑO/CREATIVIDAD tardía)
    if ((currentCircadianPhase == CircadianPhase.sueno || 
         currentCircadianPhase == CircadianPhase.creatividad) && carbsG > 60) {
      return (
        true,
        '⚠️  Fase circadiana tardía con >60g carbos. '
            'Puede afectar calidad de sueño. Considera reducir a 30g.'
      );
    }

    return (true, null);
  }

  /// Calcula total de calorías
  static double calculateTotalCalories({
    required double carbsG,
    required double proteinG,
    required double fatG,
  }) {
    return (carbsG * 4) + (proteinG * 4) + (fatG * 9);
  }

  /// Obtiene multiplicador de nutrición (Sincronizado con OrchestratorEngine)
  static double getNutritionPhaseMultiplier(CircadianPhase phase) {
    return switch (phase) {
      CircadianPhase.sueno => 0.6,
      CircadianPhase.alerta => 0.8,
      CircadianPhase.cognitivo => 1.0,
      CircadianPhase.receso => 0.95,
      CircadianPhase.motorFuerza => 0.9,
      CircadianPhase.creatividad => 0.7,
    };
  }

  /// Valida si es seguro comer ahora
  static bool canEatNow({
    required FastingPhase currentFastingPhase,
    required CircadianPhase currentCircadianPhase,
  }) {
    // No es seguro/recomendado comer en la fase de SUEÑO
    if (currentCircadianPhase == CircadianPhase.sueno) {
      return false;
    }
    return true; 
  }

  /// Valida composición de macros para coherencia metabólica
  static String? validateMacroComposition({
    required double carbsG,
    required double proteinG,
    required double fatG,
  }) {
    final totalCalories = calculateTotalCalories(
      carbsG: carbsG,
      proteinG: proteinG,
      fatG: fatG,
    );

    if (totalCalories == 0) {
      return 'Debes ingresar al menos algún macronutriente.';
    }

    final carbPercentage = (carbsG * 4) / totalCalories;
    final proteinPercentage = (proteinG * 4) / totalCalories;
    final fatPercentage = (fatG * 9) / totalCalories;

    // Validar rangos normales
    if (carbPercentage > 0.85) {
      return 'Carbos muy altos (${(carbPercentage * 100).toStringAsFixed(0)}%). '
          'Máximo recomendado es 80%.';
    }

    if (proteinPercentage > 0.5) {
      return 'Proteína muy alta (${(proteinPercentage * 100).toStringAsFixed(0)}%). '
          'Máximo recomendado es 40%.';
    }

    if (fatPercentage > 0.75) {
      return 'Grasas muy altas (${(fatPercentage * 100).toStringAsFixed(0)}%). '
          'Máximo recomendado es 70%.';
    }

    return null;
  }

  /// Base de datos de alimentos comunes con valores nutricionales
  static final Map<String, FoodItem> commonFoods = {
    // Proteína
    'pechuga_pollo': FoodItem(
      name: 'Pechuga de pollo (100g)',
      category: 'Proteína',
      carbsG: 0,
      proteinG: 31,
      fatG: 3.6,
      calories: 165,
    ),
    'huevo': FoodItem(
      name: 'Huevo grande',
      category: 'Proteína',
      carbsG: 0.6,
      proteinG: 6,
      fatG: 5,
      calories: 78,
    ),
    'yogur_griego': FoodItem(
      name: 'Yogur griego (100g)',
      category: 'Proteína',
      carbsG: 3.6,
      proteinG: 10,
      fatG: 0.4,
      calories: 59,
    ),

    // Carbohidrato
    'arroz_blanco': FoodItem(
      name: 'Arroz blanco cocido (100g)',
      category: 'Carbohidrato',
      carbsG: 28,
      proteinG: 2.7,
      fatG: 0.3,
      calories: 130,
    ),
    'plátano': FoodItem(
      name: 'Plátano mediano',
      category: 'Carbohidrato',
      carbsG: 27,
      proteinG: 1.1,
      fatG: 0.3,
      calories: 105,
    ),
    'avena': FoodItem(
      name: 'Avena cruda (30g)',
      category: 'Carbohidrato',
      carbsG: 27,
      proteinG: 5,
      fatG: 5,
      calories: 150,
    ),

    // Grasa
    'aguacate': FoodItem(
      name: 'Aguacate (100g)',
      category: 'Grasas',
      carbsG: 9,
      proteinG: 3,
      fatG: 15,
      calories: 160,
    ),
    'aceite_oliva': FoodItem(
      name: 'Aceite de oliva (1 cucharada)',
      category: 'Grasas',
      carbsG: 0,
      proteinG: 0,
      fatG: 14,
      calories: 120,
    ),

    // Verdura
    'broccoli': FoodItem(
      name: 'Brócoli cocido (100g)',
      category: 'Verdura',
      carbsG: 7,
      proteinG: 2.8,
      fatG: 0.4,
      calories: 34,
    ),
    'espinaca': FoodItem(
      name: 'Espinaca cocida (100g)',
      category: 'Verdura',
      carbsG: 3.6,
      proteinG: 2.7,
      fatG: 0.4,
      calories: 23,
    ),

    // Comidas completas
    'salmon_papas': FoodItem(
      name: 'Salmón (150g) + papas (150g)',
      category: 'Comidas Completas',
      carbsG: 42,
      proteinG: 35,
      fatG: 12,
      calories: 450,
    ),
  };
}

/// Modelo para representar un alimento
class FoodItem {
  final String name;
  final String category;
  final double carbsG;
  final double proteinG;
  final double fatG;
  final double calories;

  FoodItem({
    required this.name,
    required this.category,
    required this.carbsG,
    required this.proteinG,
    required this.fatG,
    required this.calories,
  });
}

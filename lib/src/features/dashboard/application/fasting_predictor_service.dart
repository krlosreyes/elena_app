import 'package:elena_app/src/core/orchestrator/biological_phases.dart';
import 'package:flutter/foundation.dart';

/// SPEC-35: Servicio predictor de fin de ayuno óptimo (Tipado)
/// Utiliza el motor orquestador central para coherencia metabólica
class FastingPredictorService {
  /// RF-35-01: Calcula glucógeno estimado durante ayuno
  /// Fórmula: Glucógeno = 400g - (horasAyuno/24 * 100)
  /// Rango normal: 50-500g
  static double estimateGlycogenLevel(double fastedHours) {
    const maxGlycogen = 400.0;
    const glycogenDepletionRate = 100.0 / 24.0; // 100g por 24 horas

    final estimated = maxGlycogen - (fastedHours * glycogenDepletionRate);
    return estimated.clamp(50.0, 500.0);
  }

  /// RF-35-02: Determina fase de ayuno actual (Sincronizado SPEC-01)
  static FastingPhase determineFastingPhase(double fastedHours) {
    if (fastedHours < 4) return FastingPhase.alerta;
    if (fastedHours < 8) return FastingPhase.gluconeogenesis;
    if (fastedHours < 12) return FastingPhase.cetosis;
    return FastingPhase.autofagia;
  }

  /// RF-35-03: Recomienda momento óptimo para romper ayuno
  /// Considera fase circadiana, glucógeno y recuperación
  /// Retorna: DateTime predicho para ruptura óptima
  static DateTime? predictOptimalBreakTime({
    required double currentFastingHours,
    required CircadianPhase currentCircadianPhase,
    required double sleepQuality,
    required double estimatedGlycogen,
  }) {
    final now = DateTime.now();

    // En fase de SUEÑO, recomienda esperar hasta la mañana
    if (currentCircadianPhase == CircadianPhase.sueno) {
      final tomorrow = now.add(const Duration(days: 1));
      return tomorrow.copyWith(hour: 6, minute: 0);
    }

    // En fase de ALERTA (Mañana), es buen momento
    if (currentCircadianPhase == CircadianPhase.alerta) {
      return now; // Ahora es óptimo
    }

    // En fase COGNITIVA, es muy bueno también
    if (currentCircadianPhase == CircadianPhase.cognitivo) {
      return now;
    }

    // En fase de CREATIVIDAD (Noche), esperar a mañana si el ayuno es corto
    if (currentCircadianPhase == CircadianPhase.creatividad && currentFastingHours < 16) {
      final tomorrow = now.add(const Duration(days: 1));
      return tomorrow.copyWith(hour: 6, minute: 0);
    }

    return null;
  }

  /// RF-35-04: Sugiere perfil de macronutrientes óptimo para ruptura
  /// Retorna 3 opciones (A, B, C) con diferentes estrategias
  static List<MacroOption> suggestBreakfastMacros({
    required FastingPhase currentFastingPhase,
    required CircadianPhase currentCircadianPhase,
    required double estimatedGlycogen,
    required double sleepQuality,
  }) {
    final options = <MacroOption>[];

    if (currentFastingPhase == FastingPhase.autofagia) {
      // En ayuno profundo, estrategia conservadora
      options.add(
        MacroOption(
          name: 'Opción A: Proteína + Grasa (Conservadora)',
          description: 'Proteína pura + grasas. Evita glucosa pura.',
          carbsPercent: 10,
          proteinPercent: 45,
          fatPercent: 45,
          exampleMeal: 'Huevos 3 + aguacate',
          reason: 'Maximiza digestión lenta. Protege glucosa para órganos vitales.',
        ),
      );

      options.add(
        MacroOption(
          name: 'Opción B: Carbos Complejos + Proteína',
          description: 'Carbohidratos complejos con proteína. Regenera glucógeno.',
          carbsPercent: 40,
          proteinPercent: 35,
          fatPercent: 25,
          exampleMeal: 'Avena + proteína + arándanos',
          reason: 'Carbos de lenta absorción. Permite gluconeogénesis gradual.',
        ),
      );

      options.add(
        MacroOption(
          name: 'Opción C: Fruta + Proteína (Segura)',
          description: 'Frutas con fibra + proteína. Equilibrio.',
          carbsPercent: 50,
          proteinPercent: 25,
          fatPercent: 25,
          exampleMeal: 'Plátano + yogur griego',
          reason: 'Carbos naturales con fibra. Absorción controlada.',
        ),
      );
    } else if (currentFastingPhase == FastingPhase.cetosis) {
      // En cetosis, puedes hacer transición gradual
      options.add(
        MacroOption(
          name: 'Opción A: Mantén Cetosis (Grasa primero)',
          description: 'Grasas + proteína. Prolonga estado ceto.',
          carbsPercent: 5,
          proteinPercent: 35,
          fatPercent: 60,
          exampleMeal: 'Salmón + aguacate',
          reason: 'Si quieres mantener cetosis, evita carbos.',
        ),
      );

      options.add(
        MacroOption(
          name: 'Opción B: Salida Gradual (Carbos moderados)',
          description: 'Carbos complejos + proteína. Transición.',
          carbsPercent: 40,
          proteinPercent: 35,
          fatPercent: 25,
          exampleMeal: 'Arroz integral + pollo',
          reason: 'Aumenta carbos gradualmente.',
        ),
      );

      options.add(
        MacroOption(
          name: 'Opción C: Máxima Nutrición',
          description: 'Balance equilibrado. Máximo micronutriente.',
          carbsPercent: 50,
          proteinPercent: 25,
          fatPercent: 25,
          exampleMeal: 'Vegetales + huevos + cereales',
          reason: 'Balance óptimo de nutrientes.',
        ),
      );
    } else {
      // En fases tempranas (ALERTA, GLUCONEOGENESIS), flexibilidad total
      options.add(
        MacroOption(
          name: 'Opción A: Carbos Rápidos (Refuerzo)',
          description: 'Carbos simples. Recuperación rápida.',
          carbsPercent: 60,
          proteinPercent: 20,
          fatPercent: 20,
          exampleMeal: 'Arroz + pollo + plátano',
          reason: 'Máxima glucosa disponible. Mejor si hiciste ejercicio.',
        ),
      );

      options.add(
        MacroOption(
          name: 'Opción B: Equilibrio (Estándar)',
          description: 'Distribución balanceada.',
          carbsPercent: 45,
          proteinPercent: 30,
          fatPercent: 25,
          exampleMeal: 'Pasta + pechuga + verduras',
          reason: 'Balance ideal para mayoría de situaciones.',
        ),
      );

      options.add(
        MacroOption(
          name: 'Opción C: Bajo Carbo (Control)',
          description: 'Proteína y grasa. Mínimos carbos.',
          carbsPercent: 20,
          proteinPercent: 50,
          fatPercent: 30,
          exampleMeal: 'Carne + verduras + aceite',
          reason: 'Si controlas crecimiento rápido de glucosa.',
        ),
      );
    }

    return options;
  }

  /// RF-35-05: Registra resultado de ruptura de ayuno para retroalimentación
  static void recordBreakResult({
    required int fastingDuration,
    required String chosenMacroProfile,
    required double glucoseLevelPostMeal,
    required String userFeedback,
  }) {
    debugPrint(
      '📊 SPEC-35-05: Resultado de ruptura registrado.\n'
      'Duración ayuno: ${fastingDuration}h\n'
      'Macros elegidos: $chosenMacroProfile\n'
      'Glucosa post-comida: ${glucoseLevelPostMeal.toStringAsFixed(1)} mg/dL\n'
      'Feedback: $userFeedback',
    );
  }

  /// Valida si es seguro romper el ayuno ahora
  static bool canBreakFastNow({
    required FastingPhase currentFastingPhase,
    required CircadianPhase currentCircadianPhase,
    required double sleepQuality,
  }) {
    // En fase de SUEÑO no es recomendado alimentarse
    if (currentCircadianPhase == CircadianPhase.sueno) {
      return false;
    }

    // En Autofagia con calidad de sueño muy baja, prolongar recuperación
    if (currentFastingPhase == FastingPhase.autofagia && sleepQuality < 0.4) {
      return false;
    }

    return true;
  }

  /// Determina si es óptimo para ayunar
  static bool isOptimalForFasting({
    required FastingPhase fastingPhase,
    required double sleepQuality,
  }) {
    final isDeepFasting = fastingPhase == FastingPhase.cetosis ||
        fastingPhase == FastingPhase.autofagia;
    return isDeepFasting && sleepQuality > 0.6;
  }
}

/// Modelo para opción de macronutrientes
class MacroOption {
  final String name;
  final String description;
  final int carbsPercent;
  final int proteinPercent;
  final int fatPercent;
  final String exampleMeal;
  final String reason;

  MacroOption({
    required this.name,
    required this.description,
    required this.carbsPercent,
    required this.proteinPercent,
    required this.fatPercent,
    required this.exampleMeal,
    required this.reason,
  });

  int get totalPercent => carbsPercent + proteinPercent + fatPercent;
}

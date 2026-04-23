import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:elena_app/src/features/fasting/domain/models/fasting_prediction.dart';

/// SPEC-35: Servicio de predicción de momento óptimo para romper ayuno
class FastingPredictorService {
  /// Calcula predicción de fin de ayuno
  /// RF-35-01: Estimar glucógeno basado en duración + historial
  /// RF-35-02: Sugerir 3 opciones macro con glucemia
  /// RF-35-03: Ajustar según circadiano
  /// RF-35-04: Calcular momento óptimo
  static FastingPrediction calculatePrediction({
    required String userId,
    required int fastedHours,
    required String currentFastingPhase,
    required String currentCircadianPhase,
    required double? lastMealCarbsG,
    required double? lastMealProteinG,
    required double? lastMealFatG,
    required List<int>? last7DaysCarbsAverage,
    required double sleepRecoveryScore,
  }) {
    // RF-35-01: Estimar glucógeno
    // Formula: glucógeno_estimado = 400g - (fastedHours / 24 * 100)
    // Máximo: 500g (glucógeno almacenado típico)
    // Mínimo: 50g (estado crítico)
    final baseGlycogen = 400.0;
    final glycogenDepletion = (fastedHours / 24.0) * 100.0;
    final estimatedGlycogen = (baseGlycogen - glycogenDepletion).clamp(50.0, 500.0);

    debugPrint('📊 SPEC-35: Glucógeno estimado=$estimatedGlycogen g, fastedHours=$fastedHours');

    // RF-35-03: Determinar tiempo óptimo según circadiano
    // ALERTA (6-9): NO es óptimo comer muchos carbs
    // ENERGÍA (9-14): Es óptimo comer casi cualquier cosa
    // CREPÚSCULO (14-18): Cardohidratos algo menos tolerados
    // SUEÑO (18-22): NO es óptimo comer
    // LIMPIEZA (22-6): Pobre metabolismo
    final now = DateTime.now();
    DateTime optimalBreakTime = now;
    String recommendedCircadianPhase = currentCircadianPhase;

    switch (currentCircadianPhase) {
      case 'ALERTA': // 6-9 AM
        // Esperar a ENERGÍA
        optimalBreakTime = now.add(const Duration(hours: 3));
        recommendedCircadianPhase = 'ENERGÍA';
        break;
      case 'ENERGÍA': // 9 AM - 2 PM
        // ES ÓPTIMO AHORA
        optimalBreakTime = now;
        break;
      case 'CREPÚSCULO': // 2 PM - 6 PM
        // Es subóptimo pero tolerable
        optimalBreakTime = now;
        break;
      case 'SUEÑO': // 6 PM - 10 PM
        // Esperar a mañana ENERGÍA
        optimalBreakTime = now.add(const Duration(hours: 12));
        recommendedCircadianPhase = 'ENERGÍA';
        break;
      case 'LIMPIEZA': // 10 PM - 6 AM
        // Esperar a ALERTA y luego ENERGÍA
        optimalBreakTime = now.add(const Duration(hours: 9));
        recommendedCircadianPhase = 'ENERGÍA';
        break;
    }

    // RF-35-04: Calcular momento óptimo basado en glucógeno
    // Si glucógeno < 100g: Urgente romper (pero con macro A=low-carb)
    // Si glucógeno 100-200g: Óptimo romper en 30-60 min
    // Si glucógeno > 200g: Puede esperar, pero si en Cetosis >12h, es buen momento
    bool isOptimalNow = false;
    int minutesUntilOptimal = 0;

    if (estimatedGlycogen < 100.0) {
      // Glucógeno crítico - romper ASAP pero con cuidado
      optimalBreakTime = now;
      isOptimalNow = true;
      minutesUntilOptimal = 0;
      debugPrint('🚨 SPEC-35: Glucógeno crítico (<100g). Romper ahora con Opción A');
    } else if (estimatedGlycogen < 200.0 && currentFastingPhase == 'CETOSIS') {
      // Cetosis + glucógeno bajo = óptimo para romper
      optimalBreakTime = now.add(const Duration(minutes: 30));
      minutesUntilOptimal = 30;
      debugPrint('✅ SPEC-35: Óptimo para romper en 30 min (Cetosis + glucógeno bajo)');
    } else if (currentFastingPhase == 'AUTOFAGIA' && estimatedGlycogen < 150.0) {
      // Autofagia profunda - romper con urgencia
      optimalBreakTime = now;
      isOptimalNow = true;
      minutesUntilOptimal = 0;
      debugPrint('⚠️  SPEC-35: Autofagia profunda. Romper ahora con cuidado');
    } else {
      // Situación normal: esperar a circadiano óptimo
      minutesUntilOptimal =
          optimalBreakTime.difference(now).inMinutes.clamp(0, 1440);
    }

    // RF-35-02: Generar 3 opciones macro
    final macroOptions = _generateMacroOptions(
      estimatedGlycogen: estimatedGlycogen,
      currentFastingPhase: currentFastingPhase,
      currentCircadianPhase: currentCircadianPhase,
      sleepRecoveryScore: sleepRecoveryScore,
    );

    // Seleccionar opción recomendada según contexto
    String suggestedMacroProfile = 'B'; // Default = balanced
    String glucemicResponse = 'MEDIA';

    if (estimatedGlycogen < 150.0) {
      // Bajo glucógeno: recomendar baja en carbs
      suggestedMacroProfile = 'A';
      glucemicResponse = 'BAJA';
    } else if (currentFastingPhase == 'AUTOFAGIA' || currentCircadianPhase == 'ALERTA') {
      // Autofagia o ALERTA phase: baja en carbs
      suggestedMacroProfile = 'A';
      glucemicResponse = 'BAJA';
    } else if (currentCircadianPhase == 'ENERGÍA' && sleepRecoveryScore > 0.7) {
      // ENERGÍA + buen sueño: puede tolerar más carbs
      suggestedMacroProfile = 'C';
      glucemicResponse = 'ALTA';
    } else {
      suggestedMacroProfile = 'B';
      glucemicResponse = 'MEDIA';
    }

    // Calcular confianza del predictor
    // Basada en: duración del ayuno + historial + sleep recovery
    // Máximo: 0.95 (nunca 1.0 porque siempre hay incertidumbre)
    double confidence = 0.6;
    if (fastedHours > 12 && fastedHours < 24) confidence += 0.2; // Rango común
    if (sleepRecoveryScore > 0.6) confidence += 0.1; // Buen sueño = más confiable
    confidence = confidence.clamp(0.5, 0.95);

    debugPrint(
        '✅ SPEC-35: Predicción generada. Macro=$suggestedMacroProfile, Glucemia=$glucemicResponse, Confianza=${(confidence * 100).toStringAsFixed(1)}%');

    return FastingPrediction(
      id: const Uuid().v4(),
      userId: userId,
      generatedAt: DateTime.now(),
      fastedHours: fastedHours,
      estimatedGlycogen: estimatedGlycogen,
      currentFastingPhase: currentFastingPhase,
      currentCircadianPhase: currentCircadianPhase,
      optimalBreakTime: optimalBreakTime,
      suggestedMacroProfile: suggestedMacroProfile,
      glucemicResponse: glucemicResponse,
      confidence: confidence,
      minutesUntilOptimal: minutesUntilOptimal,
      macroOptions: macroOptions,
    );
  }

  /// Genera 3 opciones de macros para ruptura de ayuno
  /// A = Proteína+Grasas (bajo carb), B = Balanced, C = Alto carb
  static List<MacroOption> _generateMacroOptions({
    required double estimatedGlycogen,
    required String currentFastingPhase,
    required String currentCircadianPhase,
    required double sleepRecoveryScore,
  }) {
    return [
      // Opción A: Bajo carb - proteína + grasas
      MacroOption(
        profile: 'A',
        suggestedCarbs: 20.0,
        suggestedProtein: 30.0,
        suggestedFat: 15.0,
        estimatedCalories: 350,
        glucemicResponse: 'BAJA',
        description:
            'Proteína + Grasa (bajo carb). Ideal después de ayuno profundo. Absorción lenta = no spike.',
        foodExamples: [
          'Pollo 100g + aguacate',
          'Huevos 3 + mantequilla',
          'Salmón 80g + aceite de oliva',
          'Queso + almendras'
        ],
        confidence: 0.95,
      ),
      // Opción B: Balanced - carbs + proteína + grasa
      MacroOption(
        profile: 'B',
        suggestedCarbs: 50.0,
        suggestedProtein: 25.0,
        suggestedFat: 12.0,
        estimatedCalories: 470,
        glucemicResponse: 'MEDIA',
        description:
            'Balanceado. Carbohidratos moderados + proteína. Buena absorción sin spike.',
        foodExamples: [
          'Pollo 100g + arroz integral 150g',
          'Huevos 2 + pan integral + mantequilla',
          'Yogur griego + granola + fruta',
          'Pasta integral + tomate + pechuga'
        ],
        confidence: 0.85,
      ),
      // Opción C: Alto carb - más carbohidratos
      MacroOption(
        profile: 'C',
        suggestedCarbs: 80.0,
        suggestedProtein: 20.0,
        suggestedFat: 8.0,
        estimatedCalories: 540,
        glucemicResponse: 'ALTA',
        description:
            'Alto en carbs. Ideal si glucógeno muy bajo + ENERGÍA phase + buen sueño.',
        foodExamples: [
          'Arroz blanco 200g + huevo',
          'Plátano grande + granola + miel',
          'Avena 60g + miel + fruta',
          'Papa 250g + queso + huevo'
        ],
        confidence: 0.7,
      ),
    ];
  }

  /// Registra el feedback después de romper el ayuno
  /// RF-35-05: Registrar predicción con resultado real
  static FastingPrediction recordBreakResult({
    required FastingPrediction prediction,
    required DateTime actualBreakTime,
    required String actualMacroChoice,
    required int energyLevel, // 1-10
    String? userNotes,
  }) {
    final minutesDifference = actualBreakTime.difference(prediction.optimalBreakTime).inMinutes.abs();

    debugPrint(
        '📝 SPEC-35: Ruptura registrada. Macro=$actualMacroChoice, Energía=$energyLevel/10, Diferencia=${minutesDifference}min vs óptimo');

    return prediction.copyWith(
      hasBeenBroken: true,
      actualBreakTime: actualBreakTime,
      actualMacroChoice: actualMacroChoice,
      userEnergyLevel: energyLevel,
      userNotes: userNotes,
    );
  }
}

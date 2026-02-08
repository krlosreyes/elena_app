import '../../profile/domain/user_model.dart';
import '../../plan/domain/health_plan.dart';
import '../domain/recommendation_plan.dart';

class ElenaBrain {
  /// Genera un [RecommendationPlan] personalizado basado en el [UserModel].
  static RecommendationPlan generatePlan(UserModel user) {
    // 1. Hidratación (Fórmula: Peso / 7 = Vasos de 250ml)
    // Convertimos a litos: (Peso / 7) * 0.25
    final dailyWaterIntres = (user.currentWeightKg / 7) * 0.25;

    // 2. Protocolo de Ayuno
    String protocol;
    String fastDescription;

    int fastingHours;
    int eatingWindowHours;

    switch (user.fastingExperience) {
      case FastingExperience.advanced:
        protocol = '16:8';
        fastingHours = 16;
        eatingWindowHours = 8;
        fastDescription = 'Ayuno de 16 horas. Ventana de comida de 8 horas.';
        break;
      case FastingExperience.intermediate:
        protocol = '14:10';
        fastingHours = 14;
        eatingWindowHours = 10;
        fastDescription = 'Ayuno de 14 horas. Ventana de comida de 10 horas.';
        break;
      case FastingExperience.beginner:
      default:
        protocol = '12:12';
        fastingHours = 12;
        eatingWindowHours = 12;
        fastDescription = 'Ayuno básico de 12 horas. Descanso digestivo nocturno.';
        break;
    }

    // Cálculo de Ventana de Alimentación
    // Última Comida = Hora Dormir - 3 horas
    final bedTimeParts = user.bedTime.split(':').map(int.parse).toList();
    final bedDateTime = DateTime(2024, 1, 1, bedTimeParts[0], bedTimeParts[1]);
    
    final lastMealTime = bedDateTime.subtract(const Duration(hours: 3));
    final firstMealTime = lastMealTime.subtract(Duration(hours: eatingWindowHours));
    
    // Formateo HH:mm
    String _formatTime(DateTime dt) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }

    final windowStart = _formatTime(firstMealTime);
    final windowEnd = _formatTime(lastMealTime);

    // 3. Ejercicio (Fórmula MAF 180)
    final age = DateTime.now().year - user.birthDate.year;
    int mafHeartRate = 180 - age;

    // Corrección Maffetone (Patologías o Sedentarismo)
    final hasPathologies = user.pathologies.isNotEmpty && !user.pathologies.contains('none');
    final isSedentary = user.activityLevel == ActivityLevel.sedentary;

    if (hasPathologies || isSedentary) {
      mafHeartRate -= 5;
    }

    final exerciseDesc =
        'Ejercicio en Zona 2 (Caminar rápido/Trotar) manteniendo tu ritmo cardiaco por debajo de $mafHeartRate ppm para máxima oxidación de grasa.';

    // 4. Monitoreo de Glucosa
    // Riesgo metabólico: Patologías clave o Cintura/Altura > 0.55
    final isMetabolicRisk = _hasMetabolicRisk(user);
    final waistToHeightRatio = user.waistCircumferenceCm / user.heightCm;

    bool requiresGlucometer = false;
    String? glucoseTargetFasting;
    String? glucoseTargetPostMeal;
    String? monitoringFocusMessage;

    if (isMetabolicRisk || waistToHeightRatio > 0.55) {
      requiresGlucometer = true;
      glucoseTargetFasting = '< 100 mg/dL';
      glucoseTargetPostMeal = '< 140 mg/dL (2h post-comida)';
      monitoringFocusMessage =
          'Es vital que midas tu reacción a los carbohidratos. Consigue un glucómetro para conocer tu cuerpo.';
    }

    return RecommendationPlan(
      dailyWaterIntakeLitres: double.parse(dailyWaterIntres.toStringAsFixed(1)),
      recommendedFastingProtocol: protocol,
      fastingWindowDescription: fastDescription,
      recommendedEatingWindowStart: windowStart,
      recommendedEatingWindowEnd: windowEnd,
      exerciseZoneHeartRate: mafHeartRate,
      exerciseFrequency: 'Caminata 45min diarios o ejercicio suave',
      exerciseDescription: exerciseDesc,
      requiresGlucometer: requiresGlucometer,
      glucoseTargetFasting: glucoseTargetFasting,
      glucoseTargetPostMeal: glucoseTargetPostMeal,
      monitoringFocusMessage: monitoringFocusMessage,
      generatedAt: DateTime.now(),
    );
  }

  /// Genera un [HealthPlan] clínico detallado.
  static HealthPlan generateHealthPlan(UserModel user) {
    // 1. Métricas Base (Reutilizamos lógica simple)
    final dailyWaterGlasses = (user.currentWeightKg / 7).round();
    
    // MAF 180 Calculation
    int age = DateTime.now().year - user.birthDate.year;
    int maf = 180 - age;
    if (_hasMetabolicRisk(user) || user.activityLevel == ActivityLevel.sedentary) {
      maf -= 5;
    }

    // 2. Lógica de Protocolo
    String protocol = '12:12';
    if (user.fastingExperience == FastingExperience.advanced) protocol = '16:8';
    if (user.fastingExperience == FastingExperience.intermediate) protocol = '14:10';

    // 3. Estrategia de Ejercicio
    String exStrategy = 'Caminata en Zona 2';
    String exFreq = '45 min diarios';
    
    // Reglas Clínicas de Ejercicio
    if (user.physicalLimitations.contains('joint_pain') || user.physicalLimitations.contains('knee_pain')) {
      exStrategy = 'Bajo Impacto (Natación / Elíptica)';
      exFreq = '30 min diarios suave';
    } else if (user.activityLevel == ActivityLevel.sedentary) {
      exStrategy = 'Caminata a paso ligero constante';
      exFreq = '30 min diarios (progresivo)';
    } else if (user.activityLevel == ActivityLevel.heavy) {
      exStrategy = 'Entrenamiento de Fuerza + Zona 2';
      exFreq = '3-4 veces por semana pesas + caminata diaria';
    }

    // Regla de Resistencia a la Insulina (Caminar post-comida)
    if (_hasPathology(user, 'insulin_resistance') || _hasPathology(user, 'diabetes')) {
      exFreq += '. Añadir 15 min de caminata después de cada comida fuerte.';
    }

    // 4. Estrategia de Nutrición
    String nutStrategy = 'Alimentación Balanceada Real';
    String breakFast = 'Huevos, Aguacate o Caldo de Huesos. Evitar fruta sola.';
    String why = 'Para optimizar tu metabolismo y energía.';

    // Regla de Cintura/Altura (Riesgo Metabólico fuerte)
    final waistRatio = user.waistCircumferenceCm / user.heightCm;
    if (waistRatio > 0.55 || _hasMetabolicRisk(user)) {
      nutStrategy = 'Estrategia Cero Snacks. Dieta 3x1 o Low Carb estricto.';
      why = 'Tu perímetro abdominal indica resistencia a la insulina. Necesitamos bajar la frecuencia de insulina, no solo calorías.';
    } else if (user.dietaryPreference == DietaryPreference.keto) {
      nutStrategy = 'Keto Limpio (Grasas saludables, no procesados)';
      breakFast = 'Café bombón o Huevos con tocino.';
    }

    // Regla de Prediabetes (Orden de Alimentos)
    if (_hasPathology(user, 'prediabetes') || _hasPathology(user, 'diabetes')) {
      nutStrategy += '. Orden: 1. Vegetales -> 2. Proteína/Grasa -> 3. Carbos.';
    }

    // 5. Estrategia de Glucosa
    String? glucStrategy;
    if (_hasMetabolicRisk(user) || waistRatio > 0.55) {
      glucStrategy = 'Meta ayunas < 100 mg/dL. Meta 2h post-comida < 140 mg/dL. Elimina agresores.';
    }

    return HealthPlan(
      protocol: protocol,
      hydrationGoal: dailyWaterGlasses,
      maxHeartRate: maf,
      exerciseStrategy: exStrategy,
      exerciseFrequency: exFreq,
      nutritionStrategy: nutStrategy,
      breakingFastTip: breakFast,
      glucoseStrategy: glucStrategy,
      whyThisPlan: why,
      generatedAt: DateTime.now(),
    );
  }

  static bool _hasMetabolicRisk(UserModel user) {
    const riskPathologies = [
      'prediabetes',
      'diabetes',
      'insulin_resistance',
      'metabolic_syndrome',
      'pcos',
    ];
    return user.pathologies.any((p) => riskPathologies.contains(p.toLowerCase()));
  }

  static bool _hasPathology(UserModel user, String key) {
    return user.pathologies.contains(key);
  }
}

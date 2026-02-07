import '../../profile/domain/user_model.dart';
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

    switch (user.fastingExperience) {
      case FastingExperience.advanced:
        protocol = '16:8';
        fastDescription = 'Ayuno de 16 horas. Ventana de comida de 8 horas.';
        break;
      case FastingExperience.intermediate:
        protocol = '14:10';
        fastDescription = 'Ayuno de 14 horas. Ventana de comida de 10 horas.';
        break;
      case FastingExperience.beginner:
      default:
        protocol = '12:12';
        fastDescription = 'Ayuno básico de 12 horas. Descanso digestivo nocturno.';
        break;
    }

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
    final isMetabolicRisk = _checkMetabolicRisk(user);
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

  static bool _checkMetabolicRisk(UserModel user) {
    const riskPathologies = [
      'prediabetes',
      'diabetes',
      'insulin_resistance',
      'metabolic_syndrome',
      'hypothyroidism', // A menudo relacionado
      'pcos', // Ovario poliquístico
    ];

    for (final pathology in user.pathologies) {
      if (riskPathologies.contains(pathology.toLowerCase())) {
        return true;
      }
    }
    return false;
  }
}

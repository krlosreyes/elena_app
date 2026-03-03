import '../../profile/domain/user_model.dart';
import '../../plan/domain/health_plan.dart';


class ElenaBrain {

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
    
    // Regla: Si hay resistencia a la insulina, forzar o sugerir 16:8
    if (_hasPathology(user, 'insulin_resistance') || _hasPathology(user, 'prediabetes')) {
      protocol = '16:8';
    }

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

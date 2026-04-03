import 'dart:math';

import 'package:elena_app/src/shared/domain/models/health_plan.dart';
import 'package:elena_app/src/shared/domain/models/mti_model.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';

/// ✅ ELENA BRAIN V2.0 (Metabolic Precision Engine)
///
/// Refined for: Metabolic Flexibility, Sarcopenia Prevention, and Insulin Control.
/// Logic: Uses Katch-McArdle when Body Fat is available for superior TDEE accuracy.
class ElenaBrain {
  // ... rest of header ...
  static const double minHeightCm = 50.0;
  static const double minWeightKg = 30.0;
  static const double minBmrFloor = 1200.0; // Absolute safety floor
  static const double metabolicStressMultiplier = 1.07;

  // TODO: Remove in Phase 4 cleanup
  /// MTI Classification Engine
  static MtiClassification classifyMtiScore(double score) {
    if (score <= 30) return MtiClassification.highRisk;
    if (score <= 50) return MtiClassification.warning;
    if (score <= 70) return MtiClassification.moderate;
    if (score <= 85) return MtiClassification.good;
    return MtiClassification.optimal;
  }

  // --- 1. Clinical Anthropometry & Body Composition ---

  // TODO: Remove in Phase 4 – duplicated metabolic logic
  // BMI calculation is duplicated here and consumed by MetabolicProfile.fromUser.
  // Phase 4: move to core/science/MetabolicEngine as single source of truth.
  static double calculateBMI(double weightKg, double heightCm) {
    if (heightCm < minHeightCm) return 0.0;
    return (weightKg / pow(heightCm / 100, 2)).clamp(10.0, 60.0);
  }

  // TODO: Remove in Phase 4 – duplicated metabolic logic
  // WHtR is identical to core/science/MetabolicEngine.calculateMetaICA.
  static double calculateWHtR(double? waistCm, double heightCm) {
    if (waistCm == null || heightCm < minHeightCm) return 0.0;
    return (waistCm / heightCm).clamp(0.2, 1.2);
  }

  // TODO: Remove in Phase 4 – duplicated metabolic logic
  // WHR is identical to core/science/MetabolicEngine.calculateMetaICC.
  /// Calculates Waist-to-Hip Ratio (WHR).
  static double calculateWHR(double? waistCm, double? hipCm) {
    if (waistCm == null || hipCm == null || hipCm <= 1.0) return 0.0;
    return (waistCm / hipCm).clamp(0.4, 1.5);
  }

  // TODO: Remove in Phase 4 – duplicated metabolic logic
  // Body fat (US Navy) should live in core/science/MetabolicEngine.
  /// US Navy Formula - High Authority Precision
  static double? calculateBodyFat({
    required double heightCm,
    required double? waistCm,
    required double? neckCm,
    double? hipCm,
    required bool isMale,
  }) {
    if (waistCm == null ||
        neckCm == null ||
        heightCm < minHeightCm ||
        waistCm < 20.0 ||
        neckCm < 10.0) {
      return null;
    }

    try {
      double bf;
      if (isMale) {
        final diff = waistCm - neckCm;
        if (diff <= 1.0) return null;
        bf = 495 /
                (1.0324 -
                    0.19077 * (log(diff) / ln10) +
                    0.15456 * (log(heightCm) / ln10)) -
            450;
      } else {
        if (hipCm == null || hipCm <= 10.0) return null;
        final diff = waistCm + hipCm - neckCm;
        if (diff <= 1.0) return null;
        bf = 495 /
                (1.29579 -
                    0.35004 * (log(diff) / ln10) +
                    0.22100 * (log(heightCm) / ln10)) -
            450;
      }
      return bf.clamp(3.0, 60.0);
    } catch (_) {
      return null;
    }
  }

  // TODO: Remove in Phase 4 – duplicated metabolic logic
  // Alias duplicates calculateBodyFat above.
  /// Alias for calculateBodyFat for automated calls
  static double? calculateFatPercentage({
    required double heightCm,
    required double? waistCm,
    required double? neckCm,
    double? hipCm,
    required bool isMale,
  }) =>
      calculateBodyFat(
        heightCm: heightCm,
        waistCm: waistCm,
        neckCm: neckCm,
        hipCm: hipCm,
        isMale: isMale,
      );

  /// Calculates estimated muscle mass percentage based on lean mass.
  static double? calculateMuscleMass({
    required double? fatPercentage,
  }) {
    if (fatPercentage == null) return null;
    final leanMassPct = 100.0 - fatPercentage;
    // Skeletal muscle is roughly 78% of lean body mass in healthy individuals.
    return (leanMassPct * 0.78).clamp(20.0, 60.0);
  }

  // --- 2. Advanced Metabolic Engine ---

  // TODO: Remove in Phase 4 – duplicated metabolic logic
  // BMR (Katch-McArdle / Mifflin-St Jeor) should live in core/science/MetabolicEngine.
  /// BMR Logic: Prefers Katch-McArdle (Lean Mass based) over Mifflin-St Jeor.
  static double calculateBMR(UserModel user) {
    final bf = calculateBodyFat(
      heightCm: user.heightCm,
      waistCm: user.waistCircumferenceCm,
      neckCm: user.neckCircumferenceCm,
      hipCm: user.hipCircumferenceCm,
      isMale: user.gender == Gender.male,
    );

    double bmr;
    if (bf != null) {
      // Katch-McArdle: More accurate for metabolic health
      final leanMass = user.currentWeightKg * (1 - (bf / 100));
      bmr = 370 + (21.6 * leanMass);
    } else {
      // Fallback: Mifflin-St Jeor
      bmr = (10 * user.currentWeightKg) +
          (6.25 * user.heightCm) -
          (5 * user.age) +
          (user.gender == Gender.male ? 5 : -161);
    }

    // Ajuste para compensar el gasto energético derivado de la inflamación crónica de bajo grado.
    if (_hasMetabolicRisk(user)) bmr *= metabolicStressMultiplier;

    return bmr;
  }

  // TODO: Remove in Phase 4 cleanup
  // TODO: Remove in Phase 4 – duplicated metabolic logic
  // Macro calculation duplicates nutrition/MetabolicEngine.generate pipeline.
  static Map<String, double> calculateMacros(UserModel user) {
    final bmr = calculateBMR(user);
    final tdee = bmr * _getActivityMultiplier(user.activityLevel);

    // Strategy: Insulin Resistance = Lower Deficit to protect Cortisol
    double deficitFactor = _hasMetabolicRisk(user) ? 0.10 : 0.20;
    double targetCalories = tdee * (1.0 - deficitFactor);

    // CRITICAL: Safety Floor (Never below BMR to avoid metabolic damage)
    targetCalories = max(targetCalories, bmr);
    targetCalories = max(targetCalories, minBmrFloor);

    double p, c, f;
    final whtr = calculateWHtR(user.waistCircumferenceCm, user.heightCm);

    if (user.dietaryPreference == DietaryPreference.keto) {
      p = 1.8 * user.currentWeightKg * 4; // High protein to protect muscle
      c = 25.0 * 4; // Strict 25g net carbs
      f = targetCalories - p - c;
    } else if (whtr > 0.52 || _hasMetabolicRisk(user)) {
      // Low Carb / Insulin Control (40% Fat, 35% Prot, 25% Carb)
      p = (targetCalories * 0.35);
      c = (targetCalories * 0.25);
      f = targetCalories - p - c;
    } else {
      // Balanced Metabolic (30% Prot, 35% Carb, 35% Fat)
      p = (targetCalories * 0.30);
      c = (targetCalories * 0.35);
      f = targetCalories - p - c;
    }

    return {
      'calories': targetCalories.roundToDouble(),
      'protein': (p / 4).roundToDouble(),
      'carbs': (c / 4).roundToDouble(),
      'fats': (f / 9).roundToDouble(),
    };
  }

  /// Estimates macros based on portions that prioritize metabolic control.
  static Map<String, int> estimateMacrosFromFoods(List<String> foods) {
    int p = 0;
    int c = 0;
    int f = 0;
    for (final food in foods) {
      final l = food.toLowerCase();
      if (l.contains('huevo') || l.contains('carne') || l.contains('pollo')) {
        p += 25;
        f += 5;
      } else if (l.contains('aguacate') || l.contains('nuez')) {
        f += 15;
        p += 2;
      } else if (l.contains('arroz') || l.contains('papa')) {
        c += 35;
        p += 3;
      } else if (l.contains('brócoli') || l.contains('fibra')) {
        c += 5;
      }
    }
    return {
      'calories': (p * 4) + (c * 4) + (f * 9),
      'protein': p,
      'carbs': c,
      'fats': f
    };
  }

  // TODO: Remove in Phase 4 cleanup
  // TODO: Remove in Phase 4 – duplicated metabolic logic
  // Metabolic phase mirrors core/science/MetabolicEngine.calculateZone.
  /// Provides a qualitative state of the current metabolism.
  static String getMetabolicPhase(
      int p, int c, int f, Duration fastingElapsed) {
    if (fastingElapsed.inHours > 16) return "AUTOFAGIA";
    if (fastingElapsed.inHours > 12) return "LIPÓLISIS";
    if (c > 50 && c > p) return "INSULINA ALTA";
    if (p > 40 && c < 30) return "ANABOLISMO";
    return "EQUILIBRIO";
  }

  // --- 3. MTI (Metabolic Terrain Index) & Sarcopenia ---

  static double calculateSarcopeniaRisk(UserModel user) {
    final bf = calculateBodyFat(
      heightCm: user.heightCm,
      waistCm: user.waistCircumferenceCm,
      neckCm: user.neckCircumferenceCm,
      isMale: user.gender == Gender.male,
    );

    if (bf == null) return 50.0; // Uncertainty risk

    double muscleMassPct = 100 - bf;
    // Age factor: Risk increases non-linearly after 45
    double ageFactor = pow((user.age - 35).clamp(0, 60) / 15, 1.5).toDouble();

    double muscleDeficit =
        (user.gender == Gender.male ? 75 - muscleMassPct : 65 - muscleMassPct)
            .clamp(0, 30);
    double activityPenalty =
        user.activityLevel == ActivityLevel.sedentary ? 20 : 0;

    return (ageFactor * 2.5 + muscleDeficit * 3.0 + activityPenalty)
        .clamp(0.0, 100.0);
  }

  // TODO: Remove in Phase 4 cleanup
  static double calculateTotalMTI(
    UserModel user, {
    double? realTimeFastingHours,
    double? realTimeNutritionScore,
    double? realTimeExerciseScore,
    double? realTimeSleepHours,
    double? realTimeHydrationScore,
  }) {
    final isMale = user.gender == Gender.male;
    final b = calculateBodyScore(
      user.waistCircumferenceCm,
      user.heightCm,
      user.hipCircumferenceCm ?? ((user.waistCircumferenceCm ?? 0.0) * 1.1),
      user.neckCircumferenceCm,
      isMale,
    );

    final fastingHours = realTimeFastingHours ??
        calculateFastingHours(user.usualFirstMealTime, user.usualLastMealTime);
    final m = calculateMetabolicScore(fastingHours, user.energyLevel1To10 ?? 7);

    final nutritionScore = realTimeNutritionScore ??
        (user.snackingHabit == SnackingHabit.never
            ? 90.0
            : (user.snackingHabit == SnackingHabit.sometimes ? 70.0 : 40.0));

    final exerciseScore =
        realTimeExerciseScore ?? getActivityScore(user.activityLevel);

    final h = calculateLifestyleScore(
      nutritionScore,
      exerciseScore,
      realTimeSleepHours ?? user.averageSleepHours ?? 7.5,
      realTimeHydrationScore ?? 0.0,
    );

    final score = (100.0 * (0.4 * b + 0.3 * m + 0.3 * h));
    if (score.isNaN || score.isInfinite) return 50.0;
    return score.clamp(0.0, 100.0);
  }

  // TODO: Remove in Phase 4 cleanup
  static double calculateMTIForUser(UserModel user) => calculateTotalMTI(user);

  // TODO: Remove in Phase 4 cleanup
  static double calculateBodyScore(double? waistCm, double heightCm,
      double? hipCm, double? neckCm, bool isMale) {
    if (waistCm == null || waistCm < 1.0 || heightCm <= 0) {
      return 0.5; // Default safe middle score
    }
    final whtr = waistCm / heightCm;
    final s1 = (1.0 - ((whtr - 0.45).abs() / 0.15)).clamp(0.0, 1.0);

    final whr = (hipCm != null && hipCm > 1.0)
        ? (waistCm / hipCm)
        : (waistCm / (waistCm * 1.1));

    final idealWhr = isMale ? 0.90 : 0.82;
    final s2 = (1.0 - ((whr - idealWhr).abs() / 0.2)).clamp(0.0, 1.0);

    final s3 = (neckCm != null && neckCm > 1.0)
        ? (1.0 - ((neckCm / heightCm - 0.23).abs() / 0.1)).clamp(0.0, 1.0)
        : 0.5;

    final bodyScore = (s1 + s2 + s3) / 3.0;
    return bodyScore.isNaN ? 0.5 : bodyScore;
  }

  // TODO: Remove in Phase 4 cleanup
  static double calculateMetabolicScore(
      double avgFastingHours, int energyLevel1To10) {
    final s4 = 1.0 / (1.0 + exp(-(avgFastingHours - 14.0) / 2.0));
    final s5 = (energyLevel1To10.clamp(1, 10)) / 10.0;
    return (0.6 * s4) + (0.4 * s5);
  }

  // TODO: Remove in Phase 4 cleanup
  static double calculateLifestyleScore(
      double nutritionScore, double exerciseScore, double sleepHours,
      [double hydrationScore = 50.0]) {
    final s6 = (nutritionScore.clamp(0.0, 100.0)) / 100.0;
    final s7 = (exerciseScore.clamp(0.0, 100.0)) / 100.0;
    final s8 = (1.0 - ((sleepHours - 8.0).abs() / 4.0)).clamp(0.0, 1.0);
    final s9 = (hydrationScore.clamp(0.0, 100.0)) / 100.0;
    return (0.35 * s6) + (0.35 * s7) + (0.2 * s8) + (0.1 * s9);
  }

  // TODO: Remove in Phase 4 cleanup
  /// ✅ 🧠 Cálculo Circadiano de Calidad de Sueño (Protocolo 20/20)
  static const double sleepLatency =
      20.0; // Minutos estimados para conciliar el sueño

  static double calculateSleepQuality({
    required DateTime checkIn, // Hora real de inicio (en la cama)
    required DateTime checkOut, // Hora real de despertar
    required String? targetSleepTime, // Meta p.ej "23:00"
    required String? targetWakeTime, // Meta p.ej "07:00"
    DateTime? lastMealTime, // Sincronización con Nutrición
  }) {
    // 1. Latency Engine: Restar latencia del tiempo total
    final sleepStart = checkIn.add(Duration(minutes: sleepLatency.toInt()));
    final double durationHours =
        checkOut.difference(sleepStart).inMinutes / 60.0;

    // Puntuación duración: Meta 7.5h (5 ciclos 90min)
    final double durationScore = (durationHours / 7.5).clamp(0.0, 1.0) * 100;

    // 2. Consistencia (40% del Score)
    double consistencyScore = 100.0;
    if (targetSleepTime != null && targetWakeTime != null) {
      final double targetSleep = _timeToDouble(targetSleepTime);
      final double targetWake = _timeToDouble(targetWakeTime);
      final double actualSleep = checkIn.hour + (checkIn.minute / 60.0);
      final double actualWake = checkOut.hour + (checkOut.minute / 60.0);

      final double sleepDev = (actualSleep - targetSleep).abs();
      final double wakeDev = (actualWake - targetWake).abs();

      consistencyScore =
          (100 - (sleepDev * 10) - (wakeDev * 10)).clamp(0.0, 100.0);
    }

    double finalScore = (durationScore * 0.6) + (consistencyScore * 0.4);

    // 3. Encadenamiento Metabólico: Penalización por Digestión Activa
    if (lastMealTime != null) {
      final digestionGap = checkIn.difference(lastMealTime).inHours;
      if (digestionGap < 3) {
        finalScore *= 0.85; // Penalización del 15%
      }
    }

    return finalScore.clamp(0.0, 100.0);
  }

  // TODO: Remove in Phase 4 – duplicated metabolic logic
  // Fasting hours calculation should be a shared utility in core/science.
  static double calculateFastingHours(String? firstMeal, String? lastMeal) {
    if (firstMeal == null ||
        firstMeal.isEmpty ||
        lastMeal == null ||
        lastMeal.isEmpty) {
      return 12.0;
    }
    try {
      final last = _timeToDouble(lastMeal);
      final first = _timeToDouble(firstMeal);
      double fasting = (24.0 - last) + first;
      if (fasting > 24.0) fasting -= 1.0; // Small adjustment
      if (fasting < 0) fasting += 24.0;
      return fasting.clamp(0.0, 24.0);
    } catch (_) {
      return 12.0;
    }
  }

  static double calculateSleepHours(String? bedTime, String? wakeUpTime) {
    if (bedTime == null ||
        bedTime.isEmpty ||
        wakeUpTime == null ||
        wakeUpTime.isEmpty) {
      return 7.5;
    }
    try {
      final bed = _timeToDouble(bedTime);
      final wake = _timeToDouble(wakeUpTime);
      double sleep = wake - bed;
      if (sleep <= 0) sleep += 24.0;
      return sleep.clamp(0.0, 24.0);
    } catch (_) {
      return 7.5;
    }
  }

  static bool isSleepWindow(UserModel user, DateTime currentTime) {
    if (user.bedTime == null || user.wakeUpTime == null) return false;
    final bed = _timeToDouble(user.bedTime!);
    final wake = _timeToDouble(user.wakeUpTime!);
    final now = currentTime.hour + (currentTime.minute / 60.0);

    if (bed < wake) {
      return now >= bed && now <= wake;
    } else {
      return now >= bed || now <= wake;
    }
  }

  // TODO: Remove in Phase 4 – duplicated metabolic logic
  // calculateIndices wraps calculateWHtR + calculateWHR → same duplication.
  static Map<String, double> calculateIndices(
      double heightCm, double? waistCm, double? hipCm) {
    return {
      'metaICA': calculateWHtR(waistCm, heightCm),
      'metaICC': calculateWHR(waistCm, hipCm),
    };
  }

  static double getActivityScore(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 20.0;
      case ActivityLevel.light:
        return 40.0;
      case ActivityLevel.moderate:
        return 70.0;
      case ActivityLevel.heavy:
        return 90.0;
    }
  }

  // --- Helper Methods (Private) ---

  static double _getActivityMultiplier(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 1.2;
      case ActivityLevel.light:
        return 1.375;
      case ActivityLevel.moderate:
        return 1.55;
      case ActivityLevel.heavy:
        return 1.725;
    }
  }

  static bool _hasMetabolicRisk(UserModel user) {
    final risks = [
      'diabetes',
      'prediabetes',
      'diabetes_t2',
      'insulin_resistance',
      'pcos',
      'metabolicSyndrome',
      'obesity',
      'fatty_liver'
    ];
    return user.pathologies.any((p) => risks.contains(p));
  }

  // TODO: Remove in Phase 4 cleanup
  // TODO: Remove in Phase 4 – duplicated metabolic logic
  // HealthPlan generation overlaps with nutrition/MetabolicEngine pipeline.
  static HealthPlan generateHealthPlan(UserModel user) {
    final bmi = calculateBMI(user.currentWeightKg, user.heightCm);
    final whtr = calculateWHtR(user.waistCircumferenceCm, user.heightCm);
    final hasMetabolicRisk = _hasMetabolicRisk(user);

    // Protocol Logic
    String protocol = "12:12";
    if (hasMetabolicRisk || whtr > 0.55) {
      protocol = "16:8";
    } else if (bmi > 25) {
      protocol = "14:10";
    }

    // Hydration Logic: (Weight / 7) * 250ml
    final hydrationGoal = (user.currentWeightKg / 7).round();

    // Exercise Strategy
    String exercise = "Actividad General";
    if (whtr > 0.50 || hasMetabolicRisk) {
      exercise = "Caminata Post-prandial (Zona 2)";
    }

    return HealthPlan(
      protocol: protocol,
      hydrationGoal: hydrationGoal,
      maxHeartRate: 180 - user.age,
      exerciseStrategy: exercise,
      exerciseFrequency: "45 min diarios",
      nutritionStrategy:
          hasMetabolicRisk ? "Baja en Carbohidratos" : "Equilibrada",
      breakingFastTip: "Romper con caldo o grasas saludables",
      whyThisPlan: "Ajustado por riesgo metabólico detectado.",
      generatedAt: DateTime.now(),
    );
  }

  // TODO: Remove in Phase 4 – duplicated metabolic logic
  // Glucose estimation duplicated here and in MetabolicHub. Consolidate in core/science.
  static double estimateGlucose(double hoursFasted) {
    return 110.0 - (38 * (1.0 - exp(-0.15 * hoursFasted)));
  }

  // TODO: Remove in Phase 4 – duplicated metabolic logic
  // Ketone estimation duplicated here and in MetabolicHub. Consolidate in core/science.
  static double estimateKetones(double hoursFasted) {
    if (hoursFasted < 8) return 0.2;
    final val = 0.2 + (0.1 * exp(0.18 * (hoursFasted - 8)));
    return val.clamp(0.2, 5.0);
  }

  static DateTime getNextValidMealTime(DateTime lastMealStart) {
    return lastMealStart.add(const Duration(hours: 4));
  }

  static double _timeToDouble(String time) {
    final regExp =
        RegExp(r"(\d{1,2}):(\d{2})\s?(AM|PM)?", caseSensitive: false);
    final match = regExp.firstMatch(time);
    if (match == null) return 0.0;
    int hour = int.parse(match.group(1)!);
    int minute = int.parse(match.group(2)!);
    String? period = match.group(3);
    if (period != null) {
      if (period.toUpperCase() == 'PM' && hour < 12) hour += 12;
      if (period.toUpperCase() == 'AM' && hour == 12) hour = 0;
    }
    return hour + (minute / 60.0);
  }
}

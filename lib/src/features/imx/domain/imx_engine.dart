import 'dart:math' as math;
import '../../fasting/domain/fasting_session.dart';
import '../../progress/domain/measurement_log.dart';
import '../../profile/domain/user_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// IMX ENGINE — Índice de Metamorfosis Real
//
// Fórmula maestra:
//   IMX = (0.40 × PilarB) + (0.30 × PilarM) + (0.30 × PilarH)
//
// Pilar B – Composición Corporal (40%)
//   Basado en ratios cuerpo: ICC, cintura/altura, % grasa calculado por fórmula
//   US Navy. Si no hay medidas suficientes, el pilar se marca como 0 (sin datos).
//
// Pilar M – Comportamiento Metabólico (30%)
//   Consistencia del ayuno (completados/totales) + cumplimiento de duración
//   planned vs real. Requiere al menos 1 sesión de ayuno.
//
// Pilar H – Hábitos de Estilo de Vida (30%)
//   Calculado desde los datos de onboarding del user:
//   actividad física, picoteo, sueño, alimentación.
//   Mejora cuando el usuario registra nivel de energía (energyLevel 1-10).
// ─────────────────────────────────────────────────────────────────────────────

/// Resultado detallado por pilar para mostrar en la UI (Motor v2)
class ImxResult {
  final double total;           // 0-100
  final double scoreStructure;  // Capa A: Estructura (0-100)
  final double scoreMetabolic;  // Capa B: Metabólica (0-100)
  final double scoreBehavior;   // Capa C: Comportamiento (0-100)
  
  final String category;        // Deteriorado, Inestable, Funcional, Eficiente, Optimizado
  final String categoryType;    // internal tag: deteriorated, unstable, functional, efficient, optimized

  final double bodyFat;         // % Grasa
  final double ffmi;            // FFMI score
  final double leanMassKg;      // Masa magra en kg

  final DateTime? calculatedAt; // Timestamp de la última vez que se calculó

  const ImxResult({
    required this.total,
    required this.scoreStructure,
    required this.scoreMetabolic,
    required this.scoreBehavior,
    required this.category,
    required this.categoryType,
    required this.bodyFat,
    required this.ffmi,
    required this.leanMassKg,
    this.calculatedAt,
  });

  // Getter para compatibilidad con UI antigua si es necesario (mapeando a pilares antiguos)
  double get pilarB => scoreStructure;
  double get pilarM => scoreMetabolic;
  double get pilarH => scoreBehavior;

  factory ImxResult.fromJson(Map<String, dynamic> json) {
    final breakdown = json['breakdown'] as Map<String, dynamic>;
    final details = json['details'] as Map<String, dynamic>;
    
    return ImxResult(
      total: (json['score'] as num).toDouble(),
      scoreStructure: (breakdown['structure'] as num).toDouble(),
      scoreMetabolic: (breakdown['metabolic'] as num).toDouble(),
      scoreBehavior: (breakdown['behavior'] as num).toDouble(),
      category: json['category'] as String,
      categoryType: json['categoryType'] as String,
      bodyFat: (details['bodyFat'] as num).toDouble(),
      ffmi: (details['ffmi'] as num).toDouble(),
      leanMassKg: (details['leanMassKg'] as num).toDouble(),
      calculatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': total,
      'breakdown': {
        'structure': scoreStructure,
        'metabolic': scoreMetabolic,
        'behavior': scoreBehavior,
      },
      'category': category,
      'categoryType': categoryType,
      'details': {
        'bodyFat': bodyFat,
        'ffmi': ffmi,
        'leanMassKg': leanMassKg,
      },
      'calculatedAt': calculatedAt?.toIso8601String(),
    };
  }

  static const empty = ImxResult(
    total: 0,
    scoreStructure: 0,
    scoreMetabolic: 0,
    scoreBehavior: 0,
    category: 'Calculando...',
    categoryType: 'unstable',
    bodyFat: 0,
    ffmi: 0,
    leanMassKg: 0,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ImxResult &&
        other.total == total &&
        other.scoreStructure == scoreStructure &&
        other.scoreMetabolic == scoreMetabolic &&
        other.scoreBehavior == scoreBehavior &&
        other.category == category &&
        other.categoryType == categoryType &&
        other.bodyFat == bodyFat &&
        other.ffmi == ffmi &&
        other.leanMassKg == leanMassKg;
  }

  @override
  int get hashCode =>
      total.hashCode ^
      scoreStructure.hashCode ^
      scoreMetabolic.hashCode ^
      scoreBehavior.hashCode ^
      category.hashCode ^
      categoryType.hashCode ^
      bodyFat.hashCode ^
      ffmi.hashCode ^
      leanMassKg.hashCode;
}

class ImxEngine {

  // ───────────────────────────────────────────────────────────────────────────
  // PILLAR B — COMPOSICIÓN CORPORAL (40%)
  // Inputs: medidas corporales del último registro
  // ───────────────────────────────────────────────────────────────────────────
  static double calculatePilarB({
    required double heightCm,
    required double waistCm,
    required double neckCm,
    double? hipCm,
    required bool isMale,
  }) {
    if (heightCm <= 0 || waistCm <= 0 || neckCm <= 0) return 0.0;

    double score = 0.0;
    int factors = 0;

    // 1. Ratio cintura/altura (WHtR) — 50% del pilar B
    // Óptimo: < 0.5. Riesgo: > 0.6
    final whtR = waistCm / heightCm;
    double whtRScore;
    if (whtR <= 0.45) {
      whtRScore = 100.0;
    } else if (whtR <= 0.50) {
      // Bueno: escala lineal 100→80
      whtRScore = 100.0 - ((whtR - 0.45) / 0.05) * 20.0;
    } else if (whtR <= 0.60) {
      // Moderado: escala lineal 80→30
      whtRScore = 80.0 - ((whtR - 0.50) / 0.10) * 50.0;
    } else {
      // Alto riesgo: escala lineal 30→0
      whtRScore = (30.0 - ((whtR - 0.60) / 0.10) * 30.0).clamp(0.0, 30.0);
    }
    score += whtRScore * 0.5;
    factors++;

    // 2. ICC — Índice Cintura-Cadera (30% del pilar B)
    if (hipCm != null && hipCm > 0) {
      final icc = waistCm / hipCm;
      double iccScore;
      // Hombre óptimo: < 0.90 | Mujer óptimo: < 0.80
      final iccLimit = isMale ? 0.90 : 0.80;
      final iccHigh  = isMale ? 1.00 : 0.90;
      if (icc <= iccLimit) {
        iccScore = 100.0;
      } else if (icc <= iccHigh) {
        iccScore = 100.0 - ((icc - iccLimit) / (iccHigh - iccLimit)) * 70.0;
      } else {
        iccScore = 30.0 - ((icc - iccHigh) / 0.1) * 30.0;
        iccScore = iccScore.clamp(0.0, 30.0);
      }
      score += iccScore * 0.3;
      factors++;
    }

    // 3. % Grasa corporal US Navy (20% del pilar B)
    final fat = MeasurementLog.calculateBodyFat(
      heightCm: heightCm,
      waistCm: waistCm,
      neckCm: neckCm,
      hipCm: hipCm,
      isMale: isMale,
    );
    if (fat != null && fat > 0) {
      // Rangos óptimos: Hombre 6-20%, Mujer 14-28%
      final fatOptMax  = isMale ? 20.0 : 28.0;
      final fatOptMin  = isMale ? 6.0  : 14.0;
      double fatScore;
      if (fat >= fatOptMin && fat <= fatOptMax) {
        fatScore = 100.0;
      } else if (fat > fatOptMax && fat <= fatOptMax + 10) {
        fatScore = 100.0 - ((fat - fatOptMax) / 10.0) * 70.0;
      } else if (fat < fatOptMin) {
        fatScore = (90.0 - (fatOptMin - fat) * 5.0).clamp(0.0, 90.0);
      } else {
        fatScore = (30.0 - ((fat - (fatOptMax + 10)) / 5.0) * 10.0).clamp(0.0, 30.0);
      }
      score += fatScore * 0.2;
      factors++;
    }

    // Normalizar si falta ICC (solo 2 factores disponibles)
    if (factors == 2) {
      // WHtR(50%) + fat(20%) → escalar a 100
      return (score / 0.7 * 1.0).clamp(0.0, 100.0);
    }

    return score.clamp(0.0, 100.0);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PILLAR M — COMPORTAMIENTO METABÓLICO (30%)
  // Inputs: últimas 7 sesiones de ayuno
  // ───────────────────────────────────────────────────────────────────────────
  static double calculatePilarM(List<FastingSession> recentSessions) {
    if (recentSessions.isEmpty) return 0.0;

    double score = 0.0;

    // 1. Tasa de completación (60% del pilar M)
    final completed = recentSessions.where((s) => s.isCompleted).length;
    final completionRate = completed / recentSessions.length;
    score += completionRate * 60.0;

    // 2. Cumplimiento de duración planeada vs real (40% del pilar M)
    // Una sesión completada que duró >= 80% del tiempo planeado = bien
    final sessionsWithEnd = recentSessions
        .where((s) => s.isCompleted && s.endTime != null)
        .toList();

    if (sessionsWithEnd.isNotEmpty) {
      double durationScore = 0.0;
      for (final s in sessionsWithEnd) {
        final plannedMins = s.plannedDurationHours * 60.0;
        final actualMins = s.endTime!.difference(s.startTime).inMinutes.toDouble();
        final ratio = (actualMins / plannedMins).clamp(0.0, 1.2);
        // Óptimo: 0.90-1.10 del tiempo planeado
        if (ratio >= 0.90 && ratio <= 1.10) {
          durationScore += 100.0;
        } else if (ratio >= 0.80) {
          durationScore += 80.0;
        } else if (ratio >= 0.70) {
          durationScore += 60.0;
        } else {
          durationScore += 30.0;
        }
      }
      score += (durationScore / sessionsWithEnd.length) * 0.40;
    } else if (completed > 0) {
      // Si hay completados pero sin endTime, asumir cumplimiento parcial
      score += 25.0;
    }

    return score.clamp(0.0, 100.0);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PILLAR H — HÁBITOS DE ESTILO DE VIDA (30%)
  // Inputs: perfil de onboarding + último energyLevel registrado
  // ───────────────────────────────────────────────────────────────────────────
  static double calculatePilarH({
    required ActivityLevel activityLevel,
    required SnackingHabit snackingHabit,
    required DietaryPreference dietaryPreference,
    double? averageSleepHours,
    int? energyLevel, // 1-10, del último MeasurementLog
  }) {
    double score = 0.0;

    // 1. Actividad física (25% del pilar H)
    final double activityScore = switch (activityLevel) {
      ActivityLevel.sedentary => 20.0,
      ActivityLevel.light     => 55.0,
      ActivityLevel.moderate  => 80.0,
      ActivityLevel.heavy     => 100.0,
    };
    score += activityScore * 0.25;

    // 2. Hábito de picoteo / snacking (25% del pilar H)
    // Negativo para el ayuno intermitente
    final double snackScore = switch (snackingHabit) {
      SnackingHabit.never     => 100.0,
      SnackingHabit.sometimes => 65.0,
      SnackingHabit.frequent  => 20.0,
    };
    score += snackScore * 0.25;

    // 3. Calidad del sueño (25% del pilar H)
    // Óptimo: 7-9 horas
    double sleepScore = 50.0; // default si no hay dato
    if (averageSleepHours != null && averageSleepHours > 0) {
      if (averageSleepHours >= 7.0 && averageSleepHours <= 9.0) {
        sleepScore = 100.0;
      } else if (averageSleepHours >= 6.0 && averageSleepHours < 7.0) {
        sleepScore = 75.0;
      } else if (averageSleepHours > 9.0 && averageSleepHours <= 10.0) {
        sleepScore = 80.0;
      } else if (averageSleepHours < 6.0) {
        sleepScore = 30.0;
      } else {
        sleepScore = 40.0;
      }
    }
    score += sleepScore * 0.25;

    // 4. Nivel de energía subjetivo (25% del pilar H)
    // Registrado por el usuario en el check-in semanal
    double energyScore = 50.0; // default si no hay dato
    if (energyLevel != null) {
      energyScore = (energyLevel / 10.0 * 100.0).clamp(0.0, 100.0);
    }
    score += energyScore * 0.25;

    return score.clamp(0.0, 100.0);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // ECUACIÓN MAESTRA — calcula el IMX completo con los 3 pilares
  // ───────────────────────────────────────────────────────────────────────────
  static ImxResult calculateIMX({
    required UserModel user,
    required List<FastingSession> recentSessions,
    MeasurementLog? latestMeasurement,
  }) {
    // ── Pilar B ──────────────────────────────────────────────────────────────
    final hasBodyData = (latestMeasurement?.waistCircumference != null &&
        latestMeasurement?.neckCircumference != null);

    double pilarB = 0.0;
    if (hasBodyData) {
      pilarB = calculatePilarB(
        heightCm: user.heightCm,
        waistCm: latestMeasurement!.waistCircumference!,
        neckCm: latestMeasurement.neckCircumference!,
        hipCm: latestMeasurement.hipCircumference,
        isMale: user.gender == Gender.male,
      );
    } else if (user.waistCircumferenceCm > 0 && user.neckCircumferenceCm > 0) {
      // Fallback: usar los valores del perfil de onboarding
      pilarB = calculatePilarB(
        heightCm: user.heightCm,
        waistCm: user.waistCircumferenceCm,
        neckCm: user.neckCircumferenceCm,
        hipCm: user.hipCircumferenceCm,
        isMale: user.gender == Gender.male,
      );
    }

    // ── Pilar M ──────────────────────────────────────────────────────────────
    final hasFastingData = recentSessions.isNotEmpty;
    final pilarM = calculatePilarM(recentSessions);

    // ── Pilar H ──────────────────────────────────────────────────────────────
    final pilarH = calculatePilarH(
      activityLevel: user.activityLevel,
      snackingHabit: user.snackingHabit,
      dietaryPreference: user.dietaryPreference,
      averageSleepHours: user.averageSleepHours,
      energyLevel: latestMeasurement?.energyLevel,
    );

    // ── Ecuación Maestra: B(40%) + M(30%) + H(30%) ──────────────────────────
    // Si falta pilar B, redistribuimos su peso entre M y H
    double total;
    if (!hasBodyData && user.waistCircumferenceCm <= 0) {
      // Solo M y H disponibles: 50/50
      total = (0.50 * pilarM) + (0.50 * pilarH);
    } else {
      total = (0.40 * pilarB) + (0.30 * pilarM) + (0.30 * pilarH);
    }

    return ImxResult(
      total: total.clamp(0.0, 100.0),
      scoreStructure: pilarB,
      scoreMetabolic: pilarM,
      scoreBehavior: pilarH,
      category: total < 50 ? 'Inestable' : 'Funcional', // Basic fallback category
      categoryType: total < 50 ? 'unstable' : 'functional',
      bodyFat: MeasurementLog.calculateBodyFat(
            heightCm: user.heightCm,
            waistCm: user.waistCircumferenceCm,
            neckCm: user.neckCircumferenceCm,
            isMale: user.gender == Gender.male,
          ) ??
          0.0,
      ffmi: 0.0,
      leanMassKg: 0.0,
      calculatedAt: DateTime.now(),
    );
  }

  // ── Backward-compatible simple score (used where only double is expected) ──
  static double calculateTotalIMX({
    required double waistCm,
    required double heightCm,
    required List<FastingSession> recentSessions,
  }) {
    final whtR = heightCm > 0 ? (waistCm / heightCm) : 0.5;
    double em;
    if (whtR <= 0.45) em = 100.0;
    else if (whtR <= 0.60) em = 100.0 - ((whtR - 0.45) / 0.15) * 70.0;
    else em = 30.0 - ((whtR - 0.60) / 0.10) * 30.0;
    em = em.clamp(0.0, 100.0);

    final ca = recentSessions.isEmpty ? 0.0
        : (recentSessions.where((s) => s.isCompleted).length / recentSessions.length) * 100.0;

    return ((0.60 * ca) + (0.40 * em)).clamp(0.0, 100.0);
  }
}
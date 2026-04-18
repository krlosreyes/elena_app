// SPEC-14 (revisión): Motor de Sugerencias de Objetivos
// Genera objetivos personalizados a partir de los datos biométricos del UserModel.
// Completamente estático — no hace IO, no tiene efectos secundarios.
// Usa los mismos umbrales científicos que ScoreEngine y BodyCompositionCalc:
//   · WHTR ≤ 0.50 → zona metabólica segura (umbral internacional)
//   · Grasa corporal: rangos ACSM por género
//   · Hidratación: 35 ml × kg (fisiología básica)
//   · Sueño: 7–9 h (NIH / Huberman Lab)
//   · Ejercicio: OMS 150 min/semana → ~22 min/día mínimo

import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/features/goals/domain/user_goal.dart';

// ─── Modelo de sugerencia ─────────────────────────────────────────────────────

class GoalSuggestion {
  /// Tipo de objetivo
  final GoalType type;

  /// Valor actual medido/calculado del usuario (lo que Elena ya sabe).
  final double currentValue;

  /// Valor objetivo sugerido por Elena (calculado científicamente).
  final double suggestedTarget;

  /// Una línea de respaldo científico — sin jerga, en segunda persona.
  final String rationale;

  /// Si Elena considera que este objetivo debería activarse de forma proactiva.
  /// true cuando la métrica está fuera del rango saludable.
  final bool shouldActivate;

  /// Etiqueta del estado actual ("Riesgo alto", "Fitness", "Óptimo", etc.)
  final String currentStatusLabel;

  const GoalSuggestion({
    required this.type,
    required this.currentValue,
    required this.suggestedTarget,
    required this.rationale,
    required this.shouldActivate,
    required this.currentStatusLabel,
  });
}

// ─── Motor ────────────────────────────────────────────────────────────────────

class GoalSuggestionEngine {
  const GoalSuggestionEngine._();

  /// Genera el mapa completo de sugerencias a partir del UserModel.
  /// Siempre devuelve las 6 sugerencias aunque algún dato sea estimado.
  static Map<GoalType, GoalSuggestion> suggest(UserModel user) {
    final bool isMale = user.gender.toLowerCase() == 'masculino' ||
                        user.gender.toLowerCase() == 'male' ||
                        user.gender.toLowerCase() == 'm';

    return {
      GoalType.weightTarget:
          _weightSuggestion(user, isMale),
      GoalType.bodyFatTarget:
          _bodyFatSuggestion(user, isMale),
      GoalType.fastingDaysPerWeek:
          _fastingDaysSuggestion(user),
      GoalType.exerciseMinPerDay:
          _exerciseSuggestion(user),
      GoalType.sleepHoursPerNight:
          _sleepSuggestion(user),
      GoalType.hydrationLitersPerDay:
          _hydrationSuggestion(user),
    };
  }

  // ─── Peso objetivo ──────────────────────────────────────────────────────────
  //
  // Estrategia: partimos de la masa magra actual (ya que esa es la que
  // queremos preservar) y calculamos el peso total al llegar al %grasa
  // objetivo. Esto es más preciso que escalar por WHTR.
  //
  //   peso_objetivo = masa_magra / (1 − %grasa_objetivo / 100)

  static GoalSuggestion _weightSuggestion(UserModel user, bool isMale) {
    final double bf       = user.bodyFatPercentage.clamp(5.0, 50.0);
    final double leanMass = user.weight * (1 - bf / 100);

    // Target bf = próxima zona mejor (igual lógica que bodyFat)
    final double targetBf = _nextFatZoneTarget(bf, isMale);
    final double targetWeight = leanMass / (1 - targetBf / 100);

    final double currentWhtr = user.waistCircumference != null
        ? user.waistCircumference! / user.height
        : 0.0;

    final bool outOfRange = bf > (isMale ? 18.0 : 25.0);

    String statusLabel;
    if (currentWhtr > 0 && currentWhtr >= 0.56) {
      statusLabel = 'Riesgo metabólico alto';
    } else if (currentWhtr > 0 && currentWhtr >= 0.50) {
      statusLabel = 'Riesgo moderado';
    } else if (outOfRange) {
      statusLabel = 'Por encima del rango óptimo';
    } else {
      statusLabel = 'En rango saludable';
    }

    return GoalSuggestion(
      type:              GoalType.weightTarget,
      currentValue:      user.weight,
      suggestedTarget:   (targetWeight * 2).round() / 2, // redondeo 0.5 kg
      rationale:         outOfRange
          ? 'Tu masa magra es ${leanMass.toStringAsFixed(1)} kg. '
            'Llegar a ${targetWeight.toStringAsFixed(1)} kg preserva músculo '
            'mientras reduce la grasa que limita tu IMR.'
          : 'Tu composición ya está en rango. El objetivo es mantener '
            'el peso que sostiene tu masa magra actual.',
      shouldActivate:    outOfRange,
      currentStatusLabel: statusLabel,
    );
  }

  // ─── Grasa corporal objetivo ────────────────────────────────────────────────
  //
  // Zonas ACSM:
  //   Hombre: Atlético <14%, Fitness 14–17%, Promedio 18–24%, Alto ≥25%
  //   Mujer:  Atlético <21%, Fitness 21–24%, Promedio 25–31%, Alto ≥32%
  //
  // Sugerimos el techo de la zona inmediatamente mejor.

  static GoalSuggestion _bodyFatSuggestion(UserModel user, bool isMale) {
    final double bf = user.bodyFatPercentage.clamp(5.0, 50.0);
    final double target = _nextFatZoneTarget(bf, isMale);

    final String currentZone = _fatZoneLabel(bf, isMale);
    final String targetZone  = _fatZoneLabel(target, isMale);
    final bool   outOfRange  = isMale ? bf >= 18.0 : bf >= 25.0;

    return GoalSuggestion(
      type:              GoalType.bodyFatTarget,
      currentValue:      bf,
      suggestedTarget:   target,
      rationale:         outOfRange
          ? 'Estás en zona $currentZone (${bf.toStringAsFixed(0)}%). '
            'El rango ${isMale ? "Fitness para hombres" : "Fitness para mujeres"} '
            'es ${isMale ? "14–17%" : "21–24%"}. Alcanzar $targetZone activa '
            'sensibilidad a la insulina y mejora tu bloque de Estructura en el IMR.'
          : 'Tu %grasa ya está en zona $currentZone. '
            'El objetivo es mantener o mejorar gradualmente.',
      shouldActivate:    outOfRange,
      currentStatusLabel: currentZone,
    );
  }

  static double _nextFatZoneTarget(double bf, bool isMale) {
    if (isMale) {
      if (bf >= 25) return 20.0; // Alto  → techo Promedio
      if (bf >= 18) return 17.0; // Promedio → techo Fitness
      if (bf >= 14) return 13.0; // Fitness → techo Atlético
      return bf;                 // Ya atlético — mantener
    } else {
      if (bf >= 32) return 28.0; // Alto  → techo Promedio
      if (bf >= 25) return 24.0; // Promedio → techo Fitness
      if (bf >= 21) return 20.0; // Fitness → techo Atlético
      return bf;                 // Ya atlético — mantener
    }
  }

  static String _fatZoneLabel(double bf, bool isMale) {
    if (isMale) {
      if (bf < 6)  return 'Esencial';
      if (bf < 14) return 'Atlético';
      if (bf < 18) return 'Fitness';
      if (bf < 25) return 'Promedio';
      return 'Alto';
    } else {
      if (bf < 14) return 'Esencial';
      if (bf < 21) return 'Atlético';
      if (bf < 25) return 'Fitness';
      if (bf < 32) return 'Promedio';
      return 'Alto';
    }
  }

  // ─── Días de ayuno por semana ───────────────────────────────────────────────
  //
  // Usamos weeklyAdherence (0.0–1.0 × 7 días) para estimar los días actuales.
  // Sugerimos +1 día si está por debajo de 5, con tope en 6 días/sem.

  static GoalSuggestion _fastingDaysSuggestion(UserModel user) {
    final double currentDays = (user.weeklyAdherence * 7).clamp(0.0, 7.0);
    final int    roundedDays = currentDays.round();
    final int    targetDays  = roundedDays >= 5 ? 5 : (roundedDays + 1).clamp(2, 6);

    final bool outOfRange = roundedDays < 4;

    String statusLabel;
    if (roundedDays <= 1) statusLabel = 'Sin protocolo activo';
    else if (roundedDays < 4) statusLabel = 'Adherencia baja';
    else if (roundedDays < 6) statusLabel = 'Adherencia moderada';
    else statusLabel = 'Alta consistencia';

    return GoalSuggestion(
      type:              GoalType.fastingDaysPerWeek,
      currentValue:      currentDays,
      suggestedTarget:   targetDays.toDouble(),
      rationale:         'Tu adherencia actual es ${currentDays.toStringAsFixed(1)} días/semana. '
                         'La investigación muestra que mantener el protocolo ≥5 días activa '
                         'adaptaciones metabólicas sostenidas que no ocurren con menos frecuencia.',
      shouldActivate:    outOfRange,
      currentStatusLabel: statusLabel,
    );
  }

  // ─── Ejercicio (minutos/día) ────────────────────────────────────────────────
  //
  // OMS: 150 min/semana de intensidad moderada = 22 min/día.
  // Sugerimos max(30, min(ejercicio_actual + 10, 60)), redondeado a 5 min.

  static GoalSuggestion _exerciseSuggestion(UserModel user) {
    final double current = user.exerciseGoalMinutes.clamp(0, 120).toDouble();
    double rawTarget = (current + 10).clamp(30, 60);
    // Redondear a múltiplo de 5
    final double target = (rawTarget / 5).round() * 5.0;

    final bool outOfRange = current < 30;

    String statusLabel;
    if (current < 15)  statusLabel = 'Sin actividad registrada';
    else if (current < 30) statusLabel = 'Por debajo de recomendación OMS';
    else if (current < 45) statusLabel = 'En rango recomendado';
    else statusLabel = 'Nivel alto de actividad';

    return GoalSuggestion(
      type:              GoalType.exerciseMinPerDay,
      currentValue:      current,
      suggestedTarget:   target,
      rationale:         'La OMS establece 150 min/semana como mínimo para beneficios '
                         'metabólicos. Con ${target.toStringAsFixed(0)} min/día puedes '
                         'sumar hasta 7.5 pts directos al bloque de Comportamiento en tu IMR.',
      shouldActivate:    outOfRange,
      currentStatusLabel: statusLabel,
    );
  }

  // ─── Sueño (horas/noche) ───────────────────────────────────────────────────
  //
  // Calculamos las horas de sueño del perfil circadiano.
  // NIH / Huberman: 7–9 h es el rango óptimo para regulación de cortisol.

  static GoalSuggestion _sleepSuggestion(UserModel user) {
    final double current = _estimateSleepHours(user.profile);
    double target;
    bool outOfRange;

    if (current < 7.0) {
      target     = 7.5;
      outOfRange = true;
    } else if (current > 9.0) {
      target     = 8.0;
      outOfRange = false;
    } else {
      target     = current; // Ya en rango — mantener
      outOfRange = false;
    }

    String statusLabel;
    if (current < 6)       statusLabel = 'Privación crónica de sueño';
    else if (current < 7)  statusLabel = 'Por debajo del rango óptimo';
    else if (current <= 9) statusLabel = 'En rango óptimo';
    else                   statusLabel = 'Sueño excesivo';

    return GoalSuggestion(
      type:              GoalType.sleepHoursPerNight,
      currentValue:      (current * 2).round() / 2.0, // redondeo 0.5 h
      suggestedTarget:   target,
      rationale:         '7–9 horas optimizan la regulación de cortisol y grelina. '
                         'En ese rango, tu ayuno es significativamente más eficiente '
                         'porque el hambre hormonal se regula durante la noche.',
      shouldActivate:    outOfRange,
      currentStatusLabel: statusLabel,
    );
  }

  static double _estimateSleepHours(CircadianProfile profile) {
    // Extraemos solo hora:minuto para evitar problemas de fecha
    final double wakeDecimal  = profile.wakeUpTime.hour +
                                profile.wakeUpTime.minute / 60.0;
    final double sleepDecimal = profile.sleepTime.hour +
                                profile.sleepTime.minute / 60.0;
    double hours = wakeDecimal - sleepDecimal;
    if (hours <= 0) hours += 24; // Cruza la medianoche
    return hours.clamp(3.0, 12.0);
  }

  // ─── Hidratación (litros/día) ───────────────────────────────────────────────
  //
  // Fórmula metabólica estándar: 35 ml × kg de peso corporal.
  // Misma fórmula que HydrationNotifier para consistencia.

  static GoalSuggestion _hydrationSuggestion(UserModel user) {
    final double target = (user.weight * 0.035 * 4).round() / 4.0; // redondeo 0.25 L
    const double averageIntake = 1.5; // consumo típico sedentario (línea de base)
    final bool outOfRange = target > 2.0; // Casi siempre habrá oportunidad

    return GoalSuggestion(
      type:              GoalType.hydrationLitersPerDay,
      currentValue:      averageIntake,
      suggestedTarget:   target.clamp(1.0, 4.0),
      rationale:         'Tu cuerpo necesita ${target.toStringAsFixed(2)} L/día: '
                         '35 ml × ${user.weight.toStringAsFixed(0)} kg. '
                         'La hidratación adecuada mejora el transporte de cetonas durante '
                         'el ayuno y reduce el cortisol de estrés metabólico.',
      shouldActivate:    true, // Hidratación siempre relevante
      currentStatusLabel: 'Nivel estimado (sin registro)',
    );
  }
}

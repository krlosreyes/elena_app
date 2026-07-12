// SPEC-14 (revisión): Motor de Sugerencias de Objetivos
// Genera objetivos personalizados a partir de los datos biométricos del UserModel.
// Completamente estático — no hace IO, no tiene efectos secundarios.
// Usa los mismos umbrales científicos que ScoreEngine y BodyCompositionCalc:
//   · WHTR ≤ 0.50 → zona metabólica segura (umbral internacional)
//   · Grasa corporal: rangos ACSM por género
//   · Hidratación: 35 ml × kg (fisiología básica)
//   · Sueño: 7–9 h (NIH / Huberman Lab)
//   · Ejercicio: protocolo diferenciado por zona grasa + sistema nervioso (SPEC-244)

import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/features/goals/domain/user_goal.dart';

// ─── Protocolo de ejercicio (SPEC-244) ───────────────────────────────────────
//
// Encapsula el tipo de ejercicio recomendado, los minutos base y la
// justificación científica para cada combinación de zona grasa + sistema
// nervioso. No es const porque el campo rationale puede variar según
// modificadores en tiempo de ejecución.

class _ExerciseProtocol {
  /// Etiqueta corta que aparece como badge de estado (máx ~20 chars).
  final String typeLabel;

  /// Minutos diarios de referencia para el protocolo (promedio semanal).
  final int minTarget;

  /// Texto largo que se muestra en "¿Por qué este objetivo?".
  final String rationale;

  const _ExerciseProtocol({
    required this.typeLabel,
    required this.minTarget,
    required this.rationale,
  });
}

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
  /// Siempre devuelve las 7 sugerencias aunque algún dato sea estimado.
  ///
  /// `recentCocienteAPct` es opcional (SPEC-168.0.C): cuando el dashboard
  /// tiene >= 2 semanas de historial de comidas A-dominantes, se inyecta
  /// el promedio reciente para personalizar la sugerencia de Nutrición.
  /// Si es null, el engine usa el baseline poblacional de 50 %.
  /// SPEC-203.2 (auditoría onboarding): `recentExerciseMinPerDay` permite
  /// inyectar el promedio REAL de ejercicio (de los logs / HealthKit) como
  /// "actual", en vez del placeholder `exerciseGoalMinutes` (que es un goal,
  /// no actividad medida). Si es null (onboarding nuevo, sin historial), cae
  /// al comportamiento estimado.
  static Map<GoalType, GoalSuggestion> suggest(
    UserModel user, {
    double? recentCocienteAPct,
    double? recentExerciseMinPerDay,
  }) {
    final bool isMale = user.gender.toLowerCase() == 'masculino' ||
        user.gender.toLowerCase() == 'male' ||
        user.gender.toLowerCase() == 'm';

    return {
      GoalType.weightTarget: _weightSuggestion(user, isMale),
      GoalType.bodyFatTarget: _bodyFatSuggestion(user, isMale),
      GoalType.fastingDaysPerWeek: _fastingDaysSuggestion(user),
      GoalType.exerciseMinPerDay:
          _exerciseSuggestion(user, isMale, recentExerciseMinPerDay),
      GoalType.sleepHoursPerNight: _sleepSuggestion(user),
      GoalType.hydrationLitersPerDay: _hydrationSuggestion(user),
      GoalType.nutritionADominantPercent:
          _nutritionSuggestion(recentCocienteAPct),
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
    // SPEC-92: bodyFat nullable → si no hay dato, usar fallback
    // poblacional (15 hombre / 25 mujer) para no romper la sugerencia.
    final double rawBf = user.bodyFatPercentage ?? (isMale ? 15.0 : 25.0);
    final double bf = rawBf.clamp(5.0, 50.0);
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
      type: GoalType.weightTarget,
      currentValue: user.weight,
      suggestedTarget: (targetWeight * 2).round() / 2, // redondeo 0.5 kg
      rationale: outOfRange
          ? 'Tu masa magra es ${leanMass.toStringAsFixed(1)} kg. '
              'Llegar a ${targetWeight.toStringAsFixed(1)} kg preserva músculo '
              'mientras reduce la grasa que limita tu IMR.'
          : 'Tu composición ya está en rango. El objetivo es mantener '
              'el peso que sostiene tu masa magra actual.',
      shouldActivate: outOfRange,
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
    // SPEC-92: bodyFat nullable → fallback poblacional para sugerencia.
    final double rawBf = user.bodyFatPercentage ?? (isMale ? 15.0 : 25.0);
    final double bf = rawBf.clamp(5.0, 50.0);
    final double target = _nextFatZoneTarget(bf, isMale);

    final String currentZone = _fatZoneLabel(bf, isMale);
    final String targetZone = _fatZoneLabel(target, isMale);
    final bool outOfRange = isMale ? bf >= 18.0 : bf >= 25.0;

    return GoalSuggestion(
      type: GoalType.bodyFatTarget,
      currentValue: bf,
      suggestedTarget: target,
      rationale: outOfRange
          ? 'Estás en zona $currentZone (${bf.toStringAsFixed(0)}%). '
              'El rango ${isMale ? "Fitness para hombres" : "Fitness para mujeres"} '
              'es ${isMale ? "14–17%" : "21–24%"}. Alcanzar $targetZone activa '
              'sensibilidad a la insulina y mejora tu bloque de Estructura en el IMR.'
          : 'Tu %grasa ya está en zona $currentZone. '
              'El objetivo es mantener o mejorar gradualmente.',
      shouldActivate: outOfRange,
      currentStatusLabel: currentZone,
    );
  }

  /// SPEC-203.1 (auditoría onboarding): solo se sugiere BAJAR de zona cuando
  /// el objetivo se activa (Promedio/Alto). Antes, a un usuario en zona
  /// Fitness (no activado: umbral 18% H / 25% M) se le sugería igual bajar al
  /// techo Atlético → mensaje mixto ("ya estás bien" + "baja a 13%"). Ahora
  /// Fitness/Atlético = mantener, coherente con la no-activación.
  static double _nextFatZoneTarget(double bf, bool isMale) {
    if (isMale) {
      if (bf >= 25) return 20.0; // Alto → techo Promedio
      if (bf >= 18) return 17.0; // Promedio → techo Fitness
      return bf; // Fitness/Atlético/Esencial — mantener
    } else {
      if (bf >= 32) return 28.0; // Alto → techo Promedio
      if (bf >= 25) return 24.0; // Promedio → techo Fitness
      return bf; // Fitness/Atlético/Esencial — mantener
    }
  }

  static String _fatZoneLabel(double bf, bool isMale) {
    if (isMale) {
      if (bf < 6) return 'Esencial';
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
    final int roundedDays = currentDays.round();
    // SPEC-203.1 (auditoría onboarding): piso de 3 días/sem. Antes el
    // principiante (0 días) recibía una meta de solo 2 — poco ambiciosa para
    // instalar el hábito. 3 es la dosis mínima que genera adaptación visible.
    final int targetDays = roundedDays >= 5 ? 5 : (roundedDays + 1).clamp(3, 6);

    final bool outOfRange = roundedDays < 4;

    String statusLabel;
    if (roundedDays <= 1) {
      statusLabel = 'Sin protocolo activo';
    } else if (roundedDays < 4) {
      statusLabel = 'Adherencia baja';
    } else if (roundedDays < 6) {
      statusLabel = 'Adherencia moderada';
    } else {
      statusLabel = 'Alta consistencia';
    }

    return GoalSuggestion(
      type: GoalType.fastingDaysPerWeek,
      currentValue: currentDays,
      suggestedTarget: targetDays.toDouble(),
      rationale:
          'Tu adherencia actual es ${currentDays.toStringAsFixed(1)} días/semana. '
          'La investigación muestra que mantener el protocolo ≥5 días activa '
          'adaptaciones metabólicas sostenidas que no ocurren con menos frecuencia.',
      shouldActivate: outOfRange,
      currentStatusLabel: statusLabel,
    );
  }

  // ─── Ejercicio (minutos/día) — SPEC-244 ────────────────────────────────────
  //
  // El protocolo de ejercicio se diferencia por zona grasa ACSM y sistema
  // nervioso (pasivo/excitado). No es un flat "current + 10": cada zona
  // tiene un tipo de ejercicio óptimo y un rango de minutos distinto.
  //
  // Fuentes:
  //   · ACSM Position Stand on Exercise and Physical Activity (2011)
  //   · Laforgia et al. — EPOC y oxidación de grasa post-ejercicio
  //   · Gibala et al. — HIIT vs. cardio continuo en recomposición
  //   · OMS — 150-300 min/semana actividad moderada

  static GoalSuggestion _exerciseSuggestion(
    UserModel user,
    bool isMale,
    double? recentMinPerDay,
  ) {
    // SPEC-203.2: actividad REAL de logs/HealthKit como "actual".
    // Sin historial → placeholder del goal (estimado).
    final bool hasReal = recentMinPerDay != null;
    final double current = (hasReal
            ? recentMinPerDay
            : user.exerciseGoalMinutes.toDouble())
        .clamp(0, 120)
        .toDouble();

    // ── Composición corporal ────────────────────────────────────────────────
    final double rawBf = user.bodyFatPercentage ?? (isMale ? 20.0 : 28.0);
    final double bf = rawBf.clamp(5.0, 50.0);

    final double whtr = (user.waistCircumference != null && user.height > 0)
        ? user.waistCircumference! / user.height
        : 0.0;
    final bool highVisceralRisk = whtr >= 0.56;

    // Sistema nervioso: 'excitado' → bajar intensidad para no elevar cortisol.
    final String ns = user.nervousSystem.toLowerCase();
    final bool isExcited = ns == 'excitado' || ns == 'excited';

    // ── Protocolo basado en zona grasa ──────────────────────────────────────
    final _ExerciseProtocol proto = _exerciseProtocolFor(
      bf: bf,
      isMale: isMale,
      highVisceralRisk: highVisceralRisk,
      isExcited: isExcited,
    );

    // Si el usuario ya tiene actividad real, nunca sugerimos menos que su
    // promedio actual + 5 min (progresión); el piso es el protocolo de zona.
    final double rawTarget = hasReal
        ? (current + 5).clamp(proto.minTarget.toDouble(), 75.0)
        : proto.minTarget.toDouble();
    final double target = (rawTarget / 5).round() * 5.0;

    final bool outOfRange = current < 30;

    // El statusLabel refleja el TIPO de ejercicio, no solo el volumen.
    // BUGFIX (SPEC-244 auditoría 2026-07-12): sin actividad real, el label
    // debe seguir marcando "(estimado)" — principio de honestidad ("no
    // afirmamos un nivel" sin dato real). SPEC-244 introdujo el protocolo
    // por zona pero perdió el marcador al enfocar el label en el tipo de
    // ejercicio; lo restauramos sin perder la info de zona.
    String statusLabel;
    if (!hasReal) {
      statusLabel = '${proto.typeLabel} (estimado)';
    } else if (current < 15) {
      statusLabel = 'Sin actividad · ${proto.typeLabel}';
    } else if (current < 30) {
      statusLabel = 'Bajo OMS · ${proto.typeLabel}';
    } else {
      statusLabel = proto.typeLabel;
    }

    return GoalSuggestion(
      type: GoalType.exerciseMinPerDay,
      currentValue: current,
      suggestedTarget: target,
      rationale: proto.rationale,
      shouldActivate: outOfRange,
      currentStatusLabel: statusLabel,
    );
  }

  // ─── Tabla de protocolos por zona grasa + sistema nervioso ─────────────────

  static _ExerciseProtocol _exerciseProtocolFor({
    required double bf,
    required bool isMale,
    required bool highVisceralRisk,
    required bool isExcited,
  }) {
    // ── ZONA ALTO (H ≥25 %, M ≥32 %) ───────────────────────────────────────
    // Prioridad: reducción de grasa + preservar masa magra.
    if (isMale ? bf >= 25 : bf >= 32) {
      if (isExcited) {
        return const _ExerciseProtocol(
          typeLabel: 'Cardio suave + Movilidad',
          minTarget: 30,
          rationale:
              'Tu zona de grasa (Alto) y sistema nervioso excitado piden '
              'movimiento de baja intensidad para no elevar el cortisol, '
              'que frena la quema de grasa.\n\n'
              'Protocolo recomendado:\n'
              '· 4 días — caminata rápida o bici suave (25-35 min)\n'
              '· 2 días — movilidad, yoga o stretching dinámico (15-20 min)\n\n'
              'El cardio de baja intensidad sostenida utiliza grasa como '
              'combustible principal (zona aeróbica). Combinado con tu '
              'ayuno intermitente, maximiza la oxidación lipídica sin '
              'disparar el cortisol.',
        );
      }
      return _ExerciseProtocol(
        typeLabel: highVisceralRisk
            ? 'Cardio diario + Fuerza funcional'
            : 'Cardio + Fuerza funcional',
        minTarget: 35,
        rationale:
            'Tu zona actual (Alto) prioriza reducción de grasa mientras '
            'preservas músculo.\n\n'
            'Protocolo recomendado:\n'
            '· 3 días — cardio moderado-intenso: caminata rápida, bici '
            'o natación (30-40 min)\n'
            '· 2 días — fuerza funcional: sentadillas, peso corporal, '
            'mancuernas ligeras (25-30 min)\n\n'
            '${highVisceralRisk ? 'Tu cintura indica grasa visceral — la caminata diaria de 30+ min es la intervención más efectiva documentada para reducirla. ' : ''}'
            'La combinación genera EPOC (quema elevada post-ejercicio) y '
            'preserva tu masa magra durante el déficit del ayuno. '
            'Cada sesión de fuerza mejora la sensibilidad a la insulina '
            'hasta 48 h después.',
      );
    }

    // ── ZONA PROMEDIO (H 18-24 %, M 25-31 %) ────────────────────────────────
    // Prioridad: recomposición corporal (↑ masa magra = ↓ %grasa sin déficit).
    if (isMale ? bf >= 18 : bf >= 25) {
      if (isExcited) {
        return const _ExerciseProtocol(
          typeLabel: 'Fuerza moderada + Cardio suave',
          minTarget: 35,
          rationale:
              'Zona Promedio con sistema nervioso excitado: recomposición '
              'sin sobrecargar el eje cortisol-adrenalina.\n\n'
              'Protocolo recomendado:\n'
              '· 3 días — fuerza con pesos moderados: sentadillas, press, '
              'jalones (30-35 min, descansos amplios)\n'
              '· 2 días — caminata o natación suave (20-25 min)\n\n'
              'La fuerza aumenta tu masa magra y mejora la sensibilidad a '
              'la insulina — efecto que el cardio de alta intensidad no '
              'produce en tu perfil nervioso. Cada kilo de músculo nuevo '
              'quema ~50 kcal adicionales en reposo.',
        );
      }
      return const _ExerciseProtocol(
        typeLabel: 'Fuerza + Cardio moderado',
        minTarget: 35,
        rationale:
            'Tu zona (Promedio) es ideal para recomposición corporal: '
            'ganar músculo mientras reduces grasa.\n\n'
            'Protocolo recomendado:\n'
            '· 3 días — fuerza compuesta: pesas, TRX o funcional (30-40 min). '
            'Ejercicios multiarticulares: sentadilla, peso muerto, press, remo\n'
            '· 2 días — cardio moderado: bici, elíptica o trote suave '
            '(25-30 min, zona 2 aeróbica)\n\n'
            'Cada kilo de músculo nuevo quema ~50 kcal adicionales en reposo '
            '— el mejor aliado de tu ayuno intermitente. La fuerza compuesta '
            'activa más fibras musculares y eleva el EPOC post-entreno.',
      );
    }

    // ── ZONA FITNESS (H 14-17 %, M 21-24 %) ─────────────────────────────────
    // Prioridad: definición + potencia metabólica.
    if (isMale ? bf >= 14 : bf >= 21) {
      if (isExcited) {
        return const _ExerciseProtocol(
          typeLabel: 'Fuerza progresiva + Cardio zona 2',
          minTarget: 35,
          rationale:
              'Zona Fitness con sistema nervioso excitado: mantén alta la '
              'intensidad en fuerza pero sustituye el HIIT por cardio zona 2.\n\n'
              'Protocolo recomendado:\n'
              '· 3-4 días — fuerza progresiva con sobrecarga gradual (35-40 min)\n'
              '· 2 días — cardio zona 2: bici o trote suave, frecuencia '
              'cardíaca 60-70 % máx (20-25 min)\n\n'
              'El cardio zona 2 optimiza la eficiencia mitocondrial y la '
              'oxidación de grasa sin añadir carga al sistema nervioso. '
              'En tu perfil, HIIT frecuente puede elevar cortisol y frenar '
              'la recuperación muscular.',
        );
      }
      return const _ExerciseProtocol(
        typeLabel: 'Fuerza progresiva + HIIT',
        minTarget: 40,
        rationale:
            'Tu zona Fitness permite entrenamientos de mayor intensidad '
            'para seguir mejorando composición corporal.\n\n'
            'Protocolo recomendado:\n'
            '· 3-4 días — fuerza progresiva con sobrecarga gradual (35-45 min). '
            'Incrementa peso o repeticiones cada 1-2 semanas\n'
            '· 2 días — HIIT corto: intervalos 40"/20" o Tabata (15-20 min). '
            'Sprints, burpees, saltos, bici estacionaria\n\n'
            'El HIIT en tu rango de grasa eleva el EPOC hasta 24 h, '
            'amplificando la quema de grasa durante el ayuno siguiente. '
            'La sobrecarga progresiva en fuerza evita la adaptación y '
            'mantiene activo tu metabolismo en reposo.',
      );
    }

    // ── ZONA ATLÉTICO / ESENCIAL (H <14 %, M <21 %) ─────────────────────────
    // Prioridad: mantenimiento de rendimiento + prevención de plateau.
    if (isExcited) {
      return const _ExerciseProtocol(
        typeLabel: 'Fuerza + Recuperación activa',
        minTarget: 40,
        rationale:
            'Tu composición atlética con sistema nervioso excitado requiere '
            'gestionar la carga de entrenamiento para evitar sobreentrenamiento.\n\n'
            'Protocolo recomendado:\n'
            '· 3-4 días — fuerza periodizada: alterna semanas de volumen '
            'e intensidad (35-45 min)\n'
            '· 2 días — recuperación activa: yoga, natación suave o '
            'caminata (20-25 min)\n\n'
            'La recuperación activa mantiene el metabolismo elevado sin '
            'acumular estrés neuromuscular. La periodización evita el '
            'plateau y mantiene la respuesta anabólica activa semana a semana.',
      );
    }
    return const _ExerciseProtocol(
      typeLabel: 'Fuerza periodizada + Cardio activo',
      minTarget: 45,
      rationale:
          'Tu composición atlética soporta entrenamiento de alto rendimiento '
          'y periodización estructurada.\n\n'
          'Protocolo recomendado:\n'
          '· 4 días — fuerza con periodización: alterna bloques de volumen '
          '(4x12) e intensidad (5x5) cada 3-4 semanas (40-50 min)\n'
          '· 2 días — cardio activo: trote, ciclismo o natación a ritmo '
          'moderado-alto (30-35 min)\n\n'
          'La periodización previene la adaptación y mantiene tu metabolismo '
          'respondiendo progresivamente. El cardio activo mejora la capacidad '
          'aeróbica sin interferir con las adaptaciones de fuerza.',
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
      target = 7.5;
      outOfRange = true;
    } else if (current > 9.0) {
      target = 8.0;
      outOfRange = false;
    } else {
      target = current; // Ya en rango — mantener
      outOfRange = false;
    }

    String statusLabel;
    if (current < 6) {
      statusLabel = 'Privación crónica de sueño';
    } else if (current < 7) {
      statusLabel = 'Por debajo del rango óptimo';
    } else if (current <= 9) {
      statusLabel = 'En rango óptimo';
    } else {
      statusLabel = 'Sueño excesivo';
    }

    return GoalSuggestion(
      type: GoalType.sleepHoursPerNight,
      currentValue: (current * 2).round() / 2.0, // redondeo 0.5 h
      suggestedTarget: target,
      rationale: '7–9 horas optimizan la regulación de cortisol y grelina. '
          'En ese rango, tu ayuno es significativamente más eficiente '
          'porque el hambre hormonal se regula durante la noche.',
      shouldActivate: outOfRange,
      currentStatusLabel: statusLabel,
    );
  }

  static double _estimateSleepHours(CircadianProfile profile) {
    // SPEC-191: USO LEGÍTIMO — estimación heurística de horas de sueño
    // a partir de la configuración del usuario. Sirve para sugerir
    // un goal personalizado. NO define el día metabólico ni se usa
    // para evaluar cumplimiento — eso lo hace el SleepLog real.
    // Ver METABOLIC_DAY_CONSTITUTION.md §9 — Test ácido.
    final double wakeDecimal =
        profile.wakeUpTime.hour + profile.wakeUpTime.minute / 60.0;
    final double sleepDecimal =
        profile.sleepTime.hour + profile.sleepTime.minute / 60.0;
    double hours = wakeDecimal - sleepDecimal;
    if (hours <= 0) hours += 24; // Cruza la medianoche
    return hours.clamp(3.0, 12.0);
  }

  // ─── Nutrición A-dominante (%) ─────────────────────────────────────────────
  //
  // SPEC-168.0.C: el pilar Nutrición se evalúa como % de comidas A-dominantes
  // (Frank Suárez). Antes existía un threshold hard-coded de 0.80; ahora el
  // usuario lo configura desde Onboarding / Perfil con sugerencia personalizada.
  //
  // Estrategia (escalera de 4 escalones para no desmotivar):
  //   - < 60 %  → target 70 %  (calidad baja: subir 1 escalón)
  //   - < 75 %  → target 80 %  (calidad media: consolidar)
  //   - < 85 %  → target 85 %  (buena: refinar)
  //   - ≥ 85 %  → mantener     (alta: no presionar más)
  //
  // Si no hay histórico (onboarding nuevo), baseline poblacional = 50 %.

  static GoalSuggestion _nutritionSuggestion(double? recentCocienteAPct) {
    final double current = (recentCocienteAPct ?? 50.0).clamp(0.0, 100.0);
    final double target;
    final bool outOfRange;

    if (current < 60.0) {
      target = 70.0;
      outOfRange = true;
    } else if (current < 75.0) {
      target = 80.0;
      outOfRange = true;
    } else if (current < 85.0) {
      target = 85.0;
      outOfRange = false;
    } else {
      target = current; // ya excelente — mantener
      outOfRange = false;
    }

    final String hadHistory = recentCocienteAPct != null
        ? 'Hoy tus comidas son ${current.toStringAsFixed(0)}% A-dominantes.'
        : 'Aún no tenemos historial suficiente; partimos del promedio '
            'poblacional (50%).';

    return GoalSuggestion(
      type: GoalType.nutritionADominantPercent,
      currentValue: current,
      suggestedTarget: target,
      rationale: '$hadHistory '
          'El sistema metabólico se vuelve más eficiente cuando llegas a '
          '${target.toStringAsFixed(0)}%: la insulina baja, el ayuno '
          'siguiente se sostiene mejor y la flexibilidad metabólica se '
          'consolida.',
      shouldActivate: outOfRange,
      currentStatusLabel: _nutritionStatusLabel(current),
    );
  }

  static String _nutritionStatusLabel(double pct) {
    if (pct < 50) return 'Calidad baja';
    if (pct < 70) return 'Calidad media';
    if (pct < 85) return 'Buena calidad';
    return 'Calidad alta';
  }

  // ─── Hidratación (litros/día) ───────────────────────────────────────────────
  //
  // Fórmula metabólica estándar: 35 ml × kg de peso corporal.
  // Misma fórmula que HydrationNotifier para consistencia.

  static GoalSuggestion _hydrationSuggestion(UserModel user) {
    final double target =
        (user.weight * 0.035 * 4).round() / 4.0; // redondeo 0.25 L
    const double averageIntake =
        1.5; // consumo típico sedentario (línea de base)

    return GoalSuggestion(
      type: GoalType.hydrationLitersPerDay,
      currentValue: averageIntake,
      suggestedTarget: target.clamp(1.0, 4.0),
      rationale: 'Tu cuerpo necesita ${target.toStringAsFixed(2)} L/día: '
          '35 ml × ${user.weight.toStringAsFixed(0)} kg. '
          'La hidratación adecuada mejora el transporte de cetonas durante '
          'el ayuno y reduce el cortisol de estrés metabólico.',
      shouldActivate: true, // Hidratación siempre relevante
      currentStatusLabel: 'Nivel estimado (sin registro)',
    );
  }
}

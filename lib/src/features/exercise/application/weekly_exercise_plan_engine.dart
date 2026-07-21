// Propuesta módulo Ejercicio (2026-07-21), Fase 2: motor puro que
// genera el plan semanal de 6 días (fuerza + cardio) + 1 descanso.
//
// Reusa el mismo insumo científico que
// goals/application/goal_suggestion_engine.dart (SPEC-244) — zona ACSM
// (BodyZone) × sistema nervioso Frank Suárez — pero en vez de producir
// un texto de rationale para una card de meta, produce una estructura
// de 7 días consumible por UI/racha/notificaciones.
//
// Evidencia (ver documentacion/propuestas/Propuesta_Modulo_Ejercicio_
// 2026-07-21.docx §3 para fuentes completas):
//   · ACSM 2025/2026 — proximidad al fallo > carga absoluta; los
//     principiantes no necesitan cargas pesadas desde el día 1.
//   · Concurrent training: fuerza+cardio la misma semana no compromete
//     fuerza/hipertrofia si no se apilan siempre el mismo día — este
//     motor reparte los tipos a lo largo de la semana en vez de
//     agruparlos.
//   · Timing circadiano: fuerza rinde más 16-20h (coincide con la fase
//     `motorFuerza` ya definida en biological_phases.dart); HIIT se
//     sugiere en `cognitivo` (9-13h); cardio suave en `receso`.
//
// Función pura — sin Flutter, sin Riverpod, sin DateTime.now() salvo
// para `generatedAt` (inyectable). Testeable con valores sintéticos.

import 'package:elena_app/src/core/orchestrator/biological_phases.dart';
import 'package:elena_app/src/features/analysis/domain/body_zone.dart';
import 'package:elena_app/src/features/exercise/domain/exercise_profile.dart';
import 'package:elena_app/src/features/exercise/domain/weekly_exercise_plan.dart';

class WeeklyExercisePlanEngine {
  WeeklyExercisePlanEngine._();

  /// Día de descanso por defecto cuando el perfil no declaró
  /// disponibilidad (ISO weekday: 7 = domingo).
  static const int _kDefaultRestWeekday = 7;

  static WeeklyExercisePlan generate({
    required BodyZone zone,
    required bool isExcited,
    required ExerciseProfile profile,
    DateTime? now,
  }) {
    final split = _splitFor(zone);
    final restWeekday = _restWeekdayFor(profile);
    final activeWeekdays = [
      for (var w = 1; w <= 7; w++)
        if (w != restWeekday) w,
    ];

    final sequence = _interleave(
      fuerzaCount: split.fuerza,
      cardioCount: split.cardio,
    );

    final strengthMinutes = _strengthMinutesFor(profile);
    final cardioMinutes = _cardioMinutesFor(zone);

    var cardioSessionIndex = 0;
    final totalCardio = split.cardio;

    final days = <PlanDayEntry>[];
    for (var i = 0; i < activeWeekdays.length; i++) {
      final weekday = activeWeekdays[i];
      final type = sequence[i];

      if (type == PlanSessionType.fuerza) {
        days.add(PlanDayEntry(
          weekday: weekday,
          type: PlanSessionType.fuerza,
          durationMinutes: strengthMinutes,
          cardioIntensity: null,
          recommendedPhase: CircadianPhase.motorFuerza,
          rationale: _strengthRationale(
            zone: zone,
            isExcited: isExcited,
            profile: profile,
          ),
        ));
      } else {
        final intensity = _cardioIntensityFor(
          zone: zone,
          isExcited: isExcited,
          sessionIndex: cardioSessionIndex,
          totalCardioSessions: totalCardio,
        );
        cardioSessionIndex++;
        days.add(PlanDayEntry(
          weekday: weekday,
          type: PlanSessionType.cardio,
          durationMinutes: cardioMinutes,
          cardioIntensity: intensity,
          recommendedPhase: intensity == CardioIntensity.alta
              ? CircadianPhase.cognitivo
              : CircadianPhase.receso,
          rationale: _cardioRationale(zone: zone, intensity: intensity),
        ));
      }
    }

    days.add(PlanDayEntry(
      weekday: restWeekday,
      type: PlanSessionType.descanso,
      durationMinutes: 0,
      cardioIntensity: null,
      recommendedPhase: null,
      rationale: 'Descanso completo — la adaptación muscular ocurre en '
          'la recuperación, no solo en el entrenamiento.',
    ));

    days.sort((a, b) => a.weekday.compareTo(b.weekday));

    return WeeklyExercisePlan(
      days: days,
      zoneLabel: zone.label,
      generatedAt: now ?? DateTime.now(),
    );
  }

  // ─── Split fuerza/cardio por zona (§4.2 de la propuesta) ────────────
  //
  // Los conteos NO cambian por sistema nervioso — `isExcited` solo
  // modula tipo/intensidad de cardio y el tono del rationale de fuerza
  // (ver _cardioIntensityFor / _strengthRationale), consistente con la
  // tabla de la propuesta ("Ajuste si sistema nervioso excitado" es en
  // su mayoría un cambio de TIPO, no de frecuencia).

  static ({int fuerza, int cardio}) _splitFor(BodyZone zone) {
    switch (zone) {
      case BodyZone.alto:
        return (fuerza: 3, cardio: 3);
      case BodyZone.promedio:
        return (fuerza: 4, cardio: 2);
      case BodyZone.fitness:
        return (fuerza: 4, cardio: 2);
      case BodyZone.atletico:
      case BodyZone.esencial:
        return (fuerza: 5, cardio: 1);
    }
  }

  // ─── Día de descanso ──────────────────────────────────────────────

  static int _restWeekdayFor(ExerciseProfile profile) {
    final available = profile.availableWeekdays;
    // Señal limpia: el usuario marcó exactamente 6 días disponibles →
    // el 7mo (el que falta) es su descanso preferido.
    if (available.length == 6) {
      for (var w = 1; w <= 7; w++) {
        if (!available.contains(w)) return w;
      }
    }
    return _kDefaultRestWeekday;
  }

  // ─── Distribución de tipos a lo largo de la semana ──────────────────
  //
  // Evidencia (§3.1): no apilar fuerza y cardio de alta intensidad
  // siempre el mismo bloque de días — reparte proporcionalmente en vez
  // de agrupar todo el cardio al final. Algoritmo de distribución
  // uniforme (acumulador tipo Bresenham) sobre 6 slots.

  static List<PlanSessionType> _interleave({
    required int fuerzaCount,
    required int cardioCount,
  }) {
    final total = fuerzaCount + cardioCount;
    final sequence = <PlanSessionType>[];
    var acc = 0;
    for (var i = 0; i < total; i++) {
      acc += fuerzaCount;
      if (acc >= total) {
        acc -= total;
        sequence.add(PlanSessionType.fuerza);
      } else {
        sequence.add(PlanSessionType.cardio);
      }
    }
    // El acumulador puede dejar todo el cardio al principio si
    // fuerzaCount < cardioCount (nunca ocurre con nuestras zonas, pero
    // por robustez lo normalizamos): si el primer elemento es cardio y
    // hay fuerza en la secuencia, rotamos para empezar con fuerza — el
    // orden fuerza→cardio dentro de la semana preserva mejor la fuerza
    // dinámica (§3.1, secuencia intra-sesión — aplicado aquí a nivel
    // semanal por analogía conservadora).
    if (sequence.isNotEmpty &&
        sequence.first == PlanSessionType.cardio &&
        fuerzaCount > 0) {
      final firstFuerza =
          sequence.indexOf(PlanSessionType.fuerza);
      final rotated = [
        ...sequence.sublist(firstFuerza),
        ...sequence.sublist(0, firstFuerza),
      ];
      return rotated;
    }
    return sequence;
  }

  // ─── Duración por sesión ─────────────────────────────────────────────

  static int _strengthMinutesFor(ExerciseProfile profile) {
    // ACSM 2025/2026: principiantes no necesitan sesiones largas para
    // adaptarse — la proximidad al fallo importa más que el volumen.
    switch (profile.strengthExperience) {
      case ExerciseExperienceLevel.none:
        return 25;
      case ExerciseExperienceLevel.lessThan6Months:
        return 30;
      case ExerciseExperienceLevel.sixTo24Months:
        return 40;
      case ExerciseExperienceLevel.moreThan2Years:
        return 45;
    }
  }

  static int _cardioMinutesFor(BodyZone zone) {
    switch (zone) {
      case BodyZone.alto:
        return 30; // OMS: caminata diaria 30+ min es la intervención
        // más documentada para grasa visceral.
      case BodyZone.promedio:
      case BodyZone.fitness:
        return 25;
      case BodyZone.atletico:
      case BodyZone.esencial:
        return 25;
    }
  }

  // ─── Intensidad de cardio ────────────────────────────────────────────
  //
  // Sistema nervioso excitado → siempre baja intensidad (zona 2 /
  // caminata) para no sobrecargar el eje cortisol-adrenalina — mismo
  // criterio que GoalSuggestionEngine._exerciseProtocolFor. No excitado
  // → se reserva 1 sesión de alta intensidad (HIIT) cuando el split
  // tiene ≥2 cardio; con 1 sola sesión de cardio (zonas Atlético/
  // Esencial) se prioriza baja intensidad para no competir con el
  // volumen alto de fuerza de esas zonas.

  static CardioIntensity _cardioIntensityFor({
    required BodyZone zone,
    required bool isExcited,
    required int sessionIndex,
    required int totalCardioSessions,
  }) {
    if (isExcited) return CardioIntensity.baja;
    if (totalCardioSessions <= 1) return CardioIntensity.baja;
    // Una sola sesión de alta intensidad por semana — la última del
    // bloque de cardio (no la primera, para no anteponer fatiga
    // neuromuscular al resto de la semana).
    final isLastCardio = sessionIndex == totalCardioSessions - 1;
    return isLastCardio ? CardioIntensity.alta : CardioIntensity.baja;
  }

  // ─── Rationale corto por sesión ──────────────────────────────────────

  static String _strengthRationale({
    required BodyZone zone,
    required bool isExcited,
    required ExerciseProfile profile,
  }) {
    if (profile.hasInjuries) {
      return 'Fuerza con foco en técnica y movilidad — evita cargar la '
          'zona que declaraste con molestias.';
    }
    final intensityWord = isExcited ? 'moderada' : 'progresiva';
    switch (zone) {
      case BodyZone.alto:
        return 'Fuerza funcional $intensityWord — preserva masa magra '
            'mientras reduces grasa.';
      case BodyZone.promedio:
        return 'Fuerza compuesta $intensityWord — motor de la '
            'recomposición corporal en tu zona.';
      case BodyZone.fitness:
        return 'Fuerza $intensityWord con sobrecarga gradual — sigue '
            'mejorando composición corporal.';
      case BodyZone.atletico:
      case BodyZone.esencial:
        return 'Fuerza periodizada — mantenimiento de rendimiento sin '
            'plateau.';
    }
  }

  static String _cardioRationale({
    required BodyZone zone,
    required CardioIntensity intensity,
  }) {
    if (intensity == CardioIntensity.alta) {
      return 'HIIT corto — eleva el EPOC hasta 24h, amplifica la quema '
          'de grasa en el ayuno siguiente.';
    }
    return 'Cardio zona 2 — usa grasa como combustible principal sin '
        'elevar cortisol ni interferir con tu fuerza.';
  }
}

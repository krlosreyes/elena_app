// SPEC-148 §RF-148-03 (2026-06-05): TransformationNarrator.
//
// Selecciona UN copy del pool de 12 según los deltas dominantes del
// snapshot 30d. Pure Dart — sin Flutter ni Riverpod. Determinista
// (mismo snapshot + mismo recentIds → mismo copy).
//
// Tono: humano-cercano, sin culpa, segunda persona, reconoce esfuerzo.
// Memoria de proyecto: `notification-tone-human-not-clinical`.
//
// Bibliografía: las citas son las mismas que usan los hitos de ayuno
// (SPEC-169 §14) y el CycleFeedbackGenerator (SPEC-149) para
// consistencia perceptual.

import 'package:elena_app/src/features/analysis/domain/transformation_snapshot.dart';

/// Una narrativa elegida del pool. Lo que la `TransformationCard`
/// renderiza debajo de la grilla de indicadores.
class TransformationNarrative {
  /// Identificador estable para el cooldown anti-repetición. Se persiste
  /// en SharedPreferences por el caller del widget si quiere evitar
  /// repetir el mismo copy varios snapshots seguidos.
  final String id;

  /// Frase del coach. Termina con punto. No incluye la cita — el
  /// widget la pinta aparte con tipografía distinta.
  final String headline;

  /// Cita corta tipo `'Autor Año'`. Null si el copy no necesita
  /// respaldo bibliográfico (caso del fallback default).
  final String? citation;

  const TransformationNarrative({
    required this.id,
    required this.headline,
    this.citation,
  });
}

class TransformationNarrator {
  TransformationNarrator._();

  // Tolerancias para considerar un cambio "significativo". Calibradas
  // contra ruido de medición típico (báscula doméstica ±0.3 kg, cinta
  // ±0.5 cm, etc.).
  static const double _kWeightEpsilonKg = 0.3;
  static const double _kWaistEpsilonCm = 0.5;
  static const double _kBodyFatEpsilonPct = 0.5;
  static const double _kSleepEpsilonHours = 0.2;
  static const int _kImrEpsilon = 2;

  /// Selecciona la mejor narrativa para el snapshot dado.
  ///
  /// `recentIds`: ids del pool ya mostrados en snapshots anteriores —
  /// el narrador trata de evitar repetir. Si todos los candidatos
  /// válidos están en `recentIds`, igual devuelve el primero (mejor
  /// repetir un insight relevante que mostrar uno irrelevante).
  ///
  /// Si el snapshot no tiene ningún indicador con ambos puntos
  /// (`isEmpty`), retorna `null` — el widget muestra el placeholder
  /// cálido en lugar de una narrativa.
  static TransformationNarrative? pick(
    TransformationSnapshot snapshot, {
    Set<String> recentIds = const {},
  }) {
    if (snapshot.isEmpty) return null;

    final candidates = _candidates(snapshot);

    // Primera pasada: elegir el primero NO repetido.
    for (final c in candidates) {
      if (!recentIds.contains(c.id)) return c;
    }
    // Segunda pasada: todos están en recentIds — devolver el primero.
    if (candidates.isNotEmpty) return candidates.first;

    // Default — siempre matchea, último recurso.
    return _default;
  }

  static const _default = TransformationNarrative(
    id: 'default',
    headline:
        'Cada 30 días cuenta. Seguir registrando te da la foto.',
    citation: null,
  );

  // ─── Pool ────────────────────────────────────────────────────────────

  static List<TransformationNarrative> _candidates(
    TransformationSnapshot s,
  ) {
    final out = <TransformationNarrative>[];

    final weightDelta = s.weightKg.delta?.toDouble();
    final waistDelta = s.waistCm.delta?.toDouble();
    final bodyFatDelta = s.bodyFatPct.delta?.toDouble();
    final sleepDelta = s.sleepHoursAvg.delta?.toDouble();
    final fastingDelta = s.fastingDaysOf7.delta?.toInt();
    final imrDelta = s.imr.delta?.toInt();
    final currentFasting = s.fastingDaysOf7.current ?? 0;

    bool weightDown(double byKg) =>
        weightDelta != null && weightDelta <= -byKg;
    bool weightUp(double byKg) =>
        weightDelta != null && weightDelta >= byKg;
    bool weightStable() => s.weightKg.isStableWithin(_kWeightEpsilonKg);

    bool waistDown(double byCm) =>
        waistDelta != null && waistDelta <= -byCm;
    bool waistStable() => s.waistCm.isStableWithin(_kWaistEpsilonCm);

    bool bodyFatDown(double byPct) =>
        bodyFatDelta != null && bodyFatDelta <= -byPct;

    bool sleepUp(double byH) =>
        sleepDelta != null && sleepDelta >= byH;
    bool sleepDown(double byH) =>
        sleepDelta != null && sleepDelta <= -byH;
    bool sleepStable() => s.sleepHoursAvg.isStableWithin(_kSleepEpsilonHours);

    bool fastingHighNow() => currentFasting >= 5;
    bool fastingMoreThan(int by) =>
        fastingDelta != null && fastingDelta >= by;
    bool fastingLessThan(int by) =>
        fastingDelta != null && fastingDelta <= -by;

    bool imrUp(int by) => imrDelta != null && imrDelta >= by;

    // ── 1. Progreso claro (4 copies) ────────────────────────────────

    if (weightDown(1.0) && fastingHighNow()) {
      out.add(const TransformationNarrative(
        id: 'progress-weight-down-fasting-high',
        headline:
            'Tu ayuno está haciendo el trabajo, y se ve en la balanza. '
            'Seguilo así.',
        citation: 'Mattson 2017',
      ));
    }

    if (imrUp(_kImrEpsilon) && sleepUp(_kSleepEpsilonHours)) {
      out.add(const TransformationNarrative(
        id: 'progress-imr-up-sleep-up',
        headline:
            'El sueño está empujando tu base metabólica hacia arriba. '
            'Cuando duermes mejor, el resto se ordena.',
        citation: 'Walker 2017',
      ));
    }

    if (waistDown(1.5) && bodyFatDown(1.0)) {
      out.add(const TransformationNarrative(
        id: 'progress-waist-down-bf-down',
        headline:
            'Estás perdiendo lo que se nota en salud — visceral y '
            'composición — no solo en la balanza.',
        citation: 'Lopez-Minguez 2018',
      ));
    }

    if (fastingMoreThan(2) && currentFasting >= 5) {
      // No `const` — interpola `currentFasting` (variable runtime).
      out.add(TransformationNarrative(
        id: 'progress-fasting-streak-grew',
        headline:
            '$currentFasting de 7 días de ayuno es disciplina, no fuerza '
            'de voluntad. Acabás de cruzar a hábito.',
        citation: 'Levine 2017',
      ));
    }

    // ── 2. Cambio silente (3 copies) ────────────────────────────────

    if (weightStable() && waistDown(1.0)) {
      out.add(const TransformationNarrative(
        id: 'silent-weight-stable-waist-down',
        headline:
            'Estás perdiendo visceral antes que masa magra — eso es '
            'exactamente lo que querés ver.',
        citation: 'Petersen-Shulman 2018',
      ));
    }

    if (weightUp(0.5) && bodyFatDown(0.5)) {
      out.add(const TransformationNarrative(
        id: 'silent-weight-up-bf-down',
        headline:
            'Subiste un poco de peso pero bajaste grasa: el músculo pesa '
            'más, y el cuerpo está cambiando para mejor.',
        citation: 'ACSM 2021',
      ));
    }

    if (waistStable() && sleepUp(_kSleepEpsilonHours)) {
      out.add(const TransformationNarrative(
        id: 'silent-waist-stable-sleep-up',
        headline:
            'El sueño consistente está consolidando los cambios que '
            'todavía no se ven afuera, pero sí adentro.',
        citation: 'Walker 2017',
      ));
    }

    // ── 3. Estancamiento legítimo (2 copies) ───────────────────────

    if (weightStable() &&
        waistStable() &&
        sleepStable() &&
        currentFasting >= 4) {
      out.add(const TransformationNarrative(
        id: 'plateau-discipline-pays',
        headline:
            'Seguís registrando con consistencia. El cuerpo responde en '
            'ondas, no en líneas rectas — la próxima ola se prepara.',
        citation: 'Sutton 2018',
      ));
    }

    if (weightStable() && waistStable() && sleepStable()) {
      out.add(const TransformationNarrative(
        id: 'plateau-next-wave',
        headline:
            '30 días sin cambio visible no es estancamiento — es el '
            'cuerpo construyendo abajo lo que vas a ver arriba pronto.',
        citation: 'Mattson 2017',
      ));
    }

    // ── 4. Retroceso sin culpa (2 copies) ───────────────────────────

    if (weightUp(1.0) && fastingLessThan(1)) {
      out.add(const TransformationNarrative(
        id: 'setback-weight-up-fasting-down',
        headline:
            'El último mes tuvo más comidas social y menos ayunos — '
            'sin culpa. Esta semana volvemos a tomar ritmo.',
        citation: null,
      ));
    }

    if (sleepDown(0.5)) {
      out.add(const TransformationNarrative(
        id: 'setback-sleep-dropped',
        headline:
            'Tu sueño cayó este mes, y el cuerpo lo está sintiendo. '
            'Acostarte 20 min antes esta noche ya empieza a sumar.',
        citation: 'Walker 2017',
      ));
    }

    return out;
  }
}

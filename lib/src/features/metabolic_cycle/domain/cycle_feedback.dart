// SPEC-149: CycleFeedback — el coaching moment al cierre del ciclo.
//
// Generado al momento del cierre por funciones puras que reciben las
// magnitudes finales y producen achievements, gaps, insight y citation.
//
// Cada línea de feedback debe ser:
// - Específica al pilar y magnitud (no genérica).
// - Anclada a una cita bibliográfica del proyecto cuando aplica.
// - Actionable (decirle al usuario qué hacer mañana, no solo describir).

import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';

/// Umbral por encima del cual un pilar se considera "logrado" para el
/// feedback. Coherente con SPEC-149 §RF-149-03.
const double kAchievementThreshold = 0.80;

/// Coaching feedback generado al cierre de un MetabolicCycle.
class CycleFeedback {
  /// Lista de logros del ciclo — pilares con magnitud ≥0.80 con copy
  /// específico que celebra y educa.
  final List<String> achievements;

  /// Lista de gaps — pilares por debajo del umbral, ordenados de mayor
  /// a menor gap. Copy actionable indica qué hacer mañana.
  final List<String> gaps;

  /// Insight adaptativo seleccionado de un pool según el patrón del
  /// ciclo. Una frase educativa que conecta el comportamiento con la
  /// ciencia metabólica.
  final String insight;

  /// Cita bibliográfica que respalda el insight. Formato corto:
  /// 'Autor Año, Revista'. Null si el insight no requiere cita.
  final String? citation;

  const CycleFeedback({
    required this.achievements,
    required this.gaps,
    required this.insight,
    this.citation,
  });
}

/// Generador puro de CycleFeedback. Determinista — mismas magnitudes +
/// mismos parámetros producen mismo feedback.
///
/// Para evitar copy repetitivo en ciclos consecutivos, el caller puede
/// pasar `recentInsightIds` (los IDs de los últimos N insights ya
/// mostrados) y el generador evita repetir.
class CycleFeedbackGenerator {
  CycleFeedbackGenerator._();

  /// Construye el feedback completo del ciclo.
  static CycleFeedback generate({
    required CycleMagnitudes magnitudes,
    required double? fastingDurationHours,
    required double? feedingWindowHours,
    required DateTime? windowClosedAt,
    Set<String> recentInsightIds = const {},
  }) {
    final achievements = _buildAchievements(
      magnitudes: magnitudes,
      fastingDurationHours: fastingDurationHours,
      feedingWindowHours: feedingWindowHours,
      windowClosedAt: windowClosedAt,
    );
    final gaps = _buildGaps(magnitudes);
    final picked = _pickInsight(
      magnitudes: magnitudes,
      fastingDurationHours: fastingDurationHours,
      windowClosedAt: windowClosedAt,
      recentInsightIds: recentInsightIds,
    );
    return CycleFeedback(
      achievements: achievements,
      gaps: gaps,
      insight: picked.text,
      citation: picked.citation,
    );
  }

  // ─── Achievements ─────────────────────────────────────────────────────────

  static List<String> _buildAchievements({
    required CycleMagnitudes magnitudes,
    required double? fastingDurationHours,
    required double? feedingWindowHours,
    required DateTime? windowClosedAt,
  }) {
    final out = <String>[];

    // Ayuno: si fastingMagnitude ≥0.80 Y hubo ayuno real.
    if (magnitudes.fastingMagnitude >= kAchievementThreshold &&
        fastingDurationHours != null &&
        fastingDurationHours >= 12) {
      final hours = fastingDurationHours.toStringAsFixed(1);
      out.add('Ayuno ${hours}h — autofagia activa (Mattson 2017)');
    }

    // Sueño: si magnitud ≥0.80 → 7h+ típicamente.
    if (magnitudes.sleepQualityScore >= kAchievementThreshold) {
      out.add('Sueño reparador — leptina/grelina equilibradas (Walker 2017)');
    }

    // Hidratación al ≥100%: termorregulación + cognición OK.
    if (magnitudes.hydrationMagnitude >= 1.0) {
      out.add('Hidratación completa — termorregulación óptima (EFSA 2010)');
    }

    // Ejercicio al ≥100%: dosis ACSM cumplida.
    if (magnitudes.exerciseMagnitude >= 1.0) {
      out.add('Ejercicio completo — dosis ACSM cumplida (ACSM 2021)');
    }

    // Nutrición: Cociente A ≥0.80.
    if (magnitudes.nutritionMagnitude >= kAchievementThreshold) {
      final pct = (magnitudes.nutritionMagnitude * 100).round();
      out.add('Cociente A $pct% — respuesta insulínica baja (Liu 2000)');
    }

    // Ventana cerrada temprano: bonus si cerraste antes de las 19h.
    if (windowClosedAt != null && windowClosedAt.hour < 19) {
      final hh = windowClosedAt.hour.toString().padLeft(2, '0');
      final mm = windowClosedAt.minute.toString().padLeft(2, '0');
      out.add('Ventana cerrada $hh:$mm — eTRF favorable (Sutton 2018)');
    }

    return out;
  }

  // ─── Gaps ─────────────────────────────────────────────────────────────────

  static List<String> _buildGaps(CycleMagnitudes m) {
    final candidates = <({String pillar, double gap, String copy})>[];

    if (m.fastingMagnitude < kAchievementThreshold) {
      candidates.add((
        pillar: 'fasting',
        gap: kAchievementThreshold - m.fastingMagnitude,
        copy: 'Ayuno corto — mañana apuntá al 80% del protocolo para activar autofagia',
      ));
    }
    if (m.sleepQualityScore < kAchievementThreshold) {
      candidates.add((
        pillar: 'sleep',
        gap: kAchievementThreshold - m.sleepQualityScore,
        copy: 'Sueño bajo — Spiegel 1999: <7h desregula leptina y aumenta hambre al día siguiente',
      ));
    }
    if (m.hydrationMagnitude < kAchievementThreshold) {
      final pct = (m.hydrationMagnitude * 100).round();
      candidates.add((
        pillar: 'hydration',
        gap: kAchievementThreshold - m.hydrationMagnitude,
        copy: 'Hidratación $pct% — mañana 2L para mantener termorregulación',
      ));
    }
    if (m.exerciseMagnitude < kAchievementThreshold) {
      candidates.add((
        pillar: 'exercise',
        gap: kAchievementThreshold - m.exerciseMagnitude,
        copy: 'Ejercicio incompleto — 20 min mínimo es la dosis ACSM diaria',
      ));
    }
    if (m.nutritionMagnitude < kAchievementThreshold) {
      final pct = (m.nutritionMagnitude * 100).round();
      candidates.add((
        pillar: 'nutrition',
        gap: kAchievementThreshold - m.nutritionMagnitude,
        copy: 'Cociente A $pct% — más verduras y proteína en próximas comidas',
      ));
    }

    // Ordenar por gap descendente — el peor primero.
    candidates.sort((a, b) => b.gap.compareTo(a.gap));
    return candidates.map((c) => c.copy).toList();
  }

  // ─── Insight adaptativo ──────────────────────────────────────────────────

  static ({String text, String? citation, String id}) _pickInsight({
    required CycleMagnitudes magnitudes,
    required double? fastingDurationHours,
    required DateTime? windowClosedAt,
    required Set<String> recentInsightIds,
  }) {
    // Pool de insights candidatos con su precondición y prioridad.
    // El primero que matchea y NO está en recentInsightIds gana.
    final candidates = _insightPool(
      magnitudes: magnitudes,
      fastingDurationHours: fastingDurationHours,
      windowClosedAt: windowClosedAt,
    );

    for (final c in candidates) {
      if (!recentInsightIds.contains(c.id)) {
        return c;
      }
    }
    // Si todos están en recentInsightIds, devolver el primero igual
    // (mejor repetir un insight relevante que mostrar uno irrelevante).
    return candidates.isEmpty
        ? (
            text:
                'Cada ciclo metabólico es una oportunidad de mejora. Mañana es otro día.',
            citation: null,
            id: 'default'
          )
        : candidates.first;
  }

  static List<({String text, String? citation, String id})> _insightPool({
    required CycleMagnitudes magnitudes,
    required double? fastingDurationHours,
    required DateTime? windowClosedAt,
  }) {
    final out = <({String text, String? citation, String id})>[];
    final fasting = magnitudes.fastingMagnitude;
    final sleep = magnitudes.sleepQualityScore;
    final nutrition = magnitudes.nutritionMagnitude;
    final hydration = magnitudes.hydrationMagnitude;
    final exercise = magnitudes.exerciseMagnitude;

    // Ayuno alto + sueño bajo: la autofagia no se consolida.
    if (fasting >= 0.85 && sleep < 0.70) {
      out.add((
        text:
            'Tu ayuno fue excelente pero el sueño quedó corto. La autofagia que iniciaste no se consolida sin sueño profundo.',
        citation: 'Mattson 2017 + Walker 2017',
        id: 'insight-fasting-high-sleep-low',
      ));
    }

    // Ayuno bueno + nutrición E-dominante: contradicción metabólica.
    if (fasting >= 0.80 && nutrition < 0.50) {
      out.add((
        text:
            'Buen ayuno, pero hoy tus platos fueron E-dominantes. El ayuno gana cuando la ventana cierra con A.',
        citation: 'Sutton 2018 + Frank Suárez §3',
        id: 'insight-fasting-good-nutrition-e',
      ));
    }

    // Ventana cerrada temprano + nutrición alta: combo perfecto.
    if (windowClosedAt != null &&
        windowClosedAt.hour < 19 &&
        nutrition >= 0.80) {
      out.add((
        text:
            'Cerrar la ventana temprano con platos A-dominantes es la combinación de mayor impacto. Sostén este patrón.',
        citation: 'Sutton 2018 + Lopez-Minguez 2018',
        id: 'insight-early-window-high-nutrition',
      ));
    }

    // Hidratación baja con ejercicio alto: deshidratación de entrenamiento.
    if (hydration < 0.60 && exercise >= 0.80) {
      out.add((
        text:
            'Entrenaste bien pero la hidratación quedó corta. El ejercicio sin hidratación adecuada compromete recuperación.',
        citation: 'ACSM 2021 + EFSA 2010',
        id: 'insight-low-hydration-high-exercise',
      ));
    }

    // Todo ≥0.80: ciclo óptimo.
    if (fasting >= 0.80 &&
        sleep >= 0.80 &&
        hydration >= 0.80 &&
        exercise >= 0.80 &&
        nutrition >= 0.80) {
      out.add((
        text:
            'Ciclo metabólico óptimo. Esta consistencia es lo que mueve tu IMR longitudinal — no los picos puntuales.',
        citation: 'Petersen-Shulman 2018',
        id: 'insight-perfect-cycle',
      ));
    }

    // Sueño bajo + nutrición baja: spiral de hambre.
    if (sleep < 0.60 && nutrition < 0.60) {
      out.add((
        text:
            'Dormiste poco y comiste E-dominante. Spiegel 1999 mostró que <7h de sueño aumenta hambre y reduce control nutricional al día siguiente.',
        citation: 'Spiegel 1999, Lancet',
        id: 'insight-low-sleep-low-nutrition',
      ));
    }

    // Ayuno bajo (usuario empezando o saltó):
    if (fasting < 0.50 && fasting > 0.0) {
      out.add((
        text:
            'Tu ayuno fue corto hoy. Para activar autofagia se necesitan al menos 14h continuas (Mattson 2017). Empezá mañana 30 min antes.',
        citation: 'Mattson 2017, Ageing Res Rev',
        id: 'insight-short-fasting',
      ));
    }

    // Default si nada matchea con prioridad: mensaje general motivacional.
    out.add((
      text:
          'Cada ciclo metabólico cerrado es información. La constancia mueve el IMR.',
      citation: null,
      id: 'insight-general-motivational',
    ));

    return out;
  }
}

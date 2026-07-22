// SPEC-69: SleepQualityCalculator — métrica multidimensional de calidad de sueño.
//
// Antes (SPEC-04): `sleepQuality` era una función monótona de horas dormidas
// (curve piecewise: <7h linear hasta 0.85, 7-9h = 1.0, >9h penalización
// gradual). Ignoraba dimensiones que la literatura del sueño considera
// críticas: latencia, fragmentación, brecha metabólica con la última cena.
//
// Ahora: combinación ponderada de 4 dimensiones disponibles (la 5ta —
// subjectiveQuality — entra como bonus opcional). Degrada graciosamente
// cuando faltan dimensiones (RF-69-04): renormaliza los pesos sobre las
// dimensiones disponibles, manteniendo el rango de salida 0.0–1.0.
//
// Función pura. Sin Flutter, sin DateTime.now(), sin estado mutable.

class SleepQualityCalculator {
  SleepQualityCalculator._();

  // ── Constantes de pesos — SPEC-70: ref IMR_BIBLIOGRAPHY.md §5 ───────────

  /// Peso de la duración. SPEC-70 §5.1 — HIGH (AASM, Walker 2017).
  static const double _wDuration = 0.50;

  /// Peso de la brecha metabólica. SPEC-70 §5.2 — MEDIUM (Crispim 2011).
  static const double _wMetabolicGap = 0.20;

  /// Peso de la latencia. SPEC-70 §5.3 — MEDIUM (Spielman 1987).
  static const double _wLatency = 0.15;

  /// Peso de los despertares. SPEC-70 §5.4 — MEDIUM (Bonnet & Arand 2003).
  static const double _wAwakenings = 0.15;

  // ── API ────────────────────────────────────────────────────────────────

  /// Calcula la calidad de sueño normalizada en [0.0, 1.0].
  ///
  /// [sleepHours]            — duración total. Obligatorio.
  /// [metabolicGapMinutes]   — minutos entre última comida y dormir.
  ///                            Si null, la dimensión se omite y se renormaliza.
  /// [sleepLatencyMinutes]   — null → omitida.
  /// [nightAwakenings]       — null → omitida.
  /// [subjectiveQuality]     — 1-5, opcional. Si presente, multiplica el
  ///                            score final por un factor en [0.85, 1.10].
  ///
  /// Garantías:
  /// - Si solo se provee `sleepHours`, equivale al cálculo anterior
  ///   (curve piecewise por duración) — backward compat.
  /// - Si todas las dimensiones están presentes, la fórmula completa aplica.
  /// - Resultado siempre en [0.0, 1.0].
  static double calculate({
    required double sleepHours,
    int? metabolicGapMinutes,
    int? sleepLatencyMinutes,
    int? nightAwakenings,
    int? subjectiveQuality,
  }) {
    // Score por duración (siempre presente).
    final double durationScore = _scoreDuration(sleepHours);

    // Acumular pesos efectivos solo de las dimensiones disponibles.
    double totalWeight = _wDuration;
    double weightedSum = _wDuration * durationScore;

    if (metabolicGapMinutes != null) {
      weightedSum += _wMetabolicGap * _scoreMetabolicGap(metabolicGapMinutes);
      totalWeight += _wMetabolicGap;
    }
    if (sleepLatencyMinutes != null) {
      weightedSum += _wLatency * _scoreLatency(sleepLatencyMinutes);
      totalWeight += _wLatency;
    }
    if (nightAwakenings != null) {
      weightedSum += _wAwakenings * _scoreAwakenings(nightAwakenings);
      totalWeight += _wAwakenings;
    }

    final double base = (weightedSum / totalWeight).clamp(0.0, 1.0);

    // Bonus / penalización suave por percepción subjetiva.
    if (subjectiveQuality != null) {
      final factor = _subjectiveFactor(subjectiveQuality);
      return (base * factor).clamp(0.0, 1.0);
    }
    return base;
  }

  // ── Scores por dimensión ───────────────────────────────────────────────

  /// Curva piecewise por horas dormidas (antiguo `_normalizeSleep` del
  /// MetabolicStateBuilder, conservada por compatibilidad numérica).
  static double _scoreDuration(double hours) {
    if (hours <= 0) return 0.0;
    if (hours < 7) return ((hours / 7.0) * 0.85).clamp(0.0, 1.0);
    if (hours <= 9) return 1.0;
    // > 9h: penalización gradual, mínimo 0.6.
    return (1.0 - ((hours - 9) / 5.0)).clamp(0.6, 1.0);
  }

  /// Brecha metabólica: > 3h es óptimo. SPEC-70 §5.5 — escalones LOW
  /// (gradación lineal-aproximada del riesgo, sin literatura directa
  /// para los puntos intermedios).
  static double _scoreMetabolicGap(int minutes) {
    if (minutes >= 180) return 1.0; // ≥ 3h (Crispim 2011)
    if (minutes >= 120) return 0.7; // 2-3h
    if (minutes >= 60) return 0.4; // 1-2h
    return 0.1; // < 1h: digestión activa al dormir
  }

  /// Latencia. SPEC-70 §5.6 — umbral 30min MEDIUM (modelo 3P de
  /// Spielman); demás escalones LOW.
  static double _scoreLatency(int minutes) {
    if (minutes <= 20) return 1.0;
    if (minutes <= 30) return 0.7; // umbral diagnóstico Spielman
    if (minutes <= 60) return 0.4;
    return 0.1; // > 1h
  }

  /// Despertares. SPEC-70 §5.7 — ENGINEERING JUDGMENT (sin umbral
  /// clínico universal; gradación proporcional 0-1 normal → 4+ patológico).
  static double _scoreAwakenings(int count) {
    if (count <= 1) return 1.0;
    if (count == 2) return 0.7;
    if (count == 3) return 0.4;
    return 0.1; // ≥ 4
  }

  /// Factor multiplicativo por calidad subjetiva 1-5.
  /// SPEC-70 §5.8 — ENGINEERING JUDGMENT (rango asimétrico 0.85–1.10
  /// porque "muy mal" reportado tiende a tener más fundamento que
  /// "muy bien"; el ajuste subjetivo nunca domina al objetivo).
  /// Mapeo lineal: 1→0.85, 2→0.92, 3→1.00, 4→1.05, 5→1.10.
  static double _subjectiveFactor(int rating) {
    switch (rating) {
      case 1:
        return 0.85;
      case 2:
        return 0.92;
      case 3:
        return 1.00;
      case 4:
        return 1.05;
      case 5:
        return 1.10;
      default:
        return 1.0;
    }
  }
}

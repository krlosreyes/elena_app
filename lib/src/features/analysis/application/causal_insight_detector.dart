// SPEC-162: motor de detección de patrones causa-efecto.
//
// Toma series temporales de hábitos (inputs) y outcomes (resultados)
// y emite los patrones detectados, ordenados por fuerza descendente.
//
// Pure Dart — sin Flutter ni Riverpod.

import 'package:elena_app/src/features/analysis/domain/causal_insight.dart';
import 'package:elena_app/src/features/analysis/domain/metric_series.dart';
import 'package:elena_app/src/features/analysis/domain/time_series_point.dart';

class CausalInsightDetector {
  CausalInsightDetector._();

  /// Mínimo de puntos (semanas) necesarios para correr el detector.
  static const int kMinPointsForDetection = 4;

  /// Magnitud de cambio que activa `sustainedImprovement` (relativa
  /// al rango de la serie).
  static const double kSustainedImprovementThreshold = 0.20;

  /// Magnitud de caída que activa `criticalDrop`.
  static const double kCriticalDropThreshold = 0.20;

  /// Magnitud de caída semana-a-semana para `weeklyDrop`.
  static const double kWeeklyDropThreshold = 0.15;

  /// Detecta hasta `maxInsights` patrones, ordenados por fuerza
  /// descendente. Si no encuentra ninguno, retorna lista vacía y la
  /// UI muestra mensaje neutro.
  ///
  /// `habits`: las 5 series de pilares (Ayuno, Nutrición, Hidratación,
  /// Ejercicio, Sueño).
  /// `outcomes`: las series de resultados (IMR, Peso).
  static List<CausalInsight> detect({
    required List<MetricSeries> habits,
    required List<MetricSeries> outcomes,
    int maxInsights = 3,
  }) {
    final found = <CausalInsight>[];

    // Sostenida mejora correlacionada con outcome.
    for (final habit in habits) {
      for (final outcome in outcomes) {
        final ins = _detectSustainedImprovement(habit, outcome);
        if (ins != null) found.add(ins);
      }
    }

    // Caída crítica de hábito.
    for (final habit in habits) {
      final ins = _detectCriticalDrop(habit);
      if (ins != null) found.add(ins);
    }

    // Mejor período del outcome principal (IMR).
    if (outcomes.isNotEmpty) {
      final imr = outcomes.first; // convención: primer outcome = IMR
      final ins = _detectBestPeriod(imr, habits);
      if (ins != null) found.add(ins);
    }

    // Caída semanal de outcome con co-ocurrencia de caída de hábito.
    for (final outcome in outcomes) {
      for (final habit in habits) {
        final ins = _detectWeeklyDrop(outcome, habit);
        if (ins != null) found.add(ins);
      }
    }

    // Ordenar por strength descendente y limitar.
    found.sort((a, b) => b.strength.compareTo(a.strength));
    return found.take(maxInsights).toList();
  }

  // ─── Detectores ────────────────────────────────────────────────────

  /// `sustainedImprovement`: hábito subió ≥20% del rango Y outcome
  /// también mejoró (sube si es IMR, baja si es Peso) en el mismo lapso.
  static CausalInsight? _detectSustainedImprovement(
    MetricSeries habit,
    MetricSeries outcome,
  ) {
    if (habit.points.length < kMinPointsForDetection ||
        outcome.points.length < kMinPointsForDetection) {
      return null;
    }
    final habitDelta = habit.points.last.value - habit.points.first.value;
    final habitRange = habit.maxValue - habit.minValue;
    if (habitRange == 0) return null;
    final habitChangeRel = habitDelta / habitRange;
    if (habitChangeRel < kSustainedImprovementThreshold) return null;

    final outcomeDelta = outcome.points.last.value - outcome.points.first.value;
    final outcomeImproved = _outcomeImproved(outcome.label, outcomeDelta);
    if (!outcomeImproved) return null;

    final strength = habitChangeRel.clamp(0.0, 1.0);
    return CausalInsight(
      type: CausalInsightType.sustainedImprovement,
      headline:
          'Subiste tu ${habit.label.toLowerCase()} de '
          '${_fmt(habit.points.first.value)} a '
          '${_fmt(habit.points.last.value)} ${habit.unit}.',
      detail: 'Tu ${outcome.label} pasó de '
          '${_fmt(outcome.points.first.value)} a '
          '${_fmt(outcome.points.last.value)} ${outcome.unit} '
          'en el mismo lapso.',
      citation: _citationForHabit(habit.label),
      periodStart: habit.points.first.weekStart,
      periodEnd: habit.points.last.weekStart,
      strength: strength,
    );
  }

  /// `criticalDrop`: hábito cayó ≥20% del rango en las últimas semanas.
  static CausalInsight? _detectCriticalDrop(MetricSeries habit) {
    if (habit.points.length < kMinPointsForDetection) return null;
    final delta = habit.points.last.value - habit.points.first.value;
    final range = habit.maxValue - habit.minValue;
    if (range == 0) return null;
    final relChange = delta / range;
    if (relChange > -kCriticalDropThreshold) return null;
    final strength = relChange.abs().clamp(0.0, 1.0);
    return CausalInsight(
      type: CausalInsightType.criticalDrop,
      headline:
          'Tu ${habit.label.toLowerCase()} viene cayendo en las últimas semanas.',
      detail:
          'Pasaste de ${_fmt(habit.points.first.value)} a '
          '${_fmt(habit.points.last.value)} ${habit.unit}. '
          'Si seguís bajando, esperá retroceso en composición.',
      citation: _citationForHabit(habit.label),
      periodStart: habit.points.first.weekStart,
      periodEnd: habit.points.last.weekStart,
      strength: strength,
    );
  }

  /// `bestPeriod`: encuentra el mejor tramo del outcome principal y
  /// menciona el hábito con mejor performance en ese tramo.
  static CausalInsight? _detectBestPeriod(
    MetricSeries outcome,
    List<MetricSeries> habits,
  ) {
    if (outcome.points.length < kMinPointsForDetection) return null;
    // Mejor punto del outcome (mayor si es IMR, menor si es Peso).
    TimeSeriesPoint best = outcome.points.first;
    for (final p in outcome.points) {
      if (_isBetter(outcome.label, p.value, best.value)) {
        best = p;
      }
    }
    // Habit con mayor valor en la misma semana.
    String? topHabitLabel;
    double topHabitValue = -1;
    for (final habit in habits) {
      final match = habit.points.firstWhere(
        (p) => p.weekStart == best.weekStart,
        orElse: () => TimeSeriesPoint(
          weekStart: best.weekStart,
          value: -1,
          sampleCount: 0,
        ),
      );
      if (match.value > topHabitValue) {
        topHabitValue = match.value;
        topHabitLabel = habit.label;
      }
    }
    if (topHabitLabel == null) return null;
    return CausalInsight(
      type: CausalInsightType.bestPeriod,
      headline:
          'Tu mejor semana de ${outcome.label} fue el ${_fmtDate(best.weekStart)}.',
      detail:
          'Coincide con un pico de ${topHabitLabel.toLowerCase()} '
          '(${_fmt(topHabitValue)}).',
      citation: 'Mattson 2017 + Walker 2017',
      periodStart: best.weekStart,
      periodEnd: best.weekStart.add(const Duration(days: 6)),
      strength: 0.5,
    );
  }

  /// `weeklyDrop`: outcome cayó ≥15% en 1 semana, hábito también
  /// cayó esa semana → posible causa-efecto.
  static CausalInsight? _detectWeeklyDrop(
    MetricSeries outcome,
    MetricSeries habit,
  ) {
    if (outcome.points.length < 2 || habit.points.length < 2) return null;
    for (int i = 1; i < outcome.points.length; i++) {
      final prev = outcome.points[i - 1];
      final curr = outcome.points[i];
      final outcomeRange = outcome.maxValue - outcome.minValue;
      if (outcomeRange == 0) continue;
      final outcomeRel = (curr.value - prev.value) / outcomeRange;
      // Para IMR caída es negativo; para Peso "caída" es subida (positivo).
      final isAdverse = outcome.label == 'Peso'
          ? outcomeRel > kWeeklyDropThreshold
          : outcomeRel < -kWeeklyDropThreshold;
      if (!isAdverse) continue;

      // Buscar caída del hábito en la misma semana.
      final habitPrev = habit.points.firstWhere(
        (p) => p.weekStart == prev.weekStart,
        orElse: () => TimeSeriesPoint(
          weekStart: prev.weekStart,
          value: -1,
          sampleCount: 0,
        ),
      );
      final habitCurr = habit.points.firstWhere(
        (p) => p.weekStart == curr.weekStart,
        orElse: () => TimeSeriesPoint(
          weekStart: curr.weekStart,
          value: -1,
          sampleCount: 0,
        ),
      );
      if (habitPrev.value < 0 || habitCurr.value < 0) continue;
      final habitRange = habit.maxValue - habit.minValue;
      if (habitRange == 0) continue;
      final habitRel = (habitCurr.value - habitPrev.value) / habitRange;
      if (habitRel > -kWeeklyDropThreshold) continue;

      return CausalInsight(
        type: CausalInsightType.weeklyDrop,
        headline:
            'Tu ${outcome.label} cambió fuerte la semana del ${_fmtDate(curr.weekStart)}.',
        detail:
            '${outcome.label}: ${_fmt(prev.value)} → ${_fmt(curr.value)} ${outcome.unit}. '
            '${habit.label}: ${_fmt(habitPrev.value)} → ${_fmt(habitCurr.value)} ${habit.unit}.',
        citation: _citationForHabit(habit.label),
        periodStart: curr.weekStart,
        periodEnd: curr.weekStart.add(const Duration(days: 6)),
        strength: outcomeRel.abs().clamp(0.0, 1.0),
      );
    }
    return null;
  }

  // ─── Helpers ───────────────────────────────────────────────────────

  /// Para IMR: subir = mejor. Para Peso: bajar = mejor (asumimos
  /// objetivo de pérdida; SPEC-152 §2.4 mantiene copy neutro).
  static bool _outcomeImproved(String outcomeLabel, double delta) {
    if (outcomeLabel == 'Peso') {
      return delta < 0; // bajó
    }
    return delta > 0; // IMR subió
  }

  static bool _isBetter(String outcomeLabel, double a, double b) {
    if (outcomeLabel == 'Peso') return a < b;
    return a > b;
  }

  static String _citationForHabit(String habitLabel) {
    switch (habitLabel.toLowerCase()) {
      case 'ayuno':
        return 'Mattson 2017 + Sutton 2018';
      case 'sueño':
        return 'Walker 2017 + AASM';
      case 'hidratación':
        return 'EFSA 2010 + Popkin 2010';
      case 'ejercicio':
        return 'OMS 2020 + AHA 2018';
      case 'nutrición a':
      case 'nutrición':
        return 'Frank Suárez (Tipo A/E) + Jenkins 2002';
      default:
        return 'Mattson 2017';
    }
  }

  static String _fmt(double v) {
    if (v >= 100) return v.toStringAsFixed(0);
    if (v >= 10) return v.toStringAsFixed(1);
    return v.toStringAsFixed(1);
  }

  static const _monthsShort = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  static String _fmtDate(DateTime dt) =>
      '${dt.day} ${_monthsShort[dt.month - 1]}';
}

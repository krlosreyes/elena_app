// SPEC-201: detector de observaciones honestas y accionables.
//
// Reemplaza a `CausalInsightDetector` (correlaciones espurias por pares con n
// minúsculo). Aquí NO se cruza hábito×outcome buscando coincidencias de una
// semana. Cada observación es auto-referencial:
//   RF-01 baseline   — una métrica esta semana vs tu propio promedio.
//   RF-02 streak      — días consecutivos cumpliendo un pilar.
//   RF-03 goalProx    — cercanía a tu meta de agua los últimos días.
//   RF-05 dedup+piso  — sin datos suficientes → vacío (UI muestra estado honesto).
//
// Pure Dart — testeable sin Flutter ni Riverpod.

import 'package:elena_app/src/features/analysis/domain/metric_series.dart';
import 'package:elena_app/src/features/analysis/domain/observation.dart';
import 'package:elena_app/src/features/streak/domain/streak_entry.dart';

class ObservationDetector {
  ObservationDetector._();

  /// Semanas mínimas para comparar contra el promedio personal.
  static const int kMinWeeksForBaseline = 3;

  /// Desvío relativo (vs promedio) que vuelve relevante una baseline.
  static const double kBaselineDeviation = 0.12;

  /// Racha mínima (días) para celebrarla.
  static const int kMinStreakDays = 3;

  /// Días recientes a mirar para la cercanía a meta.
  static const int kRecentDaysForGoal = 3;

  /// Banda "cerca de la meta" (fracción de la meta diaria).
  static const double kGoalCloseLow = 0.6;
  static const double kGoalCloseHigh = 0.95;

  /// Días mínimos con data para emitir algo (piso de datos honesto).
  static const int kMinDaysForObservations = 4;

  /// `habitWeekly`: las 5 series semanales de pilares (Ayuno, Nutrición,
  /// Hidratación, Ejercicio, Sueño).
  /// `dailyEntries`: historial de streak ASCENDENTE por fecha.
  static List<Observation> detect({
    required List<MetricSeries> habitWeekly,
    required List<StreakEntry> dailyEntries,
    int maxObservations = 3,
  }) {
    // RF-05: piso de datos. Sin un mínimo de días registrados, no inventamos.
    final daysWithData =
        dailyEntries.where((e) => e.pillarsCompleted > 0).length;
    if (daysWithData < kMinDaysForObservations) return const [];

    final streak = _detectStreak(dailyEntries);
    final goal = _detectGoalProximity(dailyEntries);
    final baselines = _detectBaselines(habitWeekly);

    // Diversidad: primero lo más fuerte de cada tipo, luego rellenar por
    // fuerza. Dedup por sujeto (pilar/métrica).
    final ordered = <Observation>[];
    final seen = <String>{};

    void add(Observation? o) {
      if (o == null) return;
      if (seen.contains(o.subject)) return;
      seen.add(o.subject);
      ordered.add(o);
    }

    add(streak);
    add(goal);
    if (baselines.isNotEmpty) add(baselines.first);
    // Rellenar con el resto de baselines por fuerza.
    for (final b in baselines.skip(1)) {
      if (ordered.length >= maxObservations) break;
      add(b);
    }

    ordered.sort((a, b) => b.strength.compareTo(a.strength));
    return ordered.take(maxObservations).toList();
  }

  // ─── RF-01: baseline (tú vs tu promedio) ───────────────────────────────

  /// Una observación por pilar cuyo último valor semanal se desvía ≥
  /// `kBaselineDeviation` de su propio promedio. Ordenadas por desvío.
  static List<Observation> _detectBaselines(List<MetricSeries> habits) {
    final out = <Observation>[];
    for (final s in habits) {
      if (s.points.length < kMinWeeksForBaseline) continue;
      final values = s.points.map((p) => p.value).toList();
      final mean = values.reduce((a, b) => a + b) / values.length;
      if (mean == 0) continue;
      final last = values.last;
      final relDev = (last - mean) / mean;
      if (relDev.abs() < kBaselineDeviation) continue;

      final below = relDev < 0;
      final unit = s.unit;
      final lbl = s.label;
      out.add(Observation(
        type: ObservationType.baseline,
        subject: lbl,
        headline: below
            ? 'Tu ${lbl.toLowerCase()} esta semana está por debajo de tu '
                'promedio.'
            : 'Tu ${lbl.toLowerCase()} esta semana está por encima de tu '
                'promedio.',
        detail: '${_fmt(last)}$unit esta semana vs tu promedio de '
            '${_fmt(mean)}$unit.',
        action: below ? _nudgeFor(lbl) : null,
        strength: relDev.abs().clamp(0.0, 1.0),
      ));
    }
    out.sort((a, b) => b.strength.compareTo(a.strength));
    return out;
  }

  static String? _nudgeFor(String habitLabel) {
    switch (habitLabel.toLowerCase()) {
      case 'ayuno':
        return 'Estirá tu ventana de ayuno una hora hoy.';
      case 'sueño':
        return 'Apuntá a acostarte 20 minutos antes hoy.';
      case 'hidratación':
        return 'Sumá un vaso de agua ahora.';
      case 'ejercicio':
        return 'Meté 10 minutos de movimiento hoy.';
      case 'nutrición':
      case 'nutrición a':
        return 'Elegí un plato Tipo A en tu próxima comida.';
      default:
        return null;
    }
  }

  // ─── RF-02: racha de consistencia ──────────────────────────────────────

  static Observation? _detectStreak(List<StreakEntry> ascending) {
    if (ascending.isEmpty) return null;

    final candidates = <({String label, String verb, int days})>[
      (label: 'Ayuno', verb: 'cerrando tu ayuno', days: _currentStreak(ascending, (e) => e.fastingCompleted)),
      (label: 'Sueño', verb: 'durmiendo bien', days: _currentStreak(ascending, (e) => e.sleepCompleted)),
      (label: 'Hidratación', verb: 'cumpliendo tu hidratación', days: _currentStreak(ascending, (e) => e.hydrationCompleted)),
      (label: 'Ejercicio', verb: 'moviéndote', days: _currentStreak(ascending, (e) => e.exerciseLogged)),
      (label: 'Nutrición', verb: 'comiendo en tu ventana', days: _currentStreak(ascending, (e) => e.nutritionLogged)),
    ];

    candidates.sort((a, b) => b.days.compareTo(a.days));
    final top = candidates.first;
    if (top.days < kMinStreakDays) return null;

    return Observation(
      type: ObservationType.streak,
      subject: 'racha-${top.label}',
      headline: 'Llevas ${top.days} días seguidos ${top.verb}.',
      detail: 'Tu mejor racha activa. La consistencia es lo que mueve tu IMR.',
      action: 'Mantené el impulso hoy.',
      strength: (top.days / 7).clamp(0.3, 1.0),
    );
  }

  /// Días consecutivos (calendario) cumpliendo `completed`, contando desde
  /// el día más reciente hacia atrás. Corta en el primer hueco o fallo.
  static int _currentStreak(
    List<StreakEntry> ascending,
    bool Function(StreakEntry) completed,
  ) {
    if (ascending.isEmpty) return 0;
    int streak = 0;
    DateTime? expected;
    for (int i = ascending.length - 1; i >= 0; i--) {
      final e = ascending[i];
      final d = _parse(e.date);
      if (d == null) break;
      if (expected != null && !_sameDay(d, expected)) break; // hueco
      if (!completed(e)) break;
      streak++;
      expected = DateTime(d.year, d.month, d.day).subtract(const Duration(days: 1));
    }
    return streak;
  }

  // ─── RF-03: cercanía a la meta (hidratación) ───────────────────────────

  static Observation? _detectGoalProximity(List<StreakEntry> ascending) {
    final recent = ascending
        .where((e) => e.hydrationMagnitude != null)
        .toList();
    if (recent.length < 2) return null;
    final lastN = recent.length <= kRecentDaysForGoal
        ? recent
        : recent.sublist(recent.length - kRecentDaysForGoal);
    final avg = lastN
            .map((e) => e.hydrationMagnitude!.clamp(0.0, 2.0))
            .reduce((a, b) => a + b) /
        lastN.length;

    if (avg >= 1.0) return null; // ya cumple — no hace falta empujar
    if (avg >= kGoalCloseLow && avg < kGoalCloseHigh) {
      final pct = (avg * 100).round();
      return Observation(
        type: ObservationType.goalProximity,
        subject: 'meta-hidratacion',
        headline: 'Estás cerca de tu meta de agua.',
        detail: 'Los últimos ${lastN.length} días promediaste $pct % de tu '
            'meta diaria. Un vaso más y la cierras.',
        action: 'Registrá un vaso ahora.',
        strength: 0.55,
      );
    }
    if (avg < kGoalCloseLow) {
      final pct = (avg * 100).round();
      return Observation(
        type: ObservationType.goalProximity,
        subject: 'meta-hidratacion',
        headline: 'Tu hidratación viene corta de tu meta.',
        detail: 'Los últimos ${lastN.length} días promediaste $pct % de tu '
            'meta diaria.',
        action: 'Sumá un vaso de agua ahora.',
        strength: 0.5,
      );
    }
    return null;
  }

  // ─── Helpers ───────────────────────────────────────────────────────────

  static DateTime? _parse(String yyyymmdd) {
    final parts = yyyymmdd.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _fmt(double v) {
    if (v >= 100) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }
}

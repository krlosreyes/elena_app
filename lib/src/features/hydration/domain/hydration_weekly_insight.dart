// SPEC-161: snapshot semanal de hidratación + insight adaptativo.
//
// Pure Dart — sin Flutter ni Riverpod. Lo consume HydrationWeeklyCard.

/// Tier del insight según % del target alcanzado en promedio semanal.
enum HydrationInsightTier {
  empty,
  severelyLow, // <60%
  low, // 60-80%
  adequate, // 80-100%
  optimal, // >=100%
}

class HydrationDayEntry {
  /// Día calendárico del registro.
  final DateTime date;

  /// Litros totales registrados ese día.
  final double liters;

  /// % vs target diario del usuario (1.0 = 100%).
  final double percentVsTarget;

  const HydrationDayEntry({
    required this.date,
    required this.liters,
    required this.percentVsTarget,
  });
}

class HydrationWeeklyBreakdown {
  /// Lista de días ordenada del más antiguo al más reciente. Incluye
  /// solo los días con al menos 1 log (no rellena con 0s).
  final List<HydrationDayEntry> days;

  /// Litros promedio sobre los días con registros. 0 si no hay.
  final double litersAvg;

  /// % promedio vs target del usuario (1.0 = 100%).
  final double percentAvg;

  /// Target diario derivado del usuario (35ml × kg).
  final double targetLitersPerDay;

  /// Tier del insight (algoritmo del computer).
  final HydrationInsightTier tier;

  /// Rango cubierto.
  final DateTime rangeStart;
  final DateTime rangeEnd;

  const HydrationWeeklyBreakdown({
    required this.days,
    required this.litersAvg,
    required this.percentAvg,
    required this.targetLitersPerDay,
    required this.tier,
    required this.rangeStart,
    required this.rangeEnd,
  });

  factory HydrationWeeklyBreakdown.empty({
    required double targetLitersPerDay,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    return HydrationWeeklyBreakdown(
      days: const [],
      litersAvg: 0,
      percentAvg: 0,
      targetLitersPerDay: targetLitersPerDay,
      tier: HydrationInsightTier.empty,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
  }

  bool get isEmpty => days.isEmpty;
}

/// Mensaje del coach por tier. Bibliografía coherente con SPEC-150
/// (hidratación) y SPEC-153 (WeeklyCoachingCard).
class HydrationCoachingMessage {
  final String headline;
  final String action;
  final String citation;

  const HydrationCoachingMessage({
    required this.headline,
    required this.action,
    required this.citation,
  });

  static HydrationCoachingMessage? forTier(HydrationInsightTier tier) {
    switch (tier) {
      case HydrationInsightTier.empty:
        return null;
      case HydrationInsightTier.severelyLow:
        return const HydrationCoachingMessage(
          headline:
              'Tu hidratación está severamente baja. Compromete cetonas y cortisol.',
          action:
              'Empieza con un vaso (250 ml) cada 90 min hasta las 21:00. Baja el café y el mate.',
          citation: 'EFSA 2010 + Popkin 2010',
        );
      case HydrationInsightTier.low:
        return const HydrationCoachingMessage(
          headline: 'Estás bajo el target. Riesgo de retención y cansancio.',
          action:
              'Suma 2 vasos extra al día. El ayuno saca más agua que la comida: compénsalo.',
          citation: 'EFSA 2010 + Popkin 2010',
        );
      case HydrationInsightTier.adequate:
        return const HydrationCoachingMessage(
          headline: 'En rango. Sostén la cadencia.',
          action: 'Mantén ≥1 vaso cada 90 min. Beber ≤21:00 protege tu sueño.',
          citation: 'EFSA 2010',
        );
      case HydrationInsightTier.optimal:
        return const HydrationCoachingMessage(
          headline: 'Excelente. La constancia regula el sistema linfático.',
          action:
              'Mantén esta cadencia — es la base que sostiene los otros 4 pilares.',
          citation: 'EFSA 2010 + Popkin 2010',
        );
    }
  }
}

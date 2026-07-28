// SPEC-158: snapshot de la distribución semanal de MealRatio.
//
// Pure Dart — sin Flutter ni Riverpod. Lo consume `MealsRatioCard`.

import 'package:elena_app/src/features/nutrition/domain/meal_ratio.dart';

/// Tier del insight según % A-dominante de la semana.
enum MealsRatioInsightTier {
  empty,
  poor, // < 50%
  insufficient, // 50-69%
  good, // 70-79%
  excellent, // ≥ 80%
}

class MealsRatioBreakdown {
  /// Conteo de logs por ratio. Llaves siempre presentes (0 si no hay).
  final Map<MealRatio, int> counts;

  /// Total de logs en la ventana.
  final int total;

  /// Inicio de la ventana (inclusive).
  final DateTime rangeStart;

  /// Fin de la ventana (inclusive).
  final DateTime rangeEnd;

  const MealsRatioBreakdown({
    required this.counts,
    required this.total,
    required this.rangeStart,
    required this.rangeEnd,
  });

  factory MealsRatioBreakdown.empty({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    return MealsRatioBreakdown(
      counts: {for (final r in MealRatio.values) r: 0},
      total: 0,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
  }

  /// Cantidad de comidas A-dominantes (criterio SPEC-137 `isADominant`).
  int get aDominantCount {
    int n = 0;
    counts.forEach((ratio, count) {
      if (ratio.isADominant) n += count;
    });
    return n;
  }

  /// Fracción de A-dominantes (0..1). 0 si no hay logs.
  double get aDominantFraction => total == 0 ? 0 : aDominantCount / total;

  /// % de A-dominantes redondeado (0..100).
  int get aDominantPercent => (aDominantFraction * 100).round();

  bool get isEmpty => total == 0;

  /// Tier del insight basado en aDominantPercent. Define el copy y
  /// color que el widget elige para el bloque inferior.
  MealsRatioInsightTier get tier {
    if (isEmpty) return MealsRatioInsightTier.empty;
    final pct = aDominantPercent;
    if (pct >= 80) return MealsRatioInsightTier.excellent;
    if (pct >= 70) return MealsRatioInsightTier.good;
    if (pct >= 50) return MealsRatioInsightTier.insufficient;
    return MealsRatioInsightTier.poor;
  }
}

/// Pool de insights por tier. Headline + acción + cita.
/// Bibliografía: Frank Suárez (operacional Tipo A/E) + Jenkins 2002
/// (IG, defensa científica del marco vía `NUTRITION_BIBLIOGRAPHY §4`).
class MealsRatioInsight {
  final String headline;
  final String action;
  final String citation;

  const MealsRatioInsight({
    required this.headline,
    required this.action,
    required this.citation,
  });

  static MealsRatioInsight? forTier(MealsRatioInsightTier tier) {
    switch (tier) {
      case MealsRatioInsightTier.empty:
        return null;
      case MealsRatioInsightTier.excellent:
        return const MealsRatioInsight(
          headline: 'Excelente semana A-dominante.',
          action:
              'Sostener este nivel desactiva resistencia a la insulina y libera grasa visceral.',
          citation: 'Frank Suárez (Tipo A/E) + Jenkins 2002',
        );
      case MealsRatioInsightTier.good:
        return const MealsRatioInsight(
          headline: 'Buen nivel A-dominante.',
          action:
              'Mantente arriba del 70% para sostener sensibilidad a la insulina.',
          citation: 'Frank Suárez (Tipo A/E)',
        );
      case MealsRatioInsightTier.insufficient:
        return const MealsRatioInsight(
          headline: 'Tu semana tuvo demasiados platos E.',
          action:
              'Empieza por reemplazar un plato por día con un Todo A — proteína, verduras, grasa saludable.',
          citation: 'Frank Suárez (Tipo A/E) + Jenkins 2002',
        );
      case MealsRatioInsightTier.poor:
        return const MealsRatioInsight(
          headline: 'Tu semana fue E-dominante.',
          action:
              'Los alimentos refinados están dictando tu metabolismo. Vuelve al 2 a 1 mínimo esta semana.',
          citation: 'Frank Suárez (Tipo A/E)',
        );
    }
  }
}

// SPEC-158: motor puro del MealsRatioCard.
//
// Dado los NutritionLog de la última semana, computa el breakdown por
// MealRatio (5 categorías) + métricas derivadas (% A-dominante, total).
//
// Pure Dart — sin Flutter ni Riverpod.

import 'package:elena_app/src/features/nutrition/domain/meal_ratio.dart';
import 'package:elena_app/src/features/nutrition/domain/meals_ratio_breakdown.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_log.dart';

class MealsRatioComputer {
  MealsRatioComputer._();

  /// Construye el breakdown desde los logs entregados por el provider.
  /// `rangeStart`/`rangeEnd` se reportan tal cual para que el widget
  /// pueda mostrar el header de fechas.
  static MealsRatioBreakdown compute({
    required List<NutritionLog> logs,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    if (logs.isEmpty) {
      return MealsRatioBreakdown.empty(
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      );
    }

    final counts = <MealRatio, int>{
      for (final r in MealRatio.values) r: 0,
    };
    for (final log in logs) {
      counts[log.ratio] = (counts[log.ratio] ?? 0) + 1;
    }

    return MealsRatioBreakdown(
      counts: counts,
      total: logs.length,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
  }
}

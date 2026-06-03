// SPEC-158: provider que alimenta el MealsRatioCard.
//
// Consume `watchSinceLogs(uid, since=now-7d)` del NutritionRepository
// y delega el cálculo al MealsRatioComputer.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/services/day_boundary_resolver.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/features/nutrition/application/meals_ratio_computer.dart';
import 'package:elena_app/src/features/nutrition/data/nutrition_repository_impl.dart';
import 'package:elena_app/src/features/nutrition/domain/meals_ratio_breakdown.dart';

/// Días de la ventana semanal. Fijo en 7 — coherente con
/// WeeklyCoachingCard (SPEC-153).
const int kMealsRatioWindowDays = 7;

final lastWeekMealsRatioProvider =
    StreamProvider.autoDispose<MealsRatioBreakdown>((ref) {
  final account = ref.watch(authStateProvider).value;
  final today = DateTime.now();
  final rangeEnd = DayBoundaryResolver.startOfDay(today);
  final rangeStart =
      rangeEnd.subtract(const Duration(days: kMealsRatioWindowDays - 1));

  if (account == null) {
    return Stream.value(
      MealsRatioBreakdown.empty(
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      ),
    );
  }

  return ref
      .watch(nutritionRepositoryProvider)
      .watchSinceLogs(account.uid, rangeStart)
      .map((logs) => MealsRatioComputer.compute(
            logs: logs,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
          ));
});

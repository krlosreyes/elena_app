// SPEC-161: provider que alimenta el HydrationWeeklyCard.
//
// Combina watchSince(uid, 7d) del HydrationRepository + el peso del
// usuario para calcular el target diario (35ml × kg). Delega cómputo
// al HydrationWeeklyComputer.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/services/day_boundary_resolver.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/features/dashboard/application/hydration_weekly_computer.dart';
import 'package:elena_app/src/features/dashboard/data/hydration_repository_impl.dart';
import 'package:elena_app/src/features/dashboard/domain/hydration_weekly_insight.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

const int kHydrationCardWindowDays = 7;

/// Target en litros del usuario (35ml × kg). Fallback razonable si
/// no hay peso registrado.
double _targetFor(double? weightKg) {
  if (weightKg == null || weightKg <= 0) return 2.5;
  return weightKg * 0.035;
}

final lastWeekHydrationProvider =
    StreamProvider.autoDispose<HydrationWeeklyBreakdown>((ref) {
  final account = ref.watch(authStateProvider).value;
  final user = ref.watch(currentUserStreamProvider).valueOrNull;
  final target = _targetFor(user?.weight);

  final today = DateTime.now();
  final rangeEnd = DayBoundaryResolver.startOfDay(today);
  final rangeStart =
      rangeEnd.subtract(const Duration(days: kHydrationCardWindowDays - 1));

  if (account == null) {
    return Stream.value(
      HydrationWeeklyBreakdown.empty(
        targetLitersPerDay: target,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      ),
    );
  }

  return ref
      .watch(hydrationRepositoryProvider)
      .watchSince(account.uid, rangeStart)
      .map((logs) => HydrationWeeklyComputer.compute(
            logs: logs,
            targetLitersPerDay: target,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
          ));
});

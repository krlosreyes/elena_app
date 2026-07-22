// SPEC-161 + SPEC-190 (2026-06-05): provider que alimenta el
// HydrationWeeklyCard. Migrado a "últimos 7 ciclos cerrados" en lugar
// de "últimos 7 días" para cumplir METABOLIC_DAY_CONSTITUTION.md §1.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/features/hydration/application/hydration_weekly_computer.dart';
import 'package:elena_app/src/features/hydration/data/hydration_repository_impl.dart';
import 'package:elena_app/src/features/hydration/domain/hydration_log.dart';
import 'package:elena_app/src/features/hydration/domain/hydration_weekly_insight.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

/// SPEC-190: ventana = 7 ciclos cerrados.
const int kHydrationCardWindowCycles = 7;

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
  final cyclesAsync = ref.watch(last7ClosedCyclesProvider);
  final cycles = cyclesAsync.valueOrNull ?? const <MetabolicCycle>[];

  if (account == null || cycles.isEmpty) {
    final now = DateTime.now();
    return Stream.value(
      HydrationWeeklyBreakdown.empty(
        targetLitersPerDay: target,
        rangeStart: now,
        rangeEnd: now,
      ),
    );
  }

  final newest = cycles.first;
  final oldest = cycles.last;
  final rangeStart = oldest.startedAt;
  final rangeEnd = newest.closedAt ?? DateTime.now();

  return ref
      .watch(hydrationRepositoryProvider)
      .watchSince(account.uid, rangeStart, until: rangeEnd)
      .map((logs) {
    final cycleAwareLogs = _filterByCycles(logs, cycles);
    return HydrationWeeklyComputer.compute(
      logs: cycleAwareLogs,
      targetLitersPerDay: target,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
  });
});

/// SPEC-190: filtra logs por pertenencia a algún ciclo cerrado de la
/// lista. Descarta logs huérfanos entre ciclos.
List<HydrationLog> _filterByCycles(
  List<HydrationLog> logs,
  List<MetabolicCycle> cycles,
) {
  return logs.where((log) {
    for (final c in cycles) {
      final closedAt = c.closedAt;
      if (closedAt == null) continue;
      if (!log.timestamp.isBefore(c.startedAt) &&
          !log.timestamp.isAfter(closedAt)) {
        return true;
      }
    }
    return false;
  }).toList();
}

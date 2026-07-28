// SPEC-138 §16.4: providers Riverpod que exponen el indicador UPF
// (% ultra-procesados) al diario (cycle-aware, SPEC-149) y al
// semanal (últimos 7 días calendarios).
//
// Patrón coherente con `last_week_meals_ratio_provider.dart` (SPEC-158).
// El cómputo puro vive en `upf_share_computer.dart` — estos providers
// solo orquestan el stream del repo + la ventana temporal.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/services/day_boundary_resolver.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart';
import 'package:elena_app/src/features/nutrition/application/upf_share_computer.dart';
import 'package:elena_app/src/features/nutrition/data/nutrition_repository_impl.dart';

/// Días de la ventana semanal de UPF. 7 — coherente con
/// `kMealsRatioWindowDays` (SPEC-158). Si el comité médico decide
/// cambiar la ventana, actualizar también allá para mantener
/// comparabilidad visual.
const int kUpfWeeklyWindowDays = 7;

/// % UPF agregado del CICLO METABÓLICO en curso (cycle-aware, SPEC-149).
///
/// Si no hay ciclo en curso (usuario fuera del flujo metabólico),
/// devuelve `UpfShareResult.empty()`.
///
/// Útil para mostrar el chip del plato actual en contexto del día.
final dailyUpfShareProvider = StreamProvider.autoDispose<UpfShareResult>((ref) {
  final account = ref.watch(authStateProvider).value;
  final cycle = ref.watch(currentMetabolicCycleProvider).valueOrNull;

  if (account == null || cycle == null) {
    return Stream.value(const UpfShareResult.empty());
  }

  return ref
      .watch(nutritionRepositoryProvider)
      .watchSinceLogs(account.uid, cycle.startedAt)
      .map(UpfShareComputer.compute);
});

/// % UPF agregado de los últimos 7 días calendarios.
///
/// Esta es la métrica que alimenta:
/// - El insight de coaching en `CycleFeedback` cuando supera
///   `UpfThresholds.weeklyAlertPercent`.
/// - El delta `upfShareDelta` en `TransformationSnapshot` (SPEC-148).
///
/// NO es cycle-aware porque el patrón semanal trasciende ciclos
/// individuales — Hall 2019 documenta exceso calórico sostenido tras
/// 2+ semanas de consumo UPF, no tras un solo ciclo.
final weeklyUpfShareProvider =
    StreamProvider.autoDispose<UpfShareResult>((ref) {
  final account = ref.watch(authStateProvider).value;
  if (account == null) return Stream.value(const UpfShareResult.empty());

  final today = DateTime.now();
  final rangeEnd = DayBoundaryResolver.startOfDay(today);
  final rangeStart =
      rangeEnd.subtract(const Duration(days: kUpfWeeklyWindowDays - 1));

  return ref
      .watch(nutritionRepositoryProvider)
      .watchSinceLogs(account.uid, rangeStart)
      .map(UpfShareComputer.compute);
});

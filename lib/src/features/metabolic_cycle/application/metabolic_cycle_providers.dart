// SPEC-149 §RF-149-07: providers Riverpod para el módulo de ciclo metabólico.
//
// Patrón side-effect-only y streams derivados similar al pattern de
// SPEC-143 (biometric_history_service) — el service vive como Provider
// singleton, los streams reactivos vienen del repository.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:elena_app/src/core/providers/shared_preferences_provider.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_service.dart';
import 'package:elena_app/src/features/metabolic_cycle/data/metabolic_cycle_repository_impl.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';

/// Service singleton para la sesión. NO autoDispose — debe preservar
/// estado interno (futuro: caching, debounce, etc.).
final metabolicCycleServiceProvider =
    Provider<MetabolicCycleService>((ref) {
  final repo = ref.watch(metabolicCycleRepositoryProvider);
  return MetabolicCycleService(repository: repo);
});

/// Stream del ciclo metabólico actualmente abierto. Null si no hay.
/// Emite null mientras el usuario no está autenticado.
final currentMetabolicCycleProvider =
    StreamProvider<MetabolicCycle?>((ref) {
  final account = ref.watch(authStateProvider).value;
  if (account == null) return Stream.value(null);
  return ref
      .watch(metabolicCycleRepositoryProvider)
      .watchOpenCycle(account.uid);
});

/// Stream del último ciclo cerrado. Fuente del card de cierre.
final lastClosedMetabolicCycleProvider =
    StreamProvider<MetabolicCycle?>((ref) {
  final account = ref.watch(authStateProvider).value;
  if (account == null) return Stream.value(null);
  return ref
      .watch(metabolicCycleRepositoryProvider)
      .watchLastClosed(account.uid);
});

/// Historial de los últimos 90 ciclos cerrados para Análisis y SPEC-141.
final metabolicCyclesHistoryProvider =
    StreamProvider<List<MetabolicCycle>>((ref) {
  final account = ref.watch(authStateProvider).value;
  if (account == null) return Stream.value(const []);
  return ref
      .watch(metabolicCycleRepositoryProvider)
      .watchRecentClosed(account.uid);
});

/// Key de SharedPreferences para marcar el último ciclo cerrado como
/// "visto" por el usuario (descartado del card en Dashboard).
const String _kLastCycleClosureDismissedKey =
    'metabolicCycle.lastClosureDismissedCycleId';

/// True si hay un ciclo cerrado reciente que aún NO fue descartado por
/// el usuario. Drive el render del CycleClosureCard en Dashboard.
final hasUnreadCycleClosureProvider = Provider<bool>((ref) {
  final last = ref.watch(lastClosedMetabolicCycleProvider).valueOrNull;
  if (last == null) return false;

  final prefs = ref.watch(sharedPreferencesProvider);
  final dismissedCycleId =
      prefs.getString(_kLastCycleClosureDismissedKey);

  // Hay cierre no leído si el último cierre tiene un cycleId distinto
  // al último que el usuario descartó.
  return dismissedCycleId != last.cycleId;
});

/// Helper que marca el último cierre como visto. Llamado por el card al
/// hacer tap en ✕ o al iniciar el siguiente ayuno desde el CTA.
Future<void> dismissLastCycleClosure({
  required SharedPreferences prefs,
  required String cycleId,
}) async {
  await prefs.setString(_kLastCycleClosureDismissedKey, cycleId);
}

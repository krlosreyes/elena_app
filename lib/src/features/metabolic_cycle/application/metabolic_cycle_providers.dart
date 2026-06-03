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

/// SPEC-149.1: notifier reactivo del dismissedCycleId.
///
/// Originalmente (SPEC-149 v1.0) `hasUnreadCycleClosureProvider` leía
/// `prefs.getString(...)` directo. Riverpod no observa cambios internos
/// de SharedPreferences, así que al escribir el dismiss no se invalidaba
/// el provider y la card no se ocultaba (Bug 1a SPEC-149.1).
///
/// Ahora el dismissedCycleId vive como `String?` reactivo. Se hidrata
/// desde prefs en construcción del notifier y se actualiza en memoria
/// + prefs en cada `dismiss(cycleId)`.
class CycleClosureDismissalNotifier extends StateNotifier<String?> {
  CycleClosureDismissalNotifier(this._prefs)
      : super(_prefs.getString(_kLastCycleClosureDismissedKey));

  final SharedPreferences _prefs;

  /// Marca el cycleId como "visto" en memoria + en prefs.
  Future<void> dismiss(String cycleId) async {
    await _prefs.setString(_kLastCycleClosureDismissedKey, cycleId);
    if (mounted) state = cycleId;
  }
}

/// Provider del dismissedCycleId reactivo. El nullable indica "ningún
/// ciclo fue descartado aún en este device".
final cycleClosureDismissalProvider =
    StateNotifierProvider<CycleClosureDismissalNotifier, String?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CycleClosureDismissalNotifier(prefs);
});

/// True si hay un ciclo cerrado reciente que aún NO fue descartado por
/// el usuario. Drive el render del CycleClosureCard en Dashboard.
///
/// SPEC-149.1: ahora watchea `cycleClosureDismissalProvider` (reactivo)
/// en lugar de leer prefs directamente.
final hasUnreadCycleClosureProvider = Provider<bool>((ref) {
  final last = ref.watch(lastClosedMetabolicCycleProvider).valueOrNull;
  if (last == null) return false;

  final dismissedCycleId = ref.watch(cycleClosureDismissalProvider);

  // Hay cierre no leído si el último cierre tiene un cycleId distinto
  // al último que el usuario descartó.
  return dismissedCycleId != last.cycleId;
});

/// Helper legacy mantenido por compat. Internamente delega al notifier
/// reactivo. Nuevos callers deben usar
/// `ref.read(cycleClosureDismissalProvider.notifier).dismiss(cycleId)`.
@Deprecated('Use cycleClosureDismissalProvider.notifier.dismiss instead.')
Future<void> dismissLastCycleClosure({
  required SharedPreferences prefs,
  required String cycleId,
}) async {
  await prefs.setString(_kLastCycleClosureDismissedKey, cycleId);
}

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

/// SPEC-190 (2026-06-05): últimos 7 ciclos cerrados para la analítica
/// semanal (last_week_meals_ratio, last_week_hydration, last_week_exercise,
/// weekly_coaching). Sin reloj: la "semana" no es 7 días sino 7 ciclos
/// cerrados consecutivos. Ver METABOLIC_DAY_CONSTITUTION.md §1.
final last7ClosedCyclesProvider =
    StreamProvider<List<MetabolicCycle>>((ref) {
  final account = ref.watch(authStateProvider).value;
  if (account == null) return Stream.value(const []);
  return ref
      .watch(metabolicCycleRepositoryProvider)
      .watchRecentClosed(account.uid, limit: 7);
});

/// SPEC-190: últimos 14 ciclos cerrados para period_comparison_provider
/// ("últimos 7 vs los 7 anteriores").
final last14ClosedCyclesProvider =
    StreamProvider<List<MetabolicCycle>>((ref) {
  final account = ref.watch(authStateProvider).value;
  if (account == null) return Stream.value(const []);
  return ref
      .watch(metabolicCycleRepositoryProvider)
      .watchRecentClosed(account.uid, limit: 14);
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

/// SPEC-202.2: el "momento" de cierre — un ciclo recién cerrado por acción
/// consciente (iniciar el próximo ayuno) que el Dashboard debe presentar como
/// un sheet inmediato ("arrancaste tu ayuno, así cerró tu día anterior") en
/// vez de dejar una tarjeta pasiva que aparece desconectada en la mañana.
/// El evaluador lo setea; el Dashboard lo consume y lo limpia.
final cycleClosureMomentProvider = StateProvider<MetabolicCycle?>((ref) => null);

/// SPEC-202.2: ventana de frescura. Si el cierre ocurrió hace más de esto, la
/// tarjeta pasiva NO se muestra — evita el pop desconectado de la mañana
/// cuando el ciclo cerró por un fallback mientras la app estuvo cerrada.
const Duration kCycleClosureFreshness = Duration(hours: 6);

/// True si hay un ciclo cerrado reciente que aún NO fue descartado por
/// el usuario. Drive el render del CycleClosureCard en Dashboard.
///
/// SPEC-149.1: watchea `cycleClosureDismissalProvider` (reactivo).
/// SPEC-202.2: además exige que el cierre sea FRESCO — un cierre viejo (la app
/// estuvo cerrada y el ciclo cerró por fallback en la madrugada) ya no salta
/// como tarjeta desconectada.
final hasUnreadCycleClosureProvider = Provider<bool>((ref) {
  final last = ref.watch(lastClosedMetabolicCycleProvider).valueOrNull;
  if (last == null) return false;

  final dismissedCycleId = ref.watch(cycleClosureDismissalProvider);
  if (dismissedCycleId == last.cycleId) return false;

  // SPEC-202.2: gating de frescura. Sin closedAt, lo tratamos como fresco
  // (no rompemos el caso legacy). Con closedAt viejo → no mostrar pasivo.
  final closedAt = last.closedAt;
  if (closedAt != null &&
      DateTime.now().difference(closedAt) > kCycleClosureFreshness) {
    return false;
  }
  return true;
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

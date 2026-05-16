/// SPEC-29 + SPEC-52.1 (cleanup): Global Sleep Provider.
///
/// Punto de entrada centralizado para el estado de sueño sin crear
/// dependencias cíclicas entre notifiers.
///
/// SPEC-52.1: limpiados los selectores que apuntaban a getters inexistentes
/// en SleepState (`lastSleepDurationHours`, `isSufficientSleep`,
/// `isOptimalSleep`, `sleepAdherence`, `recoveryStatus`). Esos getters eran
/// deuda baseline — habían sido removidos del modelo en algún refactor
/// previo y este archivo no se actualizó. Ahora los selectores derivan de
/// `lastLog.duration` directamente.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/features/dashboard/application/sleep_notifier.dart';
import 'package:elena_app/src/features/dashboard/domain/sleep_log.dart';

/// Provider global del SleepNotifier. El resto de la app no lo construye
/// directamente; siempre usa `globalSleepProvider`.
final globalSleepProvider =
    StateNotifierProvider<SleepNotifier, SleepState>((ref) {
  return SleepNotifier(ref);
});

// ─────────────────────────────────────────────────────────────────────────────
// Selectors derivados de lastLog
// ─────────────────────────────────────────────────────────────────────────────

/// Duración del último sueño en horas (0.0 si no hay log).
final sleepDurationProvider = Provider<double>((ref) {
  final log = ref.watch(globalSleepProvider).lastLog;
  if (log == null) return 0.0;
  return log.duration.inMinutes / 60.0;
});

/// Último log de sueño persistido (puede ser null).
final lastSleepLogProvider = Provider<SleepLog?>((ref) {
  return ref.watch(globalSleepProvider).lastLog;
});

/// True si el sueño fue suficiente (≥ 6.5h, umbral AASM).
final isSleepSufficientProvider = Provider<bool>((ref) {
  return ref.watch(sleepDurationProvider) >= 6.5;
});

/// True si el sueño fue óptimo (7–9h, ventana funcional).
final isSleepOptimalProvider = Provider<bool>((ref) {
  final h = ref.watch(sleepDurationProvider);
  return h >= 7.0 && h <= 9.0;
});

/// Adherencia básica del sueño (0.0–1.0): 1.0 si optimal, 0.6 si sufficient,
/// 0.0 si menor. SPEC-69 introducirá una métrica multidimensional.
final sleepAdherenceProvider = Provider<double>((ref) {
  if (ref.watch(isSleepOptimalProvider)) return 1.0;
  if (ref.watch(isSleepSufficientProvider)) return 0.6;
  return 0.0;
});

/// Status de recuperación basado en horas dormidas.
/// SPEC-69 lo enriquecerá con latencia, despertares y gap metabólico.
final recoveryStatusProvider = Provider<String>((ref) {
  if (ref.watch(isSleepOptimalProvider)) return 'OPTIMAL';
  if (ref.watch(isSleepSufficientProvider)) return 'ADEQUATE';
  return 'INSUFFICIENT';
});

/// Notifier para invocar acciones de control (saveManualSleep, etc.).
final sleepNotifierProvider = Provider((ref) {
  return ref.watch(globalSleepProvider.notifier);
});

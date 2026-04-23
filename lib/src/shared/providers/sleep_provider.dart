/// SPEC-29: Global Sleep Provider
/// Punto de entrada centralizado para acceso global al estado del sueño
/// sin crear dependencias cíclicas entre notifiers

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/features/dashboard/application/sleep_notifier.dart';
import 'package:elena_app/src/features/dashboard/domain/sleep_log.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SPEC-29: Provider Global del Sueño
// ─────────────────────────────────────────────────────────────────────────────

/// Provider global que cualquier notifier puede leer sin dependencias cíclicas
/// Ejemplo uso en StreakNotifier:
///   final sleepDuration = _ref.read(globalSleepProvider).getSleepHours();
final globalSleepProvider =
    StateNotifierProvider<SleepNotifier, SleepState>((ref) {
  return SleepNotifier(ref);
});

// ─────────────────────────────────────────────────────────────────────────────
// SPEC-29: Selectors (para acceso seguro a campos específicos)
// ─────────────────────────────────────────────────────────────────────────────

/// Retorna solo la duración del último sueño (0.0 si no hay log)
/// Uso: _ref.read(sleepDurationProvider)
final sleepDurationProvider = Provider<double>((ref) {
  return ref.watch(globalSleepProvider).lastSleepDurationHours;
});

/// Retorna solo el log del último sueño
/// Uso: _ref.read(lastSleepLogProvider)
final lastSleepLogProvider = Provider<SleepLog?>((ref) {
  return ref.watch(globalSleepProvider).lastLog;
});

/// Retorna true si el sueño fue suficiente (>= 6.5 horas)
/// Uso: _ref.read(isSleepSufficientProvider)
final isSleepSufficientProvider = Provider<bool>((ref) {
  return ref.watch(globalSleepProvider).isSufficientSleep;
});

/// Retorna true si el sueño fue óptimo (7-9 horas)
/// Uso: _ref.read(isSleepOptimalProvider)
final isSleepOptimalProvider = Provider<bool>((ref) {
  return ref.watch(globalSleepProvider).isOptimalSleep;
});

/// Retorna adherencia de sueño como proporción (0.0-1.0)
/// Usado por StreakEngine y ScoreEngine
/// Uso: _ref.read(sleepAdherenceProvider)
final sleepAdherenceProvider = Provider<double>((ref) {
  return ref.watch(globalSleepProvider).sleepAdherence;
});

/// Retorna el status de recuperación: INSUFFICIENT, ADEQUATE, OPTIMAL
/// Uso: _ref.read(recoveryStatusProvider)
final recoveryStatusProvider = Provider<String>((ref) {
  return ref.watch(globalSleepProvider).recoveryStatus;
});

/// Stream de cambios en el estado del sueño (para UI en tiempo real)
/// Uso: ref.watch(sleepStateStreamProvider)
final sleepStateStreamProvider = StreamProvider<SleepState>((ref) async* {
  final notifier = ref.watch(globalSleepProvider.notifier);
  yield ref.watch(globalSleepProvider);
  // Yield new values cuando el estado cambia
  await for (final state in ref.watch(globalSleepProvider.notifier).stream) {
    yield state;
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// SPEC-29: Métodos de Control Globales
// ─────────────────────────────────────────────────────────────────────────────

/// Provider para obtener métodos de control del SleepNotifier
/// Uso: final notifier = _ref.read(sleepNotifierProvider);
///      await notifier.saveManualSleep(bedtime: ..., wakeTime: ...)
final sleepNotifierProvider = Provider((ref) {
  return ref.watch(globalSleepProvider.notifier);
});

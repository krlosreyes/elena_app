/// SPEC-209: Providers derivados de sueño — fuente única `sleepProvider`.
///
/// SPEC-29 + SPEC-52.1 (cleanup): antes este archivo instanciaba
/// `globalSleepProvider` (segunda instancia de SleepNotifier) causando:
///   - Doble suscripción Firestore a sleep_history.
///   - IMR calculado con datos del usuario anterior tras logout.
///   - Desincronización entre sleepProvider y globalSleepProvider.
///
/// SPEC-209 elimina globalSleepProvider. Todo el código apunta a
/// `sleepProvider` (lib/src/features/sleep/application/sleep_notifier.dart)
/// que es la fuente de verdad única, correctamente invalidada en signOut().
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/features/sleep/application/sleep_notifier.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Selectors derivados — todos leen de sleepProvider (fuente única)
// ─────────────────────────────────────────────────────────────────────────────

/// Duración del último sueño en horas (0.0 si no hay log).
final sleepDurationProvider = Provider<double>((ref) {
  final log = ref.watch(sleepProvider).lastLog;
  if (log == null) return 0.0;
  return log.duration.inMinutes / 60.0;
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

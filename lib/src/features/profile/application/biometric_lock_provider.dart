// Bloqueo semanal de peso y medidas (ver biometric_lock_service.dart).
//
// Fuentes:
//   - progressProvider.biometricHistory (Firestore): la medición manual más
//     reciente. Sobrevive a reinstalar la app o cambiar de teléfono.
//   - biometricLocalEditProvider (SharedPreferences): respaldo inmediato,
//     para que el bloqueo aplique al instante aunque el historial tarde en
//     sincronizar (p. ej. sin conexión).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/providers/shared_preferences_provider.dart';
import 'package:elena_app/src/features/profile/domain/biometric_lock_service.dart';
import 'package:elena_app/src/features/progress/application/progress_notifier.dart';

/// Última medición guardada en este dispositivo.
final biometricLocalEditProvider = StateProvider<DateTime?>((ref) {
  final raw = ref
      .watch(sharedPreferencesProvider)
      .getString(BiometricLockService.kLastEditKey);
  return raw == null ? null : DateTime.tryParse(raw);
});

final biometricLockProvider = Provider<BiometricLockState>((ref) {
  final history = ref.watch(progressProvider.select((s) => s.biometricHistory));
  DateTime? fromHistory;
  for (final e in history) {
    if (!BiometricLockService.countsAsMeasurement(e.source)) continue;
    final t = e.recordedAt ?? e.createdAt;
    if (fromHistory == null || t.isAfter(fromHistory)) fromHistory = t;
  }
  return BiometricLockService.compute(
    lastMeasuredAt: BiometricLockService.latest(
      fromHistory,
      ref.watch(biometricLocalEditProvider),
    ),
  );
});

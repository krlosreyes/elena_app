// SPEC-236: sincronización automática de estado iPhone → Watch.
//
// Escucha cambios en los providers relevantes y envía updates al Watch
// automáticamente. Se inicializa una sola vez en app.dart.
//
// Frecuencia controlada: no envía más de 1 update por provider por minuto
// para no saturar WatchConnectivity (budget limitado en watchOS).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/core/services/watch_connectivity_service.dart';
import 'package:elena_app/src/features/dashboard/application/fasting_notifier.dart';
import 'package:elena_app/src/features/dashboard/application/hydration_notifier.dart';
import 'package:elena_app/src/core/services/live_activity_service.dart';

/// Inicializa los listeners de sincronización con el Watch.
///
/// Llamar una sola vez desde app.dart después de que los providers estén
/// disponibles. Cada listener envía updates al Watch cuando detecta cambios.
class WatchStateSync {
  WatchStateSync._();

  static DateTime? _lastFastingSync;
  static DateTime? _lastHydrationSync;

  /// Throttle: no enviar más de 1 update por minuto por provider.
  static const _minSyncInterval = Duration(seconds: 30);

  /// Sincroniza el estado del ayuno con el Watch.
  /// Llamar desde el tick del fasting_notifier (cada minuto).
  static void syncFastingState(FastingState state) {
    if (!WatchConnectivityService.isPaired) return;

    final now = DateTime.now();
    if (_lastFastingSync != null &&
        now.difference(_lastFastingSync!) < _minSyncInterval) {
      return;
    }
    _lastFastingSync = now;

    final elapsed = state.duration.inMinutes;
    final phase = LiveActivityPhase.fromElapsedMinutes(elapsed);

    WatchConnectivityService.sendFastingUpdate(
      isActive: state.isActive,
      elapsedMinutes: elapsed,
      targetHours: state.targetHours,
      phaseName: phase.displayName,
      protocol: state.fastingProtocol,
      startedAt: state.startTime,
    );
  }

  /// Sincroniza el estado de hidratación con el Watch.
  /// Llamar cada vez que cambia el estado de hidratación.
  static void syncHydrationState(HydrationState state) {
    if (!WatchConnectivityService.isPaired) return;

    final now = DateTime.now();
    if (_lastHydrationSync != null &&
        now.difference(_lastHydrationSync!) < _minSyncInterval) {
      return;
    }
    _lastHydrationSync = now;

    WatchConnectivityService.sendHydrationUpdate(
      glassesCount: state.history.length,
      goalGlasses: state.dailyGoalGlasses,
      totalLiters: state.todayTotal,
    );
  }

  /// Registra listeners de Riverpod para sincronización automática.
  /// Llamar desde ProviderScope del widget raíz.
  static void registerListeners(WidgetRef ref) {
    // Fasting: sync cada vez que cambia el estado.
    ref.listen(fastingProvider, (prev, next) {
      syncFastingState(next);
    });

    // Hidratación: sync cada vez que cambia.
    ref.listen(hydrationProvider, (prev, next) {
      syncHydrationState(next);
    });
  }
}

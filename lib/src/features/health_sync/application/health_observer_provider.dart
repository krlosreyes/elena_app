// SPEC-132.next — provider side-effect que conecta los observers de HealthKit
// con el sync real. Escucha el stream del HealthObserverService y dispara
// `runNow` cuando llega un evento (con debounce local de 30s para colapsar
// ráfagas: peso+pasos+sueño del mismo workout llegan casi juntos).
//
// El root widget hace `ref.watch(healthObserverSideEffectProvider)` tras el
// bootstrap de auth para que arranque cuando hay sesión.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/features/billing/application/billing_providers.dart';
import 'package:elena_app/src/features/health_sync/application/health_auto_sync_controller.dart';
import 'package:elena_app/src/features/health_sync/application/health_observer_service.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

/// Singleton del cliente de observers. Vive toda la sesión.
final healthObserverServiceProvider = Provider<HealthObserverService>((ref) {
  final service = HealthObserverService();
  ref.onDispose(service.dispose);
  return service;
});

/// Side-effect: escucha eventos de Apple Health y dispara el sync. Arranca los
/// observers nativos al montar.
final healthObserverSideEffectProvider = Provider<void>((ref) {
  final service = ref.watch(healthObserverServiceProvider);

  DateTime? lastTriggered;
  final sub = service.events.listen((event) async {
    void finish() {
      if (event.done != null && !event.done!.isCompleted) {
        event.done!.complete();
      }
    }

    final now = DateTime.now();
    // Debounce local: una sola sync por ráfaga de eventos (<30s).
    if (lastTriggered != null &&
        now.difference(lastTriggered!) < const Duration(seconds: 30)) {
      AppLogger.debug('[HKObserver] evento descartado — debounce activo');
      finish();
      return;
    }
    lastTriggered = now;

    try {
      // 2026-11-04: en un arranque en segundo plano el usuario (Firestore)
      // y la suscripción (RevenueCat) todavía están cargando. Antes el
      // evento se descartaba ahí mismo → background delivery nunca
      // sincronizaba. Ahora esperamos hasta 15 s a que estén listos.
      final ready = await _waitUntil(() {
        final user = ref.read(currentUserStreamProvider).valueOrNull;
        return user != null &&
            user.id.isNotEmpty &&
            ref.read(featureGateProvider).autoSyncAllowed;
      }, timeout: const Duration(seconds: 15));
      if (!ready) {
        AppLogger.debug(
            '[HKObserver] evento descartado — sin usuario o sin autoSync');
        return;
      }
      final user = ref.read(currentUserStreamProvider).valueOrNull!;
      AppLogger.debug('[HKObserver] evento ${event.type} — runNow '
          'uid=${AppLogger.truncateUid(user.id)}');
      // `runNow` (no `runIfDue`): data fresca confirmada por HealthKit.
      await ref
          .read(healthAutoSyncControllerProvider.notifier)
          .runNow(userId: user.id);
    } catch (e) {
      AppLogger.warning('[HKObserver] sync por evento falló: $e');
    } finally {
      finish();
    }
  });
  ref.onDispose(sub.cancel);

  // Arrancar los observers nativos (no-op en plataformas sin el canal).
  service.start();
  AppLogger.debug('[HKObserver] observers nativos iniciados');
});


/// Espera a que [condition] sea verdadera, revisando cada 500 ms.
Future<bool> _waitUntil(bool Function() condition,
    {required Duration timeout}) async {
  final deadline = DateTime.now().add(timeout);
  while (true) {
    if (condition()) return true;
    if (DateTime.now().isAfter(deadline)) return false;
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
}

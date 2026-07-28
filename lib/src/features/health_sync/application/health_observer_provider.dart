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
  final sub = service.events.listen((event) {
    final now = DateTime.now();

    // Debounce local: una sola sync por ráfaga de eventos (<30s).
    if (lastTriggered != null &&
        now.difference(lastTriggered!) < const Duration(seconds: 30)) {
      AppLogger.debug(
        '[HKObserver] evento descartado — debounce activo '
        '(${now.difference(lastTriggered!).inSeconds}s < 30s)',
      );
      return;
    }
    lastTriggered = now;

    final user = ref.read(currentUserStreamProvider).valueOrNull;
    if (user == null || user.id.isEmpty) {
      AppLogger.debug(
          '[HKObserver] evento descartado — sin usuario autenticado');
      return;
    }

    // SPEC-197: el auto-sync de wearables es Premium. Free registra manual.
    final gate = ref.read(featureGateProvider);
    if (!gate.autoSyncAllowed) {
      AppLogger.debug(
        '[HKObserver] evento descartado — autoSync no permitido '
        '(isPremium=${gate.isPremium}, isInTrial=${gate.isInTrial}). '
        'RC puede estar cargando aún; el listener de featureGateProvider '
        'en app.dart relanzará el sync cuando el entitlement esté listo.',
      );
      return;
    }

    // SEC-07: uid truncado, nunca completo en logs.
    AppLogger.debug(
        '[HKObserver] evento aceptado — lanzando runNow uid=${AppLogger.truncateUid(user.id)}');
    // `runNow` (no `runIfDue`): el evento del observer ignora el debounce de
    // 15 min del foreground — es data fresca confirmada por HealthKit.
    ref.read(healthAutoSyncControllerProvider.notifier).runNow(userId: user.id);
  });
  ref.onDispose(sub.cancel);

  // Arrancar los observers nativos (no-op en plataformas sin el canal).
  service.start();
  AppLogger.debug('[HKObserver] observers nativos iniciados');
});

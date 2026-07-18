import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Auditoría 2026-07-11 (CODE-01): varios notifiers offline-first
/// (Hydration, Exercise, Nutrition) repetían línea por línea la misma
/// gestión de `StreamSubscription`:
///   - cancelar la suscripción anterior antes de re-suscribir,
///   - cancelar la suscripción activa al cerrar sesión (logout),
///   - cancelar la suscripción en `dispose()`.
///
/// Este mixin encapsula SOLO esa gestión — el "plomería" de la
/// suscripción — y deja 100% intacta la lógica de negocio de cada
/// notifier (qué stream, con qué `since`, qué hace con los datos
/// emitidos, baseline/merge, etc.), que difiere entre pilares y NO debe
/// fusionarse.
///
/// Notifiers que SÍ comparten este patrón exacto (ver
/// `_subscribeFor(cycleStartedAt)` + `dispose()` de una sola línea):
///   - HydrationNotifier
///   - ExerciseNotifier
///   - NutritionNotifier
///
/// Notifiers dejados FUERA deliberadamente (patrón distinto, fusionar
/// sería riesgoso sin compilador disponible para validar):
///   - SleepNotifier: no es cycle-aware (no tiene `_activeUserId` /
///     `_currentCycleStartedAt`); su re-suscripción ocurre desde
///     `onDone` del propio stream con una firma distinta
///     (`_initSleepSubscription(userId)`), no desde `_subscribeFor`.
///   - FastingNotifier: no usa `StreamSubscription` en absoluto — solo
///     `ref.listen` sobre providers ya gestionados por Riverpod (ver su
///     comentario "SPEC-61: ya no hay Timer interno"). No tiene `dispose()`
///     propio que cancelar.
mixin OfflineFirstStreamMixin<T> on StateNotifier<T> {
  StreamSubscription? _offlineFirstSub;

  /// True si hay una suscripción activa. Reemplaza el chequeo repetido
  /// `_sub == null` que cada notifier usaba para decidir si ya había
  /// una suscripción viva (p.ej. antes de re-suscribir al cambiar de
  /// ciclo metabólico).
  bool get hasActiveSubscription => _offlineFirstSub != null;

  /// Cancela la suscripción anterior (si existía) y adopta la nueva.
  /// Reemplaza el patrón repetido:
  /// ```dart
  /// _sub?.cancel();
  /// _sub = null;
  /// _sub = repo.watchXxx(...).listen(...);
  /// ```
  void attachSubscription(StreamSubscription subscription) {
    _offlineFirstSub?.cancel();
    _offlineFirstSub = subscription;
  }

  /// Cancela la suscripción activa sin reemplazarla — usado en el path
  /// de logout, donde el notifier resetea su estado y espera al
  /// próximo usuario antes de volver a suscribirse.
  void cancelActiveSubscription() {
    _offlineFirstSub?.cancel();
    _offlineFirstSub = null;
  }

  @override
  void dispose() {
    _offlineFirstSub?.cancel();
    super.dispose();
  }
}

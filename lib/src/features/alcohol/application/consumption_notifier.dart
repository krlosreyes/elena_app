// SPEC-261: notifier del Protocolo de Consumo Consciente.
//
// Sigue el patrón de HydrationNotifier (SPEC-50.1 / SPEC-149.2 / SPEC-194):
//   - Se ancla al Día Metabólico vía `currentMetabolicCycleProvider`
//     (Constitución §1: cero reloj) con fallback a `startOfDay(now)`.
//   - Offline-first: NUNCA hace `await` a un write de Firestore. Escribe
//     en la caché local y el stream `watchSince` refleja el cambio al
//     instante, incluso sin red.
//
// Los consumos (`drinks`) provienen del stream de Firestore. Los metadatos
// de la sesión (fase, presupuesto, acciones de mitigación) son estado local
// de la ocasión; persistirlos como documento `ConsumoSession` queda para una
// fase posterior.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/offline_first_stream_mixin.dart';
import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/core/services/day_boundary_resolver.dart';
import 'package:elena_app/src/features/alcohol/data/consumption_repository_impl.dart';
import 'package:elena_app/src/features/alcohol/domain/alcohol_catalog_item.dart';
import 'package:elena_app/src/features/alcohol/domain/consumption_session.dart';
import 'package:elena_app/src/features/alcohol/domain/drink_event.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

class ConsumptionNotifier extends StateNotifier<ConsumptionSession>
    with OfflineFirstStreamMixin<ConsumptionSession> {
  final Ref _ref;
  String? _activeUserId;
  DateTime? _currentCycleStartedAt;

  ConsumptionNotifier(this._ref) : super(const ConsumptionSession()) {
    _init();
  }

  void _init() {
    _ref.listen<AsyncValue<UserModel?>>(currentUserStreamProvider,
        (previous, next) {
      next.whenData((user) {
        if (user != null) {
          _activeUserId = user.id;
          _subscribeFor(_currentCycleStartedAt);
        } else {
          _activeUserId = null;
          cancelActiveSubscription();
          if (mounted) state = const ConsumptionSession();
        }
      });
    }, fireImmediately: true);

    _ref.listen<AsyncValue<MetabolicCycle?>>(
      currentMetabolicCycleProvider,
      (previous, next) {
        next.whenData((cycle) {
          final newSince = cycle?.startedAt;
          if (!hasActiveSubscription || newSince != _currentCycleStartedAt) {
            _currentCycleStartedAt = newSince;
            _subscribeFor(newSince);
          }
        });
      },
      fireImmediately: true,
    );
  }

  void _subscribeFor(DateTime? cycleStartedAt) {
    final userId = _activeUserId;
    if (userId == null) return;
    final since =
        cycleStartedAt ?? DayBoundaryResolver.startOfDay(DateTime.now());
    attachSubscription(_ref
        .read(consumptionRepositoryProvider)
        .watchSince(userId, since)
        .listen((drinks) {
      if (mounted) {
        state = state.copyWith(drinks: drinks);
      }
    }));
  }

  // ── Ciclo de vida del protocolo ─────────────────────────────────────

  /// Activa el protocolo (Fase A · Antes). Idempotente si ya está activo.
  void startProtocol({double? budgetStandardUnits}) {
    if (!mounted) return;
    state = state.copyWith(
      phase: ConsumptionPhase.antes,
      budgetStandardUnits: budgetStandardUnits ?? state.budgetStandardUnits,
    );
  }

  void setBudget(double standardUnits) {
    if (!mounted || standardUnits <= 0) return;
    state = state.copyWith(budgetStandardUnits: standardUnits);
  }

  void setHydratedBefore(bool value) =>
      _setFlag(hydratedBefore: value);
  void setAteBefore(bool value) => _setFlag(ateBefore: value);
  void setRecoveryFastPlanned(bool value) =>
      _setFlag(recoveryFastPlanned: value);

  void _setFlag({
    bool? hydratedBefore,
    bool? ateBefore,
    bool? recoveryFastPlanned,
  }) {
    if (!mounted) return;
    state = state.copyWith(
      hydratedBefore: hydratedBefore,
      ateBefore: ateBefore,
      recoveryFastPlanned: recoveryFastPlanned,
    );
  }

  /// Calcula la hora objetivo del último trago dejando [marginHours] de
  /// margen antes de dormir, para proteger el sueño.
  void computeLastCall(DateTime bedtime, {double marginHours = 3}) {
    if (!mounted) return;
    final target =
        bedtime.subtract(Duration(minutes: (marginHours * 60).round()));
    state = state.copyWith(lastCallTarget: target);
  }

  /// Avanza a la siguiente fase de forma lineal.
  void advancePhase() {
    if (!mounted) return;
    final next = switch (state.phase) {
      ConsumptionPhase.inactive => ConsumptionPhase.antes,
      ConsumptionPhase.antes => ConsumptionPhase.durante,
      ConsumptionPhase.durante => ConsumptionPhase.despues,
      ConsumptionPhase.despues => ConsumptionPhase.recuperacion,
      ConsumptionPhase.recuperacion => ConsumptionPhase.recuperacion,
    };
    state = state.copyWith(phase: next);
  }

  /// Cierra el protocolo y vuelve a inactivo (conserva el historial en
  /// Firestore; solo se limpian los metadatos locales de la ocasión).
  void endProtocol() {
    if (!mounted) return;
    state = ConsumptionSession(drinks: state.drinks);
  }

  // ── Registro de consumos (offline-first) ────────────────────────────

  /// Registra un consumo desde el catálogo. No bloquea la UI esperando al
  /// servidor: el stream refleja el nuevo total enseguida (incluso sin red).
  void logDrink(
    AlcoholCatalogItem item, {
    double? servingMl,
    bool waterChaser = false,
  }) {
    final user = _ref.read(currentUserStreamProvider).value;
    if (user == null) return;

    final event = DrinkEvent.fromCatalog(
      item,
      servingMl: servingMl,
      waterChaser: waterChaser,
    );

    final repo = _ref.read(consumptionRepositoryProvider);
    unawaited(repo.add(user.id, event).catchError((Object e) {
      AppLogger.error('ConsumptionNotifier.logDrink falló', e);
    }));
  }

  /// Descuenta el último consumo del ciclo actual.
  void removeLastDrink() {
    final user = _ref.read(currentUserStreamProvider).value;
    if (user == null || state.drinks.isEmpty) return;

    final since = _currentCycleStartedAt ??
        DayBoundaryResolver.startOfDay(DateTime.now());

    unawaited(_ref
        .read(consumptionRepositoryProvider)
        .removeLast(user.id, since)
        .catchError((Object e) {
      AppLogger.error('ConsumptionNotifier.removeLastDrink falló', e);
    }));
  }
}

final consumptionProvider =
    StateNotifierProvider<ConsumptionNotifier, ConsumptionSession>((ref) {
  return ConsumptionNotifier(ref);
});

// SPEC-261 / SPEC-261.4: notifier del Protocolo de Consumo Consciente.
//
// Sigue el patrón de HydrationNotifier (offline-first, anclado al Día
// Metabólico). Dos fuentes de verdad, consistentes entre sí:
//   - `drinks`  → colección alcohol_history (stream anclado al ciclo).
//   - metadatos → documento alcohol_session/current (fase, plan, insumos).
//
// Ambos se persisten en Firestore y sobreviven al cierre de la app. Los
// writes son no bloqueantes (offline-first): el estado local se actualiza al
// instante y el stream lo confirma después, incluso sin red.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/offline_first_stream_mixin.dart';
import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/core/services/day_boundary_resolver.dart';
import 'package:elena_app/src/features/alcohol/data/consumption_repository_impl.dart';
import 'package:elena_app/src/features/alcohol/data/consumption_session_repository.dart';
import 'package:elena_app/src/features/alcohol/domain/alcohol_catalog_item.dart';
import 'package:elena_app/src/features/alcohol/domain/consumption_session.dart';
import 'package:elena_app/src/features/alcohol/domain/drink_event.dart';
import 'package:elena_app/src/features/alcohol/domain/drink_recommendation.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

class ConsumptionNotifier extends StateNotifier<ConsumptionSession>
    with OfflineFirstStreamMixin<ConsumptionSession> {
  final Ref _ref;
  String? _activeUserId;
  DateTime? _currentCycleStartedAt;
  StreamSubscription<ConsumptionSession?>? _sessionSub;

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
          _subscribeSession();
        } else {
          _activeUserId = null;
          cancelActiveSubscription();
          _sessionSub?.cancel();
          _sessionSub = null;
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

  /// Stream de consumos (drinks), anclado al ciclo metabólico.
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

  /// Stream de los metadatos de la sesión (documento `current`). Restaura la
  /// ocasión al abrir la app; null = no hay ocasión → sesión inactiva.
  void _subscribeSession() {
    final userId = _activeUserId;
    if (userId == null) return;
    _sessionSub?.cancel();
    _sessionSub = _ref
        .read(consumptionSessionRepositoryProvider)
        .watch(userId)
        .listen((meta) {
      if (mounted) {
        state = state.copyMetaFrom(meta ?? const ConsumptionSession());
      }
    });
  }

  /// Persiste los metadatos actuales (offline-first, no bloqueante).
  void _persistSession() {
    final userId = _activeUserId;
    if (userId == null) return;
    unawaited(_ref
        .read(consumptionSessionRepositoryProvider)
        .save(userId, state)
        .catchError((Object e) {
      AppLogger.error('ConsumptionNotifier.persistSession falló', e);
    }));
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    super.dispose();
  }

  // ── Ciclo de vida del protocolo ─────────────────────────────────────

  /// Activa el protocolo (Fase A · Antes). Idempotente si ya está activo.
  void startProtocol({double? budgetStandardUnits}) {
    if (!mounted) return;
    state = state.copyWith(
      phase: ConsumptionPhase.antes,
      budgetStandardUnits: budgetStandardUnits ?? state.budgetStandardUnits,
    );
    _persistSession();
  }

  void setBudget(double standardUnits) {
    if (!mounted || standardUnits <= 0) return;
    state = state.copyWith(budgetStandardUnits: standardUnits);
    _persistSession();
  }

  /// SPEC-261.4: tipo de trago elegido en el picker.
  void setDrinkType(String id) {
    if (!mounted) return;
    state = state.copyWith(drinkTypeId: id);
    _persistSession();
  }

  /// SPEC-261.4: hora de inicio de la fiesta.
  void setStartTime(DateTime t) {
    if (!mounted) return;
    state = state.copyWith(startTime: t);
    _persistSession();
  }

  /// SPEC-261.4: agenda de mañana (define la hora de dormir recomendada).
  void setSchedule({required bool worksTomorrow, DateTime? wakeTime}) {
    if (!mounted) return;
    state = state.copyWith(worksTomorrow: worksTomorrow, wakeTime: wakeTime);
    _persistSession();
  }

  /// SPEC-261.4: aplica el plan recomendado (presupuesto + horas) y arranca
  /// el registro (Durante).
  void applyPlan(DrinkRecommendation r) {
    if (!mounted) return;
    // El presupuesto del tracking va en UEA, no en servidas físicas.
    final budget = r.budgetUnits < 1.0 ? 1.0 : r.budgetUnits;
    state = state.copyWith(
      budgetStandardUnits: budget,
      bedtime: r.bedtime,
      lastCallTarget: r.lastCall,
      phase: ConsumptionPhase.durante,
    );
    _persistSession();
  }

  void setHydratedBefore(bool value) => _setFlag(hydratedBefore: value);
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
    _persistSession();
  }

  /// Registra la hora de dormir y calcula la hora del último trago dejando el
  /// margen de sueño (3 h por defecto) para proteger el REM.
  void setBedtime(DateTime bedtime,
      {Duration margin = ConsumptionSession.sleepMargin}) {
    if (!mounted) return;
    state = state.copyWith(
      bedtime: bedtime,
      lastCallTarget: bedtime.subtract(margin),
    );
    _persistSession();
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
    _persistSession();
  }

  /// Cierra el protocolo y vuelve a inactivo. Conserva el historial de tragos
  /// (alcohol_history); borra el documento de sesión persistido.
  void endProtocol() {
    if (!mounted) return;
    final userId = _activeUserId;
    state = ConsumptionSession(drinks: state.drinks);
    if (userId != null) {
      unawaited(_ref
          .read(consumptionSessionRepositoryProvider)
          .clear(userId)
          .catchError((Object e) {
        AppLogger.error('ConsumptionNotifier.endProtocol clear falló', e);
      }));
    }
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

    // Guiado y contextual: el primer trago mueve la sesión de "Antes" a
    // "Durante" sin que el usuario tenga que tocar nada.
    if (mounted && state.phase == ConsumptionPhase.antes) {
      state = state.copyWith(phase: ConsumptionPhase.durante);
      _persistSession();
    }

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

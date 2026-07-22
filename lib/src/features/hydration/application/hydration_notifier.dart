import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
// IMPORTANTE: Esta es la ruta al archivo que creamos para centralizar el usuario
import 'package:elena_app/src/core/analytics/analytics_events.dart';
import 'package:elena_app/src/core/offline_first_stream_mixin.dart';
import 'package:elena_app/src/core/orchestrator/biological_phases.dart';
import 'package:elena_app/src/core/services/analytics_service.dart';
import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/core/services/notification_service.dart';
import 'package:elena_app/src/core/services/notification_scheduler.dart';
import 'package:elena_app/src/features/coaching/application/coaching_completion_service.dart';
// SPEC-194 (2026-06-06): day_boundary_resolver reintroducido como
// FALLBACK cuando no hay ciclo abierto. Cuando hay ciclo, el comportamiento
// sigue cycle-aware estricto (Constitución §1). Sin ciclo, ventana
// startOfDay(now) para que los logs del día sean visibles.
import 'package:elena_app/src/core/services/day_boundary_resolver.dart';
import 'package:elena_app/src/features/hydration/data/hydration_repository_impl.dart';
import 'package:elena_app/src/features/hydration/domain/hydration_log.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';
import 'package:elena_app/src/features/goals/application/goal_notifier.dart';
import 'package:elena_app/src/features/goals/application/pillar_goal_resolver.dart';

class HydrationState {
  final double dailyGoalLiters;
  final double currentAmountLiters;
  final List<HydrationLog> history;
  final bool isSaving;
  final bool isGoalReached;

  /// SPEC-179 (2026-06-05): mensaje del último error de persistencia,
  /// null cuando no hay error pendiente. La UI lo lee para mostrar
  /// SnackBar con "Reintentar". Se limpia al siguiente write exitoso
  /// o al consumirse explícitamente vía `clearError()`.
  final String? lastWriteError;

  HydrationState({
    this.dailyGoalLiters = 2.5,
    this.currentAmountLiters = 0.0,
    this.history = const [],
    this.isSaving = false,
    this.isGoalReached = false,
    this.lastWriteError,
  });

  double get progressPercentage =>
      (currentAmountLiters / dailyGoalLiters).clamp(0.0, 1.0);

  String get goalFormatted => dailyGoalLiters.toStringAsFixed(1);
  String get currentFormatted => currentAmountLiters.toStringAsFixed(1);

  HydrationState copyWith({
    double? dailyGoalLiters,
    double? currentAmountLiters,
    List<HydrationLog>? history,
    bool? isSaving,
    bool? isGoalReached,
    Object? lastWriteError = _kSentinel,
  }) {
    return HydrationState(
      dailyGoalLiters: dailyGoalLiters ?? this.dailyGoalLiters,
      currentAmountLiters: currentAmountLiters ?? this.currentAmountLiters,
      history: history ?? this.history,
      isSaving: isSaving ?? this.isSaving,
      isGoalReached: isGoalReached ?? this.isGoalReached,
      // Sentinel para permitir setear explícitamente a null.
      lastWriteError: identical(lastWriteError, _kSentinel)
          ? this.lastWriteError
          : lastWriteError as String?,
    );
  }
}

// SPEC-179: sentinel para distinguir "no se pasó" de "se pasó null".
const Object _kSentinel = Object();

class HydrationNotifier extends StateNotifier<HydrationState>
    with OfflineFirstStreamMixin<HydrationState> {
  final Ref _ref;
  String? _activeUserId;
  DateTime? _currentCycleStartedAt;

  HydrationNotifier(this._ref) : super(HydrationState()) {
    _init();
  }

  void _init() {
    _ref.listen<AsyncValue<UserModel?>>(currentUserStreamProvider,
        (previous, next) {
      next.whenData((user) {
        if (user != null) {
          // BUGFIX objetivos: meta desde "Mis objetivos" (SoT) con fallback
          // a la fórmula por peso (35 ml/kg).
          final calculatedGoal = PillarGoalResolver.hydrationLiters(
            _ref.read(goalsProvider),
            user,
          );

          state = state.copyWith(
            dailyGoalLiters: calculatedGoal,
            isGoalReached: state.currentAmountLiters >= calculatedGoal,
          );

          _activeUserId = user.id;
          // SPEC-149.2: la suscripción concreta la hace _subscribeFor con
          // el `since` del ciclo actual. Si todavía no llegó el ciclo,
          // _subscribeFor usa fallback a startOfDay.
          _subscribeFor(_currentCycleStartedAt);
        } else {
          // SPEC-11: Usuario cerró sesión — cancelar suscripción activa y
          // resetear estado al valor inicial para aislar al próximo usuario.
          _activeUserId = null;
          cancelActiveSubscription();
          if (mounted) state = HydrationState();
        }
      });
    }, fireImmediately: true);

    // SPEC-149.2: re-suscribir cuando cambia el inicio del ciclo
    // metabólico — el conteo de hidratación se ancla al Día Metabólico.
    _ref.listen<AsyncValue<MetabolicCycle?>>(
      currentMetabolicCycleProvider,
      (previous, next) {
        next.whenData((cycle) {
          final newSince = cycle?.startedAt;
          // SPEC-178.bugfix2 (2026-06-05): si el primer fire emite con
          // cycle == null, newSince == _currentCycleStartedAt (ambos null)
          // y la igualdad bloqueaba la suscripción inicial. Subscribe
          // siempre que no haya subscription activa.
          if (!hasActiveSubscription ||
              newSince != _currentCycleStartedAt) {
            _currentCycleStartedAt = newSince;
            _subscribeFor(newSince);
          }
        });
      },
      fireImmediately: true,
    );

    // BUGFIX objetivos: recomputar la meta cuando el usuario edita sus
    // objetivos en "Mis objetivos" (la card es la fuente de verdad).
    _ref.listen<GoalsMap>(goalsProvider, (previous, next) {
      final user = _ref.read(currentUserStreamProvider).valueOrNull;
      if (user == null || !mounted) return;
      final goal = PillarGoalResolver.hydrationLiters(next, user);
      state = state.copyWith(
        dailyGoalLiters: goal,
        isGoalReached: state.currentAmountLiters >= goal,
      );
    });
  }

  /// SPEC-149.2 + SPEC-189 + SPEC-194.1 (2026-06-06): suscripción al
  /// stream filtrado por la ventana del ciclo metabólico, con FALLBACK
  /// a `startOfDay(now)` cuando no hay ciclo abierto.
  ///
  /// Cycle-aware (Constitución §1) cuando hay ciclo: ventana desde
  /// `cycle.startedAt`. SIN ciclo (primer uso, post-cierre antes del
  /// siguiente ayuno, desync), usamos `startOfDay(now)` como ventana
  /// para que los logs registrados hoy sean visibles en los rings.
  ///
  /// Sin este fallback, el ring quedaba en 0% aunque el usuario hubiese
  /// registrado litros — bug post-SPEC-194 al quitar el placeholder.
  /// Cuando el usuario inicie su próximo ayuno, el listener al
  /// `currentMetabolicCycleProvider` re-suscribe con la ventana del
  /// ciclo nuevo automáticamente.
  void _subscribeFor(DateTime? cycleStartedAt) {
    final userId = _activeUserId;
    if (userId == null) return;
    final since = cycleStartedAt ??
        DayBoundaryResolver.startOfDay(DateTime.now());
    attachSubscription(_ref
        .read(hydrationRepositoryProvider)
        .watchSince(userId, since)
        .listen((logs) {
      if (mounted) {
        final total = logs.fold<double>(
          0.0,
          (sum, log) => sum + log.amountInLiters,
        );
        state = state.copyWith(
          currentAmountLiters: total,
          history: logs,
          isGoalReached: total >= state.dailyGoalLiters,
        );
      }
    }));
  }

  /// SPEC-58 + SPEC-149.2: Reset idempotente disparado al cierre del
  /// ciclo metabólico o a medianoche calendárica (red de seguridad).
  ///
  /// Limpia el contador en caché y re-suscribe el stream usando el
  /// `since` del ciclo activo (anclado al Día Metabólico).
  ///
  /// Conserva `dailyGoalLiters` porque depende del peso del usuario,
  /// no del día.
  void resetDaily() {
    if (!mounted) return;
    state = HydrationState(
      dailyGoalLiters: state.dailyGoalLiters,
    );
    _subscribeFor(_currentCycleStartedAt);

    // Audit notif (2026-06-10): re-armar los recordatorios de hidratación del
    // día nuevo. Si ayer se cumplió la meta los cancelamos; el reset los
    // vuelve a programar para que hoy arranquen de nuevo (cada 30 min).
    final user = _ref.read(currentUserStreamProvider).value;
    if (user != null) {
      unawaited(NotificationScheduler.scheduleHydrationReminders(user));
    }
  }

  Future<void> addWater(double amount) async {
    // Usamos el .value del AsyncValue del provider centralizado
    final user = _ref.read(currentUserStreamProvider).value;
    if (user == null) return;

    final bool wasReached = state.isGoalReached;
    final bool reached =
        (state.currentAmountLiters + amount) >= state.dailyGoalLiters;

    final newLog = HydrationLog(
      amountInLiters: amount,
      timestamp: DateTime.now(),
    );

    // SPEC-206 (offline-first): NO bloqueamos la UI esperando el ack del
    // servidor. `repo.add` escribe en la caché local de Firestore al instante;
    // el listener `watchSince` (.snapshots) refleja el nuevo total enseguida
    // —incluso SIN red— porque la caché emite con hasPendingWrites. El Future
    // del write solo resuelve al reconectar: hacerle `await` (como antes)
    // dejaba `isSaving` colgado offline y la app parecía "no funcionar sin
    // internet". Ahora el dato se ve al toque y se sincroniza solo al volver
    // la conexión.

    // Efecto LOCAL (no requiere red): meta alcanzada → cancelar recordatorios.
    if (reached && !wasReached) {
      unawaited(_cancelHydrationRemindersOnGoal());
    }

    final repo = _ref.read(hydrationRepositoryProvider);
    unawaited(
      repo.add(user.id, newLog).then((_) {
        if (!mounted) return;
        // Ack del servidor (online): limpiar error + efectos que requieren red.
        state = state.copyWith(lastWriteError: null);
        AnalyticsService.logEvent(
          AnalyticsEvents.pillarLogged,
          params: const {AnalyticsParams.pillar: 'hydration'},
        );
        _ref
            .read(coachingCompletionProvider)
            .onPillarActivity(Pillar.hydration);
      }).catchError((Object e) {
        // Error REAL (permisos/validación), NO el simple offline —que queda
        // pendiente sin emitir—. Firestore revierte la mutación local fallida
        // y el listener corrige el total; acá solo avisamos a la UI.
        if (!mounted) return;
        AppLogger.error('HydrationNotifier.addWater falló', e);
        state = state.copyWith(
          lastWriteError:
              'No pudimos guardar tu hidratación. Revisa tu conexión.',
        );
      }),
    );
  }

  /// Cancela los recordatorios de hidratación del día al alcanzar la meta.
  /// Es local (flutter_local_notifications) → corre con o sin red. Un fallo
  /// acá NO afecta el registro de agua ya encolado en Firestore.
  Future<void> _cancelHydrationRemindersOnGoal() async {
    try {
      await NotificationService.cancelHydration();
      await NotificationService.cancel(NotificationIds.hydrationSnooze);
      AppLogger.info(
          '[Hydration] meta alcanzada → recordatorios de hoy cancelados');
    } catch (e) {
      AppLogger.warning('[Hydration] no se pudieron cancelar notifs: $e');
    }
  }

  /// Descuenta el último vaso registrado en el ciclo actual.
  /// Borra el log más reciente de Firestore; el stream re-emite el total
  /// corregido automáticamente. No-op si no hay logs en la ventana.
  Future<void> removeLastWater() async {
    final user = _ref.read(currentUserStreamProvider).value;
    if (user == null) return;
    if (state.history.isEmpty) return;

    final since = _currentCycleStartedAt ??
        DayBoundaryResolver.startOfDay(DateTime.now());

    unawaited(
      _ref
          .read(hydrationRepositoryProvider)
          .removeLastLog(user.id, since)
          .catchError((Object e) {
        AppLogger.error('HydrationNotifier.removeLastWater falló', e);
        if (mounted) {
          state = state.copyWith(
            lastWriteError:
                'No pudimos descontar el vaso. Revisa tu conexión.',
          );
        }
      }),
    );
  }

  /// SPEC-179: la UI llama esto cuando muestra el SnackBar de error
  /// para que no se repita en el próximo build.
  void clearWriteError() {
    if (state.lastWriteError != null) {
      state = state.copyWith(lastWriteError: null);
    }
  }
}

final hydrationProvider =
    StateNotifierProvider<HydrationNotifier, HydrationState>((ref) {
  return HydrationNotifier(ref);
});

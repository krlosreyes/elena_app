import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
// IMPORTANTE: Esta es la ruta al archivo que creamos para centralizar el usuario
import 'package:elena_app/src/core/services/day_boundary_resolver.dart';
import 'package:elena_app/src/features/dashboard/data/hydration_repository_impl.dart';
import 'package:elena_app/src/features/dashboard/domain/hydration_log.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

class HydrationState {
  final double dailyGoalLiters;
  final double currentAmountLiters;
  final List<HydrationLog> history;
  final bool isSaving;
  final bool isGoalReached;

  HydrationState({
    this.dailyGoalLiters = 2.5,
    this.currentAmountLiters = 0.0,
    this.history = const [],
    this.isSaving = false,
    this.isGoalReached = false,
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
  }) {
    return HydrationState(
      dailyGoalLiters: dailyGoalLiters ?? this.dailyGoalLiters,
      currentAmountLiters: currentAmountLiters ?? this.currentAmountLiters,
      history: history ?? this.history,
      isSaving: isSaving ?? this.isSaving,
      isGoalReached: isGoalReached ?? this.isGoalReached,
    );
  }
}

class HydrationNotifier extends StateNotifier<HydrationState> {
  final Ref _ref;
  StreamSubscription? _hydrationSubscription;
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
          final double weight = user.weight > 0 ? user.weight : 75.0;
          final calculatedGoal = (weight * 0.035);

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
          _hydrationSubscription?.cancel();
          _hydrationSubscription = null;
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
          if (newSince != _currentCycleStartedAt) {
            _currentCycleStartedAt = newSince;
            _subscribeFor(newSince);
          }
        });
      },
      fireImmediately: true,
    );
  }

  /// SPEC-149.2: suscripción al stream filtrado por la ventana del
  /// ciclo metabólico. Fallback a startOfDay si no hay ciclo abierto.
  void _subscribeFor(DateTime? cycleStartedAt) {
    final userId = _activeUserId;
    if (userId == null) return;
    _hydrationSubscription?.cancel();
    final since =
        cycleStartedAt ?? DayBoundaryResolver.startOfDay(DateTime.now());
    _hydrationSubscription = _ref
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
    });
  }

  @override
  void dispose() {
    _hydrationSubscription?.cancel();
    super.dispose();
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
  }

  Future<void> addWater(double amount) async {
    // Usamos el .value del AsyncValue del provider centralizado
    final user = _ref.read(currentUserStreamProvider).value;
    if (user == null) return;

    final newAmount = state.currentAmountLiters + amount;
    final bool reached = newAmount >= state.dailyGoalLiters;

    final newLog = HydrationLog(
      amountInLiters: amount,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      currentAmountLiters: newAmount,
      history: [...state.history, newLog],
      isSaving: true,
      isGoalReached: reached,
    );

    try {
      // SPEC-50.1: HydrationRepository.add (no UserRepository.saveHydrationLog).
      final repo = _ref.read(hydrationRepositoryProvider);
      await repo.add(user.id, newLog);
    } catch (e) {
      // Log de error técnico
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }
}

final hydrationProvider =
    StateNotifierProvider<HydrationNotifier, HydrationState>((ref) {
  return HydrationNotifier(ref);
});

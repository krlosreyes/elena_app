import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
// IMPORTANTE: Esta es la ruta al archivo que creamos para centralizar el usuario
import 'package:elena_app/src/shared/providers/user_provider.dart'; 
import 'package:elena_app/src/features/dashboard/domain/hydration_log.dart';
import 'package:elena_app/src/shared/domain/services/user_repository.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';

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

  double get progressPercentage => (currentAmountLiters / dailyGoalLiters).clamp(0.0, 1.0);

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

  HydrationNotifier(this._ref) : super(HydrationState()) {
    _init();
  }

  void _init() {
    _ref.listen<AsyncValue<UserModel?>>(currentUserStreamProvider, (previous, next) {
      next.whenData((user) {
        if (user != null) {
          final double weight = user.weight > 0 ? user.weight : 75.0;
          final calculatedGoal = (weight * 0.035);

          state = state.copyWith(
            dailyGoalLiters: calculatedGoal,
            isGoalReached: state.currentAmountLiters >= calculatedGoal,
          );

          // Iniciar suscripción a hidratación real
          _initHydrationSubscription(user.id);
        } else {
          // SPEC-11: Usuario cerró sesión — cancelar suscripción activa y
          // resetear estado al valor inicial para aislar al próximo usuario.
          _hydrationSubscription?.cancel();
          _hydrationSubscription = null;
          if (mounted) state = HydrationState();
        }
      });
    }, fireImmediately: true);
  }

  void _initHydrationSubscription(String userId) {
    _hydrationSubscription?.cancel();
    _hydrationSubscription = _ref
        .read(userRepositoryProvider)
        .watchTodayHydration(userId)
        .listen((totalLiters) {
      if (mounted) {
        state = state.copyWith(
          currentAmountLiters: totalLiters,
          isGoalReached: totalLiters >= state.dailyGoalLiters,
        );
      }
    });
  }

  @override
  void dispose() {
    _hydrationSubscription?.cancel();
    super.dispose();
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
      final repo = _ref.read(userRepositoryProvider);
      await repo.saveHydrationLog(user.id, newLog);
    } catch (e) {
      // Log de error técnico
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }
}

final hydrationProvider = StateNotifierProvider<HydrationNotifier, HydrationState>((ref) {
  return HydrationNotifier(ref);
});
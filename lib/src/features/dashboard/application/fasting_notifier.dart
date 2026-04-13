import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/core/rules/circadian_rules.dart';
import 'package:elena_app/src/shared/domain/services/user_repository.dart';
import 'package:elena_app/src/features/dashboard/presentation/dashboard_screen.dart';
import '../domain/fasting_status.dart';

class FastingNotifier extends StateNotifier<FastingState> {
  final Ref _ref;
  Timer? _timer;

  FastingNotifier(this._ref) : super(FastingState.initial()) {
    _init();
  }

  void _init() {
    _ref.listen(currentUserStreamProvider, (previous, next) {
      final user = next.value;
      if (user != null) {
        final lastMeal = user.profile.lastMealGoal;
        final firstMeal = user.profile.firstMealGoal;

        bool isFasting = false;
        DateTime? activeStartTime;

        // Lógica de decisión: El evento más reciente define el estado actual
        if (lastMeal != null) {
          if (firstMeal == null || lastMeal.isAfter(firstMeal)) {
            isFasting = true;
            activeStartTime = lastMeal;
          } else {
            isFasting = false;
            activeStartTime = firstMeal;
          }
        }

        state = state.copyWith(
          startTime: activeStartTime,
          isActive: isFasting,
        );
      }
    }, fireImmediately: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  Future<void> startFasting() async {
    final now = DateTime.now();
    await _updateUserGoal(lastMeal: now);
  }

  Future<void> stopFasting() async {
    final now = DateTime.now();
    await _updateUserGoal(firstMeal: now);
  }

  Future<void> _updateUserGoal({DateTime? lastMeal, DateTime? firstMeal}) async {
    final userRepo = _ref.read(userRepositoryProvider);
    final currentUser = _ref.read(currentUserStreamProvider).value;

    if (currentUser != null) {
      final updatedUser = currentUser.copyWith(
        profile: currentUser.profile.copyWith(
          lastMealGoal: lastMeal ?? currentUser.profile.lastMealGoal,
          firstMealGoal: firstMeal ?? currentUser.profile.firstMealGoal,
        ),
      );
      await userRepo.saveUser(updatedUser);
    }
  }

  void _tick() {
    final now = DateTime.now();
    final currentCircadian = CircadianRules.getPhaseName(now);
    final timeToLock = CircadianRules.timeUntilLock(now);

    if (state.startTime == null) {
      state = state.copyWith(
        circadianPhase: currentCircadian, 
        timeUntilLock: timeToLock
      );
      return;
    }

    final duration = now.difference(state.startTime!);
    
    // Actualizamos el estado con la duración actual. 
    // Los getters proactivos en el domain se encargarán del resto en la UI.
    state = state.copyWith(
      duration: duration,
      phase: state.isActive ? FastingState.determinePhase(duration) : FastingPhase.none,
      circadianPhase: currentCircadian,
      timeUntilLock: timeToLock,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final fastingProvider = StateNotifierProvider<FastingNotifier, FastingState>((ref) {
  return FastingNotifier(ref);
});

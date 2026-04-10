import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/core/rules/circadian_rules.dart';
import 'package:elena_app/src/shared/domain/services/user_repository.dart';
import 'package:elena_app/src/features/dashboard/presentation/dashboard_screen.dart'; // Para el stream del usuario
import '../domain/fasting_status.dart';

// ... (Mantenemos FastingPhase y FastingState igual a como los definiste) ...

class FastingNotifier extends StateNotifier<FastingState> {
  final Ref _ref; // Necesitamos el Ref para leer otros providers
  Timer? _timer;

  FastingNotifier(this._ref) : super(FastingState()) {
    // Iniciamos el tick de inmediato para actualizar fases circadianas constantes
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  /// Inicia el ayuno y lo persiste en nam5
  Future<void> startFasting() async {
    final now = DateTime.now();
    
    // 1. Actualización de UI inmediata (Optimistic UI)
    state = state.copyWith(
      startTime: now, 
      isActive: true,
      circadianPhase: CircadianRules.getPhaseName(now),
      timeUntilLock: CircadianRules.timeUntilLock(now),
    );

    // 2. Persistencia en Firestore
    final userRepo = _ref.read(userRepositoryProvider);
    final currentUser = _ref.read(currentUserStreamProvider).value;

    if (currentUser != null) {
      // Actualizamos el modelo con la nueva marca de inicio (lastMealGoal)
      final updatedUser = currentUser.copyWith(
        profile: currentUser.profile.copyWith(lastMealGoal: now),
      );
      await userRepo.saveUser(updatedUser);
    }
  }

  void stopFasting() {
    _timer?.cancel();
    state = FastingState();
  }

  void _tick() {
    final now = DateTime.now();
    
    // Lógica para detectar si hay un ayuno en curso desde los datos del usuario
    // Si el estado local no tiene startTime, intentamos recuperarlo del Stream de Firebase
    if (!state.isActive) {
      final userFromFirebase = _ref.read(currentUserStreamProvider).value;
      final savedStart = userFromFirebase?.profile.lastMealGoal;

      // Si el tiempo guardado en Firebase es válido (no es "ahora" por defecto)
      if (savedStart != null && savedStart.isBefore(now.subtract(const Duration(seconds: 1)))) {
        state = state.copyWith(
          startTime: savedStart,
          isActive: true,
        );
      }
    }

    if (!state.isActive) {
      state = state.copyWith(
        circadianPhase: CircadianRules.getPhaseName(now),
        timeUntilLock: CircadianRules.timeUntilLock(now),
      );
      return;
    }

    final startTime = state.startTime ?? now;
    final duration = now.difference(startTime);
    
    state = state.copyWith(
      duration: duration,
      phase: _calculateFastingPhase(duration),
      circadianPhase: CircadianRules.getPhaseName(now),
      timeUntilLock: CircadianRules.timeUntilLock(now),
    );
  }

  FastingPhase _calculateFastingPhase(Duration d) {
    final hours = d.inHours;
    if (hours < 12) return FastingPhase.postAbsorption;
    if (hours < 18) return FastingPhase.transition;
    if (hours < 24) return FastingPhase.fatBurning;
    if (hours < 72) return FastingPhase.autophagy;
    return FastingPhase.survival;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// Actualizamos la definición del provider para pasarle el Ref
final fastingProvider = StateNotifierProvider<FastingNotifier, FastingState>((ref) {
  return FastingNotifier(ref);
});
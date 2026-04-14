import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/core/rules/circadian_rules.dart';
import 'package:elena_app/src/shared/domain/services/user_repository.dart';
import 'package:elena_app/src/features/dashboard/presentation/dashboard_screen.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import '../domain/fasting_status.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

final lastFastingIntervalProvider = StreamProvider<FastingInterval?>((ref) {
  final userRepo = ref.watch(userRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  final uid = authState.value?.id;

  if (uid == null) return Stream.value(null);
  return userRepo.watchLastInterval(uid);
});

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
        state = state.copyWith(fastingProtocol: user.fastingProtocol);
      }
    }, fireImmediately: true);

    _ref.listen(lastFastingIntervalProvider, (previous, next) {
      next.when(
        data: (interval) {
          if (interval == null) {
            state = state.copyWith(
              startTime: null,
              isActive: false,
              duration: Duration.zero,
              phase: FastingPhase.none,
            );
          } else {
            final now = DateTime.now();
            final duration = now.difference(interval.startTime);

            state = state.copyWith(
              startTime: interval.startTime,
              isActive: interval.isFasting,
              duration: duration,
              phase: interval.isFasting 
                  ? FastingState.determinePhase(duration) 
                  : FastingPhase.none,
            );
          }
        },
        loading: () => debugPrint("⏳ Sincronizando coordenadas metabólicas..."),
        error: (err, stack) => debugPrint("⚠️ Error en historial: $err"),
      );
    }, fireImmediately: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  Future<void> startFasting() async {
    final uid = _ref.read(authStateProvider).value?.id;
    if (uid == null) return;
    final userRepo = _ref.read(userRepositoryProvider);
    await userRepo.startNewInterval(uid, true);
  }

  Future<void> stopFasting() async {
    final uid = _ref.read(authStateProvider).value?.id;
    if (uid == null) return;
    final userRepo = _ref.read(userRepositoryProvider);
    await userRepo.startNewInterval(uid, false);
  }

  void _tick() {
    if (!mounted) return;
    final now = DateTime.now();
    final user = _ref.read(currentUserStreamProvider).value;

    // --- LÓGICA DE PROACTIVIDAD ELENA (PRE-SLEEP ALERT) ---
    bool shouldShowPreSleepWarning = false;
    
    if (user != null && !state.isActive) {
      // Normalizamos la hora de dormir a hoy
      final sleepToday = DateTime(now.year, now.month, now.day, 
          user.profile.sleepTime.hour, user.profile.sleepTime.minute);
      
      final diffToSleep = sleepToday.difference(now);
      
      // Si faltan menos de 3 horas para dormir y sigue comiendo...
      if (diffToSleep.inHours >= 0 && diffToSleep.inHours < 3) {
        shouldShowPreSleepWarning = true;
      }
    }

    if (state.startTime == null) {
      state = state.copyWith(
        circadianPhase: CircadianRules.getPhaseName(now),
        timeUntilLock: CircadianRules.timeUntilLock(now),
        // Aquí podrías añadir una propiedad 'nearSleepWarning' a tu FastingState si la creas
      );
      return;
    }

    final duration = now.difference(state.startTime!);
    
    state = state.copyWith(
      duration: duration,
      circadianPhase: CircadianRules.getPhaseName(now),
      timeUntilLock: CircadianRules.timeUntilLock(now),
      phase: state.isActive 
          ? FastingState.determinePhase(duration) 
          : FastingPhase.none,
    );

    // Monitorización por consola para debug técnico
    if (shouldShowPreSleepWarning) {
      // En el futuro esto disparará la notificación push
      debugPrint("📢 ALERTA METABÓLICA: Faltan menos de 3h para dormir. Cerrar ventana.");
    }
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
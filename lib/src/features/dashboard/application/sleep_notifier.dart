import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/features/dashboard/application/fasting_notifier.dart';
import 'package:elena_app/src/features/dashboard/presentation/dashboard_screen.dart';
import 'package:elena_app/src/shared/domain/services/user_repository.dart';
import '../domain/sleep_log.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

class SleepState {
  final SleepLog? lastLog;
  final bool isSleepMode;
  final bool isSaving;
  final bool isWaitingForWakeUp; // Bandera para mostrar el Widget de despertar

  SleepState({
    this.lastLog, 
    this.isSleepMode = false, 
    this.isSaving = false,
    this.isWaitingForWakeUp = false,
  });

  SleepState copyWith({
    SleepLog? lastLog, 
    bool? isSleepMode, 
    bool? isSaving,
    bool? isWaitingForWakeUp,
  }) {
    return SleepState(
      lastLog: lastLog ?? this.lastLog,
      isSleepMode: isSleepMode ?? this.isSleepMode,
      isSaving: isSaving ?? this.isSaving,
      isWaitingForWakeUp: isWaitingForWakeUp ?? this.isWaitingForWakeUp,
    );
  }
}

class SleepNotifier extends StateNotifier<SleepState> {
  final Ref _ref;

  SleepNotifier(this._ref) : super(SleepState());

  void updateSleepConsciousness() {
    final userAsync = _ref.read(currentUserStreamProvider);
    final fastingState = _ref.read(fastingProvider);

    userAsync.whenData((user) {
      if (user == null) return;

      final now = DateTime.now();
      
      // 1. Normalización de horas teóricas
      final sleepTime = DateTime(now.year, now.month, now.day, 
          user.profile.sleepTime.hour, user.profile.sleepTime.minute);
      
      final wakeTime = DateTime(now.year, now.month, now.day, 
          user.profile.wakeUpTime.hour, user.profile.wakeUpTime.minute);

      // 2. Lógica de Ventana de Despertar
      // Si ya pasó la hora de despertar teórica, pero aún no ha confirmado manualmente
      final bool inWakeUpWindow = now.isAfter(wakeTime) && now.isBefore(wakeTime.add(const Duration(hours: 4)));

      final log = SleepLog(
        id: 'sync_${now.year}${now.month}${now.day}',
        fellAsleep: sleepTime, 
        wokeUp: wakeTime,
        lastMealTime: fastingState.startTime ?? sleepTime.subtract(const Duration(hours: 4)),
      );

      final isNight = now.isAfter(sleepTime) || now.isBefore(wakeTime);

      state = state.copyWith(
        lastLog: log, 
        isSleepMode: isNight,
        isWaitingForWakeUp: inWakeUpWindow,
      );
    });
  }

  /// CIERRE DE CICLO MANUAL: Se dispara cuando el usuario oprime "¿Ya despertaste?"
  Future<void> confirmManualWakeUp() async {
    final now = DateTime.now();
    final userAsync = _ref.read(currentUserStreamProvider);
    final repo = _ref.read(userRepositoryProvider);
    
    if (state.lastLog == null) return;

    state = state.copyWith(isSaving: true);
    
    // Sobreescribimos el log con la hora REAL de despertar (ahora mismo)
    final realLog = SleepLog(
      id: state.lastLog!.id,
      fellAsleep: state.lastLog!.fellAsleep,
      wokeUp: now, // <--- Hito real
      lastMealTime: state.lastLog!.lastMealTime,
    );

    final user = userAsync.value;
    if (user != null && user.id.isNotEmpty) {
      try {
        await repo.saveSleepLog(user.id, realLog);
        // Al confirmar, limpiamos la espera de despertar
        state = state.copyWith(
          lastLog: realLog, 
          isWaitingForWakeUp: false,
          isSleepMode: false,
        );
        debugPrint("🚀 Ciclo de sueño cerrado manualmente a las: $now");
      } catch (e) {
        debugPrint("❌ Error al cerrar ciclo: $e");
      }
    }

    state = state.copyWith(isSaving: false);
  }
}

final sleepProvider = StateNotifierProvider<SleepNotifier, SleepState>((ref) {
  return SleepNotifier(ref);
});
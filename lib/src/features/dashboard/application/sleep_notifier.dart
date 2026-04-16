import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/features/dashboard/application/fasting_notifier.dart';
import 'package:elena_app/src/shared/domain/services/user_repository.dart';
import '../domain/sleep_log.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

/// CLASE DE ESTADO (El contrato que el compilador no encontraba)
class SleepState {
  final SleepLog? lastLog;
  final bool isSleepMode;
  final bool isSaving;
  final bool isWaitingForWakeUp;

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
  bool _manualWakeUpConfirmedToday = false;

  SleepNotifier(this._ref) : super(SleepState());

  void updateSleepConsciousness() {
    final userAsync = _ref.read(currentUserStreamProvider);
    final fastingState = _ref.read(fastingProvider);

    userAsync.whenData((user) {
      if (user == null) return;

      final now = DateTime.now();
      
      final sleepTime = DateTime(now.year, now.month, now.day, 
          user.profile.sleepTime.hour, user.profile.sleepTime.minute);
      
      final wakeTime = DateTime(now.year, now.month, now.day, 
          user.profile.wakeUpTime.hour, user.profile.wakeUpTime.minute);

      // Reset de bandera a mediodía para el ciclo siguiente
      if (now.hour == 12) _manualWakeUpConfirmedToday = false;

      // Solo mostramos el overlay si está en rango Y NO ha confirmado manualmente
      final bool inWakeUpWindow = now.isAfter(wakeTime) && 
                                 now.isBefore(wakeTime.add(const Duration(hours: 4))) &&
                                 !_manualWakeUpConfirmedToday;

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

  Future<void> confirmManualWakeUp() async {
    final now = DateTime.now();
    final userAsync = _ref.read(currentUserStreamProvider);
    final repo = _ref.read(userRepositoryProvider);
    
    if (state.lastLog == null || state.isSaving) return;

    state = state.copyWith(isSaving: true);
    
    final realLog = SleepLog(
      id: state.lastLog!.id,
      fellAsleep: state.lastLog!.fellAsleep,
      wokeUp: now,
      lastMealTime: state.lastLog!.lastMealTime,
    );

    final user = userAsync.value;
    if (user != null && user.id.isNotEmpty) {
      try {
        await repo.saveSleepLog(user.id, realLog);
        _manualWakeUpConfirmedToday = true; 

        state = state.copyWith(
          lastLog: realLog, 
          isWaitingForWakeUp: false,
          isSleepMode: false,
          isSaving: false,
        );
        debugPrint("🚀 Ciclo cerrado correctamente.");
      } catch (e) {
        debugPrint("❌ Error al cerrar: $e");
        state = state.copyWith(isSaving: false);
      }
    } else {
       state = state.copyWith(isSaving: false);
    }
  }
}

final sleepProvider = StateNotifierProvider<SleepNotifier, SleepState>((ref) {
  return SleepNotifier(ref);
});
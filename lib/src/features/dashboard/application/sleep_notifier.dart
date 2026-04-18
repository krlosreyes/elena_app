import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/features/dashboard/application/fasting_notifier.dart';
import 'package:elena_app/src/shared/domain/services/user_repository.dart';
import '../domain/sleep_log.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';

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
  StreamSubscription? _sleepSubscription;

  SleepNotifier(this._ref) : super(SleepState()) {
    _init();
  }

  void _init() {
    _ref.listen<AsyncValue<UserModel?>>(currentUserStreamProvider, (previous, next) {
      next.whenData((user) {
        if (user != null) {
          _initSleepSubscription(user.id);
        } else {
          // SPEC-11: Usuario cerró sesión — cancelar suscripción activa y
          // limpiar el estado para que el próximo usuario vea datos en blanco.
          _sleepSubscription?.cancel();
          _sleepSubscription = null;
          _manualWakeUpConfirmedToday = false;
          if (mounted) state = SleepState();
        }
      });
    }, fireImmediately: true);
  }

  void _initSleepSubscription(String userId) {
    _sleepSubscription?.cancel();
    _sleepSubscription = _ref
        .read(userRepositoryProvider)
        .watchLatestSleep(userId)
        .listen((log) {
      if (mounted) {
        state = state.copyWith(lastLog: log);
      }
    });
  }

  @override
  void dispose() {
    _sleepSubscription?.cancel();
    super.dispose();
  }

  void updateSleepConsciousness() {
    final userAsync = _ref.read(currentUserStreamProvider);

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

      final isNight = now.isAfter(sleepTime) || now.isBefore(wakeTime);

      state = state.copyWith(
        // Removido: lastLog: log (ya no hardcodeamos 7h si el usuario no ha registrado)
        isSleepMode: isNight,
        isWaitingForWakeUp: inWakeUpWindow,
      );
    });
  }

  Future<void> confirmManualWakeUp() async {
    final now = DateTime.now();
    final userAsync = _ref.read(currentUserStreamProvider);
    final fastingState = _ref.read(fastingProvider);
    final repo = _ref.read(userRepositoryProvider);
    
    if (state.isSaving) return;

    final user = userAsync.value;
    if (user != null && user.id.isNotEmpty) {
      state = state.copyWith(isSaving: true);

      // Calcular hora de dormir matemáticamente (asumiendo anoche si es de mañana)
      DateTime sleepTimeThisCycle = DateTime(now.year, now.month, now.day, 
            user.profile.sleepTime.hour, user.profile.sleepTime.minute);
      
      if (now.hour < 12 && user.profile.sleepTime.hour > 12) {
        sleepTimeThisCycle = sleepTimeThisCycle.subtract(const Duration(days: 1));
      }

      final realLog = SleepLog(
        id: 'sync_${now.year}${now.month}${now.day}',
        fellAsleep: sleepTimeThisCycle,
        wokeUp: now,
        lastMealTime: fastingState.startTime ?? sleepTimeThisCycle.subtract(const Duration(hours: 4)),
      );

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
    }
  }

  Future<void> saveManualSleep({
    required TimeOfDay bedtime,
    required TimeOfDay wakeTime,
  }) async {
    final now = DateTime.now();
    final userAsync = _ref.read(currentUserStreamProvider);
    final fastingState = _ref.read(fastingProvider);
    final repo = _ref.read(userRepositoryProvider);

    final user = userAsync.value;
    if (user == null || user.id.isEmpty) return;

    state = state.copyWith(isSaving: true);

    try {
      // 1. Construir fechas base (hoy)
      DateTime wakeTimeDt = DateTime(now.year, now.month, now.day, wakeTime.hour, wakeTime.minute);
      DateTime bedtimeDt = DateTime(now.year, now.month, now.day, bedtime.hour, bedtime.minute);

      // 2. Si la hora de dormir es mayor a la de despertar (ej: 23:00 vs 07:00), 
      // asumimos que se acostó el día anterior.
      if (bedtimeDt.isAfter(wakeTimeDt)) {
        bedtimeDt = bedtimeDt.subtract(const Duration(days: 1));
      }

      final realLog = SleepLog(
        id: 'manual_${now.year}${now.month}${now.day}',
        fellAsleep: bedtimeDt,
        wokeUp: wakeTimeDt,
        lastMealTime: fastingState.startTime ?? bedtimeDt.subtract(const Duration(hours: 4)),
      );

      await repo.saveSleepLog(user.id, realLog);
      
      state = state.copyWith(
        lastLog: realLog,
        isSaving: false,
        isWaitingForWakeUp: false,
      );
      
      debugPrint("🌙 Registro manual de sueño guardado: ${realLog.duration.inHours}h");
    } catch (e) {
      debugPrint("❌ Error en saveManualSleep: $e");
      state = state.copyWith(isSaving: false);
      rethrow;
    }
  }
}

final sleepProvider = StateNotifierProvider<SleepNotifier, SleepState>((ref) {
  return SleepNotifier(ref);
});
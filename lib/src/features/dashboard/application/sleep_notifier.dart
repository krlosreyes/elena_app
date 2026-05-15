import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/features/dashboard/application/fasting_notifier.dart';
import 'package:elena_app/src/features/dashboard/data/sleep_repository_impl.dart';
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
    // SPEC-50: consumimos sleepRepositoryProvider en lugar de
    // userRepositoryProvider — Sleep ya no vive en el repo monolítico.
    _sleepSubscription = _ref
        .read(sleepRepositoryProvider)
        .watchLatest(userId)
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

  /// SPEC-58: Reset diario idempotente.
  ///
  /// Limpia los flags efímeros del ciclo wake-up (`_manualWakeUpConfirmedToday`,
  /// `isWaitingForWakeUp`, `isSleepMode`). Conserva `lastLog` porque proviene
  /// de Firestore y representa el último sueño real registrado, sin importar
  /// el día actual.
  void resetDaily() {
    if (!mounted) return;
    _manualWakeUpConfirmedToday = false;
    state = state.copyWith(
      isSleepMode: false,
      isWaitingForWakeUp: false,
    );
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

  /// SPEC-108: id canónico de un registro de sueño por día calendario.
  /// Unificado entre todos los paths (confirmManualWakeUp,
  /// saveManualSleep) para evitar docs duplicados por día.
  String _dayDocId(DateTime t) {
    final m = t.month.toString().padLeft(2, '0');
    final d = t.day.toString().padLeft(2, '0');
    return 'sleep_${t.year}$m$d';
  }

  /// SPEC-108: ¿ya hay un registro de sueño persistido para el día
  /// calendario de `t`? Útil para evitar sobreescritura automática.
  bool _hasLogForDay(DateTime t) {
    final log = state.lastLog;
    if (log == null) return false;
    return log.wokeUp.year == t.year &&
        log.wokeUp.month == t.month &&
        log.wokeUp.day == t.day;
  }

  Future<void> confirmManualWakeUp() async {
    final now = DateTime.now();
    final userAsync = _ref.read(currentUserStreamProvider);
    final fastingState = _ref.read(fastingProvider);
    // SPEC-50: SleepRepository en lugar de UserRepository.
    final repo = _ref.read(sleepRepositoryProvider);

    if (state.isSaving) return;

    // SPEC-108: si el usuario YA registró su sueño de hoy manualmente
    // (con metadata como calidad 1-5), no sobreescribimos con
    // defaults calculados. Solo marcamos el flag interno para que el
    // overlay automático no vuelva a saltar.
    if (_hasLogForDay(now)) {
      _manualWakeUpConfirmedToday = true;
      state = state.copyWith(
        isWaitingForWakeUp: false,
        isSleepMode: false,
      );
      AppLogger.debug(
        'confirmManualWakeUp: ya hay registro manual de hoy, no se sobreescribe',
      );
      return;
    }

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
        // SPEC-108: id unificado por día (antes `sync_*` distinto del
        // que usaba saveManualSleep → docs duplicados).
        id: _dayDocId(now),
        fellAsleep: sleepTimeThisCycle,
        wokeUp: now,
        lastMealTime: fastingState.startTime ?? sleepTimeThisCycle.subtract(const Duration(hours: 4)),
      );

      try {
        await repo.save(user.id, realLog);
        _manualWakeUpConfirmedToday = true;

        state = state.copyWith(
          lastLog: realLog,
          isWaitingForWakeUp: false,
          isSleepMode: false,
          isSaving: false,
        );
        AppLogger.debug('Ciclo de sueño cerrado correctamente.');
      } catch (e, stackTrace) {
        AppLogger.error('Error al cerrar ciclo de sueño', e, stackTrace);
        state = state.copyWith(isSaving: false);
      }
    }
  }

  Future<void> saveManualSleep({
    required TimeOfDay bedtime,
    required TimeOfDay wakeTime,
    // SPEC-71.1: metadata multidimensional opcional. Si el usuario no la
    // provee, los campos quedan null y el SleepQualityCalculator degrada
    // graciosamente usando solo la duración (mismo comportamiento previo).
    int? sleepLatencyMinutes,
    int? nightAwakenings,
    int? subjectiveQuality,
  }) async {
    final now = DateTime.now();
    final userAsync = _ref.read(currentUserStreamProvider);
    final fastingState = _ref.read(fastingProvider);
    // SPEC-50: SleepRepository en lugar de UserRepository.
    final repo = _ref.read(sleepRepositoryProvider);

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
        // SPEC-108: id unificado por día (antes `manual_*` distinto
        // del `sync_*` de confirmManualWakeUp → docs duplicados).
        id: _dayDocId(now),
        fellAsleep: bedtimeDt,
        wokeUp: wakeTimeDt,
        lastMealTime: fastingState.startTime ?? bedtimeDt.subtract(const Duration(hours: 4)),
        sleepLatencyMinutes: sleepLatencyMinutes,
        nightAwakenings: nightAwakenings,
        subjectiveQuality: subjectiveQuality,
      );

      await repo.save(user.id, realLog);

      state = state.copyWith(
        lastLog: realLog,
        isSaving: false,
        isWaitingForWakeUp: false,
      );
      
      AppLogger.debug(
        'Registro manual de sueño guardado: ${realLog.duration.inHours}h',
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error en saveManualSleep', e, stackTrace);
      state = state.copyWith(isSaving: false);
      rethrow;
    }
  }

  /// SPEC-106: elimina el último registro de sueño persistido del
  /// usuario. Usa el id del `state.lastLog` actual. Si no hay log o
  /// ya hay una operación de guardado en curso, no-op.
  ///
  /// Tras el delete, el stream `watchLatest` re-emite y el state se
  /// actualiza con `lastLog: null` (o el siguiente log más reciente
  /// si existiera).
  Future<void> deleteLastLog() async {
    if (state.isSaving) return;
    final lastLog = state.lastLog;
    if (lastLog == null) return;

    final uid = _ref.read(authStateProvider).value?.uid;
    if (uid == null) return;

    state = state.copyWith(isSaving: true);
    try {
      await _ref
          .read(sleepRepositoryProvider)
          .delete(uid, lastLog.id);
      // Optimistic: limpiamos el state local. NO usamos copyWith
      // porque su contrato actual interpreta `null` como "no
      // sobrescribir" (`lastLog ?? this.lastLog`). Construimos uno
      // nuevo con lastLog explícitamente null.
      state = SleepState(
        lastLog: null,
        isSleepMode: state.isSleepMode,
        isSaving: false,
        isWaitingForWakeUp: state.isWaitingForWakeUp,
      );
      AppLogger.debug('Registro de sueño eliminado: ${lastLog.id}');
    } catch (e, stackTrace) {
      AppLogger.error('Error al eliminar registro de sueño', e, stackTrace);
      state = state.copyWith(isSaving: false);
      rethrow;
    }
  }
}

final sleepProvider = StateNotifierProvider<SleepNotifier, SleepState>((ref) {
  return SleepNotifier(ref);
});
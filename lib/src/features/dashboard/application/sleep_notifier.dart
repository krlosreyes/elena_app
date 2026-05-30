import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/core/services/day_boundary_resolver.dart';
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
    _ref.listen<AsyncValue<UserModel?>>(currentUserStreamProvider,
        (previous, next) {
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
    _sleepSubscription =
        _ref.read(sleepRepositoryProvider).watchLatest(userId).listen((log) {
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

  /// SPEC-138: id canónico de un registro de sueño por DÍA DE ATRIBUCIÓN.
  /// El sueño se atribuye al día donde transcurre la mayor parte del intervalo
  /// (punto medio de `[fellAsleep, wokeUp]`), no al día calendario del
  /// despertar. Así un sueño 23:00→00:30 cuenta para el día que la persona
  /// vivió, no para el día nuevo. Unifica confirmManualWakeUp y saveManualSleep
  /// (reemplaza el `_dayDocId` por wokeUp de SPEC-108).
  String _attributionDocId(DateTime fellAsleep, DateTime wokeUp) =>
      'sleep_${DayBoundaryResolver.attributionDayKey(start: fellAsleep, end: wokeUp)}';

  Future<void> confirmManualWakeUp() async {
    final now = DateTime.now();
    final userAsync = _ref.read(currentUserStreamProvider);
    final fastingState = _ref.read(fastingProvider);
    // SPEC-50: SleepRepository en lugar de UserRepository.
    final repo = _ref.read(sleepRepositoryProvider);

    if (state.isSaving) return;

    final user = userAsync.value;
    if (user != null && user.id.isNotEmpty) {
      // SPEC-138: hora de dormir = ocurrencia más reciente de `sleepTime` en o
      // antes de `now`. Si la construida para hoy cae en el futuro respecto a
      // `now`, fue el día anterior. Regla determinista que reemplaza la
      // heurística frágil `now.hour < 12 && sleepTime.hour > 12`.
      DateTime sleepTimeThisCycle = DateTime(now.year, now.month, now.day,
          user.profile.sleepTime.hour, user.profile.sleepTime.minute);
      if (sleepTimeThisCycle.isAfter(now)) {
        sleepTimeThisCycle =
            sleepTimeThisCycle.subtract(const Duration(days: 1));
      }

      final docId = _attributionDocId(sleepTimeThisCycle, now);

      // SPEC-108/138: si ya hay un registro para este MISMO día de atribución,
      // no sobreescribimos con defaults calculados; solo bajamos el overlay.
      if (state.lastLog?.id == docId) {
        _manualWakeUpConfirmedToday = true;
        state = state.copyWith(
          isWaitingForWakeUp: false,
          isSleepMode: false,
        );
        AppLogger.debug(
          'confirmManualWakeUp: ya hay registro de este día, no se sobreescribe',
        );
        return;
      }

      state = state.copyWith(isSaving: true);

      final realLog = SleepLog(
        // SPEC-138: id por día de atribución (punto medio).
        id: docId,
        fellAsleep: sleepTimeThisCycle,
        wokeUp: now,
        lastMealTime: fastingState.startTime ??
            sleepTimeThisCycle.subtract(const Duration(hours: 4)),
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
      DateTime wakeTimeDt = DateTime(
          now.year, now.month, now.day, wakeTime.hour, wakeTime.minute);
      DateTime bedtimeDt =
          DateTime(now.year, now.month, now.day, bedtime.hour, bedtime.minute);

      // 2. Si la hora de dormir es mayor a la de despertar (ej: 23:00 vs 07:00),
      // asumimos que se acostó el día anterior.
      if (bedtimeDt.isAfter(wakeTimeDt)) {
        bedtimeDt = bedtimeDt.subtract(const Duration(days: 1));
      }

      final realLog = SleepLog(
        // SPEC-138: id por día de atribución (punto medio del intervalo),
        // unificado con confirmManualWakeUp.
        id: _attributionDocId(bedtimeDt, wakeTimeDt),
        fellAsleep: bedtimeDt,
        wokeUp: wakeTimeDt,
        lastMealTime: fastingState.startTime ??
            bedtimeDt.subtract(const Duration(hours: 4)),
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
      await _ref.read(sleepRepositoryProvider).delete(uid, lastLog.id);
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

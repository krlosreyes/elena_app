import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/core/analytics/analytics_events.dart';
import 'package:elena_app/src/core/orchestrator/biological_phases.dart';
import 'package:elena_app/src/core/data/app_state_repository.dart';
import 'package:elena_app/src/core/services/analytics_service.dart';
import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/features/coaching/application/coaching_completion_service.dart';
import 'package:elena_app/src/core/services/day_boundary_resolver.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/features/dashboard/application/fasting_notifier.dart';
import 'package:elena_app/src/features/dashboard/data/sleep_repository_impl.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart';
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
  // SPEC-194 (2026-06-06): la confirmación del overlay "¿Ya despertaste?"
  // se persiste en SharedPreferences por (userId, díaCalendárico). Antes
  // era una variable de instancia que se reseteaba a `false` en cada
  // cold start, causando que el overlay reapareciera cada vez que Carlos
  // abría la app. El overlay es UI legítima (SPEC-191 §9), pero debe
  // mostrarse UNA sola vez por día.
  StreamSubscription? _sleepSubscription;

  // 17-jul: bulletproofing del stream de sueño (Carlos: "sueño sigue
  // sin actualizar"). `onDone` re-suscribe, pero Firestore NO garantiza
  // que todo error termine el stream con `onDone` — algunos errores
  // (p.ej. permission-denied transitorio por refresh de token, ver
  // feedback_appcheck_watchsince_bugs) pueden dejar el stream "vivo"
  // para Dart pero mudo para siempre. Este timer reintenta activamente
  // tras un breve delay en vez de depender solo de `onDone`.
  Timer? _reconnectTimer;

  SleepNotifier(this._ref) : super(SleepState()) {
    _init();
  }


  /// Clave por día calendárico para el flag de wake-up.
  /// SPEC-228: persiste en Firestore (users/{uid}/app_state/sleep_wakeup)
  /// para que el overlay "¿Ya despertaste?" se muestre una sola vez por día
  /// en CUALQUIER device del mismo usuario.
  static String _dayKey(DateTime dayAnchor) =>
      DayBoundaryResolver.dayKeyIso(dayAnchor);

  Future<bool> _isWakeUpConfirmedFor(String userId, DateTime dayAnchor) {
    return _ref
        .read(appStateRepositoryProvider)
        .isSleepWakeUpConfirmed(userId, _dayKey(dayAnchor));
  }

  Future<void> _markWakeUpConfirmed(String userId, DateTime dayAnchor) async {
    _ref
        .read(appStateRepositoryProvider)
        .confirmSleepWakeUp(userId, _dayKey(dayAnchor));
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
          _reconnectTimer?.cancel();
          _reconnectTimer = null;
          _sleepSubscription?.cancel();
          _sleepSubscription = null;
          if (mounted) state = SleepState();
        }
      });
    }, fireImmediately: true);
  }

  void _initSleepSubscription(String userId) {
    // 17-jul: cancelar cualquier reintento pendiente antes de re-suscribir
    // — evita que un timer viejo dispare una segunda suscripción duplicada
    // sobre la que estamos por crear acá mismo.
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _sleepSubscription?.cancel();
    // SPEC-50: consumimos sleepRepositoryProvider en lugar de
    // userRepositoryProvider — Sleep ya no vive en el repo monolítico.
    // SPEC-211: onDone re-suscribe tras token refresh / reconexión Firestore.
    _sleepSubscription =
        _ref.read(sleepRepositoryProvider).watchLatest(userId).listen(
      (log) {
        if (mounted) {
          state = state.copyWith(lastLog: log);
        }
      },
      onError: (Object e) {
        AppLogger.warning('[SleepNotifier] stream error (transitorio): $e');
        // 17-jul (bulletproofing, Carlos: "sueño sigue sin actualizar"):
        // antes solo se logueaba acá. `onDone` re-suscribe, pero
        // Firestore NO garantiza que todo error dispare `onDone` — si
        // no lo dispara, el stream queda "vivo" en Dart pero mudo para
        // siempre y el pilar deja de reflejar registros nuevos hasta
        // reiniciar la app. Reintentamos activamente con un pequeño
        // delay (evita martillar Firestore en loop si el error es
        // persistente, p.ej. permission-denied real).
        _scheduleReconnect(userId);
      },
      onDone: () {
        if (mounted) _initSleepSubscription(userId);
      },
    );
  }

  /// 17-jul: reintento de suscripción tras un error del stream. Delay
  /// fijo de 5s — suficiente para que un token de auth en refresh
  /// transitorio se resuelva, sin ser tan agresivo como para saturar
  /// Firestore si el error persiste (en ese caso, cada reintento vuelve
  /// a fallar y a reprogramarse, con el mismo delay entre intentos).
  void _scheduleReconnect(String userId) {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) _initSleepSubscription(userId);
    });
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _sleepSubscription?.cancel();
    super.dispose();
  }

  /// SPEC-58 + SPEC-194: Reset diario idempotente.
  ///
  /// Limpia los flags efímeros del ciclo wake-up (`isWaitingForWakeUp`,
  /// `isSleepMode`). Conserva `lastLog` porque proviene de Firestore y
  /// representa el último sueño real registrado, sin importar el día
  /// actual. La flag persistida `wake_up_confirmed_<userId>_<dia>` NO se
  /// borra acá: la clave incluye el día, así que el día nuevo ya tiene
  /// su propia ranura.
  void resetDaily() {
    if (!mounted) return;
    state = state.copyWith(
      isSleepMode: false,
      isWaitingForWakeUp: false,
    );
  }

  // SPEC-228: método async porque el flag de wake-up ahora se lee
  // desde Firestore (cache-first). Los callers usan unawaited.
  Future<void> updateSleepConsciousness() async {
    final userAsync = _ref.read(currentUserStreamProvider);

    // NOTA: whenData() no retorna Future real; el await no espera el
    // callback interno (bug pre-existente, ver auditoría).
    userAsync.whenData((user) async {
      if (user == null) return;

      final now = DateTime.now();

      // SPEC-191: USO LEGÍTIMO — overlay informativo. `sleepTime` y
      // `wakeUpTime` se usan SOLO para decidir si mostrar el overlay
      // "buenos días / hora de dormir" según la configuración del
      // usuario. NO definen el día metabólico (eso lo hace el ciclo).
      // Ver METABOLIC_DAY_CONSTITUTION.md §9 — Test ácido.
      final sleepTime = DateTime(now.year, now.month, now.day,
          user.profile.sleepTime.hour, user.profile.sleepTime.minute);

      final wakeTime = DateTime(now.year, now.month, now.day,
          user.profile.wakeUpTime.hour, user.profile.wakeUpTime.minute);

      // SPEC-228: el flag de wake-up se lee desde Firestore (cache-first)
      // para que sea cross-device. La latencia es mínima por el cache local
      // de Firestore SDK.
      final wakeAlreadyConfirmed =
          await _isWakeUpConfirmedFor(user.id, now);

      if (!mounted) return;

      // Solo mostramos el overlay si está en rango Y NO ha confirmado.
      final bool inWakeUpWindow = now.isAfter(wakeTime) &&
          now.isBefore(wakeTime.add(const Duration(hours: 4))) &&
          !wakeAlreadyConfirmed;

      final isNight = now.isAfter(sleepTime) || now.isBefore(wakeTime);

      state = state.copyWith(
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

  /// SPEC-234: acepta [subjectiveQuality] (1-5) opcional del overlay
  /// "¿Cómo dormiste?". Si se provee, se persiste en el SleepLog.
  Future<void> confirmManualWakeUp({int? subjectiveQuality}) async {
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
      //
      // SPEC-191: USO LEGÍTIMO — fallback heurístico para inferir
      // `fellAsleep` cuando el usuario hace "manual wake up" sin haber
      // registrado su hora de dormida real. NO define el día metabólico;
      // solo arma el SleepLog con la mejor estimación posible.
      // Ver METABOLIC_DAY_CONSTITUTION.md §9 — Test ácido.
      DateTime sleepTimeThisCycle = DateTime(now.year, now.month, now.day,
          user.profile.sleepTime.hour, user.profile.sleepTime.minute);
      if (sleepTimeThisCycle.isAfter(now)) {
        sleepTimeThisCycle =
            sleepTimeThisCycle.subtract(const Duration(days: 1));
      }

      final docId = _attributionDocId(sleepTimeThisCycle, now);

      // SPEC-231 BUG-B: guard ampliado. Antes solo comparaba docId exacto,
      // pero los logs de HealthKit usan `hk_sleep_*` y Samsung Health usa
      // `sh_sleep_*`, así que el guard nunca matcheaba → se creaba un
      // duplicado manual que sobreescribía datos precisos del wearable.
      //
      // Ahora: si el lastLog tiene `wokeUp` en el mismo día calendárico
      // que `now`, ya hay un registro válido para esta noche — no crear
      // otro. El guard por docId exacto se mantiene como OR para el caso
      // donde el sleep se atribuye a un día diferente (punto medio).
      final lastLog = state.lastLog;
      if (lastLog != null) {
        final sameDocId = lastLog.id == docId;
        final lastWokeLocal = lastLog.wokeUp.toLocal();
        final nowLocal = now.toLocal();
        final sameCalendarDay = lastWokeLocal.year == nowLocal.year &&
            lastWokeLocal.month == nowLocal.month &&
            lastWokeLocal.day == nowLocal.day;
        if (sameDocId || sameCalendarDay) {
          // SPEC-194: persistir la confirmación por (user, día calendárico).
          await _markWakeUpConfirmed(user.id, now);
          state = state.copyWith(
            isWaitingForWakeUp: false,
            isSleepMode: false,
          );
          AppLogger.debug(
            'confirmManualWakeUp: ya hay registro para hoy '
            '(id=${lastLog.id}, sameDoc=$sameDocId, sameCal=$sameCalendarDay), '
            'no se sobreescribe',
          );
          return;
        }
      }

      final realLog = SleepLog(
        // SPEC-138: id por día de atribución (punto medio).
        id: docId,
        fellAsleep: sleepTimeThisCycle,
        wokeUp: now,
        lastMealTime: fastingState.startTime ??
            sleepTimeThisCycle.subtract(const Duration(hours: 4)),
        // SPEC-234: calidad subjetiva del overlay "¿Cómo dormiste?"
        subjectiveQuality: subjectiveQuality,
      );

      // SPEC-206 (offline-first): la UI lee `state.lastLog`, así que el cierre
      // del sueño se refleja al instante y los writes van a la caché (sync al
      // reconectar). Antes el `await` colgaba offline → sueño nunca cerraba.
      state = state.copyWith(
        lastLog: realLog,
        isWaitingForWakeUp: false,
        isSleepMode: false,
        isSaving: false,
      );
      // SPEC-193/194: analytics (se auto-encola sin red) + coaching.
      AnalyticsService.logEvent(
        AnalyticsEvents.pillarLogged,
        params: const {AnalyticsParams.pillar: 'sleep'},
      );
      _ref.read(coachingCompletionProvider).onPillarActivity(Pillar.sleep);
      unawaited(repo.save(user.id, realLog).catchError((Object e) {
        AppLogger.error('Persistencia de sueño falló (reintenta al sync)', e);
      }));
      // SPEC-194: persistir confirmación por (user, día calendárico).
      unawaited(_markWakeUpConfirmed(user.id, now));
      AppLogger.debug('Ciclo de sueño cerrado (optimista).');
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

      // SPEC-206 (offline-first): registro optimista (la UI lee state.lastLog)
      // + writes no bloqueantes. Antes el `await` colgaba offline.
      state = state.copyWith(
        lastLog: realLog,
        isSaving: false,
        isWaitingForWakeUp: false,
      );
      // SPEC-193/194: analytics (se auto-encola sin red) + coaching.
      AnalyticsService.logEvent(
        AnalyticsEvents.pillarLogged,
        params: const {AnalyticsParams.pillar: 'sleep'},
      );
      _ref.read(coachingCompletionProvider).onPillarActivity(Pillar.sleep);
      unawaited(repo.save(user.id, realLog).catchError((Object e) {
        AppLogger.error('Persistencia de sueño falló (reintenta al sync)', e);
      }));
      // SPEC-194: registrar sueño manualmente también baja el overlay.
      unawaited(_markWakeUpConfirmed(user.id, now));

      AppLogger.debug(
        'Registro manual de sueño guardado: ${realLog.duration.inHours}h',
      );
    } catch (e, stackTrace) {
      // Errores SÍNCRONOS (construcción de fechas/log). El write ya no lanza.
      AppLogger.error('Error en saveManualSleep', e, stackTrace);
      rethrow;
    } finally {
      // SPEC-216: garantizar que isSaving vuelve a false incluso en paths
      // no capturados por el catch (excepciones futuras, early return, etc.).
      // En el happy path ya se puso a false en el copyWith de arriba;
      // el guard evita el doble setState innecesario.
      if (mounted && state.isSaving) {
        state = state.copyWith(isSaving: false);
      }
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

    // SPEC-206 (offline-first): borrado optimista del state local + delete no
    // bloqueante. NO usamos copyWith porque su contrato interpreta `null` como
    // "no sobrescribir"; construimos uno nuevo con lastLog explícitamente null.
    state = SleepState(
      lastLog: null,
      isSleepMode: state.isSleepMode,
      isSaving: false,
      isWaitingForWakeUp: state.isWaitingForWakeUp,
    );
    unawaited(
      _ref.read(sleepRepositoryProvider).delete(uid, lastLog.id).then((_) {
        AppLogger.debug('Registro de sueño eliminado: ${lastLog.id}');
      }).catchError((Object e) {
        AppLogger.error('Borrado de sueño falló (reintenta al sincronizar)', e);
      }),
    );
  }
}

final sleepProvider = StateNotifierProvider<SleepNotifier, SleepState>((ref) {
  return SleepNotifier(ref);
});

// ────────────────────────────────────────────────────────────────────────
// SPEC-175 (2026-06-04): provider derivado cycle-aware del sueño.
//
// Sleep es un dato ÚNICO por noche, no múltiple como exercise/hydration/
// nutrition (donde los notifiers se re-suscriben a `watchSince(cycle.startedAt)`).
// El `SleepNotifier` mantiene `state.lastLog` como el último sleep
// histórico (necesario para detectar duplicados en `confirmManualWakeUp`),
// y este provider derivado expone el `SleepLog?` que pertenece al ciclo
// abierto — null cuando el sleep es de un ciclo anterior.
//
// SPEC-188 v2 (2026-06-05, Carlos): el día metabólico es 100% event-
// driven. CERO referencia al reloj. El sleep pertenece al ciclo
// metabólico si y solo si `wokeUp >= cycle.startedAt`.
//
// Sin gracia previa, sin ventana de 18h, sin reloj. El sleep que
// ocurrió ANTES del inicio del ciclo pertenece al ciclo previo (ya
// cerrado) — el feedback de ese ciclo cerrado lo refleja. El ciclo
// nuevo arranca limpio.
//
// Modelo canon (METABOLIC_DAY_CONSTITUTION.md §1):
//   - Inicio del día metabólico = tap "iniciar ayuno" (startFastingManual)
//   - Fin del día metabólico = fin de ventana de alimentación → inicia
//     nuevo ayuno → nuevo día
//   - Nada más. Ni medianoche, ni startOfDay, ni wakeUpTime, ni gracia.
// ────────────────────────────────────────────────────────────────────────

/// SPEC-175 §RF-175-01: SleepLog del ciclo metabólico abierto. Null si
/// no hay sleep o el sleep no pertenece al ciclo abierto.
///
/// SPEC-188 v2 + SPEC-194.1 (2026-06-06): regla canónica
/// `wokeUp >= cycle.startedAt` cuando HAY ciclo abierto. Cuando NO hay
/// ciclo, fallback al sleep cuyo `wokeUp >= startOfDay(now)` para que
/// el ring no quede en 0 con un registro real del día.
///
/// El fallback se activa SOLO en el caso edge "sin ciclo abierto"
/// (primer uso, post-cierre antes del siguiente ayuno, desync). Cuando
/// el usuario abre su próximo ayuno, el provider re-evalúa con la
/// ventana del ciclo nuevo automáticamente y el sleep volverá a 0 si
/// no pertenece al nuevo ciclo (comportamiento canónico).
///
/// SPEC-245 (2026-07-07): si el ciclo abrió HOY después de que el
/// usuario ya durmió (p.ej., inició ayuno a las 10am y despertó a las
/// 7am), el anchor del ciclo quedaría posterior al wakeUp →
/// `belongs = false` → anillo en 0 a pesar de tener sueño real del día.
/// Fix: usar `max(cycle.startedAt, startOfDay(now))` como effectiveAnchor.
/// Cualquier sueño de HOY siempre se atribuye al ciclo abierto del mismo
/// día, sin importar la hora de inicio del ayuno.
///
/// BUG-02 (2026-07-13, Carlos: "al terminar el día metabólico el
/// anillo de sueño no se resetea a cero"): el relajamiento de SPEC-245
/// no distinguía "primer ciclo del día" de "segundo ciclo del mismo
/// día calendárico" (usuario cierra un ciclo y abre otro más tarde,
/// mismo día). En ambos casos `cycle.startedAt.isAfter(todayStart)` es
/// true, así que el mismo retroceso a medianoche se aplicaba también
/// al ciclo nuevo — colando el sleep de esta madrugada, que ya
/// pertenecía al ciclo recién cerrado, hacia el ciclo que se acaba de
/// abrir. Fix: el relajamiento SOLO aplica si este es el primer ciclo
/// abierto hoy — si `lastClosedMetabolicCycleProvider` ya cerró un
/// ciclo hoy, ese ciclo ya "reclamó" el sueño de esta noche y el
/// nuevo arranca limpio con la regla estricta canónica de SPEC-188 v2
/// (`wokeUp >= cycle.startedAt`), sin importar si eso da 0.
final currentCycleSleepProvider = Provider<SleepLog?>((ref) {
  final sleep = ref.watch(sleepProvider);
  if (sleep.lastLog == null) {
    // 17-jul (diagnóstico, Carlos: "el anillo muestra cero"): log para
    // distinguir en producción "no hay dato en absoluto" (este caso) de
    // "hay dato pero belongs=false" (log de abajo). Sin esto, ambos
    // casos son indistinguibles desde afuera — los dos producen 0 en
    // el anillo pero la causa y el fix son completamente distintos.
    AppLogger.debug(
      '[currentCycleSleepProvider] sleep.lastLog es null — SleepNotifier '
      'todavía no tiene ningún registro (stream sin datos o sin '
      'resolver aún).',
    );
    return null;
  }

  final cycle = ref.watch(currentMetabolicCycleProvider).valueOrNull;
  final todayStart = DayBoundaryResolver.startOfDay(DateTime.now());
  final anchor = cycle?.startedAt ?? todayStart;

  // BUG-02: si ya hubo un ciclo cerrado HOY, este no es el primer
  // ciclo del día — no se relaja el anchor, el sleep de esta noche
  // pertenece al ciclo cerrado, no al que se acaba de abrir.
  final lastClosed = ref.watch(lastClosedMetabolicCycleProvider).valueOrNull;
  final hasClosedCycleToday = lastClosed?.closedAt != null &&
      !lastClosed!.closedAt!.isBefore(todayStart);

  // SPEC-245: si hay ciclo, es el primero de hoy, y su startedAt es
  // posterior al inicio del día local, no penalizamos sueño que sí
  // ocurrió hoy antes de que el ciclo empezara (típico en ayunos que
  // inician tarde en el día).
  final effectiveAnchor =
      (cycle != null && anchor.isAfter(todayStart) && !hasClosedCycleToday)
          ? todayStart
          : anchor;

  final wokeUp = sleep.lastLog!.wokeUp;
  final belongs = !wokeUp.isBefore(effectiveAnchor);
  // 17-jul (diagnóstico): visibilidad completa de la decisión — la
  // próxima vez que el anillo muestre algo inesperado, este log dice
  // exactamente qué dato había y por qué se aceptó/rechazó, sin tener
  // que reproducir el bug a ciegas otra vez.
  AppLogger.debug(
    '[currentCycleSleepProvider] lastLog.id=${sleep.lastLog!.id} '
    'wokeUp=$wokeUp cycleId=${cycle?.cycleId} '
    'cycleStartedAt=${cycle?.startedAt} todayStart=$todayStart '
    'hasClosedCycleToday=$hasClosedCycleToday '
    'effectiveAnchor=$effectiveAnchor belongs=$belongs',
  );
  return belongs ? sleep.lastLog : null;
});

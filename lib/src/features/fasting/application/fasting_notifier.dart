import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/core/analytics/analytics_events.dart';
// SPEC-194: solo `Pillar` — `biological_phases` también define `FastingPhase`,
// que aquí viene de `fasting_status` (evita ambiguous_import).
import 'package:elena_app/src/core/orchestrator/biological_phases.dart'
    show Pillar;
import 'package:elena_app/src/core/providers/ticker_providers.dart';
import 'package:elena_app/src/core/rules/circadian_rules.dart';
import 'package:elena_app/src/core/services/analytics_service.dart';
import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/features/coaching/application/coaching_completion_service.dart';
import 'package:elena_app/src/core/services/firestore_errors.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/features/fasting/data/fasting_interval_repository_impl.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/core/services/live_activity_service.dart';
import 'package:elena_app/src/core/services/notification_router.dart';
import 'package:elena_app/src/core/services/notification_service.dart';
import 'package:elena_app/src/core/services/notification_scheduler.dart';
import '../domain/fasting_status.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

// SPEC-50.4: stream del último intervalo desde FastingIntervalRepository
// (antes: userRepository.watchLastInterval).
// SPEC-73: authState ahora es AppAccount?, uid en `.uid`.
final lastFastingIntervalProvider = StreamProvider<FastingInterval?>((ref) {
  final repo = ref.watch(fastingIntervalRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  final uid = authState.value?.uid;

  if (uid == null) return Stream.value(null);
  return repo.watchLatest(uid);
});

/// SPEC-113.bugfix: stream del último ayuno CERRADO (endTime != null).
/// Permite al FastingNotifier detectar si el usuario completó un ayuno
/// HOY y mantener `completedToday=true` aunque ya esté en ventana de
/// alimentación (o haya reiniciado la app después de cerrar el ayuno).
final lastCompletedFastingProvider = StreamProvider<FastingInterval?>((ref) {
  final repo = ref.watch(fastingIntervalRepositoryProvider);
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value(null);
  return repo.watchLastCompletedFasting(uid);
});

class FastingNotifier extends StateNotifier<FastingState> {
  final Ref _ref;
  bool _fastingEndConfirmedToday = false;

  /// SPEC-235: tracking del último minuto actualizado en Live Activity
  /// para no enviar updates redundantes (tick es cada segundo).
  int _lastLiveActivityMinute = -1;

  FastingNotifier(this._ref) : super(FastingState.initial()) {
    _init();
  }

  void _init() {
    // FIRE-06 (cerrado 22-jul): la migración one-shot flat fasting_history
    // → subcolección (SPEC-222) se retiró de acá. La colección plana ya
    // se confirmó vacía y se borró en Firestore — ver
    // Addendum_Auditoria_ElenaApp_2026-07-22.docx §2 y
    // functions/scripts/verify_fasting_history_migration.js.
    _ref.listen(currentUserStreamProvider, (previous, next) {
      final user = next.value;
      if (user != null && state.fastingProtocol != user.fastingProtocol) {
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
              activationSource: FastingActivationSource.none,
            );
          } else {
            final now = DateTime.now();
            final duration = now.difference(interval.startTime);

            // SPEC-183: marcar bootstrap al restaurar desde Firestore.
            //
            // SPEC-187 (2026-06-05): PERO si el state YA tiene
            // `userInitiated` (porque `startFastingManual` hizo el
            // update optimista hace milisegundos), respetar esa marca.
            // Sin este guard, el listener sobreescribía `userInitiated`
            // con `bootstrap` durante el await del Firestore write,
            // bloqueando el cierre del ciclo previo cuando el usuario
            // iniciaba un nuevo ayuno.
            final isUserInitiatedAlreadySet = interval.isFasting &&
                state.activationSource == FastingActivationSource.userInitiated;
            state = state.copyWith(
              startTime: interval.startTime,
              isActive: interval.isFasting,
              duration: duration,
              phase: interval.isFasting
                  ? FastingState.determinePhase(duration)
                  : FastingPhase.none,
              activationSource: isUserInitiatedAlreadySet
                  ? FastingActivationSource.userInitiated
                  : (interval.isFasting
                      ? FastingActivationSource.bootstrap
                      : FastingActivationSource.none),
            );
          }
        },
        loading: () =>
            AppLogger.debug('Sincronizando coordenadas metabólicas...'),
        error: (err, stack) {
          // SPEC-107: durante logout los listeners reciben un
          // permission-denied final antes de cancelarse. No es un
          // error real — solo ruido. Degradamos a debug.
          if (FirestoreErrors.isPermissionDenied(err)) {
            AppLogger.debug(
              '[FastingNotifier] Stream cerrado tras logout: $err',
            );
          } else {
            AppLogger.warning('Error en historial', err);
          }
        },
      );
    }, fireImmediately: true);

    // SPEC-61: el ticker de 1s interno fue eliminado. Ahora consumimos el
    // pulso central (metabolicPulseProvider, cada 10s) que ya alimenta a
    // metabolicStateProvider y al resto del core. Esto reduce los rebuilds
    // de cualquier widget suscrito a fastingProvider de 60/min a 6/min.
    //
    // El display HH:MM:SS visible al usuario corre en el widget
    // LiveFastingClock con su propio Timer local; no muta fastingProvider.
    _ref.listen(metabolicPulseProvider, (previous, next) {
      if (next.value != null) _tick();
    });

    // SPEC-113.bugfix: al cargar el último ayuno completado desde BD,
    // determinar si fue HOY y si alcanzó target → restaurar
    // `completedToday=true`. Sin esto, reiniciar la app después de
    // cerrar un ayuno hace que el satélite vuelva a 0%.
    _ref.listen(lastCompletedFastingProvider, (previous, next) {
      final interval = next.value;
      if (interval == null || interval.endTime == null) return;
      final endTime = interval.endTime!;
      final now = DateTime.now();
      final isToday = endTime.year == now.year &&
          endTime.month == now.month &&
          endTime.day == now.day;
      if (!isToday) return;
      final durationSec = endTime.difference(interval.startTime).inSeconds;
      final reachedTarget = durationSec >= state.targetHours * 3600;
      if (reachedTarget && state.completedToday != true) {
        state = state.copyWith(completedToday: true);
      }
      // Fix anillo (2026-06-09): restaurar el % logrado de un ayuno
      // cerrado HOY (incl. cierre temprano) para que el anillo no
      // vuelva a 0 al reabrir la app. Solo aplica si no hay ayuno
      // activo en curso (no pisar el progreso en vivo).
      if (!state.isActive && state.targetHours > 0) {
        final achieved =
            (durationSec / (state.targetHours * 3600)).clamp(0.0, 1.0);
        if (state.closedProgressToday != achieved) {
          state = state.copyWith(closedProgressToday: achieved);
        }
      }
    }, fireImmediately: true);
  }

  /// INICIO MANUAL (Viaje en el tiempo para pruebas)
  Future<void> startFastingManual(DateTime startTime) async {
    final uid = _ref.read(authStateProvider).value?.uid;
    if (uid == null) return;

    // SPEC-187 (2026-06-05): UPDATE OPTIMISTA ANTES de transitionTo.
    //
    // El listener al `lastFastingIntervalProvider` recibe el snapshot
    // de Firestore DURANTE el `await` y, si el state aún tiene
    // `isActive: false`, marca la transición como `bootstrap`,
    // bloqueando el cierre del ciclo previo (bug observado 2026-06-05).
    //
    // Al setear `isActive: true` + `activationSource: userInitiated`
    // ANTES de tocar Firestore, ocurren dos cosas:
    //   1. El evaluator detecta la transición false→true CON
    //      `userInitiated` → dispara cierre del ciclo previo + apertura
    //      del nuevo + reset de pilares + CycleFeedback. ✓
    //   2. Cuando el listener emite (con el state ya en isActive=true),
    //      NO hay transición nueva y preserva `userInitiated` gracias
    //      al guard del listener (SPEC-187 segunda parte).
    final now = DateTime.now();
    final duration = now.difference(startTime);
    // SPEC-206 (offline-first): NO bloqueamos en isSaving. El write entra a la
    // caché local al instante → el listener `lastFastingIntervalProvider`
    // dispara la transición de ciclo (cierre+apertura) aunque no haya red.
    // Antes, el `await` del write colgaba offline y dejaba isSaving en true.
    state = state.copyWith(
      isSaving: false,
      startTime: startTime,
      isActive: true,
      duration: duration,
      phase: FastingState.determinePhase(duration),
      activationSource: FastingActivationSource.userInitiated,
      // Bugfix 2026-06-11: un ayuno NUEVO arranca con progreso limpio. Sin
      // esto, los flags del ayuno anterior (`completedToday`/`closedProgressToday`)
      // dejaban el anillo del pilar pegado en 100% al iniciar el siguiente.
      completedToday: false,
      closedProgressToday: 0.0,
    );
    _fastingEndConfirmedToday = false;

    // SPEC-50.4: FastingIntervalRepository (no UserRepository).
    final repo = _ref.read(fastingIntervalRepositoryProvider);

    // SPEC-05: hitos de ayuno (12h/18h/24h). Local (flutter_local_notifications)
    // → corre con o sin red, de inmediato.
    unawaited(NotificationScheduler.scheduleFastingMilestones(startTime));

    // SPEC-235: Live Activity en Isla Dinámica (iOS) / ongoing notif (Android).
    unawaited(LiveActivityService.start(
      startedAt: startTime,
      protocol: state.fastingProtocol,
      targetHours: state.targetHours,
    ));

    // Consciencia ayuno↔alimentación: al entrar en ayuno, cancelar toda
    // notificación que invite a comer (firstMeal, lastMealWarning,
    // nextMealReady, eTRFPreSleep). Sin esto, el usuario en pleno ayuno
    // recibe "Tu ventana abrió" o "Tu próxima comida es a las HH:MM".
    unawaited(NotificationService.cancelFeeding());

    // Write no bloqueante (offline-first). Efectos que requieren red (analytics,
    // coaching) van en el ack del servidor; un error REAL revierte el inicio.
    unawaited(
      repo
          .transitionTo(userId: uid, isFasting: true, startTime: startTime)
          .then((_) {
        AnalyticsService.logEvent(
          AnalyticsEvents.fastingStarted,
          params: {AnalyticsParams.protocol: state.fastingProtocol},
        );
        _ref.read(coachingCompletionProvider).onPillarActivity(Pillar.fasting);
      }).catchError((Object e) {
        // SPEC-187: rollback solo ante error REAL (no el offline pendiente).
        if (!mounted) return;
        state = state.copyWith(
          isActive: false,
          startTime: null,
          duration: Duration.zero,
          phase: FastingPhase.none,
          activationSource: FastingActivationSource.none,
        );
        AppLogger.warning('startFastingManual falló, rollback aplicado: $e', e);
      }),
    );

    AppLogger.debug(
      'Ayuno iniciado manualmente a las $startTime '
      '(Duración inicial: ${duration.inHours}h)',
    );
  }

  Future<void> startFasting() async {
    await startFastingManual(DateTime.now());
  }

  /// SPEC-97: corrige la hora de inicio del intervalo de ayuno activo
  /// sin cerrarlo. Caso de uso: "Empecé mi ayuno a las 18:00 pero
  /// abrí la app a las 19:00 y le dí Iniciar".
  ///
  /// Precondiciones:
  ///   - `state.isActive == true`
  ///   - `newStart < now` (no se acepta hora futura)
  ///   - `newStart > now - 24h` (límite sano)
  ///
  /// Si alguna falla, no-op silencioso. El caller (UI) ya validó.
  /// Si la corrección es exitosa, reagenda los hitos de notification
  /// (12h, 18h, 24h) desde el nuevo `startTime`.
  Future<void> correctFastingStartTime(DateTime newStart) async {
    if (!state.isActive) return;
    final uid = _ref.read(authStateProvider).value?.uid;
    if (uid == null) return;

    final now = DateTime.now();
    if (newStart.isAfter(now)) return;
    if (now.difference(newStart).inHours > 24) return;

    final repo = _ref.read(fastingIntervalRepositoryProvider);
    final newDuration = now.difference(newStart);

    // SPEC-206 (offline-first): corrección optimista + write no bloqueante.
    state = state.copyWith(
      isSaving: false,
      startTime: newStart,
      duration: newDuration,
      phase: FastingState.determinePhase(newDuration),
    );

    // Reagendar hitos desde el nuevo startTime (local, inmediato).
    unawaited(NotificationScheduler.scheduleFastingMilestones(newStart));

    // SPEC-100: filtrar por isFasting=true para no pisar ventanas fantasma.
    unawaited(
      repo
          .correctOpenIntervalStartTime(
            userId: uid,
            newStartTime: newStart,
            isFastingFilter: true,
          )
          .then((_) =>
              AppLogger.debug('Hora de inicio del ayuno corregida a $newStart '
                  '(nueva duración: ${newDuration.inMinutes}min).'))
          .catchError((Object e) {
        AppLogger.error('No se pudo corregir la hora de inicio (reintenta)', e);
      }),
    );

    // SPEC-260 (2026-07-30): re-anclar el Día Metabólico a la hora
    // corregida SIN resetear pilares. El ancla del ciclo ES el inicio del
    // ayuno; corregir la hora debe moverla, pero corregir NO es cerrar+
    // abrir, así que no pasa por `triggerDailyReset` — hidratación,
    // nutrición, ejercicio y sueño quedan intactos. Ver
    // reanchorOpenCycle() en MetabolicCycleService.
    unawaited(
      _ref
          .read(metabolicCycleServiceProvider)
          .reanchorOpenCycle(
            userId: uid,
            newStartedAt: newStart,
            protocol: state.fastingProtocol,
            tzOffsetMinutes: DateTime.now().timeZoneOffset.inMinutes,
          )
          .catchError((Object e) {
        AppLogger.warning(
          '[fasting.correctStart] reanchor del ciclo falló (reintenta al '
          'sincronizar): $e',
        );
        return null;
      }),
    );
  }

  /// SPEC-260 (2026-07-30): registra un ayuno que YA venía en curso,
  /// eligiendo su hora real de inicio ("empecé anoche a las 21:15 pero lo
  /// registro al despertar").
  ///
  /// A diferencia de `startFastingManual`, este método NO marca la
  /// activación como `userInitiated`, así que el evaluador del ciclo NO
  /// cierra el ciclo previo ni dispara `triggerDailyReset`. En su lugar
  /// ancla el Día Metabólico a [start] directamente vía
  /// `reanchorOpenCycle`, preservando el avance de los otros 4 pilares.
  /// Este es el corazón del fix: registrar un ayuno olvidado sin perder
  /// el progreso del día.
  ///
  /// Si YA hay un ayuno activo, delega en `correctFastingStartTime` (es
  /// una corrección, no un alta).
  ///
  /// Precondiciones (validadas también en la UI):
  ///   - `start < now` (no se acepta hora futura)
  ///   - `start > now - 24h` (límite sano)
  Future<void> registerOngoingFast(DateTime start) async {
    if (state.isActive) {
      await correctFastingStartTime(start);
      return;
    }

    final uid = _ref.read(authStateProvider).value?.uid;
    if (uid == null) return;

    final now = DateTime.now();
    if (start.isAfter(now)) return;
    if (now.difference(start).inHours > 24) return;

    final duration = now.difference(start);

    // Update optimista. `ongoingRegistration` (NO `userInitiated`) evita
    // que el evaluador dispare cierre+apertura+reset. El anclado del ciclo
    // lo hacemos explícitamente más abajo.
    state = state.copyWith(
      isSaving: false,
      startTime: start,
      isActive: true,
      duration: duration,
      phase: FastingState.determinePhase(duration),
      activationSource: FastingActivationSource.ongoingRegistration,
      completedToday: false,
      closedProgressToday: 0.0,
    );
    _fastingEndConfirmedToday = false;

    final repo = _ref.read(fastingIntervalRepositoryProvider);

    unawaited(NotificationScheduler.scheduleFastingMilestones(start));
    unawaited(LiveActivityService.start(
      startedAt: start,
      protocol: state.fastingProtocol,
      targetHours: state.targetHours,
    ));
    unawaited(NotificationService.cancelFeeding());

    // Persistir el intervalo (offline-first). Rollback solo ante error REAL.
    unawaited(
      repo
          .transitionTo(userId: uid, isFasting: true, startTime: start)
          .then((_) {
        AnalyticsService.logEvent(
          AnalyticsEvents.fastingStarted,
          params: {AnalyticsParams.protocol: state.fastingProtocol},
        );
        _ref.read(coachingCompletionProvider).onPillarActivity(Pillar.fasting);
      }).catchError((Object e) {
        if (!mounted) return;
        state = state.copyWith(
          isActive: false,
          startTime: null,
          duration: Duration.zero,
          phase: FastingPhase.none,
          activationSource: FastingActivationSource.none,
        );
        AppLogger.warning(
            'registerOngoingFast falló, rollback aplicado: $e', e);
      }),
    );

    // Anclar el Día Metabólico a la hora registrada SIN reset. Si hay un
    // ciclo abierto (p.ej. el del día previo aún sin cerrar), se re-ancla
    // a [start]; si no hay ninguno, se abre uno retroactivo. En ambos
    // casos NO hay cierre → NO hay `triggerDailyReset` → pilares intactos.
    unawaited(
      _ref
          .read(metabolicCycleServiceProvider)
          .reanchorOpenCycle(
            userId: uid,
            newStartedAt: start,
            protocol: state.fastingProtocol,
            tzOffsetMinutes: now.timeZoneOffset.inMinutes,
          )
          .catchError((Object e) {
        AppLogger.warning(
          '[fasting.registerOngoing] anclado del ciclo falló (reintenta al '
          'sincronizar): $e',
        );
        return null;
      }),
    );

    AppLogger.info(
      'Ayuno en curso registrado con inicio en $start '
      '(duración inicial: ${duration.inHours}h). Sin reset de pilares.',
    );
  }

  /// CIERRE MANUAL (Viaje en el tiempo para pruebas)
  Future<void> confirmManualFastingEnd(DateTime manualTime) async {
    final uid = _ref.read(authStateProvider).value?.uid;
    if (uid == null || state.isSaving) return;

    // SPEC-206 (offline-first): el cierre se refleja en la UI al instante y el
    // write va a la caché local (dispara la transición de ciclo). Antes, el
    // `await` de persistencia colgaba offline y el ayuno nunca aparecía cerrado.
    final repo = _ref.read(fastingIntervalRepositoryProvider);

    // SPEC-113.bugfix: la duración del AYUNO es (manualTime - state.startTime),
    // NO (now - manualTime).
    final fastingStartTime = state.startTime;
    final fastingDuration = fastingStartTime != null
        ? manualTime.difference(fastingStartTime)
        : Duration.zero;
    final reachedTarget = fastingDuration.inSeconds >= state.targetHours * 3600;
    // Fix anillo (2026-06-09): fracción lograda del target al cerrar,
    // incluido cierre TEMPRANO. Conserva el % en el anillo en vez de 0.
    final achievedFraction = state.targetHours > 0
        ? (fastingDuration.inSeconds / (state.targetHours * 3600))
            .clamp(0.0, 1.0)
        : 0.0;

    _fastingEndConfirmedToday = true;

    // Cierre optimista de la UI (con o sin red).
    state = state.copyWith(
      isSaving: false,
      isWaitingForFastingEnd: false,
      isActive: false,
      startTime: manualTime,
      duration: DateTime.now().difference(manualTime),
      completedToday: reachedTarget ? true : state.completedToday,
      closedProgressToday: achievedFraction,
    );

    // Notificaciones locales (no requieren red) — de inmediato.
    unawaited(_scheduleFeedingWindowNotifs(manualTime, state.fastingProtocol));

    // SPEC-235: cerrar Live Activity con resumen.
    unawaited(LiveActivityService.end(
      totalMinutes: fastingDuration.inMinutes,
      summary: reachedTarget
          ? '¡Meta alcanzada! ${fastingDuration.inHours}h de ayuno'
          : '${fastingDuration.inHours}h de ayuno completadas',
    ));

    // SPEC-193: analytics (se auto-encola si no hay red).
    if (reachedTarget) {
      AnalyticsService.logEvent(
        AnalyticsEvents.fastingCompleted,
        params: {AnalyticsParams.hours: fastingDuration.inHours},
      );
    }

    // Write no bloqueante.
    unawaited(
      repo
          .transitionTo(userId: uid, isFasting: false, startTime: manualTime)
          .then((_) => AppLogger.debug('Ayuno cerrado y sincronizado.'))
          .catchError((Object e) {
        AppLogger.error('Persistencia de cierre falló (reintenta al sync)', e);
      }),
    );
  }

  /// Notificaciones locales de la ventana de alimentación tras cerrar el ayuno.
  /// Local (flutter_local_notifications) → corre con o sin red.
  Future<void> _scheduleFeedingWindowNotifs(
      DateTime manualTime, String protocol) async {
    try {
      await NotificationService.cancelFasting();
      // SPEC-232: cancelar check-ins emocionales al cerrar ayuno.
      await NotificationService.cancelCheckIns();

      // SPEC-241: ID 101 — disparar al cierre del ayuno, no por hora de perfil.
      // El usuario acaba de cerrar el ayuno; su ventana abrió ahora mismo.
      await NotificationService.showImmediate(
        id: NotificationIds.firstMeal,
        title: '🍽️ Tu ventana abrió',
        body: 'Ya puedes comer. Tu cuerpo está listo para recibir nutrición.',
        payload: NotificationRouter.nutritionPayload(),
      );

      // FIX (race condition): lastMealWarning (ID 102) ya NO se programa aquí.
      //
      // Problema previo: este método scheduleaba un one-shot anclado al ciclo
      // (manualTime + feedingHours - 30min), pero NotificationProvider también
      // responde al cambio isActive→false y llama scheduleCircadianDay(), que
      // empieza con cancelCircadian() (cancela 100-109 incluyendo 102) y luego
      // re-agenda 102 como daily basado en profile.lastMealGoal. Como ambas
      // son async sin orden garantizado, el one-shot correcto era sobreescrito
      // por el daily incorrecto → la notificación disparaba durante el ayuno
      // del día siguiente.
      //
      // Fix: NotificationProvider es el único dueño de lastMealWarning.
      // scheduleCircadianDay() lo agenda con !isFasting guard. El ciclo
      // ya cerró → isFasting=false → se agenda correctamente a profile.lastMealGoal.
      // Trade-off menor: no anclado al ciclo exacto si el usuario cerró su
      // ayuno a una hora distinta de profile.firstMealGoal, pero al menos
      // NUNCA dispara durante la ventana de ayuno.
    } catch (e) {
      AppLogger.warning('Error no crítico en notificaciones', e);
    }
  }

  Future<void> stopFasting() async {
    await confirmManualFastingEnd(DateTime.now());
  }

  /// SPEC-151: el usuario alcanzó su target pero decide continuar
  /// ayunando más allá del protocolo. Cierra el overlay sin cerrar el
  /// ayuno — el satélite queda en 100% (clampado) y el contador sigue
  /// sumando como "overtime".
  ///
  /// Marca `_fastingEndConfirmedToday = true` para que el `_tick` no
  /// vuelva a reactivar `isWaitingForFastingEnd` durante este ciclo.
  /// Mantiene `completedToday = true` porque el target SE alcanzó —
  /// el día cuenta para racha y pilar de ayuno completado.
  ///
  /// Si el usuario luego decide cerrar, lo hace desde el botón normal
  /// de la card del dashboard (mismo flujo que cierre temprano).
  void continueFastingPastTarget() {
    if (!mounted) return;
    if (!state.isActive) return; // no-op si no hay ayuno activo
    _fastingEndConfirmedToday = true;
    state = state.copyWith(
      isWaitingForFastingEnd: false,
      completedToday: true,
    );
    AppLogger.debug(
      'SPEC-151: usuario eligió continuar ayuno tras alcanzar target. '
      'Overlay silenciado, isActive sigue true.',
    );
  }

  /// CONFIRMACIÓN MANUAL ALIMENTACIÓN
  Future<void> confirmFeedingEnd(DateTime manualTime) async {
    final uid = _ref.read(authStateProvider).value?.uid;
    if (uid == null || state.isSaving) return;

    // SPEC-50.4: FastingIntervalRepository (no UserRepository).
    final repo = _ref.read(fastingIntervalRepositoryProvider);

    // SPEC-206 (offline-first): cierre optimista de la ventana + write no
    // bloqueante. Antes el `await` colgaba offline y la ventana no se cerraba.
    state = state.copyWith(
      isSaving: false,
      isWaitingForFeedingEnd: false,
      isActive: false,
    );

    // Al cerrar ventana, iniciamos un "intervalo" que no es ayuno.
    unawaited(
      repo
          .transitionTo(userId: uid, isFasting: false, startTime: manualTime)
          .then((_) => AppLogger.debug(
              'Ventana de alimentación cerrada a las $manualTime'))
          .catchError((Object e) {
        AppLogger.warning('Cierre de ventana falló (reintenta al sync): $e');
      }),
    );
  }

  void _tick() {
    if (!mounted) return;
    final now = DateTime.now();
    final user = _ref.read(currentUserStreamProvider).value;

    // 1. Alerta Pre-Sueño
    //
    // SPEC-191: USO LEGÍTIMO — alerta UI informativa. Usa `sleepTime`
    // del perfil para avisar "cerrá tu ventana de comida ya" en las
    // 3h previas a la hora que el usuario eligió como hora de dormir.
    // NO define el día metabólico (eso lo hace el ciclo).
    // Ver METABOLIC_DAY_CONSTITUTION.md §9 — Test ácido.
    bool shouldShowPreSleepWarning = false;
    if (user != null && !state.isActive) {
      final sleepToday = DateTime(now.year, now.month, now.day,
          user.profile.sleepTime.hour, user.profile.sleepTime.minute);
      final diffToSleep = sleepToday.difference(now);
      if (diffToSleep.inHours >= 0 && diffToSleep.inHours < 3) {
        shouldShowPreSleepWarning = true;
      }
    }

    // 2. Control de Overlays Proactivos
    bool waitingForEnd = state.isWaitingForFastingEnd;
    if (state.isActive && !waitingForEnd && !_fastingEndConfirmedToday) {
      if (state.progressPercentage >= 1.0) {
        waitingForEnd = true;
      }
    }

    // 3. Sincronización de Tiempos
    if (state.startTime == null) {
      state = state.copyWith(
        circadianPhase: CircadianRules.getPhaseName(now),
        timeUntilLock: CircadianRules.timeUntilLock(now),
        nearSleepWarning: shouldShowPreSleepWarning,
        isWaitingForFastingEnd: waitingForEnd,
      );
      return;
    }

    final duration = now.difference(state.startTime!);

    state = state.copyWith(
      duration: duration,
      circadianPhase: CircadianRules.getPhaseName(now),
      timeUntilLock: CircadianRules.timeUntilLock(now),
      nearSleepWarning: shouldShowPreSleepWarning,
      isWaitingForFastingEnd: waitingForEnd,
      phase: state.isActive
          ? FastingState.determinePhase(duration)
          : FastingPhase.none,
    );

    // SPEC-235: actualizar Live Activity cada minuto (no cada segundo).
    if (state.isActive &&
        LiveActivityService.isActive &&
        duration.inMinutes != _lastLiveActivityMinute) {
      _lastLiveActivityMinute = duration.inMinutes;
      final phase = LiveActivityPhase.fromElapsedMinutes(duration.inMinutes);
      // Calcular próximo hito.
      final targetMin = state.targetHours * 60;
      final remaining =
          targetMin > duration.inMinutes ? targetMin - duration.inMinutes : 0;
      unawaited(LiveActivityService.update(
        elapsedMinutes: duration.inMinutes,
        phase: phase,
        nextMilestoneMinutes: remaining > 0 ? remaining : null,
        nextMilestoneName: remaining > 0 ? 'Meta' : null,
      ));
    }
  }

  /// SPEC-58: Reset diario idempotente.
  ///
  /// **RF-58-04:** NO elimina el `FastingInterval` activo del día anterior.
  /// El ayuno es por diseño multi-día: protocolos como 16:8 o 18:6 cruzan
  /// la medianoche por su propia naturaleza. Si el usuario inició ayuno
  /// ayer a las 18:00, sigue activo.
  ///
  /// Solo limpia el flag efímero `_fastingEndConfirmedToday` para que el
  /// overlay de "meta alcanzada" pueda volver a mostrarse en el nuevo día
  /// cuando el ayuno cumpla su target.
  void resetDaily() {
    if (!mounted) return;
    _fastingEndConfirmedToday = false;
    // SPEC-113.bugfix: el día nuevo arranca sin "completedToday".
    // Fix anillo (2026-06-09): y sin progreso de cierre del día previo
    // (0.0 = anillo vacío al empezar el día).
    state = state.copyWith(completedToday: false, closedProgressToday: 0.0);
  }

  // SPEC-61: ya no hay Timer interno. Riverpod libera la suscripción a
  // metabolicPulseProvider automáticamente cuando el notifier se dispone.
}

final fastingProvider =
    StateNotifierProvider<FastingNotifier, FastingState>((ref) {
  return FastingNotifier(ref);
});

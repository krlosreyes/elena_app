import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/core/services/notification_service.dart';
import 'package:elena_app/src/core/services/notification_router.dart';
import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/features/hydration/domain/hydration_message_pool.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';
// SPEC-215: fuente canónica única para protocolo → horas.
import 'package:elena_app/src/shared/utils/fasting_protocol.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NotificationScheduler — Motor de agenda circadiana
// ─────────────────────────────────────────────────────────────────────────────

/// Traduce el perfil circadiano y el estado de ayuno del usuario
/// en notificaciones locales concretas.
///
/// Principio científico:
///   Cada notificación corresponde a una transición biológica real —
///   no son recordatorios arbitrarios, son señales del reloj interno.
class NotificationScheduler {
  NotificationScheduler._();

  // ── API Pública ─────────────────────────────────────────────────────────────

  /// Agenda el juego completo de notificaciones circadianas para hoy.
  ///
  /// Cancela las circadianas anteriores antes de reprogramar, garantizando
  /// que un cambio de horario en /profile se refleje de inmediato.
  ///
  /// SPEC-169 §RF-169-04 (2026-06-04): cuando hay [openCycle] con
  /// protocolo conocido, el aviso "30 minutos para cerrar tu ventana"
  /// se ancla al cierre real del ciclo (startedAt + 24h) en vez del
  /// `profile.lastMealGoal`. Esto refleja la hora REAL en que el
  /// usuario inició el ayuno, no la configurada en el perfil. Si
  /// [openCycle] es null o el protocolo es 'Ninguno', cae al fallback
  /// legacy (`profile.lastMealGoal`).
  static Future<void> scheduleCircadianDay(
    UserModel user, {
    MetabolicCycle? openCycle,
    bool isFasting = false,
  }) async {
    try {
      await NotificationService.cancelCircadian();

      final profile = user.profile;

      // SPEC-191 (2026-06-05): USO LEGÍTIMO de `wakeUpTime` y `sleepTime`
      // en este archivo. Las notificaciones circadianas se agendan a las
      // horas que el USUARIO eligió en su perfil. NO definen el día
      // metabólico — solo dicen al sistema operativo "mandá este push
      // a esta hora del reloj". Ver METABOLIC_DAY_CONSTITUTION.md §9.

      // ── 1. Despertar ─────────────────────────────────────────────────────
      // SPEC-169 v1.1 (2026-06-04): tono humano-cercano + cita.
      await _scheduleCircadian(
        id: NotificationIds.wakeUp,
        hour: profile.wakeUpTime.hour,
        minute: profile.wakeUpTime.minute,
        title: '☀️ Buenos días',
        body: 'Despertaste con energía nueva. Aprovéchala en algo que te '
            'importe hoy.',
        payload: NotificationRouter.circadianPayload(),
      );

      // ── 2. Apertura de ventana de alimentación ───────────────────────────
      // SPEC-241: ID 101 se dispara al CERRAR EL AYUNO (en fasting_notifier.dart
      // → _scheduleFeedingWindowNotifs), NO por hora de perfil.
      // Si el usuario no está ayunando, el programador por hora queda como
      // fallback para días sin ayuno activo.
      final firstMeal = profile.firstMealGoal;
      if (firstMeal != null && !isFasting) {
        await _scheduleCircadian(
          id: NotificationIds.firstMeal,
          hour: firstMeal.hour,
          minute: firstMeal.minute,
          title: '🍽️ Tu ventana abrió',
          body: 'Si tienes hambre, este es buen momento para comer. Tu '
              'cuerpo ya está listo.',
          payload: NotificationRouter.nutritionPayload(),
        );
      }

      // ── 3. Advertencia 30 min antes del cierre de ventana ────────────────
      // SPEC-169 §RF-169-04: si hay ciclo metabólico abierto con
      // protocolo conocido, calcular la hora de cierre desde el ciclo
      // (anclaje real al usuario). Sino, usar profile.lastMealGoal
      // como hasta ahora.
      final lastMeal = profile.lastMealGoal;
      final cycleFastingHours = openCycle == null
          ? null
          : fastingHoursForProtocol(openCycle.fastingProtocol);
      DateTime? lastMealDt;
      if (openCycle != null && cycleFastingHours != null) {
        // Cierre de ventana = startedAt + 24h. La hora local del ciclo
        // se respeta vía toLocal() para usuarios viajeros.
        final cycleWindowClose =
            openCycle.startedAt.add(const Duration(hours: 24)).toLocal();
        lastMealDt = DateTime(
          2000,
          1,
          1,
          cycleWindowClose.hour,
          cycleWindowClose.minute,
        );
      } else if (lastMeal != null) {
        lastMealDt = DateTime(2000, 1, 1, lastMeal.hour, lastMeal.minute);
      }
      // Consciencia ayuno↔alimentación: el aviso de cierre de ventana solo
      // aplica durante la fase de alimentación.
      // SPEC-241: esta notificación NUNCA se agenda con ayuno activo.
      // Al cerrar el ayuno, _scheduleFeedingWindowNotifs() la reprograma
      // para el cierre real de ventana (startedAt + 24h - 30 min).
      if (lastMealDt != null && !isFasting) {
        final warningTime =
            lastMealDt.subtract(const Duration(minutes: 30));
        await _scheduleCircadian(
          id: NotificationIds.lastMealWarning,
          hour: warningTime.hour,
          minute: warningTime.minute,
          title: '⏰ 30 minutos para cerrar tu ventana',
          body: 'Si te falta algo por comer, ahora es buen momento. Sin '
              'culpa.',
          payload: NotificationRouter.nutritionPayload(),
        );
      }

      // ── 4. Alerta bloqueo intestinal: 60 min antes (20:30) ───────────────
      // Audit notif (2026-06-10): el "modo reparación" se ANCLA al sueño real
      // del usuario, no a 21:30 fijo. Quien duerme temprano lo recibe antes de
      // dormir (antes le llegaba a las 21:30, ya dormido = fuera de tiempo).
      // Quien duerme tarde mantiene el tope circadiano 21:30 (regla dura
      // cierre de ventana ≤21:00, ver CIRCADIAN_BIBLIOGRAPHY).
      final lockActive = repairLockActiveTime(profile.sleepTime);
      final lock30 = lockActive.subtract(const Duration(minutes: 30));
      final lock60 = lockActive.subtract(const Duration(minutes: 60));

      await _scheduleCircadian(
        id: NotificationIds.intestinalLock60,
        hour: lock60.hour,
        minute: lock60.minute,
        title: '🌙 Una hora para soltar el día',
        body: 'En una hora tu cuerpo empieza a descansar. Si no has cenado, '
            'hazlo ya.',
        payload: NotificationRouter.circadianPayload(),
      );

      await _scheduleCircadian(
        id: NotificationIds.intestinalLock30,
        hour: lock30.hour,
        minute: lock30.minute,
        title: '🌙 30 minutos para soltar',
        body: 'Falta media hora para que tu cuerpo se enfoque en descansar. '
            'Vas bien.',
        payload: NotificationRouter.circadianPayload(),
      );

      await _scheduleCircadian(
        id: NotificationIds.intestinalLockActive,
        hour: lockActive.hour,
        minute: lockActive.minute,
        title: '🌙 Modo reparación activado',
        body: 'Tu cuerpo empieza a hacer lo suyo mientras descansas. Buen '
            'momento para soltar el día.',
        payload: NotificationRouter.circadianPayload(),
      );

      // ── 7. Recordatorio de sueño ─────────────────────────────────────────
      // SPEC-241: ID 106 (sleep) ELIMINADO. Era duplicado de ID 611 (goodNight)
      // que se agenda en _scheduleSleepCoaching() a la misma hora con mejor
      // copy. Mantener los dos generaba doble notificación al mismo tiempo.

      // ── 7b. SPEC-234: coaching de sueño (rutina nocturna + buenas noches)
      await _scheduleSleepCoaching(profile.sleepTime);

      // ── 8. SPEC-169 (2026-06-04): eTRF pre-sueño ─────────────────────────
      // Patrón eTRF (Sutton 2018, Hutchison 2019): cerrar la ventana al
      // menos 3h antes de dormir mejora glucemia + sueño. Solo se agenda
      // si ese momento cae ANTES del cierre de ventana del usuario
      // (lastMealDt) — sino el aviso de cierre (bloque 3) ya cubre la
      // advertencia y duplicar sería fatigador.
      final sleepDt = DateTime(
        2000,
        1,
        1,
        profile.sleepTime.hour,
        profile.sleepTime.minute,
      );
      // Consciencia ayuno↔alimentación: el eTRF ("cerrá la cocina") no tiene
      // sentido durante ayuno — la cocina ya está cerrada.
      final eTRFCutoff = sleepDt.subtract(const Duration(hours: 3));
      if (!isFasting &&
          (lastMealDt == null || eTRFCutoff.isBefore(lastMealDt))) {
        await _scheduleCircadian(
          id: NotificationIds.eTRFPreSleep,
          hour: eTRFCutoff.hour,
          minute: eTRFCutoff.minute,
          title: '🌙 3 horas antes de dormir',
          body: 'Si cierras la cocina ahora, tu descanso de esta noche te lo '
              'va a agradecer.',
          payload: NotificationRouter.circadianPayload(),
        );
      }

      AppLogger.info(
        '[NotificationScheduler] Agenda circadiana programada para ${user.name}.',
      );
    } catch (e, st) {
      AppLogger.error(
          '[NotificationScheduler] Error scheduleCircadianDay()', e, st);
    }
  }

  /// Agenda las notificaciones de hitos de ayuno desde el momento de inicio.
  ///
  /// Estas son one-shot: se disparan una vez por sesión de ayuno.
  /// Llama a esta función desde FastingNotifier cuando se inicia el ayuno.
  static Future<void> scheduleFastingMilestones(DateTime fastingStart) async {
    try {
      await NotificationService.cancelFasting();

      // SPEC-169 v1.1 (2026-06-04): 4 hitos con tono humano-cercano + cita.
      // Hito 16h nuevo (autofagia inicial — Levine 2017); 24h queda como
      // "reparación profunda" para evitar redundancia con 16h.
      final DateTime m12h = fastingStart.add(const Duration(hours: 12));
      final DateTime m16h = fastingStart.add(const Duration(hours: 16));
      final DateTime m18h = fastingStart.add(const Duration(hours: 18));
      final DateTime m24h = fastingStart.add(const Duration(hours: 24));

      // SPEC-241: hitos accionables — "¿Cómo te sientes? Bien 😊 / Mal 😔"
      await NotificationService.scheduleAt(
        id: NotificationIds.fasting12h,
        title: '⚡ 12 horas',
        body: 'Tu cuerpo ya cambió de marcha, y tú llegaste hasta aquí. '
            '¿Cómo te sientes?',
        scheduledTime: m12h,
        repeatsDaily: false,
        actionableMilestone: true,
        payload: NotificationRouter.fastingMilestonePayload(hours: 12),
      );

      await NotificationService.scheduleAt(
        id: NotificationIds.fasting16h,
        title: '✨ 16 horas — Limpieza profunda',
        body: 'Tu cuerpo entró en limpieza profunda gracias a lo de hoy. '
            '¿Cómo te sientes?',
        scheduledTime: m16h,
        repeatsDaily: false,
        actionableMilestone: true,
        payload: NotificationRouter.fastingMilestonePayload(hours: 16),
      );

      await NotificationService.scheduleAt(
        id: NotificationIds.fasting18h,
        title: '🔥 18 horas — Cabeza clara',
        body: 'Tu cuerpo encontró otro combustible. Vas a notar la cabeza '
            'más clara. ¿Cómo te sientes?',
        scheduledTime: m18h,
        repeatsDaily: false,
        actionableMilestone: true,
        payload: NotificationRouter.fastingMilestonePayload(hours: 18),
      );

      await NotificationService.scheduleAt(
        id: NotificationIds.fasting24h,
        title: '✨ 24 horas — Reparación profunda',
        body: 'La limpieza llegó a su punto más alto. Trabajo profundo del '
            'que pocas veces te das cuenta. ¿Cómo te sientes?',
        scheduledTime: m24h,
        repeatsDaily: false,
        actionableMilestone: true,
        payload: NotificationRouter.fastingMilestonePayload(hours: 24),
      );

      // SPEC-232: programar check-ins emocionales en paralelo con los hitos.
      await scheduleCheckInMilestones(fastingStart);

      AppLogger.info(
        '[NotificationScheduler] Hitos de ayuno programados desde $fastingStart.',
      );
    } catch (e, st) {
      AppLogger.error(
          '[NotificationScheduler] Error scheduleFastingMilestones()', e, st);
    }
  }

  // ── SPEC-232: check-ins emocionales durante el ayuno ─────────────────────

  /// Programa check-ins emocionales en las transiciones de fase del ayuno
  /// (horas 4, 8, 12, 16). Cada notificación es accionable: el usuario puede
  /// responder cómo se siente directamente desde la notificación.
  static Future<void> scheduleCheckInMilestones(DateTime fastingStart) async {
    try {
      await NotificationService.cancelCheckIns();

      // Copies contextualizados por hito (alineados con PredictiveTriggerEngine).
      const milestones = <int, _CheckInMilestone>{
        4: _CheckInMilestone(
          id: NotificationIds.checkIn4h,
          title: '¿Cómo empiezas el ayuno?',
          body: 'Tu cuerpo está terminando la digestión. ¿Cómo te sientes?',
        ),
        8: _CheckInMilestone(
          id: NotificationIds.checkIn8h,
          title: 'Llevas 8 horas. ¿Cómo te sientes?',
          body: 'El glucógeno se está agotando. Un momento para escucharte.',
        ),
        12: _CheckInMilestone(
          id: NotificationIds.checkIn12h,
          title: 'Tu cuerpo cambió de marcha',
          body: 'La cetosis temprana está en marcha. ¿Cómo vas?',
        ),
        16: _CheckInMilestone(
          id: NotificationIds.checkIn16h,
          title: 'Limpieza profunda activa',
          body: 'Tu cuerpo inició la autofagia. ¿Cómo estás?',
        ),
      };

      for (final entry in milestones.entries) {
        final scheduledTime =
            fastingStart.add(Duration(hours: entry.key));

        // No programar si el hito ya pasó.
        if (scheduledTime.isBefore(DateTime.now())) continue;

        await NotificationService.scheduleAt(
          id: entry.value.id,
          title: entry.value.title,
          body: entry.value.body,
          scheduledTime: scheduledTime,
          repeatsDaily: false,
          actionableCheckIn: true,
          payload: NotificationRouter.fastingPayload(),
        );
      }

      AppLogger.info(
        '[NotificationScheduler] Check-ins emocionales programados.',
      );
    } catch (e, st) {
      AppLogger.error(
          '[NotificationScheduler] Error scheduleCheckInMilestones()', e, st);
    }
  }

  // ── Helpers internos ────────────────────────────────────────────────────────

  /// Programa una notificación circadiana diaria a una hora fija.
  /// Si la hora ya pasó hoy, el sistema la agendará para mañana automáticamente
  /// gracias a [matchDateTimeComponents: DateTimeComponents.time].
  static Future<void> _scheduleCircadian({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    bool actionableHydration = false,
    String? payload,
  }) async {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Si ya pasó hoy, que la programación ocurra desde mañana
    // (matchDateTimeComponents.time se encargará de que sea diario)
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await NotificationService.scheduleAt(
      id: id,
      title: title,
      body: body,
      scheduledTime: scheduled.toLocal(),
      repeatsDaily: true,
      actionableHydration: actionableHydration,
      payload: payload,
    );
  }

  // SPEC-137 E.5: notificación one-shot 30 min antes de la próxima
  // comida sugerida (lastMealAt + 3h). Reemplaza cualquier
  // notificación previa del mismo id — solo hay una "próxima comida"
  // en cualquier momento.
  //
  // Si la ventana ya pasó (nextMealAt - leadTime está en el pasado),
  // no agendamos nada (solo cancelamos la previa).
  static Future<void> scheduleNextMealReminder({
    required DateTime nextMealAt,
    required Duration leadTime,
  }) async {
    try {
      await NotificationService.cancel(NotificationIds.nextMealReady);
      // SPEC-241 Bug 301: buffer +10s para absorber drift de milisegundos
      // en la conversión DateTime → TZDateTime que puede rechazar la notif.
      final triggerAt = nextMealAt
          .subtract(leadTime)
          .add(const Duration(seconds: 10));
      if (triggerAt.isBefore(DateTime.now())) return;
      final hh = nextMealAt.hour.toString().padLeft(2, '0');
      final mm = nextMealAt.minute.toString().padLeft(2, '0');
      await NotificationService.scheduleAt(
        id: NotificationIds.nextMealReady,
        title: '🍽️ Tu próxima comida es a las $hh:$mm',
        body:
            'Alístate. Faltan ${leadTime.inMinutes} min para tu próxima '
            'comida sugerida.',
        scheduledTime: triggerAt,
        repeatsDaily: false,
        payload: NotificationRouter.nutritionPayload(),
      );
    } catch (e) {
      AppLogger.error('[NotificationScheduler] scheduleNextMealReminder', e);
    }
  }

  /// SPEC-137 E.5: cancela el recordatorio "próxima comida" — útil
  /// cuando el usuario remueve su último log o entra en día de
  /// permitidos.
  static Future<void> cancelNextMealReminder() async {
    await NotificationService.cancel(NotificationIds.nextMealReady);
  }

  // ─── SPEC-169 helpers ───────────────────────────────────────────────────

  /// SPEC-169 §RF-169-04 (2026-06-04): horas de ayuno por protocolo
  /// canónico. Sincronizado con `MetabolicCycleService._hoursFromProtocol`
  /// — si cambia ahí, cambiar acá. Retorna null para 'Ninguno' o
  /// desconocido (caso fallback a `profile.lastMealGoal`).
  ///
  /// Público para testabilidad — no se usa desde fuera del scheduler.
  /// Audit notif (2026-06-10): hora del "modo reparación" anclada al sueño del
  /// usuario, con tope circadiano 21:30 (regla dura cierre de ventana ≤21:00).
  /// - Duerme tarde (≥22:00 o pasada la medianoche) → 21:30 fijo.
  /// - Duerme temprano (18:00–21:59) → 30 min antes de acostarse.
  /// Devuelve un DateTime base (2000-01-01); solo importan hour/minute.
  @visibleForTesting
  static DateTime repairLockActiveTime(DateTime sleepTime) {
    final sleepHour = sleepTime.hour;
    final sleepsLate = sleepHour >= 22 || sleepHour < 12;
    if (sleepsLate) {
      return DateTime(2000, 1, 1, 21, 30);
    }
    final base = DateTime(2000, 1, 1, sleepTime.hour, sleepTime.minute);
    return base.subtract(const Duration(minutes: 30));
  }

  /// SPEC-215: delegar a [fastingHoursForProtocol] (shared/utils/fasting_protocol.dart).
  /// Mantenido como wrapper por compat con callers existentes y tests de SPEC-169.
  /// Nuevos callers deben importar y usar [fastingHoursForProtocol] directamente.
  @Deprecated('Use fastingHoursForProtocol() from shared/utils/fasting_protocol.dart')
  static int? protocolFastingHours(String protocol) =>
      fastingHoursForProtocol(protocol);

  // ─── SPEC-150: hidratación ──────────────────────────────────────────────

  /// Cadencia default entre slots de hidratación. Documentado en
  /// SPEC-150 §1.3 — 90 min se eligió sobre los 30 min pedidos por
  /// Carlos basándose en Maughan 2003 + Adan 2012 + comparativa con
  /// apps comerciales (WaterMinder, Hydro Coach).
  // SPEC-241: cadencia reducida de 30 → 45 min (de ~27 slots/día a ~17).
  static const Duration kHydrationCadence = Duration(minutes: 45);

  /// Hora máxima a la que programamos hidratación. Coincide con la
  /// alerta de bloqueo intestinal 30 min de SPEC-70.5 — durante la
  /// fase de reparación celular no buscamos despertar al usuario.
  static const int kHydrationCutoffHour = 21;

  /// Offset desde wakeUpTime al primer slot. No notificamos
  /// exactamente al despertar — damos 30 min de gracia.
  static const Duration kHydrationFirstSlotOffset = Duration(minutes: 30);

  /// SPEC-150 §RF-150-04: agenda los slots diarios de hidratación.
  /// Se llama desde NotificationProvider cuando cambia el perfil
  /// circadiano del usuario.
  static Future<void> scheduleHydrationReminders(UserModel user) async {
    try {
      await NotificationService.cancelHydration();

      final profile = user.profile;
      final wakeUp = profile.wakeUpTime;
      final sleepTime = profile.sleepTime;

      // Cutoff = min(sleepTime.hour, 21). Si el usuario duerme antes de
      // las 21, respetamos su sleep; si duerme después, paramos a 21
      // para respetar SPEC-70.5 (bloqueo intestinal).
      final cutoffHour = sleepTime.hour < kHydrationCutoffHour
          ? sleepTime.hour
          : kHydrationCutoffHour;

      // Slot inicial: wakeUp + 30 min.
      DateTime current = DateTime(
        2000,
        1,
        1,
        wakeUp.hour,
        wakeUp.minute,
      ).add(kHydrationFirstSlotOffset);

      // Fin: cutoffHour:00 del mismo día base.
      final endTime = DateTime(2000, 1, 1, cutoffHour, 0);

      final maxSlots = NotificationIds.hydrationEnd -
          NotificationIds.hydrationStart +
          1;
      int slotIndex = 0;
      while (!current.isAfter(endTime) && slotIndex < maxSlots) {
        final id = NotificationIds.hydrationStart + slotIndex;
        final message = HydrationMessagePool.selectFor(
          scheduledTime: current,
          slotIndex: slotIndex,
        );
        await _scheduleCircadian(
          id: id,
          hour: current.hour,
          minute: current.minute,
          title: message.title,
          body: message.body,
          // SPEC-199 Fase A: cada recordatorio de hidratación es accionable
          // (botones "Sí, lo registro" / "Aún no").
          actionableHydration: true,
          payload: NotificationRouter.hydrationPayload(),
        );
        current = current.add(kHydrationCadence);
        slotIndex++;
      }

      AppLogger.info(
        '[NotificationScheduler] Hidratación: $slotIndex slots programados '
        '(wake ${wakeUp.hour}:${wakeUp.minute.toString().padLeft(2, '0')}, '
        'cutoff ${cutoffHour}:00, cadencia ${kHydrationCadence.inMinutes}min).',
      );
    } catch (e, st) {
      AppLogger.error(
        '[NotificationScheduler] Error scheduleHydrationReminders()',
        e,
        st,
      );
    }
  }

  // ── SPEC-234: coaching de sueño ─────────────────────────────────────────

  /// Programa las notificaciones de coaching nocturno:
  ///   610: rutina nocturna (sleepTime - 90 min)
  ///   611: "buenas noches" enriquecido (sleepTime)
  static Future<void> _scheduleSleepCoaching(DateTime sleepTime) async {
    try {
      // Cancelar previas antes de reprogramar.
      await NotificationService.cancelSleepCoaching();

      // Rutina nocturna: 90 min antes de dormir.
      final sleepDt = DateTime(2000, 1, 1, sleepTime.hour, sleepTime.minute);
      final routineDt = sleepDt.subtract(const Duration(minutes: 90));

      await _scheduleCircadian(
        id: NotificationIds.sleepRoutine,
        hour: routineDt.hour,
        minute: routineDt.minute,
        title: '🌙 Tu cuerpo se prepara',
        body: 'En 90 minutos es tu hora de dormir. ¿Iniciamos tu rutina '
            'nocturna?',
        payload: NotificationRouter.sleepRoutinePayload(),
      );

      // "Buenas noches" enriquecido: a la hora de dormir.
      await _scheduleCircadian(
        id: NotificationIds.goodNight,
        hour: sleepTime.hour,
        minute: sleepTime.minute,
        title: '🌙 Buenas noches',
        body: 'Hoy fue un buen día para tu metabolismo. Cada hora de sueño '
            'profundo te repara.',
        payload: NotificationRouter.circadianPayload(),
      );

      AppLogger.debug(
        '[NotificationScheduler] Sleep coaching programado '
        '(rutina: ${routineDt.hour}:${routineDt.minute.toString().padLeft(2, '0')}, '
        'goodnight: ${sleepTime.hour}:${sleepTime.minute.toString().padLeft(2, '0')}).',
      );
    } catch (e, st) {
      AppLogger.error(
        '[NotificationScheduler] Error _scheduleSleepCoaching()',
        e,
        st,
      );
    }
  }
}

/// Helper para los hitos de check-in emocional (SPEC-232).
class _CheckInMilestone {
  final int id;
  final String title;
  final String body;
  const _CheckInMilestone({
    required this.id,
    required this.title,
    required this.body,
  });
}

import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/core/services/notification_service.dart';
import 'package:elena_app/src/core/services/notification_router.dart';
import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/core/services/metabolic_day_reminders.dart';
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
  ///
  /// 20-jul: [goalsSummaryBody] es el resumen compacto de "tus 5
  /// objetivos de hoy" (ej. "⏱️16:8 · 🌙8h · 💧2.5L · 💪35min · 🥦2
  /// comidas"), calculado por el caller (`NotificationProvider`, que
  /// tiene acceso a `goalsProvider` vía Riverpod — este servicio es
  /// puro y no lee providers). Si es null (aún no hay datos
  /// suficientes), la notificación simplemente no se agenda ese día.
  static Future<void> scheduleCircadianDay(
    UserModel user, {
    MetabolicCycle? openCycle,
    bool isFasting = false,
    String? goalsSummaryBody,
    // Módulo "Tu Glucosa" (23-jul, propuesta §7.2/R3): true cuando el
    // protocolo de seguimiento de glucosa está activo y no pausado —
    // dispara el recordatorio matutino de registro en ayunas. El
    // caller (NotificationProvider) lo deriva de
    // `glucoseProtocolStateProvider` porque este servicio es puro y no
    // lee providers.
    bool glucoseProtocolActive = false,
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

      // ── 1b. Tus 5 objetivos de hoy (20-jul) ──────────────────────────────
      // Pedido de Carlos: además de "Buenos días", el usuario recibe un
      // resumen de sus 5 objetivos del día, 15 min después de despertar
      // (mismo offset de gracia que ya usa hidratación —
      // kHydrationFirstSlotOffset). Tap → pantalla de Objetivos (metas +
      // avance en vivo), vía `NotificationRouter.goalsPayload()`.
      if (goalsSummaryBody != null && goalsSummaryBody.isNotEmpty) {
        final goalsDt = DateTime(
          2000,
          1,
          1,
          profile.wakeUpTime.hour,
          profile.wakeUpTime.minute,
        ).add(const Duration(minutes: 15));
        await _scheduleCircadian(
          id: NotificationIds.dailyGoalsSummary,
          hour: goalsDt.hour,
          minute: goalsDt.minute,
          title: '🎯 Tus objetivos de hoy',
          body: goalsSummaryBody,
          payload: NotificationRouter.goalsPayload(),
        );
      } else {
        await NotificationService.cancel(NotificationIds.dailyGoalsSummary);
      }

      // ── 1c. Módulo "Tu Glucosa" (23-jul, propuesta §7.2/R3) ──────────────
      // Recordatorio matutino de registro en ayunas — mismo offset que el
      // resumen de objetivos (wakeUpTime + 15 min). La ventana real de
      // registro (`GlucoseWindowState`) se ancla al wakeUp BIOLÓGICO real
      // vía `currentCycleSleepProvider`, no a esta hora de perfil — este
      // push es solo el disparador de OS; si el usuario aún no se
      // despertó, tocar la notificación abre igual el sheet de registro
      // (que respeta la ventana real, no la del perfil).
      if (glucoseProtocolActive) {
        final glucoseDt = DateTime(
          2000,
          1,
          1,
          profile.wakeUpTime.hour,
          profile.wakeUpTime.minute,
        ).add(const Duration(minutes: 15));
        await _scheduleCircadian(
          id: NotificationIds.glucoseMorningReminder,
          hour: glucoseDt.hour,
          minute: glucoseDt.minute,
          title: '🩸 Registra tu glucosa en ayunas',
          body: 'Antes de comer o beber, es buen momento para tu registro '
              'de hoy.',
          payload: NotificationRouter.circadianPayload(),
        );
      } else {
        await NotificationService.cancel(
            NotificationIds.glucoseMorningReminder);
      }

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
        final warningTime = lastMealDt.subtract(const Duration(minutes: 30));
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

      // Consciencia ayuno↔alimentación: "Si no has cenado, hazlo ya" es
      // incoherente durante el ayuno activo — el usuario NO puede comer.
      // La notificación se suprime. lock30 e lockActive tienen copy neutro
      // (soltar el día, descansar) y aplican igual durante o fuera de ayuno.
      if (!isFasting) {
        await _scheduleCircadian(
          id: NotificationIds.intestinalLock60,
          hour: lock60.hour,
          minute: lock60.minute,
          title: '🌙 Una hora para soltar el día',
          body: 'En una hora tu cuerpo empieza a descansar. Si no has cenado, '
              'hazlo ya.',
          payload: NotificationRouter.circadianPayload(),
        );
      } else {
        // Durante ayuno: cancelar explícitamente por si quedó programada de
        // una sesión anterior (p.ej. el usuario inició ayuno temprano ese día).
        await NotificationService.cancel(NotificationIds.intestinalLock60);
      }

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
  /// Día metabólico (2026-11-04): programa los 3 avisos del ciclo según el
  /// estado actual del ayuno. Idempotente: cancela 310-312 y reprograma.
  ///
  /// [anchor] = inicio del ayuno si [isFasting]; si no, el momento en que
  /// terminó el ayuno (abrió la ventana de comida). [targetHours] <= 0
  /// (protocolo "Ninguno") → no programa nada.
  static Future<void> scheduleMetabolicDayReminders({
    required bool isFasting,
    required DateTime? anchor,
    required int targetHours,
    required int wakeHour,
    required int wakeMinute,
  }) async {
    try {
      await NotificationService.cancelMetabolicDay();
      final plan = MetabolicDayReminders.plan(
        isFasting: isFasting,
        anchor: anchor,
        targetHours: targetHours,
        wakeHour: wakeHour,
        wakeMinute: wakeMinute,
        now: DateTime.now(),
      );

      if (plan.windowOpensAt != null) {
        await NotificationService.scheduleAt(
          id: NotificationIds.cycleWindowOpens,
          title: '🍽️ Tu ventana abrió',
          body: 'Cumpliste tu ayuno de $targetHours h. Cuando termines tu '
              'última comida, inicia el ayuno para cerrar tu día.',
          scheduledTime: plan.windowOpensAt!,
          repeatsDaily: false,
          payload: NotificationRouter.fastingPayload(),
        );
      }
      if (plan.closeDayAt != null) {
        await NotificationService.scheduleAt(
          id: NotificationIds.cycleCloseDay,
          title: '🌙 Cierra tu día metabólico',
          body: '¿Ya terminaste de comer? Inicia el ayuno: cierras hoy y '
              'empieza tu nuevo día.',
          scheduledTime: plan.closeDayAt!,
          repeatsDaily: false,
          payload: NotificationRouter.fastingPayload(),
        );
      }
      if (plan.rescueAt != null) {
        await NotificationService.scheduleAt(
          id: NotificationIds.cycleRescue,
          title: 'Tu día de ayer sigue abierto',
          body: '¿A qué hora fue tu última comida? Ciérralo en un toque y '
              'no pierdes tu día.',
          scheduledTime: plan.rescueAt!,
          repeatsDaily: false,
          payload: NotificationRouter.fastingPayload(),
        );
      }
      AppLogger.info(
        '[NotificationScheduler] Día metabólico: ventana=${plan.windowOpensAt} '
        'cierre=${plan.closeDayAt} rescate=${plan.rescueAt}',
      );
    } catch (e, st) {
      AppLogger.error(
          '[NotificationScheduler] Error scheduleMetabolicDayReminders()',
          e,
          st);
    }
  }

  static Future<void> scheduleFastingMilestones(DateTime fastingStart) async {
    try {
      await NotificationService.cancelFasting();

      // SPEC-169 v1.1 (2026-06-04): 4 hitos con tono humano-cercano + cita.
      // Hito 16h nuevo (autofagia inicial — Ohsumi 2016, Nobel de
      // Fisiología o Medicina; corregido 23-jul-2026, antes decía
      // "Levine 2017" por error); 24h queda como "reparación profunda"
      // para evitar redundancia con 16h.
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
        // 27-jul-2026: decía "Limpieza profunda activa / Tu cuerpo inició
        // la autofagia". A las 16 h el usuario está en `transition`
        // (12-18 h); la autofagia empieza a las 24 h según
        // `FastingPhase.startsAt`. Al programarse esta notificación al
        // iniciar el ayuno, todo usuario de 16:8 la recibía cada día en
        // la pantalla de bloqueo — donde no hay nada que la matice — y
        // luego abría la app y leía "24 h autofagia" en la leyenda del
        // reloj. Ver el mismo copy en PredictiveTriggerEngine.
        16: _CheckInMilestone(
          id: NotificationIds.checkIn16h,
          title: 'Llevas 16 horas',
          body: 'La cetosis se afianza y tu energía viene de tus reservas. '
              '¿Cómo estás?',
        ),
      };

      for (final entry in milestones.entries) {
        final scheduledTime = fastingStart.add(Duration(hours: entry.key));

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
      final triggerAt =
          nextMealAt.subtract(leadTime).add(const Duration(seconds: 10));
      if (triggerAt.isBefore(DateTime.now())) return;
      final hh = nextMealAt.hour.toString().padLeft(2, '0');
      final mm = nextMealAt.minute.toString().padLeft(2, '0');
      await NotificationService.scheduleAt(
        id: NotificationIds.nextMealReady,
        title: '🍽️ Tu próxima comida es a las $hh:$mm',
        body: 'Alístate. Faltan ${leadTime.inMinutes} min para tu próxima '
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
  @Deprecated(
      'Use fastingHoursForProtocol() from shared/utils/fasting_protocol.dart')
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

  /// Fix notificaciones (2026-10-30): hora del ÚNICO recordatorio de agua —
  /// el punto medio entre (despertar + 30 min) y el cutoff
  /// (min(hora de dormir, 21:00)). Null si no hay ventana útil.
  /// Pura, para testear sin el plugin.
  static DateTime? hydrationReminderTime({
    required int wakeHour,
    required int wakeMinute,
    required int sleepHour,
  }) {
    final cutoffHour =
        sleepHour < kHydrationCutoffHour ? sleepHour : kHydrationCutoffHour;
    final firstSlot = DateTime(2000, 1, 1, wakeHour, wakeMinute)
        .add(kHydrationFirstSlotOffset);
    final endTime = DateTime(2000, 1, 1, cutoffHour, 0);
    if (!firstSlot.isBefore(endTime)) return null;
    return firstSlot.add(
      Duration(minutes: endTime.difference(firstSlot).inMinutes ~/ 2),
    );
  }

  /// SPEC-150 §RF-150-04: agenda el recordatorio diario de hidratación.
  /// Se llama desde NotificationProvider cuando cambia el perfil
  /// circadiano del usuario.
  static Future<void> scheduleHydrationReminders(UserModel user) async {
    try {
      await NotificationService.cancelHydration();

      final profile = user.profile;
      final wakeUp = profile.wakeUpTime;
      final sleepTime = profile.sleepTime;

      // Fix notificaciones (2026-10-30): UN solo recordatorio de agua al
      // día, a mitad de la jornada, y solo si el usuario activó el tipo
      // "agua" (apagado por defecto). Antes eran ~20 diarios, uno cada 45 min.
      // El filtro final lo hace NotificationPolicy dentro de scheduleAt().
      final midday = hydrationReminderTime(
        wakeHour: wakeUp.hour,
        wakeMinute: wakeUp.minute,
        sleepHour: sleepTime.hour,
      );
      if (midday == null) return;
      final message = HydrationMessagePool.selectFor(
        scheduledTime: midday,
        slotIndex: 0,
      );
      await _scheduleCircadian(
        id: NotificationIds.hydrationStart,
        hour: midday.hour,
        minute: midday.minute,
        title: message.title,
        body: '${message.body} ¿Ya lo tomaste? Regístralo con un toque.',
        actionableHydration: true,
        payload: NotificationRouter.hydrationPayload(),
      );
      AppLogger.info(
        '[NotificationScheduler] Hidratación: 1 recordatorio a las '
        '${midday.hour}:${midday.minute.toString().padLeft(2, '0')}.',
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

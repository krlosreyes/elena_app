import 'package:timezone/timezone.dart' as tz;
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/core/services/notification_service.dart';
import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/features/hydration/domain/hydration_message_pool.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';

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
        body:
            'Tu cuerpo se despertó con la energía justa. Aprovéchala para '
            'algo que te importe hoy. · Biological Dial §3',
      );

      // ── 2. Apertura de ventana de alimentación ───────────────────────────
      final firstMeal = profile.firstMealGoal;
      if (firstMeal != null) {
        await _scheduleCircadian(
          id: NotificationIds.firstMeal,
          hour: firstMeal.hour,
          minute: firstMeal.minute,
          title: '🍽️ Tu ventana abrió',
          body:
              'Si tienes hambre, este es el momento. Tu cuerpo está listo '
              'para recibir. · Sutton 2018',
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
          : protocolFastingHours(openCycle.fastingProtocol);
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
      if (lastMealDt != null) {
        final warningTime =
            lastMealDt.subtract(const Duration(minutes: 30));
        await _scheduleCircadian(
          id: NotificationIds.lastMealWarning,
          hour: warningTime.hour,
          minute: warningTime.minute,
          title: '⏰ 30 minutos para cerrar tu ventana',
          body:
              'Si te falta algo, ahora es buen momento — sin culpa. '
              '· Mattson 2017',
        );
      }

      // ── 4. Alerta bloqueo intestinal: 60 min antes (20:30) ───────────────
      // SPEC-70.5: lock movido a 21:30; alertas se ajustan en consecuencia.
      await _scheduleCircadian(
        id: NotificationIds.intestinalLock60,
        hour: 20,
        minute: 30,
        title: '🌙 Una hora para soltar el día',
        body:
            'En una hora tu cuerpo entra en modo reparación. Si vas a cenar, '
            'hagamos que sea ya. · Lopez-Minguez 2018',
      );

      // ── 5. Alerta bloqueo intestinal: 30 min antes (21:00) ───────────────
      await _scheduleCircadian(
        id: NotificationIds.intestinalLock30,
        hour: 21,
        minute: 0,
        title: '🌙 30 minutos para soltar',
        body:
            'Tu cuerpo está a media hora de concentrarse en repararse. '
            'Si comiste antes, lo estás haciendo bien. · Lopez-Minguez 2018',
      );

      // ── 6. Bloqueo intestinal activo (21:30) ─────────────────────────────
      await _scheduleCircadian(
        id: NotificationIds.intestinalLockActive,
        hour: 21,
        minute: 30,
        title: '🌙 Modo reparación activado',
        body:
            'Tu cuerpo empieza a hacer lo suyo: limpiar y reparar. '
            'Esto pasa mientras descansas. · Xie 2013',
      );

      // ── 7. Recordatorio de sueño ─────────────────────────────────────────
      await _scheduleCircadian(
        id: NotificationIds.sleep,
        hour: profile.sleepTime.hour,
        minute: profile.sleepTime.minute,
        title: '🌙 Hora de descansar',
        body:
            'Las primeras dos horas son las que más reparan. '
            'Mereces ese descanso. · Walker 2017',
      );

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
      final eTRFCutoff = sleepDt.subtract(const Duration(hours: 3));
      if (lastMealDt == null || eTRFCutoff.isBefore(lastMealDt)) {
        await _scheduleCircadian(
          id: NotificationIds.eTRFPreSleep,
          hour: eTRFCutoff.hour,
          minute: eTRFCutoff.minute,
          title: '🌙 3 horas antes de dormir',
          body:
              'Si cierras la ventana ahora, tu descanso te lo va a '
              'agradecer. · Sutton 2018',
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

      await NotificationService.scheduleAt(
        id: NotificationIds.fasting12h,
        title: '⚡ 12 horas',
        body:
            'Tu cuerpo ya cambió de marcha — y tú llegaste hasta acá. '
            '· Cahill 2006',
        scheduledTime: m12h,
        repeatsDaily: false,
        isFasting: true,
      );

      await NotificationService.scheduleAt(
        id: NotificationIds.fasting16h,
        title: '✨ 16 horas — Limpieza profunda',
        body:
            'Tu cuerpo empezó una limpieza profunda gracias a lo que estás '
            'haciendo hoy. · Levine 2017',
        scheduledTime: m16h,
        repeatsDaily: false,
        isFasting: true,
      );

      await NotificationService.scheduleAt(
        id: NotificationIds.fasting18h,
        title: '🔥 18 horas — Cabeza clara',
        body:
            'Tu cuerpo encontró otro combustible. Tu cabeza lo va a notar '
            'pronto. · Mattson 2018',
        scheduledTime: m18h,
        repeatsDaily: false,
        isFasting: true,
      );

      await NotificationService.scheduleAt(
        id: NotificationIds.fasting24h,
        title: '✨ 24 horas — Reparación profunda',
        body:
            'La limpieza llegó a su punto más alto. Esto es trabajo profundo '
            'del que pocas veces te das cuenta. · Mizushima 2008',
        scheduledTime: m24h,
        repeatsDaily: false,
        isFasting: true,
      );

      AppLogger.info(
        '[NotificationScheduler] Hitos de ayuno programados desde $fastingStart.',
      );
    } catch (e, st) {
      AppLogger.error(
          '[NotificationScheduler] Error scheduleFastingMilestones()', e, st);
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
      final triggerAt = nextMealAt.subtract(leadTime);
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
  static int? protocolFastingHours(String protocol) {
    switch (protocol) {
      case '12:12':
        return 12;
      case '14:10':
        return 14;
      case '16:8':
        return 16;
      case '18:6':
        return 18;
      case '20:4':
        return 20;
      case '22:2':
        return 22;
      case 'OMAD':
        return 23;
      case 'Ninguno':
      default:
        return null;
    }
  }

  // ─── SPEC-150: hidratación ──────────────────────────────────────────────

  /// Cadencia default entre slots de hidratación. Documentado en
  /// SPEC-150 §1.3 — 90 min se eligió sobre los 30 min pedidos por
  /// Carlos basándose en Maughan 2003 + Adan 2012 + comparativa con
  /// apps comerciales (WaterMinder, Hydro Coach).
  static const Duration kHydrationCadence = Duration(minutes: 90);

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
          body: '${message.body} · ${message.citation}',
          // SPEC-199 Fase A: cada recordatorio de hidratación es accionable
          // (botones "Sí, lo registro" / "Aún no").
          actionableHydration: true,
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
}

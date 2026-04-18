import 'package:timezone/timezone.dart' as tz;
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/core/services/notification_service.dart';
import 'package:elena_app/src/core/services/app_logger.dart';

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
  static Future<void> scheduleCircadianDay(UserModel user) async {
    try {
      await NotificationService.cancelCircadian();

      final profile = user.profile;

      // ── 1. Despertar ─────────────────────────────────────────────────────
      await _scheduleCircadian(
        id: NotificationIds.wakeUp,
        hour: profile.wakeUpTime.hour,
        minute: profile.wakeUpTime.minute,
        title: '☀️ Fase ALERTA',
        body: 'Tu cortisol está al máximo. El mejor momento para hacer trabajo cognitivo profundo.',
      );

      // ── 2. Apertura de ventana de alimentación ───────────────────────────
      final firstMeal = profile.firstMealGoal;
      if (firstMeal != null) {
        await _scheduleCircadian(
          id: NotificationIds.firstMeal,
          hour: firstMeal.hour,
          minute: firstMeal.minute,
          title: '🍽️ Ventana de alimentación abierta',
          body: 'Tu sistema digestivo está listo. Primera comida dentro del protocolo eTRF.',
        );
      }

      // ── 3. Advertencia 30 min antes del cierre de ventana ────────────────
      final lastMeal = profile.lastMealGoal;
      if (lastMeal != null) {
        final warningTime = DateTime(2000, 1, 1, lastMeal.hour, lastMeal.minute)
            .subtract(const Duration(minutes: 30));
        await _scheduleCircadian(
          id: NotificationIds.lastMealWarning,
          hour: warningTime.hour,
          minute: warningTime.minute,
          title: '⏰ 30 min para cerrar tu ventana',
          body: 'Última oportunidad de comer dentro de tu protocolo eTRF.',
        );
      }

      // ── 4. Alerta bloqueo intestinal: 60 min antes (21:30) ───────────────
      await _scheduleCircadian(
        id: NotificationIds.intestinalLock60,
        hour: 21,
        minute: 30,
        title: '🔒 1 hora para el bloqueo intestinal',
        body: 'A las 22:30 tu sistema digestivo entra en fase de reparación.',
      );

      // ── 5. Alerta bloqueo intestinal: 30 min antes (22:00) ───────────────
      await _scheduleCircadian(
        id: NotificationIds.intestinalLock30,
        hour: 22,
        minute: 0,
        title: '⚠️ 30 min. Cierre inminente',
        body: 'Última oportunidad. Comer después de las 22:30 bloquea la reparación celular.',
      );

      // ── 6. Bloqueo intestinal activo (22:30) ─────────────────────────────
      await _scheduleCircadian(
        id: NotificationIds.intestinalLockActive,
        hour: 22,
        minute: 30,
        title: '🧬 Bloqueo intestinal activo',
        body: 'Fase SUEÑO iniciada. Tu cuerpo inicia la limpieza glinfática y la reparación celular.',
      );

      // ── 7. Recordatorio de sueño ─────────────────────────────────────────
      await _scheduleCircadian(
        id: NotificationIds.sleep,
        hour: profile.sleepTime.hour,
        minute: profile.sleepTime.minute,
        title: '🌙 Fase SUEÑO',
        body: 'Hora de dormir. La hormona del crecimiento se libera en las primeras 2 horas.',
      );

      AppLogger.info(
        '[NotificationScheduler] Agenda circadiana programada para ${user.name}.',
      );
    } catch (e, st) {
      AppLogger.error('[NotificationScheduler] Error scheduleCircadianDay()', e, st);
    }
  }

  /// Agenda las notificaciones de hitos de ayuno desde el momento de inicio.
  ///
  /// Estas son one-shot: se disparan una vez por sesión de ayuno.
  /// Llama a esta función desde FastingNotifier cuando se inicia el ayuno.
  static Future<void> scheduleFastingMilestones(DateTime fastingStart) async {
    try {
      await NotificationService.cancelFasting();

      final DateTime m12h = fastingStart.add(const Duration(hours: 12));
      final DateTime m18h = fastingStart.add(const Duration(hours: 18));
      final DateTime m24h = fastingStart.add(const Duration(hours: 24));

      await NotificationService.scheduleAt(
        id: NotificationIds.fasting12h,
        title: '⚡ 12 horas de ayuno',
        body: 'Insulina en mínimos. Gluconeogénesis activa. Tu cuerpo está usando reservas.',
        scheduledTime: m12h,
        repeatsDaily: false,
        isFasting: true,
      );

      await NotificationService.scheduleAt(
        id: NotificationIds.fasting18h,
        title: '🔥 18 horas — Cetosis activa',
        body: '¡Cetosis nutricional confirmada! Tu cerebro funciona con cuerpos cetónicos.',
        scheduledTime: m18h,
        repeatsDaily: false,
        isFasting: true,
      );

      await NotificationService.scheduleAt(
        id: NotificationIds.fasting24h,
        title: '🧬 24 horas — Autofagia iniciada',
        body: 'Tu sistema está reciclando células dañadas. Este es el nivel de limpieza profunda.',
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
    );
  }
}

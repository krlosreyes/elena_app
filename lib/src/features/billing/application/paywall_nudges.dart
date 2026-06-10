// SPEC-198 §2.4 — nudges de conversión de trial (día 5 y 12).
//
// La parte PURA (`nudgeDatesFor`) es testeable; `schedule`/`cancel` son la
// integración con NotificationService (no-op en web/sin init). Tono humano,
// sin culpa (memoria notification-tone-human-not-clinical).

import 'package:elena_app/src/core/services/notification_service.dart';

class PaywallNudges {
  const PaywallNudges._();

  static const int day5 = 5;
  static const int day12 = 12;

  /// Fechas de los dos nudges a partir de la fecha de registro.
  /// [0] = día 5 (mira tu tendencia), [1] = día 12 (tu trial termina pronto).
  static List<DateTime> nudgeDatesFor(DateTime createdAt) => [
        createdAt.add(const Duration(days: day5)),
        createdAt.add(const Duration(days: day12)),
      ];

  /// Programa los dos nudges (one-shot). Idempotente por id.
  static Future<void> schedule(DateTime createdAt) async {
    final dates = nudgeDatesFor(createdAt);
    await NotificationService.scheduleAt(
      id: NotificationIds.paywallNudgeDay5,
      title: 'Tu progreso está tomando forma',
      body: 'Mira cómo evoluciona tu tendencia con Premium. Estás a tiempo.',
      scheduledTime: dates[0],
      repeatsDaily: false,
    );
    await NotificationService.scheduleAt(
      id: NotificationIds.paywallNudgeDay12,
      title: 'Tu prueba gratuita termina en 2 días',
      body: 'Si quieres conservar tu coaching y tu tendencia, este es el '
          'momento. Sin presión.',
      scheduledTime: dates[1],
      repeatsDaily: false,
    );
  }

  /// Cancela ambos nudges (al volverse Premium ya no aplican).
  static Future<void> cancel() async {
    await NotificationService.cancel(NotificationIds.paywallNudgeDay5);
    await NotificationService.cancel(NotificationIds.paywallNudgeDay12);
  }
}

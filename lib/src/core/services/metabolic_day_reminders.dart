// Día metabólico (2026-11-04): los 3 avisos que acompañan al usuario en su
// día. El día lo abre y lo cierra SOLO el usuario al tocar "Iniciar ayuno"
// (ver docs/METABOLIC_DAY_CONSTITUTION.md §1). Estos avisos no deciden nada:
// solo lo invitan a hacer ese toque en el momento oportuno.
//
//   1. Ventana abre   — cuando se cumple la meta de horas de ayuno.
//   2. Cierra tu día  — al fin estimado de la ventana de comida (+30 min de
//                       gracia), si todavía no inició el próximo ayuno.
//   3. Rescate        — la mañana siguiente (hora de despertar + 30 min), si
//                       el día sigue sin cerrar. Lleva a "¿A qué hora fue tu
//                       última comida?".
//
// Todo se ancla a eventos del usuario (inicio de ayuno / fin de ayuno). La
// única referencia de reloj es la hora de despertar del perfil para el
// rescate, que solo dice al sistema operativo cuándo entregar el aviso.
//
// Dart puro y sin DateTime.now(): `now` llega desde fuera para poder testear.

/// Momento en que debería sonar cada aviso. Null = no programar.
class MetabolicDayReminderPlan {
  const MetabolicDayReminderPlan({
    this.windowOpensAt,
    this.closeDayAt,
    this.rescueAt,
  });

  final DateTime? windowOpensAt;
  final DateTime? closeDayAt;
  final DateTime? rescueAt;

  static const empty = MetabolicDayReminderPlan();
}

class MetabolicDayReminders {
  MetabolicDayReminders._();

  /// Margen tras el fin estimado de la ventana antes de avisar. Evita
  /// interrumpir a quien todavía está comiendo a la hora "exacta".
  static const Duration closeGrace = Duration(minutes: 30);

  /// El rescate nunca suena antes de 4 h después del aviso de cierre…
  static const Duration rescueMinAfterClose = Duration(hours: 4);

  /// …ni más de 36 h después (si pasó más, el usuario abandonó: no
  /// insistimos con un aviso diario indefinido).
  static const Duration rescueMaxAfterClose = Duration(hours: 36);

  /// Minutos después de la hora de despertar para el rescate.
  static const Duration rescueAfterWake = Duration(minutes: 30);

  /// Duración de la ventana de comida para un objetivo de ayuno. En
  /// protocolos de 24 h o más se asume 1 h (una comida).
  static Duration windowFor(int targetHours) => targetHours < 24
      ? Duration(hours: 24 - targetHours)
      : const Duration(hours: 1);

  /// Fin estimado de la ventana de comida.
  ///
  /// - En ayuno: inicio + meta + ventana.
  /// - Fuera de ayuno: [anchor] es el momento en que terminó el ayuno (abrió
  ///   la ventana) → anchor + ventana.
  static DateTime? estimatedWindowEnd({
    required bool isFasting,
    required DateTime? anchor,
    required int targetHours,
  }) {
    if (anchor == null || targetHours <= 0) return null;
    final windowStart =
        isFasting ? anchor.add(Duration(hours: targetHours)) : anchor;
    return windowStart.add(windowFor(targetHours));
  }

  static MetabolicDayReminderPlan plan({
    required bool isFasting,
    required DateTime? anchor,
    required int targetHours,
    required int wakeHour,
    required int wakeMinute,
    required DateTime now,
  }) {
    // Protocolo "Ninguno" (o sin dato): no hay ayuno → no hay avisos de ciclo.
    if (anchor == null || targetHours <= 0) return MetabolicDayReminderPlan.empty;

    DateTime? futureOrNull(DateTime? t) =>
        (t != null && t.isAfter(now)) ? t : null;

    final windowOpens =
        isFasting ? anchor.add(Duration(hours: targetHours)) : null;
    final windowEnd = estimatedWindowEnd(
      isFasting: isFasting,
      anchor: anchor,
      targetHours: targetHours,
    )!;
    final closeAt = windowEnd.add(closeGrace);

    var rescue = DateTime(
      closeAt.year,
      closeAt.month,
      closeAt.day,
      wakeHour,
      wakeMinute,
    ).add(rescueAfterWake);
    final earliest = closeAt.add(rescueMinAfterClose);
    while (rescue.isBefore(earliest)) {
      rescue = rescue.add(const Duration(days: 1));
    }
    final DateTime? rescueAt =
        rescue.difference(closeAt) > rescueMaxAfterClose ? null : rescue;

    return MetabolicDayReminderPlan(
      windowOpensAt: futureOrNull(windowOpens),
      closeDayAt: futureOrNull(closeAt),
      rescueAt: futureOrNull(rescueAt),
    );
  }
}

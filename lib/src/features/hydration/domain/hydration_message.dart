// SPEC-150 §RF-150-01: value object para mensajes de hidratación.

enum DayPeriod {
  /// 5-11h local. Rehidratación post-noche + peak de cortisol.
  morning,

  /// 11-14h local. Pre-almuerzo + productividad cognitiva.
  midday,

  /// 14-18h local. Post-comida + energía vespertina.
  afternoon,

  /// 18-21h local. Pre-sueño + bloqueo intestinal.
  evening,
}

/// Mensaje educativo de hidratación con cita bibliográfica.
class HydrationMessage {
  /// ID estable para tracking y tests. Formato 'hyd-period-NN'.
  final String id;

  /// Período del día al que aplica este mensaje.
  final DayPeriod period;

  /// Título corto que aparece en la notificación.
  final String title;

  /// Cuerpo del mensaje. Claim + dato accionable.
  final String body;

  /// Cita corta (autor + año o autoridad + año). Aparece en el body
  /// final separada por ' · '.
  final String citation;

  const HydrationMessage({
    required this.id,
    required this.period,
    required this.title,
    required this.body,
    required this.citation,
  });
}

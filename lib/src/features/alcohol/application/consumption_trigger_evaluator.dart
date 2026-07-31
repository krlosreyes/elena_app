// SPEC-261: motor de detección de patrones de consumo.
//
// Lógica pura y determinística (sin reloj propio, sin I/O): recibe las
// señales del contexto y devuelve una probabilidad P(consumo) en [0, 1]
// y si conviene mostrar el llamado a la acción del protocolo.
//
// Construido por capas, de la más simple (sin ML) a la más rica (con
// permisos), tal como el plan de fases del docx. El CTA es SIEMPRE
// opt-in: este evaluador solo sugiere; nunca activa nada por su cuenta.

import 'package:elena_app/src/features/alcohol/domain/drink_event.dart';

/// Señales de contexto para estimar la probabilidad de consumo.
class ConsumptionSignals {
  /// Momento de evaluación (inyectado — no se lee el reloj aquí).
  final DateTime now;

  /// Timestamps de consumos previos del usuario (historial personal).
  final List<DateTime> pastDrinkTimestamps;

  /// Hay un evento de calendario compatible (cena, fiesta, bar…). Opt-in.
  final bool hasSocialCalendarEvent;

  /// Víspera de festivo o día de pago / quincena.
  final bool isPaydayOrHolidayEve;

  /// El usuario declaró explícitamente que va a salir/beber.
  final bool userDeclaredIntent;

  /// Veces que ignoró el CTA en un contexto parecido (aprendizaje).
  final int recentRejectionsInContext;

  const ConsumptionSignals({
    required this.now,
    this.pastDrinkTimestamps = const [],
    this.hasSocialCalendarEvent = false,
    this.isPaydayOrHolidayEve = false,
    this.userDeclaredIntent = false,
    this.recentRejectionsInContext = 0,
  });
}

/// Resultado de una evaluación.
class ConsumptionForecast {
  final double probability; // 0..1
  final bool shouldPromptProtocol;

  const ConsumptionForecast({
    required this.probability,
    required this.shouldPromptProtocol,
  });
}

abstract final class ConsumptionTriggerEvaluator {
  /// Umbral por defecto para disparar el CTA.
  static const double defaultThreshold = 0.6;

  /// Franja considerada "social" (tarde-noche).
  static const int socialHourStart = 18;
  static const int socialHourEnd = 23;

  static ConsumptionForecast evaluate(
    ConsumptionSignals s, {
    double threshold = defaultThreshold,
  }) {
    // La intención declarada es determinante: se muestra sí o sí.
    if (s.userDeclaredIntent) {
      return const ConsumptionForecast(
        probability: 1.0,
        shouldPromptProtocol: true,
      );
    }

    double p = 0;
    p += 0.45 * _personalTemporalScore(s);
    p += 0.20 * _dayHourContextScore(s.now);
    p += 0.25 * (s.hasSocialCalendarEvent ? 1.0 : 0.0);
    p += 0.10 * (s.isPaydayOrHolidayEve ? 1.0 : 0.0);

    p *= _learningFactor(s.recentRejectionsInContext);
    final prob = p.clamp(0.0, 1.0);

    return ConsumptionForecast(
      probability: prob,
      shouldPromptProtocol: prob >= threshold,
    );
  }

  /// Qué tan típico es beber en esta combinación día-de-semana + franja,
  /// según el historial personal. 0..1.
  static double _personalTemporalScore(ConsumptionSignals s) {
    final history = s.pastDrinkTimestamps;
    if (history.length < 3) return 0; // sin datos suficientes, no inferimos.

    final weekday = s.now.weekday;
    final hourBucket = _hourBucket(s.now.hour);

    final matches = history.where((t) {
      return t.weekday == weekday && _hourBucket(t.hour) == hourBucket;
    }).length;

    // Proporción de eventos históricos que caen en este mismo contexto,
    // saturada: con ~1/4 del historial en este contexto ya es "muy típico".
    final ratio = matches / history.length;
    return (ratio * 4).clamp(0.0, 1.0);
  }

  /// ¿Estamos en una franja social (tarde-noche)? La usa la card del
  /// dashboard para insinuarse con suavidad aunque aún no haya historial
  /// personal que eleve P(consumo) por encima del umbral.
  static bool isSocialWindow(DateTime now) =>
      now.hour >= socialHourStart && now.hour <= socialHourEnd;

  /// Score por día/hora de contexto: jueves–sábado en franja social = 1.
  static double _dayHourContextScore(DateTime now) {
    final inSocialHour =
        now.hour >= socialHourStart && now.hour <= socialHourEnd;
    if (!inSocialHour) return 0;
    // 4=jueves, 5=viernes, 6=sábado.
    if (now.weekday >= DateTime.thursday) return 1.0;
    return 0.4; // entre semana en franja social: probabilidad menor.
  }

  /// Baja el peso global cuando el usuario ha ignorado el CTA repetidamente
  /// en este contexto. Nunca por debajo de 0,3 para no silenciarlo del todo.
  static double _learningFactor(int rejections) {
    final f = 1.0 - 0.2 * rejections;
    return f.clamp(0.3, 1.0);
  }

  static int _hourBucket(int hour) {
    if (hour < 12) return 0; // mañana
    if (hour < 18) return 1; // tarde
    return 2; // noche
  }

  /// Deriva los timestamps de historial a partir de eventos de consumo.
  static List<DateTime> historyFromEvents(List<DrinkEvent> events) =>
      events.map((e) => e.timestamp).toList(growable: false);
}

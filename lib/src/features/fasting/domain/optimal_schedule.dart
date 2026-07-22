// SPEC-96: horarios óptimos coherentes con el ciclo circadiano.
//
// Fuente normativa: docs/CIRCADIAN_BIBLIOGRAPHY.md §4.
//
// Ancla canónica: la ventana de comida CIERRA a las 20:30. Esto se
// deriva del bloqueo intestinal a las 22:00 (Biological Dial §13) y
// la regla de "cese de ingesta 1.5–2h antes" (Biological Dial §15).
//
// Cada protocolo deriva su `windowStart` trabajando hacia atrás desde
// 20:30 según las horas de ventana de comida que define.

import 'package:flutter/material.dart' show TimeOfDay;

/// Resultado canónico del cálculo. Todas las horas son `TimeOfDay`
/// hora local del usuario (la app no maneja zonas horarias en MVP).
class OptimalSchedule {
  /// Apertura ideal de la ventana de comida.
  final TimeOfDay windowStart;

  /// Cierre ideal de la ventana de comida. Siempre 20:30 según la
  /// bibliografía.
  final TimeOfDay windowEnd;

  /// Inicio ideal del ayuno (igual a `windowEnd` — al cerrar la
  /// ventana de comida, inicia el ayuno).
  final TimeOfDay fastingStart;

  /// Fin ideal del ayuno (igual a `windowStart` del día siguiente —
  /// al abrir la ventana de comida, termina el ayuno).
  final TimeOfDay fastingEnd;

  /// Horas que dura la ventana de comida (8 / 6 / 4 / 14).
  final int windowHours;

  /// Horas que dura el ayuno (16 / 18 / 20 / 10).
  final int fastingHours;

  /// Protocolo canónico para el que aplica este schedule.
  final String fastingProtocol;

  const OptimalSchedule({
    required this.windowStart,
    required this.windowEnd,
    required this.fastingStart,
    required this.fastingEnd,
    required this.windowHours,
    required this.fastingHours,
    required this.fastingProtocol,
  });
}

class OptimalScheduleCalculator {
  OptimalScheduleCalculator._();

  /// Cierre canónico de ventana de comida: 20:30 hora local.
  static const TimeOfDay kWindowEndAnchor = TimeOfDay(hour: 20, minute: 30);

  /// Límite absoluto. Cerrar después de 21:00 viola el bloqueo
  /// intestinal documentado en Biological Dial §13.
  static const TimeOfDay kHardLimitWindowEnd = TimeOfDay(hour: 21, minute: 0);

  /// Tolerancia ±60 min para considerar una configuración del usuario
  /// como "coherente" sin warning. Permite variabilidad social
  /// razonable sin romper el principio circadiano.
  static const int kToleranceMinutes = 60;

  /// Mapa de protocolo → horas de ventana de comida.
  ///
  /// SPEC-98: se agregaron 12:12, 14:10, 22:2 y OMAD para alinearlo
  /// con el selector visual del producto (8 protocolos totales).
  static const Map<String, int> _windowHoursByProtocol = {
    'Ninguno':
        14, // 06:30–20:30 (sin TRF estricto, solo evita snacks nocturnos).
    '12:12': 12, // 08:30–20:30 (entrada suave al ayuno intermitente).
    '14:10': 10, // 10:30–20:30 (punto medio principiantes).
    '16:8': 8, // 12:30–20:30 (clásico).
    '18:6': 6, // 14:30–20:30 (moderado-intenso).
    '20:4': 4, // 16:30–20:30 (avanzado).
    '22:2': 2, // 18:30–20:30 (avanzado, supervisión recomendada).
    'OMAD': 1, // 19:30–20:30 (una comida al día; ventana técnica).
  };

  /// Devuelve el schedule óptimo para el protocolo dado. Protocolos
  /// desconocidos caen al default 16:8 con un warning silencioso.
  static OptimalSchedule forProtocol(String protocol) {
    final int windowHours = _windowHoursByProtocol[protocol] ?? 8;
    final String canonicalProtocol =
        _windowHoursByProtocol.containsKey(protocol) ? protocol : '16:8';
    final int fastingHours = 24 - windowHours;

    final TimeOfDay windowEnd = kWindowEndAnchor;
    final TimeOfDay windowStart = _subtractHours(windowEnd, windowHours);

    return OptimalSchedule(
      windowStart: windowStart,
      windowEnd: windowEnd,
      fastingStart: windowEnd,
      fastingEnd: windowStart,
      windowHours: windowHours,
      fastingHours: fastingHours,
      fastingProtocol: canonicalProtocol,
    );
  }

  /// True si la configuración del usuario está dentro de la
  /// tolerancia ±60 min de la óptima para su protocolo. Útil para
  /// decidir si mostrar un warning al guardar.
  static bool isCoherent({
    required TimeOfDay windowStart,
    required TimeOfDay windowEnd,
    required String protocol,
  }) {
    final optimal = forProtocol(protocol);
    final startDelta =
        (_toMinutes(windowStart) - _toMinutes(optimal.windowStart)).abs();
    final endDelta =
        (_toMinutes(windowEnd) - _toMinutes(optimal.windowEnd)).abs();
    return startDelta <= kToleranceMinutes && endDelta <= kToleranceMinutes;
  }

  /// True si `windowEnd` rompe el bloqueo intestinal (>= 21:00).
  /// Esto es hard limit — la app debería bloquear el guardado.
  static bool violatesIntestinalBlock(TimeOfDay windowEnd) {
    return _toMinutes(windowEnd) >= _toMinutes(kHardLimitWindowEnd);
  }

  /// Devuelve un mensaje human-readable explicando por qué la
  /// configuración no es óptima. Si lo es, devuelve null.
  ///
  /// Útil para mostrar tooltips en onboarding y profile.
  static String? lintReason({
    required TimeOfDay windowStart,
    required TimeOfDay windowEnd,
    required String protocol,
  }) {
    if (violatesIntestinalBlock(windowEnd)) {
      return 'Cerrar la ventana de comida después de las 21:00 viola el '
          'bloqueo intestinal natural (Biological Dial §13). Comer en esa '
          'ventana destruye la calidad del sueño y baja tu IMR de mañana.';
    }

    final optimal = forProtocol(protocol);
    final startDelta =
        (_toMinutes(windowStart) - _toMinutes(optimal.windowStart)).abs();
    final endDelta =
        (_toMinutes(windowEnd) - _toMinutes(optimal.windowEnd)).abs();

    if (startDelta <= kToleranceMinutes && endDelta <= kToleranceMinutes) {
      return null; // coherente
    }

    final String optimalStart = _format(optimal.windowStart);
    final String optimalEnd = _format(optimal.windowEnd);
    return 'Tu protocolo $protocol funciona mejor entre $optimalStart y '
        '$optimalEnd. Tu configuración actual está fuera del rango ideal '
        '(±${kToleranceMinutes}min). Esto no es bloqueante, pero acercarte '
        'al óptimo mejora tu alineación circadiana.';
  }

  /// Resta horas a un TimeOfDay manejando overflow al día anterior.
  static TimeOfDay _subtractHours(TimeOfDay base, int hours) {
    final totalMinutes = _toMinutes(base) - (hours * 60);
    final adjusted = totalMinutes % (24 * 60);
    final positive = adjusted < 0 ? adjusted + (24 * 60) : adjusted;
    return TimeOfDay(hour: positive ~/ 60, minute: positive % 60);
  }

  static int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  static String _format(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

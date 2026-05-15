// SPEC-95: estado puro de la ventana de alimentación.
//
// Antes el `EatingWindowPainter` recibía datos del `FastingState` (que
// mezcla ayuno y ventana), lo cual hacía que cuando no había ayuno
// activo el arco no se pintara o quedara descalibrado.
//
// Este value object encapsula la ventana de alimentación como concepto
// propio: cuándo empezó, cuándo cierra, cuánto va, dónde estamos.

import 'package:elena_app/src/shared/domain/models/user_model.dart';

/// Estado relativo a la ventana de alimentación del día.
enum EatingWindowStatus {
  /// `now` aún no llega a `windowStart` — la ventana del día todavía
  /// no abre. Pasa cuando el usuario no ha cerrado el ayuno o
  /// `firstMealGoal` es a futuro.
  beforeWindow,

  /// `now` está entre `windowStart` y `windowEnd`. Es el caso normal
  /// durante el día.
  withinWindow,

  /// `now` superó `windowEnd`. La ventana ideal del usuario ya cerró
  /// y debería iniciar el siguiente ayuno.
  afterWindow,

  /// No hay datos suficientes para determinar la ventana (por ejemplo,
  /// el último intervalo está marcado como `isFasting=true` — ese caso
  /// debería pintar `FastingRingPainter`, no este state).
  unknown,
}

/// Resultado puro del cálculo. Sin dependencias de Flutter ni
/// Firebase — testeable 100%.
class EatingWindowState {
  /// Hora a la que abrió (o abrirá) la ventana de comida del usuario.
  final DateTime windowStart;

  /// Hora a la que cierra (o cerró) la ventana de comida.
  final DateTime windowEnd;

  /// Duración en horas, derivada del `fastingProtocol`.
  ///   16:8 → 8     18:6 → 6     20:4 → 4     Ninguno → 14
  final int windowDurationHours;

  /// "Ahora" usado en este cálculo. Se inyecta para testabilidad.
  final DateTime now;

  /// Estado relativo de `now` respecto a la ventana.
  final EatingWindowStatus status;

  /// Fracción de la ventana transcurrida en `now`. Clamp [0.0, 1.0].
  /// Si `status == beforeWindow` → 0. Si `afterWindow` → 1.
  final double progressPercent;

  const EatingWindowState({
    required this.windowStart,
    required this.windowEnd,
    required this.windowDurationHours,
    required this.now,
    required this.status,
    required this.progressPercent,
  });

  /// Computa el state a partir de los inputs disponibles.
  ///
  /// - [lastInterval]: último intervalo persistido en Firestore. Puede
  ///   ser null (usuario nuevo) o estar marcado `isFasting=true`
  ///   (entonces este state no debería usarse — el caller pinta el
  ///   ayuno).
  /// - [user]: para leer `fastingProtocol` y `profile.firstMealGoal`.
  /// - [now]: instante actual.
  static EatingWindowState compute({
    required FastingInterval? lastInterval,
    required UserModel user,
    required DateTime now,
  }) {
    final int hours = _windowHoursForProtocol(user.fastingProtocol);

    // Caso 1: hay ayuno activo. Este state no aplica; devolvemos
    // unknown con datos derivados del firstMealGoal (no debería
    // pintarse, pero protegemos el constructor para no fallar).
    if (lastInterval != null && lastInterval.isFasting) {
      final DateTime fallbackStart = _fallbackWindowStart(user, now);
      return EatingWindowState(
        windowStart: fallbackStart,
        windowEnd: fallbackStart.add(Duration(hours: hours)),
        windowDurationHours: hours,
        now: now,
        status: EatingWindowStatus.unknown,
        progressPercent: 0.0,
      );
    }

    // Caso 2: hay un intervalo de ventana de comida (isFasting=false).
    // Si su startTime es reciente (≤ 24h), usar como windowStart.
    // Si es muy viejo, caer al fallback.
    DateTime windowStart;
    if (lastInterval != null && !lastInterval.isFasting) {
      final ageHours = now.difference(lastInterval.startTime).inHours;
      windowStart = ageHours.abs() <= 24
          ? lastInterval.startTime
          : _fallbackWindowStart(user, now);
    } else {
      // Caso 3: sin historial — fallback al firstMealGoal o 08:00.
      windowStart = _fallbackWindowStart(user, now);
    }

    final DateTime windowEnd = windowStart.add(Duration(hours: hours));

    final EatingWindowStatus status;
    final double progress;
    if (now.isBefore(windowStart)) {
      status = EatingWindowStatus.beforeWindow;
      progress = 0.0;
    } else if (now.isAfter(windowEnd)) {
      status = EatingWindowStatus.afterWindow;
      progress = 1.0;
    } else {
      status = EatingWindowStatus.withinWindow;
      final totalSec = windowEnd.difference(windowStart).inSeconds;
      final elapsedSec = now.difference(windowStart).inSeconds;
      progress = totalSec > 0
          ? (elapsedSec / totalSec).clamp(0.0, 1.0)
          : 0.0;
    }

    return EatingWindowState(
      windowStart: windowStart,
      windowEnd: windowEnd,
      windowDurationHours: hours,
      now: now,
      status: status,
      progressPercent: progress,
    );
  }

  /// Mapea el protocolo de ayuno a horas de ventana de comida.
  ///   16:8 → 8     18:6 → 6     20:4 → 4     Ninguno/default → 14
  static int _windowHoursForProtocol(String protocol) {
    if (protocol.contains(':')) {
      final parts = protocol.split(':');
      if (parts.length == 2) {
        final windowPart = int.tryParse(parts[1]);
        if (windowPart != null && windowPart > 0) return windowPart;
      }
    }
    // 14 = default sensible para adulto sano sin TRF. Cubre desayuno
    // 08:00 a cena 22:00 cómodamente.
    return 14;
  }

  /// Fallback cuando no hay un `lastInterval` confiable. Usa el
  /// `firstMealGoal` del perfil circadiano del día de hoy; si tampoco
  /// existe, las 08:00 hora local.
  static DateTime _fallbackWindowStart(UserModel user, DateTime now) {
    final DateTime? goal = user.profile.firstMealGoal;
    if (goal != null) {
      return DateTime(now.year, now.month, now.day, goal.hour, goal.minute);
    }
    return DateTime(now.year, now.month, now.day, 8, 0);
  }
}

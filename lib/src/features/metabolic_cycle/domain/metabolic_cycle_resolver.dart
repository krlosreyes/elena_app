// SPEC-149: MetabolicCycleResolver — motor puro del Día Metabólico.
//
// Fuente única de verdad sobre cuándo abrir/cerrar un ciclo metabólico
// y cuál razón aplica. Dart puro, sin estado, sin DateTime.now() —
// todos los timestamps llegan desde fuera.
//
// Es el equivalente al DayBoundaryResolver (SPEC-138) pero para la
// semántica metabólica (no calendárica). Conviven sin pisarse.

import 'package:elena_app/src/features/metabolic_cycle/domain/closure_reason.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';

/// Protocolo especial que dispara el modo calendárico.
const String kNoProtocol = 'Ninguno';

/// Límite mínimo de duración para que un cierre `manualNextFasting`
/// sea aceptado. Evita falsos cierres por toques accidentales.
const Duration kMinCycleDurationForManualClose = Duration(minutes: 30);

/// Tiempo tras `expectedWindowCloseTime` después del cual disparamos
/// el trigger `fallback3hAfterWindow`.
const Duration kFallbackAfterWindowGrace = Duration(hours: 3);

/// Tiempo mínimo desde `lastMealTime` para que un sueño detectado
/// dispare `fallbackSleepDetected`.
const Duration kSleepFallbackMinSinceMeal = Duration(hours: 2);

/// Límite absoluto desde `startedAt` que dispara `fallbackAbsolute`.
const Duration kAbsoluteCycleLimit = Duration(hours: 28);

class MetabolicCycleResolver {
  MetabolicCycleResolver._();

  // ─── Apertura de ciclo ───────────────────────────────────────────────────

  /// Construye un nuevo ciclo abierto. Wrapper sobre `MetabolicCycle.open`
  /// para semántica de "resolver".
  static MetabolicCycle openCycle({
    required DateTime startedAt,
    required String fastingProtocol,
    required int tzOffsetMinutes,
  }) {
    return MetabolicCycle.open(
      startedAt: startedAt,
      fastingProtocol: fastingProtocol,
      tzOffsetMinutes: tzOffsetMinutes,
    );
  }

  // ─── Modo calendárico (fallback "Ninguno") ───────────────────────────────

  /// True si el protocolo del usuario es "Ninguno" — modo calendárico.
  static bool useCalendarFallback(String fastingProtocol) {
    return fastingProtocol == kNoProtocol;
  }

  /// Para usuarios en modo calendárico: el cierre se ancla al fin del
  /// día local de `now`. Hora exacta 23:59:59.999.
  static DateTime calendarFallbackCloseAt(DateTime now) {
    return DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
  }

  // ─── Cierre esperado del ciclo ───────────────────────────────────────────

  /// Calcula el momento esperado de cierre del ciclo abierto.
  ///
  /// El cierre esperado = `expectedWindowCloseTime` (el momento en que
  /// el usuario debería cerrar su ventana de alimentación según su
  /// protocolo). En la práctica el ciclo se cierra cuando el usuario
  /// inicia el próximo ayuno, lo cual debería ser cercano al cierre de
  /// la ventana.
  ///
  /// Para usuarios calendáricos retorna el `calendarFallbackCloseAt`.
  ///
  /// Retorna null si no hay información suficiente para calcular.
  static DateTime? expectedCloseAt({
    required MetabolicCycle openCycle,
    required DateTime? expectedWindowCloseTime,
    required DateTime now,
  }) {
    if (useCalendarFallback(openCycle.fastingProtocol)) {
      return calendarFallbackCloseAt(now);
    }
    return expectedWindowCloseTime;
  }

  // ─── Trigger de cierre ───────────────────────────────────────────────────

  /// Decide si el ciclo abierto debe cerrarse dado el estado actual.
  /// Retorna la razón aplicable o null si debe seguir abierto.
  ///
  /// La función evalúa los 6 triggers documentados en §RF-149-04 en
  /// orden de prioridad:
  ///   1. protocolChanged
  ///   2. manualNextFasting
  ///   3. fallbackSleepDetected
  ///   4. fallback3hAfterWindow
  ///   5. fallbackAbsolute
  ///   6. fallbackCalendar
  ///
  /// El caller (MetabolicCycleService) es responsable de ejecutar el
  /// cierre con la razón devuelta y construir el ciclo cerrado.
  static ClosureReason? shouldClose({
    required MetabolicCycle openCycle,
    required DateTime now,
    required String currentProtocol,
    required DateTime? expectedWindowCloseTime,
    required DateTime? lastMealTime,
    required bool sleepDetectedAfterLastMeal,
    required bool newFastingStartedExplicitly,
    required DateTime? newFastingStartedAt,
  }) {
    if (openCycle.isClosed) return null; // ya cerrado, no doble cierre

    // 1. protocolChanged: el protocolo del ciclo abierto difiere del
    //    actual del usuario. El ciclo previo queda inválido.
    if (currentProtocol != openCycle.fastingProtocol) {
      return ClosureReason.protocolChanged;
    }

    // 2. manualNextFasting: el usuario explícitamente inició un nuevo
    //    ayuno Y han pasado ≥30 min desde startedAt del ciclo abierto.
    if (newFastingStartedExplicitly &&
        newFastingStartedAt != null &&
        _hasMinimumDuration(openCycle, newFastingStartedAt)) {
      return ClosureReason.manualNextFasting;
    }

    // 3. fallbackSleepDetected: sueño + ≥2h desde lastMealTime.
    if (sleepDetectedAfterLastMeal &&
        lastMealTime != null &&
        now.difference(lastMealTime) >= kSleepFallbackMinSinceMeal) {
      return ClosureReason.fallbackSleepDetected;
    }

    // 4. fallback3hAfterWindow: 3h pasadas desde expectedWindowCloseTime.
    if (expectedWindowCloseTime != null &&
        now.difference(expectedWindowCloseTime) >=
            kFallbackAfterWindowGrace) {
      return ClosureReason.fallback3hAfterWindow;
    }

    // 5. fallbackAbsolute: 28h desde startedAt sin nada.
    if (now.difference(openCycle.startedAt) >= kAbsoluteCycleLimit) {
      return ClosureReason.fallbackAbsolute;
    }

    // 6. fallbackCalendar: solo para usuarios "Ninguno". Cierre a 23:59
    //    del día local.
    if (useCalendarFallback(openCycle.fastingProtocol)) {
      final calendarClose = calendarFallbackCloseAt(now);
      if (!now.isBefore(calendarClose) ||
          (now.year != openCycle.startedAt.year ||
              now.month != openCycle.startedAt.month ||
              now.day != openCycle.startedAt.day)) {
        // El día calendárico del startedAt ya terminó.
        return ClosureReason.fallbackCalendar;
      }
    }

    return null;
  }

  // ─── Helpers privados ──────────────────────────────────────────────────────

  static bool _hasMinimumDuration(
    MetabolicCycle openCycle,
    DateTime candidateClose,
  ) {
    final duration = candidateClose.difference(openCycle.startedAt);
    return duration >= kMinCycleDurationForManualClose;
  }
}

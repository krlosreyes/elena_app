// Módulo "Tu Glucosa" — ventana de registro matutina (propuesta §6.2 y
// regla de negocio R3/R4).
//
// Mismo patrón de anclaje que
// fasting/domain/eating_window_state.dart (`EatingWindowState.compute`):
// la ventana se ancla a un EVENTO REAL (acá, que el usuario se
// despertó — `wokeUpToday`), nunca a una hora de reloj fija. Si no hay
// evento real todavía, no hay ventana que abrir (no se inventa una
// proyección, a diferencia de EatingWindowState que sí proyecta un
// fallback — acá no tiene sentido proyectar "vas a despertarte a las
// X": o hay un wakeUp real de hoy, o no hay ventana).
//
// Función pura — sin Flutter/Riverpod, testeable con DateTime
// sintéticos.

class GlucoseWindowState {
  /// true si corresponde mostrar la tarjeta/ventana de registro
  /// matutino ahora mismo.
  final bool isOpen;

  /// Motivo por el que está cerrada (para logging/tests) — null si
  /// está abierta.
  final GlucoseWindowClosedReason? closedReason;

  const GlucoseWindowState({required this.isOpen, this.closedReason});

  static const notWokenYet = GlucoseWindowState(
    isOpen: false,
    closedReason: GlucoseWindowClosedReason.notWokenYet,
  );

  /// R3: la ventana se ancla a `wokeUpToday` (evento real de sueño de
  /// hoy — `currentCycleSleepProvider.wokeUp`, mismo provider que ya
  /// usa DashboardPillarsRow). Se cierra (R3/R4) por el primero que
  /// ocurra de:
  ///   1. Ya existe una lectura en-ayunas registrada hoy (R4).
  ///   2. El usuario ya registró su primera comida del día.
  ///   3. Pasaron 4 horas desde que se despertó.
  static GlucoseWindowState compute({
    required DateTime? wokeUpToday,
    required DateTime? firstMealLoggedToday,
    required bool hasFastingReadingToday,
    required DateTime now,
  }) {
    if (wokeUpToday == null) return notWokenYet;

    if (hasFastingReadingToday) {
      return const GlucoseWindowState(
        isOpen: false,
        closedReason: GlucoseWindowClosedReason.alreadyLogged,
      );
    }

    if (firstMealLoggedToday != null &&
        firstMealLoggedToday.isAfter(wokeUpToday)) {
      return const GlucoseWindowState(
        isOpen: false,
        closedReason: GlucoseWindowClosedReason.firstMealLogged,
      );
    }

    final elapsed = now.difference(wokeUpToday);
    if (elapsed > const Duration(hours: 4)) {
      return const GlucoseWindowState(
        isOpen: false,
        closedReason: GlucoseWindowClosedReason.expired,
      );
    }

    if (elapsed.isNegative) {
      // wokeUpToday en el futuro (reloj desincronizado o dato corrupto)
      // — conservador, no abrir.
      return notWokenYet;
    }

    return const GlucoseWindowState(isOpen: true);
  }
}

enum GlucoseWindowClosedReason {
  notWokenYet,
  alreadyLogged,
  firstMealLogged,
  expired,
}

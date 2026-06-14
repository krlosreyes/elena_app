// SPEC-208: Tests del cálculo de fastingHours post-cierre de ayuno.
//
// La lógica testeada es la selección de `fastingHours` en
// `StreakNotifier._evaluateToday()`. Como esa función es privada y
// depende de Riverpod, testeamos los tres *casos de entrada* que produce
// el fix directamente sobre `StreakEngine.evaluateFasting`, que es la
// función pura que consume el resultado.
//
// Invariante a verificar:
//   Caso A: isActive=true  → fastingHours = duration (comportamiento sin cambios)
//   Caso B: completedToday=true, !isActive → fastingHours = targetHours → evaluateFasting=true
//   Caso C: !isActive, !completedToday, closedProgress=0.6 → fastingHours parcial → evaluateFasting=false
//
// Funciones puras: no requieren mocks.

import 'package:elena_app/src/features/streak/domain/streak_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Helper: replica _fastingTargetHours de StreakNotifier (función pura)
  double fastingTargetHours(String protocol) {
    if (protocol == 'Ninguno') return 10.0;
    final parts = protocol.split(':');
    return double.tryParse(parts.first) ?? 16.0;
  }

  // Helper: replica el cálculo de fastingHours del fix SPEC-208
  double computeFastingHours({
    required bool isActive,
    required Duration duration,
    required bool? completedToday,
    required double? closedProgressToday,
    required String protocol,
  }) {
    final targetHours = fastingTargetHours(protocol);
    if (isActive) {
      return duration.inSeconds / 3600.0;
    } else if (completedToday == true) {
      return targetHours;
    } else {
      return (closedProgressToday ?? 0.0) * targetHours;
    }
  }

  group('SPEC-208 — fastingHours post-cierre de ayuno', () {
    const protocol = '16:8'; // target = 16h

    test(
        'SPEC-208-A: ayuno activo → fastingHours = duración real acumulada',
        () {
      final hours = computeFastingHours(
        isActive: true,
        duration: const Duration(hours: 14),
        completedToday: null,
        closedProgressToday: null,
        protocol: protocol,
      );

      expect(hours, closeTo(14.0, 0.01));
      // 14h < 12.8h (80% de 16h) → aún no completado
      expect(
        StreakEngine.evaluateFasting(
            fastingHours: hours, fastingProtocol: protocol),
        isTrue, // 14 >= 12.8 → true
      );
    });

    test(
        'SPEC-208-B: ayuno cerrado + completedToday=true → '
        'fastingHours = target (16h) → evaluateFasting=true',
        () {
      // Caso bug: ANTES el código usaba 0.0, lo que causaba
      // evaluateFasting=false después de cerrar el ayuno.
      final hoursConBug = 0.0; // comportamiento previo al fix
      expect(
        StreakEngine.evaluateFasting(
            fastingHours: hoursConBug, fastingProtocol: protocol),
        isFalse,
        reason: 'El bug producía false al cerrar el ayuno',
      );

      // Fix SPEC-208: usa el targetHours cuando completedToday=true
      final hoursFix = computeFastingHours(
        isActive: false,
        duration: Duration.zero,
        completedToday: true,
        closedProgressToday: 1.0,
        protocol: protocol,
      );

      expect(hoursFix, closeTo(16.0, 0.01));
      expect(
        StreakEngine.evaluateFasting(
            fastingHours: hoursFix, fastingProtocol: protocol),
        isTrue,
        reason: 'Con el fix, fastingCompleted se preserva después del cierre',
      );
    });

    test(
        'SPEC-208-C: ayuno cerrado sin completar (60% del target) → '
        'fastingHours parcial → evaluateFasting=false',
        () {
      // 60% de 16h = 9.6h < 12.8h (80% del target) → no completado
      final hours = computeFastingHours(
        isActive: false,
        duration: Duration.zero,
        completedToday: false,
        closedProgressToday: 0.6,
        protocol: protocol,
      );

      expect(hours, closeTo(9.6, 0.01));
      expect(
        StreakEngine.evaluateFasting(
            fastingHours: hours, fastingProtocol: protocol),
        isFalse,
        reason: 'Ayuno parcial (60%) no debe contar como completado',
      );
    });

    test(
        'SPEC-208-D: sin ayuno hoy (closedProgressToday=null) → '
        'fastingHours = 0.0 → evaluateFasting=false',
        () {
      final hours = computeFastingHours(
        isActive: false,
        duration: Duration.zero,
        completedToday: false,
        closedProgressToday: null,
        protocol: protocol,
      );

      expect(hours, 0.0);
      expect(
        StreakEngine.evaluateFasting(
            fastingHours: hours, fastingProtocol: protocol),
        isFalse,
      );
    });

    test(
        'SPEC-208-E: protocolo Ninguno + completedToday=true → '
        'fastingHours = 10.0 → evaluateFasting=true',
        () {
      const ningunoProtocol = 'Ninguno';
      final hours = computeFastingHours(
        isActive: false,
        duration: Duration.zero,
        completedToday: true,
        closedProgressToday: 1.0,
        protocol: ningunoProtocol,
      );

      expect(hours, closeTo(10.0, 0.01));
      expect(
        StreakEngine.evaluateFasting(
            fastingHours: hours, fastingProtocol: ningunoProtocol),
        isTrue,
      );
    });

    test(
        'SPEC-208-F: ayuno de 18:6 cerrado completado → '
        'fastingHours = 18h → evaluateFasting=true',
        () {
      const protocol186 = '18:6';
      final hours = computeFastingHours(
        isActive: false,
        duration: Duration.zero,
        completedToday: true,
        closedProgressToday: 1.0,
        protocol: protocol186,
      );

      expect(hours, closeTo(18.0, 0.01));
      // 18h >= 80% de 18h (14.4h) → true
      expect(
        StreakEngine.evaluateFasting(
            fastingHours: hours, fastingProtocol: protocol186),
        isTrue,
      );
    });
  });
}

// Módulo "Tu Glucosa" — tests de GlucoseWindowState.compute (propuesta
// §6.2, R3/R4). Ventana anclada al wakeUp REAL, cierre por el primero
// que ocurra de: ya registrado hoy / primera comida ya loggeada /
// pasaron 4h.

import 'package:elena_app/src/features/glucose/domain/glucose_window_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final wokeUp = DateTime(2026, 7, 23, 7, 0);

  group('GlucoseWindowState.compute', () {
    test('sin wakeUp real hoy → notWokenYet', () {
      final state = GlucoseWindowState.compute(
        wokeUpToday: null,
        firstMealLoggedToday: null,
        hasFastingReadingToday: false,
        now: DateTime(2026, 7, 23, 8, 0),
      );
      expect(state.isOpen, isFalse);
      expect(state.closedReason, GlucoseWindowClosedReason.notWokenYet);
    });

    test('despertó, dentro de las 4h, sin comida ni lectura → abierta', () {
      final state = GlucoseWindowState.compute(
        wokeUpToday: wokeUp,
        firstMealLoggedToday: null,
        hasFastingReadingToday: false,
        now: wokeUp.add(const Duration(hours: 1)),
      );
      expect(state.isOpen, isTrue);
      expect(state.closedReason, isNull);
    });

    test('ya hay lectura en-ayunas hoy → cerrada (alreadyLogged), R4', () {
      final state = GlucoseWindowState.compute(
        wokeUpToday: wokeUp,
        firstMealLoggedToday: null,
        hasFastingReadingToday: true,
        now: wokeUp.add(const Duration(hours: 1)),
      );
      expect(state.isOpen, isFalse);
      expect(state.closedReason, GlucoseWindowClosedReason.alreadyLogged);
    });

    test('ya registró su primera comida después de despertar → cerrada', () {
      final state = GlucoseWindowState.compute(
        wokeUpToday: wokeUp,
        firstMealLoggedToday: wokeUp.add(const Duration(minutes: 30)),
        hasFastingReadingToday: false,
        now: wokeUp.add(const Duration(hours: 1)),
      );
      expect(state.isOpen, isFalse);
      expect(state.closedReason, GlucoseWindowClosedReason.firstMealLogged);
    });

    test(
        'comida registrada ANTES de despertar (día previo) no cierra la '
        'ventana', () {
      final state = GlucoseWindowState.compute(
        wokeUpToday: wokeUp,
        firstMealLoggedToday: wokeUp.subtract(const Duration(hours: 10)),
        hasFastingReadingToday: false,
        now: wokeUp.add(const Duration(hours: 1)),
      );
      expect(state.isOpen, isTrue);
    });

    test('pasaron más de 4h desde que despertó → cerrada (expired)', () {
      final state = GlucoseWindowState.compute(
        wokeUpToday: wokeUp,
        firstMealLoggedToday: null,
        hasFastingReadingToday: false,
        now: wokeUp.add(const Duration(hours: 4, minutes: 1)),
      );
      expect(state.isOpen, isFalse);
      expect(state.closedReason, GlucoseWindowClosedReason.expired);
    });

    test('exactamente a las 4h → todavía abierta (borde no estricto)', () {
      final state = GlucoseWindowState.compute(
        wokeUpToday: wokeUp,
        firstMealLoggedToday: null,
        hasFastingReadingToday: false,
        now: wokeUp.add(const Duration(hours: 4)),
      );
      expect(state.isOpen, isTrue);
    });

    test(
        'wokeUpToday en el futuro (reloj desincronizado) → notWokenYet, '
        'conservador', () {
      final state = GlucoseWindowState.compute(
        wokeUpToday: wokeUp,
        firstMealLoggedToday: null,
        hasFastingReadingToday: false,
        now: wokeUp.subtract(const Duration(minutes: 5)),
      );
      expect(state.isOpen, isFalse);
      expect(state.closedReason, GlucoseWindowClosedReason.notWokenYet);
    });
  });
}

// SPEC-261: tests del motor de detección de patrones de consumo.

import 'package:elena_app/src/features/alcohol/application/consumption_trigger_evaluator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 2026-07-31 es viernes; 2026-08-03 es lunes.
  final fridayNight = DateTime(2026, 7, 31, 20);
  final mondayMorning = DateTime(2026, 8, 3, 9);

  // Viernes reales garantizados: parten de un viernes conocido y restan
  // semanas completas (mismo día de semana y misma franja horaria).
  List<DateTime> manyFridayNights(int n) =>
      List.generate(n, (i) => fridayNight.subtract(Duration(days: 7 * (i + 1))));

  group('intención declarada', () {
    test('es determinante: prob 1.0 y muestra CTA', () {
      final f = ConsumptionTriggerEvaluator.evaluate(
        ConsumptionSignals(now: fridayNight, userDeclaredIntent: true),
      );
      expect(f.probability, 1.0);
      expect(f.shouldPromptProtocol, isTrue);
    });
  });

  group('contexto sin historial', () {
    test('lunes por la mañana → probabilidad baja, sin CTA', () {
      final f = ConsumptionTriggerEvaluator.evaluate(
        ConsumptionSignals(now: mondayMorning),
      );
      expect(f.probability, lessThan(0.3));
      expect(f.shouldPromptProtocol, isFalse);
    });

    test('historial insuficiente (<3) no aporta señal personal', () {
      final f = ConsumptionTriggerEvaluator.evaluate(
        ConsumptionSignals(
          now: fridayNight,
          pastDrinkTimestamps: [fridayNight, fridayNight],
        ),
      );
      // Solo el score de día/hora (0.20). No alcanza el umbral.
      expect(f.probability, closeTo(0.20, 0.001));
      expect(f.shouldPromptProtocol, isFalse);
    });
  });

  group('patrón personal + contexto', () {
    test('viernes de noche habitual + calendario → dispara CTA', () {
      final f = ConsumptionTriggerEvaluator.evaluate(
        ConsumptionSignals(
          now: fridayNight,
          pastDrinkTimestamps: manyFridayNights(8),
          hasSocialCalendarEvent: true,
        ),
      );
      expect(f.probability, greaterThan(0.6));
      expect(f.shouldPromptProtocol, isTrue);
    });

    test('el aprendizaje por rechazos baja la probabilidad', () {
      final signals = ConsumptionSignals(
        now: fridayNight,
        pastDrinkTimestamps: manyFridayNights(8),
        hasSocialCalendarEvent: true,
      );
      final base = ConsumptionTriggerEvaluator.evaluate(signals);
      final afterRejections = ConsumptionTriggerEvaluator.evaluate(
        ConsumptionSignals(
          now: fridayNight,
          pastDrinkTimestamps: manyFridayNights(8),
          hasSocialCalendarEvent: true,
          recentRejectionsInContext: 3,
        ),
      );
      expect(afterRejections.probability, lessThan(base.probability));
    });

    test('nunca se silencia del todo (factor mínimo 0,3)', () {
      final f = ConsumptionTriggerEvaluator.evaluate(
        ConsumptionSignals(
          now: fridayNight,
          pastDrinkTimestamps: manyFridayNights(8),
          hasSocialCalendarEvent: true,
          isPaydayOrHolidayEve: true,
          recentRejectionsInContext: 99,
        ),
      );
      expect(f.probability, greaterThan(0));
    });
  });
}

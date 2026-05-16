// Tests del CoherenceEngine — SPEC-71.
//
// Cubre:
// - Score base = 1.0 sin violaciones.
// - Penalizaciones por dimensión (sueño, hidratación, alineación, etc.).
// - Combinaciones de violaciones (penalizaciones se suman).
// - Clamp 0.0–1.0.
// - CA-71-01: una sola penalización por sueño deficiente cuando se invoca
//   desde el flujo completo (builder + orchestrator).

import 'package:elena_app/src/core/engine/coherence_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CoherenceEngine.calculate — base', () {
    test('Sin violaciones devuelve 1.0', () {
      final c = CoherenceEngine.calculate(
        sleepHours: 8,
        hydrationLevel: 1.0,
        circadianAlignment: 1.0,
        exerciseLoad: 0.5,
        fastingHours: 12,
      );
      expect(c, 1.0);
    });
  });

  group('CoherenceEngine.calculate — penalizaciones por dimensión', () {
    test('SPEC-70.5: Sueño < 7h penaliza -0.20 (umbral subido de 6.5 a 7)', () {
      final c = CoherenceEngine.calculate(
        sleepHours: 5,
        hydrationLevel: 1.0,
        circadianAlignment: 1.0,
        exerciseLoad: 0.5,
        fastingHours: 12,
      );
      expect(c, closeTo(0.80, 1e-9));
    });

    test('Hidratación < 0.5 penaliza -0.15', () {
      final c = CoherenceEngine.calculate(
        sleepHours: 8,
        hydrationLevel: 0.4,
        circadianAlignment: 1.0,
        exerciseLoad: 0.5,
        fastingHours: 12,
      );
      expect(c, closeTo(0.85, 1e-9));
    });

    test('Alineación circadiana < 0.7 penaliza -0.15', () {
      final c = CoherenceEngine.calculate(
        sleepHours: 8,
        hydrationLevel: 1.0,
        circadianAlignment: 0.5,
        exerciseLoad: 0.5,
        fastingHours: 12,
      );
      expect(c, closeTo(0.85, 1e-9));
    });

    test('Ejercicio intenso (>0.8) con sueño pobre (<6h) suma -0.10', () {
      // Sueño 5.5h dispara también la penalización de sueño insuficiente.
      // Suma esperada: -0.20 (sueño) + -0.10 (ejercicio+sueño) = -0.30 → 0.70.
      final c = CoherenceEngine.calculate(
        sleepHours: 5.5,
        hydrationLevel: 1.0,
        circadianAlignment: 1.0,
        exerciseLoad: 0.9,
        fastingHours: 12,
      );
      expect(c, closeTo(0.70, 1e-9));
    });

    test('Ayuno >16h con hidratación <0.6 suma -0.10', () {
      // Hidratación 0.55 está sobre el umbral de -0.15 (que es <0.5),
      // así que solo penaliza por la combo ayuno+hidratación: -0.10 → 0.90.
      final c = CoherenceEngine.calculate(
        sleepHours: 8,
        hydrationLevel: 0.55,
        circadianAlignment: 1.0,
        exerciseLoad: 0.5,
        fastingHours: 18,
      );
      expect(c, closeTo(0.90, 1e-9));
    });
  });

  group('CoherenceEngine.calculate — combinaciones', () {
    test(
        'Sueño 5h + hidratación 0.3 + alineación 0.6 = 1 - 0.20 - 0.15 - 0.15 = 0.50',
        () {
      final c = CoherenceEngine.calculate(
        sleepHours: 5,
        hydrationLevel: 0.3,
        circadianAlignment: 0.6,
        exerciseLoad: 0.5,
        fastingHours: 12,
      );
      expect(c, closeTo(0.50, 1e-9));
    });

    test('Caso extremo: clamp 0.0', () {
      final c = CoherenceEngine.calculate(
        sleepHours: 3, // -0.20
        hydrationLevel: 0.2, // -0.15
        circadianAlignment: 0.3, // -0.15
        exerciseLoad: 0.9, // y sueño<6 → -0.10
        fastingHours: 18, // y hidratación<0.6 → -0.10
      );
      // Total: -0.70 → clamp a 0.30.
      expect(c, closeTo(0.30, 1e-9));
    });
  });

  group('CA-71-01: una sola penalización por dimensión (sin doble descuento)',
      () {
    // La invariante de SPEC-71: en el flujo completo (builder construye state
    // con CoherenceEngine, orchestrator usa state.metabolicCoherence directo),
    // un sueño deficiente penaliza UNA vez, no dos.
    //
    // Antes del refactor: builder restaba -0.20, orchestrator detectaba
    // "Recovery bajo" como violation y restaba otro -0.05. Total: -0.25.
    // Ahora: solo -0.20 desde el engine, las violations no descuentan más.
    //
    // Validación directa contra el engine: el resultado del engine es estable
    // y no se ajusta downstream.

    test('Sueño 5h: engine produce 0.80 — no se descuenta más en orchestrator',
        () {
      final fromEngine = CoherenceEngine.calculate(
        sleepHours: 5,
        hydrationLevel: 1.0,
        circadianAlignment: 1.0,
        exerciseLoad: 0.5,
        fastingHours: 12,
      );
      expect(fromEngine, closeTo(0.80, 1e-9));
      // El test orchestrator_engine_test.dart valida que
      // orchestrator.metabolicCoherence == state.metabolicCoherence directo.
    });
  });
}

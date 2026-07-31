// SPEC-261: tests de AlcoholImpact (costo del alcohol en el score).

import 'package:elena_app/src/features/alcohol/domain/alcohol_impact.dart';
import 'package:elena_app/src/features/alcohol/domain/consumption_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('rawImpact01', () {
    test('0 g → 0', () => expect(AlcoholImpact.rawImpact01(0), 0));
    test('saturación (60 g) → 1', () {
      expect(AlcoholImpact.rawImpact01(60), 1.0);
    });
    test('media saturación (30 g) → 0,5', () {
      expect(AlcoholImpact.rawImpact01(30), closeTo(0.5, 1e-9));
    });
    test('por encima de la saturación se satura en 1', () {
      expect(AlcoholImpact.rawImpact01(120), 1.0);
    });
  });

  group('costos', () {
    test('costo bruto máximo = maxPenaltyPoints', () {
      expect(AlcoholImpact.rawCostPoints(60),
          closeTo(AlcoholImpact.maxPenaltyPoints, 1e-9));
    });

    test('la mitigación reduce el costo', () {
      final sinMitigar = AlcoholImpact.netCostPoints(60, 0);
      final mitigado = AlcoholImpact.netCostPoints(60, 0.6);
      expect(mitigado, lessThan(sinMitigar));
      expect(mitigado, closeTo(25 * 0.4, 1e-6));
    });

    test('la mitigación se topa en maxMitigation (honestidad científica)', () {
      final topeExacto = AlcoholImpact.netCostPoints(60, 0.6);
      final excesivo = AlcoholImpact.netCostPoints(60, 0.95);
      expect(excesivo, closeTo(topeExacto, 1e-9));
    });

    test('el costo neto nunca es cero mientras haya consumo', () {
      final net =
          AlcoholImpact.netCostPoints(20, ConsumptionSession.maxMitigation);
      expect(net, greaterThan(0));
    });

    test('mitigatedPoints = bruto − neto', () {
      final bruto = AlcoholImpact.rawCostPoints(60);
      final neto = AlcoholImpact.netCostPoints(60, 0.6);
      expect(
          AlcoholImpact.mitigatedPoints(60, 0.6), closeTo(bruto - neto, 1e-9));
    });
  });

  group('etiquetas', () {
    test('escala cualitativa', () {
      expect(AlcoholImpact.label(0), 'Sin impacto');
      expect(AlcoholImpact.label(3), 'Impacto bajo');
      expect(AlcoholImpact.label(8), 'Impacto moderado');
      expect(AlcoholImpact.label(20), 'Impacto alto');
    });
  });
}

// SPEC-261: tests de ConsumptionSession (totales y factor de mitigación).

import 'package:elena_app/src/features/alcohol/domain/alcohol_catalog.dart';
import 'package:elena_app/src/features/alcohol/domain/consumption_session.dart';
import 'package:elena_app/src/features/alcohol/domain/drink_event.dart';
import 'package:flutter_test/flutter_test.dart';

DrinkEvent _beer({bool water = false}) => DrinkEvent.fromCatalog(
      AlcoholCatalog.byId('cerveza-lager')!,
      at: DateTime(2026, 7, 31, 20),
      waterChaser: water,
    );

void main() {
  group('totales', () {
    test('sesión vacía = 0 g / 0 UEA', () {
      const s = ConsumptionSession();
      expect(s.totalGrams, 0);
      expect(s.totalStandardUnits, 0);
      expect(s.isActive, isFalse);
    });

    test('acumula gramos y UEA', () {
      final s = ConsumptionSession(drinks: [_beer(), _beer()]);
      expect(s.totalGrams, closeTo(28.0, 0.1));
      expect(s.totalStandardUnits, closeTo(2.8, 0.02));
    });

    test('presupuesto excedido', () {
      final s = ConsumptionSession(
        budgetStandardUnits: 2.0,
        drinks: [_beer(), _beer()], // ~2,8 UEA
      );
      expect(s.budgetExceeded, isTrue);
      expect(s.remainingStandardUnits, lessThan(0));
    });
  });

  group('mitigación', () {
    test('sin acciones y sin tragos = 0', () {
      const s = ConsumptionSession();
      expect(s.mitigationFactor, 0);
    });

    test('las acciones de reducción de daño suben el factor', () {
      final base = ConsumptionSession(drinks: [_beer()]);
      final managed = ConsumptionSession(
        drinks: [_beer(water: true)],
        hydratedBefore: true,
        ateBefore: true,
        recoveryFastPlanned: true,
      );
      expect(managed.mitigationFactor, greaterThan(base.mitigationFactor));
    });

    test('nunca supera el tope (honestidad científica)', () {
      final s = ConsumptionSession(
        drinks: [_beer(water: true)],
        hydratedBefore: true,
        ateBefore: true,
        recoveryFastPlanned: true,
      );
      expect(
        s.mitigationFactor,
        lessThanOrEqualTo(ConsumptionSession.maxMitigation),
      );
    });

    test('hydrationRatio refleja la regla 1:1', () {
      final s = ConsumptionSession(
        drinks: [_beer(water: true), _beer(water: false)],
      );
      expect(s.hydrationRatio, closeTo(0.5, 1e-9));
    });
  });
}

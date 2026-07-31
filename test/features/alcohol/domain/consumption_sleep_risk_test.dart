// SPEC-261.2: tests de lastDrinkAt y sleepRisk en ConsumptionSession.

import 'package:elena_app/src/features/alcohol/domain/alcohol_catalog.dart';
import 'package:elena_app/src/features/alcohol/domain/consumption_session.dart';
import 'package:elena_app/src/features/alcohol/domain/drink_event.dart';
import 'package:flutter_test/flutter_test.dart';

DrinkEvent _drinkAt(DateTime at) => DrinkEvent.fromCatalog(
      AlcoholCatalog.byId('cerveza-lager')!,
      at: at,
    );

void main() {
  final bedtime = DateTime(2026, 8, 1, 0, 0); // medianoche
  final early = DateTime(2026, 7, 31, 20, 0); // 4 h antes de dormir
  final late = DateTime(2026, 7, 31, 23, 0); // 1 h antes de dormir

  group('lastDrinkAt', () {
    test('null sin tragos', () {
      expect(const ConsumptionSession().lastDrinkAt, isNull);
    });

    test('devuelve el timestamp más reciente', () {
      final s = ConsumptionSession(drinks: [_drinkAt(early), _drinkAt(late)]);
      expect(s.lastDrinkAt, late);
    });
  });

  group('sleepRisk', () {
    test('none sin hora de dormir', () {
      final s = ConsumptionSession(drinks: [_drinkAt(late)]);
      expect(s.sleepRisk, SleepRisk.none);
    });

    test('none sin tragos', () {
      final s = ConsumptionSession(bedtime: bedtime);
      expect(s.sleepRisk, SleepRisk.none);
    });

    test('low cuando el último trago deja margen (>= 3 h antes)', () {
      final s = ConsumptionSession(drinks: [_drinkAt(early)], bedtime: bedtime);
      expect(s.sleepRisk, SleepRisk.low);
    });

    test('high cuando el último trago es muy cerca de dormir', () {
      final s = ConsumptionSession(drinks: [_drinkAt(late)], bedtime: bedtime);
      expect(s.sleepRisk, SleepRisk.high);
    });

    test('el trago tardío domina aunque haya uno temprano', () {
      final s = ConsumptionSession(
        drinks: [_drinkAt(early), _drinkAt(late)],
        bedtime: bedtime,
      );
      expect(s.sleepRisk, SleepRisk.high);
    });
  });
}

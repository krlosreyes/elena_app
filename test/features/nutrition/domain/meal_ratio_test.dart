// Tests de MealRatio — SPEC-137.
//
// Cubre la API del enum y su contrato con:
// - El cálculo del Cociente A (`isADominant`).
// - La UI (`label`, `aFraction`).
// - La persistencia Firestore (`persistenceKey` ↔ `fromPersistenceKey`).
//
// Si alguno de estos tests cambia, hay que verificar el impacto en:
// - `cociente_a_service.dart` (depende de `isADominant`).
// - `nutrition_log_mapper.dart` (depende de `persistenceKey`).
// - `plate_ratio_sheet.dart` (depende de `label` y `aFraction`).

import 'package:elena_app/src/features/nutrition/domain/meal_ratio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MealRatio.values', () {
    test('expone exactamente las 5 posiciones canónicas', () {
      expect(MealRatio.values, hasLength(5));
      expect(
          MealRatio.values,
          containsAll([
            MealRatio.allA,
            MealRatio.a3e1,
            MealRatio.a2e1,
            MealRatio.a1e1,
            MealRatio.allE,
          ]));
    });

    test('el orden de declaración es Todo A → Todo E (importante para UI)', () {
      expect(MealRatio.values.first, MealRatio.allA);
      expect(MealRatio.values.last, MealRatio.allE);
    });
  });

  group('isADominant', () {
    test('allA, a3e1, a2e1 son A-dominantes', () {
      expect(MealRatio.allA.isADominant, isTrue);
      expect(MealRatio.a3e1.isADominant, isTrue);
      expect(MealRatio.a2e1.isADominant, isTrue);
    });

    test('a1e1, allE NO son A-dominantes', () {
      expect(MealRatio.a1e1.isADominant, isFalse);
      expect(MealRatio.allE.isADominant, isFalse);
    });
  });

  group('aFraction', () {
    test('retorna los valores canónicos por proporción', () {
      expect(MealRatio.allA.aFraction, 1.0);
      expect(MealRatio.a3e1.aFraction, 0.75);
      expect(MealRatio.a2e1.aFraction, 0.67);
      expect(MealRatio.a1e1.aFraction, 0.50);
      expect(MealRatio.allE.aFraction, 0.0);
    });

    test('todas las fracciones están en [0.0, 1.0]', () {
      for (final ratio in MealRatio.values) {
        expect(ratio.aFraction, inInclusiveRange(0.0, 1.0));
      }
    });

    test('la fracción decrece estrictamente de allA a allE', () {
      final fractions = MealRatio.values.map((r) => r.aFraction).toList();
      for (var i = 0; i < fractions.length - 1; i++) {
        expect(
          fractions[i],
          greaterThan(fractions[i + 1]),
          reason: 'fracciones deben decrecer estrictamente: '
              '${MealRatio.values[i]} vs ${MealRatio.values[i + 1]}',
        );
      }
    });
  });

  group('label', () {
    test('retorna el label LatAm canónico', () {
      expect(MealRatio.allA.label, 'Todo A');
      expect(MealRatio.a3e1.label, '3 a 1');
      expect(MealRatio.a2e1.label, '2 a 1');
      expect(MealRatio.a1e1.label, '1 a 1');
      expect(MealRatio.allE.label, 'Todo E');
    });

    test('todos los labels son no vacíos', () {
      for (final ratio in MealRatio.values) {
        expect(ratio.label, isNotEmpty);
      }
    });
  });

  group('persistenceKey ↔ fromPersistenceKey (round-trip)', () {
    test('cada MealRatio round-trippea via persistenceKey', () {
      for (final ratio in MealRatio.values) {
        final key = ratio.persistenceKey;
        final parsed = MealRatio.fromPersistenceKey(key);
        expect(
          parsed,
          ratio,
          reason: 'round-trip falla para $ratio (key="$key")',
        );
      }
    });

    test('persistenceKey usa los strings literales esperados', () {
      expect(MealRatio.allA.persistenceKey, 'allA');
      expect(MealRatio.a3e1.persistenceKey, 'a3e1');
      expect(MealRatio.a2e1.persistenceKey, 'a2e1');
      expect(MealRatio.a1e1.persistenceKey, 'a1e1');
      expect(MealRatio.allE.persistenceKey, 'allE');
    });
  });

  group('fromPersistenceKey — robustez ante claves inválidas', () {
    test('null cae a a2e1 (default seguro)', () {
      expect(MealRatio.fromPersistenceKey(null), MealRatio.a2e1);
    });

    test('string vacío cae a a2e1', () {
      expect(MealRatio.fromPersistenceKey(''), MealRatio.a2e1);
    });

    test('clave desconocida cae a a2e1', () {
      expect(MealRatio.fromPersistenceKey('foo'), MealRatio.a2e1);
      expect(MealRatio.fromPersistenceKey('ALLA'), MealRatio.a2e1);
      expect(MealRatio.fromPersistenceKey('a4e1'), MealRatio.a2e1);
    });

    test('logs históricos pre-SPEC-137 (sin campo) caen a a2e1', () {
      // Simulando el caso "doc Firestore sin campo ratio"
      // — el mapper llamará a fromPersistenceKey(null).
      const String? legacyValue = null;
      expect(MealRatio.fromPersistenceKey(legacyValue), MealRatio.a2e1);
    });
  });
}

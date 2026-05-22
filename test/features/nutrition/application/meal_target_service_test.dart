// Tests del MealTargetService — SPEC-137 §RF-137-03.
//
// Validan la tabla canónica de inferencia comidas-por-protocolo:
// Ninguno → 3 + snack | 16:8 → 2 + snack | 18:6 → 2 | 20:4 → 1.

import 'package:elena_app/src/features/nutrition/application/meal_target_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = MealTargetService();

  group('targetForProtocol — tabla canónica (8 protocolos SPEC-98)', () {
    test('"Ninguno" → 3 comidas + snack permitido', () {
      final t = service.targetForProtocol('Ninguno');
      expect(t.meals, 3);
      expect(t.allowsSnack, isTrue);
    });

    test('"12:12" → 3 comidas + snack permitido (12h cómoda)', () {
      final t = service.targetForProtocol('12:12');
      expect(t.meals, 3);
      expect(t.allowsSnack, isTrue);
    });

    test('"14:10" → 2 comidas + snack permitido (10h soporta snack)', () {
      final t = service.targetForProtocol('14:10');
      expect(t.meals, 2);
      expect(t.allowsSnack, isTrue);
    });

    test('"16:8" → 2 comidas + snack permitido', () {
      final t = service.targetForProtocol('16:8');
      expect(t.meals, 2);
      expect(t.allowsSnack, isTrue);
    });

    test('"18:6" → 2 comidas SIN snack', () {
      final t = service.targetForProtocol('18:6');
      expect(t.meals, 2);
      expect(t.allowsSnack, isFalse);
    });

    test('"20:4" → 1 comida SIN snack (OMAD modificado)', () {
      final t = service.targetForProtocol('20:4');
      expect(t.meals, 1);
      expect(t.allowsSnack, isFalse);
    });

    test('"22:2" → 1 comida SIN snack (ventana 2h, solo comida principal)',
        () {
      final t = service.targetForProtocol('22:2');
      expect(t.meals, 1);
      expect(t.allowsSnack, isFalse);
    });

    test('"OMAD" → 1 comida SIN snack (One Meal A Day)', () {
      final t = service.targetForProtocol('OMAD');
      expect(t.meals, 1);
      expect(t.allowsSnack, isFalse);
    });
  });

  group('targetForProtocol — robustez ante valores fuera del catálogo', () {
    test('null cae al fallback (3 + snack)', () {
      final t = service.targetForProtocol(null);
      expect(t.meals, 3);
      expect(t.allowsSnack, isTrue);
    });

    test('string vacío cae al fallback', () {
      final t = service.targetForProtocol('');
      expect(t.meals, 3);
      expect(t.allowsSnack, isTrue);
    });

    test('protocolo desconocido cae al fallback', () {
      final t = service.targetForProtocol('14:10');
      expect(t.meals, 3);
      expect(t.allowsSnack, isTrue);
    });

    test('case sensitivity — "16:8" != "16:08"', () {
      // Documenta el comportamiento actual: NO normalizamos strings.
      // Si en el futuro queremos ser laxos, se ajusta en una sub-SPEC.
      final t = service.targetForProtocol('16:08');
      expect(t.meals, 3,
          reason: 'protocolos con formato distinto al canónico caen al '
              'fallback hasta que una SPEC futura introduzca normalización');
    });
  });

  group('knownProtocols', () {
    test('expone los 8 valores canónicos de SPEC-98', () {
      expect(service.knownProtocols, hasLength(8));
      expect(service.knownProtocols, containsAll([
        'Ninguno',
        '12:12',
        '14:10',
        '16:8',
        '18:6',
        '20:4',
        '22:2',
        'OMAD',
      ]));
    });

    test('todos los conocidos retornan un MealTarget válido', () {
      for (final p in service.knownProtocols) {
        final t = service.targetForProtocol(p);
        expect(t.meals, greaterThan(0),
            reason: '$p debe tener al menos 1 comida');
        expect(t.meals, lessThanOrEqualTo(4),
            reason: '$p no puede tener más de 4 comidas razonables');
      }
    });

    test('progresión coherente: menos ventana → menos comidas', () {
      final p12 = service.targetForProtocol('12:12').meals;
      final p14 = service.targetForProtocol('14:10').meals;
      final p16 = service.targetForProtocol('16:8').meals;
      final p18 = service.targetForProtocol('18:6').meals;
      final p20 = service.targetForProtocol('20:4').meals;
      final p22 = service.targetForProtocol('22:2').meals;
      final omad = service.targetForProtocol('OMAD').meals;

      expect(p12, greaterThanOrEqualTo(p14),
          reason: '12:12 (12h) ≥ 14:10 (10h)');
      expect(p14, greaterThanOrEqualTo(p16),
          reason: '14:10 (10h) ≥ 16:8 (8h)');
      expect(p16, greaterThanOrEqualTo(p18),
          reason: '16:8 (8h) ≥ 18:6 (6h)');
      expect(p18, greaterThanOrEqualTo(p20),
          reason: '18:6 (6h) ≥ 20:4 (4h)');
      expect(p20, greaterThanOrEqualTo(p22),
          reason: '20:4 (4h) ≥ 22:2 (2h)');
      expect(p22, greaterThanOrEqualTo(omad),
          reason: '22:2 (2h) ≥ OMAD (~1h)');
    });

    test('progresión del snack: ventanas cortas no admiten snack', () {
      // Snacks permitidos solo en ventanas amplias (≥ 8h).
      expect(service.targetForProtocol('Ninguno').allowsSnack, isTrue);
      expect(service.targetForProtocol('12:12').allowsSnack, isTrue);
      expect(service.targetForProtocol('14:10').allowsSnack, isTrue);
      expect(service.targetForProtocol('16:8').allowsSnack, isTrue);
      expect(service.targetForProtocol('18:6').allowsSnack, isFalse);
      expect(service.targetForProtocol('20:4').allowsSnack, isFalse);
      expect(service.targetForProtocol('22:2').allowsSnack, isFalse);
      expect(service.targetForProtocol('OMAD').allowsSnack, isFalse);
    });
  });

  group('MealTarget — equality', () {
    test('mismo contenido es igual', () {
      const a = MealTarget(meals: 2, allowsSnack: true);
      const b = MealTarget(meals: 2, allowsSnack: true);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('contenido distinto no es igual', () {
      const a = MealTarget(meals: 2, allowsSnack: true);
      const b = MealTarget(meals: 2, allowsSnack: false);
      const c = MealTarget(meals: 3, allowsSnack: true);
      expect(a, isNot(b));
      expect(a, isNot(c));
    });
  });
}

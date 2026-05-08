// SPEC-62: tests del sealed type ValidationError.

import 'package:elena_app/src/core/errors/validation_error.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SPEC-62: jerarquía y exhaustividad', () {
    test('Todos los casos implementan Exception (catch genérico funciona)', () {
      final List<ValidationError> cases = [
        const NegativeValue(field: 'x', value: -1),
        const OutOfRange(field: 'x', value: 0, min: 1, max: 5),
        const EmptyField(field: 'x'),
        const InvalidValue(field: 'x', value: 'foo'),
        FutureTimestamp(
          field: 'x',
          value: DateTime(2099),
          toleranceFromNow: const Duration(seconds: 60),
        ),
      ];
      for (final e in cases) {
        expect(e, isA<Exception>());
        expect(e, isA<ValidationError>());
      }
    });

    test('switch sobre sealed obliga a cubrir todos los casos', () {
      // Si un día se añade un caso nuevo a la jerarquía, este switch
      // dejará de compilar — exactamente la propiedad que SPEC-62
      // promete.
      String classify(ValidationError e) => switch (e) {
            NegativeValue() => 'negative',
            OutOfRange() => 'range',
            EmptyField() => 'empty',
            InvalidValue() => 'invalid',
            FutureTimestamp() => 'future',
          };

      expect(
        classify(const NegativeValue(field: 'x', value: -1)),
        'negative',
      );
      expect(
        classify(const OutOfRange(field: 'x', value: 0, min: 1, max: 5)),
        'range',
      );
    });
  });

  group('SPEC-62: NegativeValue', () {
    test('Captura field y value', () {
      const e = NegativeValue(field: 'calories', value: -10);
      expect(e.fieldName, 'calories');
      expect(e.value, -10);
    });

    test('defaultMessage menciona >= 0', () {
      const e = NegativeValue(field: 'calories', value: -10);
      expect(e.defaultMessage, contains('>= 0'));
      expect(e.defaultMessage, contains('-10'));
      expect(e.defaultMessage, contains('calories'));
    });

    test('toString incluye el tipo y el field', () {
      const e = NegativeValue(field: 'calories', value: -10);
      expect(e.toString(), contains('ValidationError'));
      expect(e.toString(), contains('calories'));
    });
  });

  group('SPEC-62: OutOfRange', () {
    test('Captura value, min, max', () {
      const e = OutOfRange(field: 'gi', value: 120, min: 0, max: 100);
      expect(e.value, 120);
      expect(e.min, 0);
      expect(e.max, 100);
    });

    test('defaultMessage menciona el rango', () {
      const e = OutOfRange(field: 'gi', value: 120, min: 0, max: 100);
      expect(e.defaultMessage, contains('[0, 100]'));
      expect(e.defaultMessage, contains('120'));
    });
  });

  group('SPEC-62: EmptyField', () {
    test('defaultMessage indica vacío', () {
      const e = EmptyField(field: 'id');
      expect(e.defaultMessage, contains('vacío'));
      expect(e.defaultMessage, contains('id'));
    });
  });

  group('SPEC-62: InvalidValue', () {
    test('Sin expectedOneOf solo reporta valor', () {
      const e = InvalidValue(field: 'label', value: 'Brunch');
      expect(e.defaultMessage, contains('"Brunch"'));
      expect(e.defaultMessage, isNot(contains('Esperado')));
    });

    test('Con expectedOneOf incluye el listado', () {
      const e = InvalidValue(
        field: 'label',
        value: 'Brunch',
        expectedOneOf: ['Desayuno', 'Almuerzo', 'Cena'],
      );
      expect(e.defaultMessage, contains('"Brunch"'));
      expect(e.defaultMessage, contains('Esperado'));
      expect(e.defaultMessage, contains('Desayuno'));
      expect(e.defaultMessage, contains('Almuerzo'));
      expect(e.defaultMessage, contains('Cena'));
    });

    test('Lista vacía cae al mensaje básico', () {
      const e = InvalidValue(field: 'label', value: 'X', expectedOneOf: []);
      expect(e.defaultMessage, isNot(contains('Esperado')));
    });
  });

  group('SPEC-62: FutureTimestamp', () {
    test('defaultMessage incluye iso8601 y tolerancia en segundos', () {
      final ts = DateTime.utc(2099, 1, 1, 12, 0, 0);
      final e = FutureTimestamp(
        field: 'timestamp',
        value: ts,
        toleranceFromNow: const Duration(seconds: 60),
      );
      expect(e.defaultMessage, contains(ts.toIso8601String()));
      expect(e.defaultMessage, contains('60s'));
    });
  });
}

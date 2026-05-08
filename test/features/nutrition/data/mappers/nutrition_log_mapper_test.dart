// Tests del NutritionLogMapper — SPEC-63 + SPEC-64 + SPEC-62 (errores tipados).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elena_app/src/core/errors/validation_error.dart';
import 'package:elena_app/src/features/nutrition/data/mappers/nutrition_log_mapper.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_log.dart';
import 'package:flutter_test/flutter_test.dart';

NutritionLog _log({
  String id = 'abc-123',
  DateTime? timestamp,
  String label = 'Almuerzo',
  bool withinWindow = true,
  double? calories,
  double? protein,
  double? carbs,
  double? fat,
  double? fiber,
  int? glycemicIndex,
  NutritionLogSource source = NutritionLogSource.userInput,
}) =>
    NutritionLog(
      id: id,
      timestamp: timestamp ?? DateTime(2026, 5, 1, 13),
      label: label,
      withinCircadianWindow: withinWindow,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
      glycemicIndex: glycemicIndex,
      source: source,
    );

void main() {
  const mapper = NutritionLogMapper();

  group('toMap (SPEC-63 base)', () {
    test('serializa todos los campos canónicos', () {
      final log = _log();
      final map = mapper.toMap(log);
      expect(map['id'], 'abc-123');
      expect(map['timestamp'], isA<Timestamp>());
      expect(map['label'], 'Almuerzo');
      expect(map['withinCircadianWindow'], true);
      expect(map['source'], 'userInput');
    });

    test('rechaza id vacío con EmptyField (SPEC-62)', () {
      expect(
        () => mapper.toMap(_log(id: '')),
        throwsA(isA<EmptyField>()
            .having((e) => e.fieldName, 'fieldName', 'NutritionLog.id')),
      );
    });

    test('rechaza label fuera del set con InvalidValue (SPEC-62)', () {
      expect(
        () => mapper.toMap(_log(label: 'Brunch')),
        throwsA(isA<InvalidValue>()
            .having((e) => e.fieldName, 'fieldName', 'NutritionLog.label')
            .having((e) => e.value, 'value', 'Brunch')),
      );
    });

    test('rechaza timestamp >60s en el futuro con FutureTimestamp (SPEC-62)',
        () {
      final far = DateTime.now().add(const Duration(minutes: 5));
      expect(
        () => mapper.toMap(_log(timestamp: far)),
        throwsA(isA<FutureTimestamp>()
            .having((e) => e.fieldName, 'fieldName', 'NutritionLog.timestamp')
            .having((e) => e.toleranceFromNow.inSeconds,
                'tolerance secs', 60)),
      );
    });
  });

  group('toMap con macros (SPEC-64)', () {
    test('persiste macros cuando están presentes', () {
      final log = _log(
        calories: 320,
        protein: 25,
        carbs: 40,
        fat: 8,
        fiber: 5,
        glycemicIndex: 50,
        source: NutritionLogSource.catalog,
      );
      final map = mapper.toMap(log);
      expect(map['calories'], 320);
      expect(map['protein'], 25);
      expect(map['carbs'], 40);
      expect(map['fat'], 8);
      expect(map['fiber'], 5);
      expect(map['glycemicIndex'], 50);
      expect(map['source'], 'catalog');
    });

    test('OMITE macros cuando son null (preserva semántica "no medido")', () {
      final log = _log();
      final map = mapper.toMap(log);
      expect(map.containsKey('calories'), isFalse);
      expect(map.containsKey('protein'), isFalse);
      expect(map.containsKey('carbs'), isFalse);
      expect(map.containsKey('fat'), isFalse);
      expect(map.containsKey('fiber'), isFalse);
      expect(map.containsKey('glycemicIndex'), isFalse);
    });

    test('persiste calories=0 cuando se midió explícitamente como 0', () {
      // Caso: el usuario registró un caldo claro con casi cero calorías.
      // Debe distinguirse de "no se midió".
      final log = _log(calories: 0, protein: 0, carbs: 0, fat: 0);
      final map = mapper.toMap(log);
      expect(map['calories'], 0);
      expect(map['protein'], 0);
    });
  });

  group('NutritionLog constructor — invariantes (SPEC-64)', () {
    test('rechaza calories negativas con NegativeValue (SPEC-62)', () {
      expect(
        () => _log(calories: -10),
        throwsA(isA<NegativeValue>()
            .having((e) => e.fieldName, 'fieldName', 'NutritionLog.calories')),
      );
    });

    test('rechaza protein negativa con NegativeValue (SPEC-62)', () {
      expect(
        () => _log(protein: -1),
        throwsA(isA<NegativeValue>()
            .having((e) => e.fieldName, 'fieldName', 'NutritionLog.protein')),
      );
    });

    test('rechaza glycemicIndex fuera de rango con OutOfRange (SPEC-62)', () {
      expect(
        () => _log(glycemicIndex: -5),
        throwsA(isA<OutOfRange>()
            .having((e) => e.min, 'min', 0)
            .having((e) => e.max, 'max', 100)),
      );
      expect(() => _log(glycemicIndex: 120), throwsA(isA<OutOfRange>()));
    });

    test('acepta glycemicIndex en frontera (0 y 100)', () {
      expect(() => _log(glycemicIndex: 0), returnsNormally);
      expect(() => _log(glycemicIndex: 100), returnsNormally);
    });
  });

  group('hasMacros (SPEC-64)', () {
    test('false cuando calories es null', () {
      expect(_log().hasMacros, isFalse);
    });

    test('true cuando calories tiene valor (incluso 0)', () {
      expect(_log(calories: 100).hasMacros, isTrue);
      expect(_log(calories: 0).hasMacros, isTrue);
    });
  });

  group('fromMap', () {
    test('Timestamp nativo se parsea', () {
      final ts = Timestamp.fromDate(DateTime(2026, 5, 1, 13));
      final log = mapper.fromMap(
        {
          'id': 'xyz',
          'timestamp': ts,
          'label': 'Cena',
          'withinCircadianWindow': false,
          'calories': 400,
          'protein': 30,
        },
        docId: 'fallback',
      );
      expect(log.id, 'xyz');
      expect(log.label, 'Cena');
      expect(log.calories, 400);
      expect(log.protein, 30);
      expect(log.carbs, isNull); // no estaba en payload
    });

    test('logs antiguos (sin macros) se leen como null', () {
      // Backward compat: docs escritos antes de SPEC-64 NO tienen macros.
      final log = mapper.fromMap(
        {
          'id': 'old',
          'timestamp': Timestamp.fromDate(DateTime(2026, 5, 1, 8, 0)),
          'label': 'Desayuno',
          'withinCircadianWindow': true,
        },
        docId: 'fallback',
      );
      expect(log.calories, isNull);
      expect(log.protein, isNull);
      expect(log.hasMacros, isFalse);
    });

    test('source desconocida default a userInput', () {
      final log = mapper.fromMap(
        {
          'id': 'x',
          'timestamp': Timestamp.fromDate(DateTime(2026, 5, 1, 13)),
          'label': 'Almuerzo',
          'withinCircadianWindow': true,
          'source': 'something_unexpected',
        },
        docId: 'x',
      );
      expect(log.source, NutritionLogSource.userInput);
    });

    test('numeric values aceptan int o double indistintamente', () {
      // Firestore puede devolver int para valores enteros.
      final log = mapper.fromMap(
        {
          'id': 'x',
          'timestamp': Timestamp.fromDate(DateTime(2026, 5, 1, 13)),
          'label': 'Cena',
          'withinCircadianWindow': true,
          'calories': 400, // int
          'protein': 30.5, // double
        },
        docId: 'x',
      );
      expect(log.calories, 400.0);
      expect(log.protein, 30.5);
    });
  });

  group('round-trip con macros', () {
    test('toMap → fromMap preserva todos los campos', () {
      final original = _log(
        id: 'rt-1',
        timestamp: DateTime(2026, 5, 1, 19, 15),
        label: 'Cena',
        withinWindow: false,
        calories: 550,
        protein: 35,
        carbs: 60,
        fat: 18,
        fiber: 6,
        glycemicIndex: 45,
        source: NutritionLogSource.catalog,
      );
      final map = mapper.toMap(original);
      final recovered = mapper.fromMap(map, docId: 'unused');
      expect(recovered.id, original.id);
      expect(recovered.timestamp, original.timestamp);
      expect(recovered.calories, original.calories);
      expect(recovered.protein, original.protein);
      expect(recovered.carbs, original.carbs);
      expect(recovered.fat, original.fat);
      expect(recovered.fiber, original.fiber);
      expect(recovered.glycemicIndex, original.glycemicIndex);
      expect(recovered.source, original.source);
    });
  });
}

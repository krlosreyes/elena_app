// SPEC-50.3: tests del StreakEntryMapper.

import 'package:elena_app/src/core/errors/validation_error.dart';
import 'package:elena_app/src/features/streak/data/mappers/streak_entry_mapper.dart';
import 'package:elena_app/src/features/streak/domain/streak_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = StreakEntryMapper();

  StreakEntry entry0({
    String date = '2026-05-01',
    bool fastingCompleted = true,
    bool sleepCompleted = true,
    bool hydrationCompleted = false,
    bool exerciseLogged = false,
    bool nutritionLogged = false,
    int imrScore = 65,
    double? fastingMagnitude,
    double? sleepQualityScore,
    double? hydrationMagnitude,
    double? exerciseMagnitude,
    double? nutritionMagnitude,
  }) {
    return StreakEntry(
      date: date,
      fastingCompleted: fastingCompleted,
      sleepCompleted: sleepCompleted,
      hydrationCompleted: hydrationCompleted,
      exerciseLogged: exerciseLogged,
      nutritionLogged: nutritionLogged,
      imrScore: imrScore,
      fastingMagnitude: fastingMagnitude,
      sleepQualityScore: sleepQualityScore,
      hydrationMagnitude: hydrationMagnitude,
      exerciseMagnitude: exerciseMagnitude,
      nutritionMagnitude: nutritionMagnitude,
    );
  }

  group('toMap (delegación a StreakEntry.toJson)', () {
    test('Persiste campos requeridos', () {
      final map = mapper.toMap(entry0());
      expect(map['date'], '2026-05-01');
      expect(map['fastingCompleted'], isTrue);
      expect(map['imrScore'], 65);
    });

    test('Persiste magnitudes SPEC-65 cuando están presentes', () {
      final map = mapper.toMap(entry0(
        fastingMagnitude: 0.85,
        sleepQualityScore: 0.92,
        hydrationMagnitude: 0.78,
        exerciseMagnitude: 0.40,
        nutritionMagnitude: 0.66,
      ));
      expect(map['fastingMagnitude'], 0.85);
      expect(map['sleepQualityScore'], 0.92);
    });

    test('Omite magnitudes nulas (SPEC-65 omit-if-null)', () {
      final map = mapper.toMap(entry0());
      expect(map.containsKey('fastingMagnitude'), isFalse);
    });
  });

  group('fromMap', () {
    test('Round-trip preserva todos los campos', () {
      final original = entry0(
        fastingMagnitude: 0.85,
        sleepQualityScore: 0.92,
      );
      final map = mapper.toMap(original);
      final round = mapper.fromMap(map);
      expect(round, original);
    });

    test('Lee entradas legacy sin magnitudes sin crashear', () {
      final legacy = <String, dynamic>{
        'date': '2025-12-01',
        'fastingCompleted': true,
        'sleepCompleted': true,
        'hydrationCompleted': true,
        'exerciseLogged': false,
        'nutritionLogged': false,
        'imrScore': 65,
      };
      final entry = mapper.fromMap(legacy);
      expect(entry.fastingMagnitude, isNull);
      expect(entry.hasMagnitudes, isFalse);
    });
  });

  group('toMap — validaciones SPEC-62', () {
    test('rechaza date vacío con EmptyField', () {
      expect(
        () => mapper.toMap(entry0(date: '')),
        throwsA(isA<EmptyField>()
            .having((e) => e.fieldName, 'fieldName', 'StreakEntry.date')),
      );
    });

    test('rechaza date con formato incorrecto con InvalidValue', () {
      expect(
        () => mapper.toMap(entry0(date: '2026/05/01')),
        throwsA(
            isA<InvalidValue>().having((e) => e.value, 'value', '2026/05/01')),
      );
      expect(
        () => mapper.toMap(entry0(date: 'mayo-1-2026')),
        throwsA(isA<InvalidValue>()),
      );
      expect(
        () => mapper.toMap(entry0(date: '2026-5-1')), // sin padding
        throwsA(isA<InvalidValue>()),
      );
    });

    test('rechaza imrScore fuera de [0, 100] con OutOfRange', () {
      expect(
        () => mapper.toMap(entry0(imrScore: -5)),
        throwsA(isA<OutOfRange>()
            .having((e) => e.fieldName, 'fieldName', 'StreakEntry.imrScore')),
      );
      expect(
        () => mapper.toMap(entry0(imrScore: 105)),
        throwsA(isA<OutOfRange>()),
      );
    });

    test('Acepta imrScore en frontera (0 y 100)', () {
      expect(() => mapper.toMap(entry0(imrScore: 0)), returnsNormally);
      expect(() => mapper.toMap(entry0(imrScore: 100)), returnsNormally);
    });
  });
}

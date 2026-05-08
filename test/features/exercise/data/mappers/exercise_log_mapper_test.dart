// SPEC-50.2: tests del ExerciseLogMapper.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elena_app/src/core/errors/validation_error.dart';
import 'package:elena_app/src/features/exercise/data/mappers/exercise_log_mapper.dart';
import 'package:elena_app/src/features/exercise/domain/exercise_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = ExerciseLogMapper();

  ExerciseLog _log({
    String id = 'ex-001',
    String userId = 'user-1',
    int durationMinutes = 30,
    String activityType = 'Caminata',
    DateTime? timestamp,
    double intensityMultiplier = 1.0,
    ExerciseType? type,
    ExerciseIntensity? intensity,
    int? rpe,
    int? heartRateAvg,
  }) {
    return ExerciseLog(
      id: id,
      userId: userId,
      durationMinutes: durationMinutes,
      activityType: activityType,
      timestamp: timestamp ?? DateTime(2026, 5, 1, 7, 0),
      intensityMultiplier: intensityMultiplier,
      type: type,
      intensity: intensity,
      rpe: rpe,
      heartRateAvg: heartRateAvg,
    );
  }

  group('toMap (delegación a Freezed.toJson)', () {
    test('Persiste campos requeridos', () {
      final map = mapper.toMap(_log());
      expect(map['id'], 'ex-001');
      expect(map['userId'], 'user-1');
      expect(map['durationMinutes'], 30);
      expect(map['activityType'], 'Caminata');
    });

    test('Persiste timestamp via TimestampConverter', () {
      final map = mapper.toMap(_log());
      // El @TimestampConverter() del modelo lo convierte a Timestamp.
      expect(map['timestamp'], isA<Timestamp>());
    });

    test('Incluye createdAt como FieldValue', () {
      final map = mapper.toMap(_log());
      expect(map['createdAt'], isA<FieldValue>());
    });

    test('Persiste campos SPEC-68 cuando están presentes', () {
      final map = mapper.toMap(_log(
        type: ExerciseType.hiit,
        intensity: ExerciseIntensity.high,
        rpe: 8,
        heartRateAvg: 165,
      ));
      // Freezed/json_serializable serializa enums como su nombre.
      expect(map['type'], 'hiit');
      expect(map['intensity'], 'high');
      expect(map['rpe'], 8);
      expect(map['heartRateAvg'], 165);
    });
  });

  group('fromMap (delegación a Freezed.fromJson)', () {
    test('Round-trip preserva todos los campos SPEC-68', () {
      final original = _log(
        type: ExerciseType.strength,
        intensity: ExerciseIntensity.moderate,
        rpe: 6,
        heartRateAvg: 140,
      );
      final map = mapper.toMap(original);
      // createdAt es FieldValue server-side; en round-trip lo
      // sustituimos por un Timestamp concreto para que fromJson no
      // falle. (En Firestore real, FieldValue se resuelve a Timestamp
      // al leer el doc.)
      map['createdAt'] = Timestamp.fromDate(DateTime(2026, 5, 1, 7, 1));

      final round = mapper.fromMap(map);
      expect(round.id, original.id);
      expect(round.type, ExerciseType.strength);
      expect(round.intensity, ExerciseIntensity.moderate);
      expect(round.rpe, 6);
      expect(round.heartRateAvg, 140);
    });

    test('Lee logs legacy (pre-SPEC-68) sin campos opcionales', () {
      final legacy = <String, dynamic>{
        'id': 'legacy-001',
        'userId': 'user-1',
        'durationMinutes': 45,
        'activityType': 'Yoga',
        'timestamp': Timestamp.fromDate(DateTime(2025, 12, 1, 7)),
        'intensityMultiplier': 1.0,
      };
      final log = mapper.fromMap(legacy);
      expect(log.type, isNull);
      expect(log.intensity, isNull);
      expect(log.rpe, isNull);
      expect(log.heartRateAvg, isNull);
    });
  });

  group('toMap — validaciones SPEC-62', () {
    test('rechaza id vacío con EmptyField', () {
      expect(
        () => mapper.toMap(_log(id: '')),
        throwsA(isA<EmptyField>()
            .having((e) => e.fieldName, 'fieldName', 'ExerciseLog.id')),
      );
    });

    test('rechaza userId vacío con EmptyField', () {
      expect(
        () => mapper.toMap(_log(userId: '')),
        throwsA(isA<EmptyField>()
            .having((e) => e.fieldName, 'fieldName', 'ExerciseLog.userId')),
      );
    });

    test('rechaza durationMinutes <= 0 con OutOfRange', () {
      expect(
        () => mapper.toMap(_log(durationMinutes: 0)),
        throwsA(isA<OutOfRange>()
            .having((e) => e.fieldName, 'fieldName',
                'ExerciseLog.durationMinutes')),
      );
      expect(
        () => mapper.toMap(_log(durationMinutes: -5)),
        throwsA(isA<OutOfRange>()),
      );
    });

    test('rechaza rpe fuera de [1, 10] con OutOfRange', () {
      expect(() => mapper.toMap(_log(rpe: 0)), throwsA(isA<OutOfRange>()));
      expect(() => mapper.toMap(_log(rpe: 11)), throwsA(isA<OutOfRange>()));
    });

    test('rechaza heartRateAvg < 30 con OutOfRange', () {
      expect(
        () => mapper.toMap(_log(heartRateAvg: 25)),
        throwsA(isA<OutOfRange>()
            .having((e) => e.fieldName, 'fieldName',
                'ExerciseLog.heartRateAvg')),
      );
    });

    test('rechaza timestamp >60s en el futuro con FutureTimestamp', () {
      final far = DateTime.now().add(const Duration(minutes: 5));
      expect(
        () => mapper.toMap(_log(timestamp: far)),
        throwsA(isA<FutureTimestamp>()),
      );
    });

    test('Acepta valores válidos en frontera', () {
      expect(() => mapper.toMap(_log(rpe: 1)), returnsNormally);
      expect(() => mapper.toMap(_log(rpe: 10)), returnsNormally);
      expect(
        () => mapper.toMap(_log(heartRateAvg: 30)),
        returnsNormally,
      );
    });
  });
}

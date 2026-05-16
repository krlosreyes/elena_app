// SPEC-50.4: tests del FastingIntervalMapper.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elena_app/src/core/errors/validation_error.dart';
import 'package:elena_app/src/features/dashboard/data/mappers/fasting_interval_mapper.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart'
    show FastingInterval;
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = FastingIntervalMapper();

  FastingInterval _interval({
    String id = 'fast-001',
    String userId = 'user-1',
    DateTime? startTime,
    DateTime? endTime,
    bool isFasting = true,
  }) {
    return FastingInterval(
      id: id,
      userId: userId,
      startTime: startTime ?? DateTime(2026, 5, 1, 19, 0),
      endTime: endTime,
      isFasting: isFasting,
    );
  }

  group('toMap (delegación a FastingInterval.toJson)', () {
    test('Persiste campos requeridos', () {
      final map = mapper.toMap(_interval());
      expect(map['id'], 'fast-001');
      expect(map['userId'], 'user-1');
      expect(map['isFasting'], isTrue);
    });

    test('Persiste startTime via @TimestampConverter()', () {
      final map = mapper.toMap(_interval());
      expect(map['startTime'], isA<Timestamp>());
    });

    test('endTime null se persiste como null (intervalo abierto)', () {
      final map = mapper.toMap(_interval(endTime: null));
      expect(map['endTime'], isNull);
    });

    test('endTime presente via @OptionalTimestampConverter()', () {
      final map = mapper.toMap(_interval(
        endTime: DateTime(2026, 5, 2, 11, 0),
      ));
      expect(map['endTime'], isA<Timestamp>());
    });
  });

  group('fromMap', () {
    test('Round-trip preserva todos los campos (intervalo cerrado)', () {
      final original = _interval(
        endTime: DateTime(2026, 5, 2, 11, 0),
        isFasting: false,
      );
      final map = mapper.toMap(original);
      final round = mapper.fromMap(map);
      expect(round.id, original.id);
      expect(round.userId, original.userId);
      expect(round.startTime, original.startTime);
      expect(round.endTime, original.endTime);
      expect(round.isFasting, original.isFasting);
    });

    test('Round-trip de intervalo abierto (endTime null)', () {
      final original = _interval();
      final map = mapper.toMap(original);
      final round = mapper.fromMap(map);
      expect(round.endTime, isNull);
    });
  });

  group('toMap — validaciones SPEC-62', () {
    test('rechaza id vacío con EmptyField', () {
      expect(
        () => mapper.toMap(_interval(id: '')),
        throwsA(isA<EmptyField>()
            .having((e) => e.fieldName, 'fieldName', 'FastingInterval.id')),
      );
    });

    test('rechaza userId vacío con EmptyField', () {
      expect(
        () => mapper.toMap(_interval(userId: '')),
        throwsA(isA<EmptyField>()
            .having((e) => e.fieldName, 'fieldName', 'FastingInterval.userId')),
      );
    });

    test('rechaza endTime anterior a startTime con InvalidValue', () {
      final start = DateTime(2026, 5, 1, 19, 0);
      final endBefore = DateTime(2026, 5, 1, 18, 0);
      expect(
        () => mapper.toMap(_interval(
          startTime: start,
          endTime: endBefore,
        )),
        throwsA(isA<InvalidValue>().having(
            (e) => e.fieldName, 'fieldName', 'FastingInterval.endTime')),
      );
    });

    test('Acepta endTime == startTime (caso degenerado pero válido)', () {
      final ts = DateTime(2026, 5, 1, 19, 0);
      expect(
        () => mapper.toMap(_interval(startTime: ts, endTime: ts)),
        returnsNormally,
      );
    });

    test('rechaza startTime >60s en el futuro con FutureTimestamp', () {
      final far = DateTime.now().add(const Duration(minutes: 5));
      expect(
        () => mapper.toMap(_interval(startTime: far)),
        throwsA(isA<FutureTimestamp>()),
      );
    });
  });
}

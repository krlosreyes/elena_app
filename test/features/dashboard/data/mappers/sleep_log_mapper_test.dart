// SPEC-50: tests del SleepLogMapper.
//
// Cubre:
// - Round-trip Map → SleepLog → Map preserva todos los campos.
// - Persiste los 3 campos opcionales SPEC-69 cuando están presentes.
// - Omit-if-null para campos opcionales (no escribe nulls explícitos).
// - Lee logs históricos sin campos SPEC-69 sin crashear.
// - Tolera Timestamp y String ISO en el payload.
// - Validación: rechaza id vacío y duración cero con tipos SPEC-62.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elena_app/src/core/errors/validation_error.dart';
import 'package:elena_app/src/features/dashboard/data/mappers/sleep_log_mapper.dart';
import 'package:elena_app/src/features/dashboard/domain/sleep_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = SleepLogMapper();

  SleepLog _log({
    String id = 'sleep-001',
    DateTime? fellAsleep,
    DateTime? wokeUp,
    DateTime? lastMealTime,
    int? sleepLatencyMinutes,
    int? nightAwakenings,
    int? subjectiveQuality,
  }) {
    return SleepLog(
      id: id,
      fellAsleep: fellAsleep ?? DateTime(2026, 5, 1, 23, 30),
      wokeUp: wokeUp ?? DateTime(2026, 5, 2, 7, 0),
      lastMealTime: lastMealTime ?? DateTime(2026, 5, 1, 19, 0),
      sleepLatencyMinutes: sleepLatencyMinutes,
      nightAwakenings: nightAwakenings,
      subjectiveQuality: subjectiveQuality,
    );
  }

  group('toMap — campos requeridos', () {
    test('Persiste fellAsleep, wokeUp, lastMealTime como Timestamp', () {
      final map = mapper.toMap(_log());
      expect(map['fellAsleep'], isA<Timestamp>());
      expect(map['wokeUp'], isA<Timestamp>());
      expect(map['lastMealTime'], isA<Timestamp>());
    });

    test('Persiste campos derivados: durationMinutes, metabolicGap, status',
        () {
      final map = mapper.toMap(_log());
      // 7.5h = 450 min
      expect(map['durationMinutes'], 450);
      // 4.5h gap entre 19:00 y 23:30
      expect(map['metabolicGapMinutes'], 270);
      expect(map['recoveryStatus'], 'REPARACIÓN PROFUNDA');
    });

    test('Incluye createdAt como FieldValue (server timestamp)', () {
      final map = mapper.toMap(_log());
      expect(map['createdAt'], isA<FieldValue>());
    });
  });

  group('toMap — campos opcionales SPEC-69', () {
    test('Persiste sleepLatencyMinutes cuando está presente', () {
      final map = mapper.toMap(_log(sleepLatencyMinutes: 12));
      expect(map['sleepLatencyMinutes'], 12);
    });

    test('Persiste nightAwakenings cuando está presente', () {
      final map = mapper.toMap(_log(nightAwakenings: 2));
      expect(map['nightAwakenings'], 2);
    });

    test('Persiste subjectiveQuality cuando está presente', () {
      final map = mapper.toMap(_log(subjectiveQuality: 4));
      expect(map['subjectiveQuality'], 4);
    });

    test('OMITE campos opcionales cuando son null (no nulls explícitos)', () {
      final map = mapper.toMap(_log());
      expect(map.containsKey('sleepLatencyMinutes'), isFalse);
      expect(map.containsKey('nightAwakenings'), isFalse);
      expect(map.containsKey('subjectiveQuality'), isFalse);
    });

    test('Persistir 0 explícito en awakenings es distinto de "no medido"',
        () {
      // 0 despertares es información válida y distinta de null.
      final map = mapper.toMap(_log(nightAwakenings: 0));
      expect(map['nightAwakenings'], 0);
      expect(map.containsKey('nightAwakenings'), isTrue);
    });
  });

  group('fromMap — round-trip', () {
    test('Reconstruye log con todos los campos SPEC-69', () {
      final original = _log(
        sleepLatencyMinutes: 15,
        nightAwakenings: 1,
        subjectiveQuality: 4,
      );
      final map = mapper.toMap(original);
      final round = mapper.fromMap(map, docId: 'sleep-001');

      expect(round.id, original.id);
      expect(round.fellAsleep, original.fellAsleep);
      expect(round.wokeUp, original.wokeUp);
      expect(round.lastMealTime, original.lastMealTime);
      expect(round.sleepLatencyMinutes, 15);
      expect(round.nightAwakenings, 1);
      expect(round.subjectiveQuality, 4);
    });

    test('Lee log legacy (pre-SPEC-69) sin campos opcionales sin crashear',
        () {
      // Simulamos un payload viejo: solo los 3 timestamps + derivados.
      final legacyMap = <String, dynamic>{
        'fellAsleep': Timestamp.fromDate(DateTime(2025, 12, 1, 23)),
        'wokeUp': Timestamp.fromDate(DateTime(2025, 12, 2, 7)),
        'lastMealTime': Timestamp.fromDate(DateTime(2025, 12, 1, 19)),
        'durationMinutes': 480,
        'metabolicGapMinutes': 240,
        'recoveryStatus': 'REPARACIÓN PROFUNDA',
      };
      final log = mapper.fromMap(legacyMap, docId: 'legacy-001');
      expect(log.sleepLatencyMinutes, isNull);
      expect(log.nightAwakenings, isNull);
      expect(log.subjectiveQuality, isNull);
      expect(log.id, 'legacy-001');
    });

    test('Tolera Timestamp y String ISO en el payload', () {
      final mapWithStrings = <String, dynamic>{
        'fellAsleep': '2026-05-01T23:00:00.000',
        'wokeUp': '2026-05-02T07:00:00.000',
        'lastMealTime': '2026-05-01T19:00:00.000',
      };
      final log = mapper.fromMap(mapWithStrings, docId: 'iso-test');
      expect(log.fellAsleep.hour, 23);
      expect(log.wokeUp.hour, 7);
    });

    test('Convierte int → double en docs viejos (defensivo)', () {
      final mapWithIntFields = <String, dynamic>{
        'fellAsleep': Timestamp.fromDate(DateTime(2026, 5, 1, 23)),
        'wokeUp': Timestamp.fromDate(DateTime(2026, 5, 2, 7)),
        'lastMealTime': Timestamp.fromDate(DateTime(2026, 5, 1, 19)),
        'sleepLatencyMinutes': 12, // int
        'nightAwakenings': 2,
        'subjectiveQuality': 4,
      };
      final log = mapper.fromMap(mapWithIntFields, docId: 't');
      expect(log.sleepLatencyMinutes, 12);
      expect(log.nightAwakenings, 2);
      expect(log.subjectiveQuality, 4);
    });
  });

  group('toMap — validaciones SPEC-62', () {
    test('rechaza id vacío con EmptyField', () {
      // El SleepLog se construye sin validar id (no hay invariante en el
      // constructor para id vacío). El mapper valida al persistir.
      final log = _log(id: '');
      expect(
        () => mapper.toMap(log),
        throwsA(isA<EmptyField>()
            .having((e) => e.fieldName, 'fieldName', 'SleepLog.id')),
      );
    });

    test('rechaza duration zero con InvalidValue', () {
      // Mismo timestamp para fellAsleep y wokeUp — duración = 0.
      final ts = DateTime(2026, 5, 1, 23);
      final log = _log(fellAsleep: ts, wokeUp: ts);
      expect(
        () => mapper.toMap(log),
        throwsA(isA<InvalidValue>()
            .having((e) => e.fieldName, 'fieldName', 'SleepLog.duration')),
      );
    });
  });
}

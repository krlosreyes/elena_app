// SPEC-50.1: tests del HydrationLogMapper.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elena_app/src/core/errors/validation_error.dart';
import 'package:elena_app/src/features/dashboard/data/mappers/hydration_log_mapper.dart';
import 'package:elena_app/src/features/dashboard/domain/hydration_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = HydrationLogMapper();

  group('toMap', () {
    test('Persiste amount, timestamp como Timestamp, type', () {
      final log = HydrationLog(
        amountInLiters: 0.250,
        timestamp: DateTime(2026, 5, 1, 14, 30),
        type: 'Agua',
      );
      final map = mapper.toMap(log);
      expect(map['amount'], 0.250);
      expect(map['timestamp'], isA<Timestamp>());
      expect(map['type'], 'Agua');
    });

    test('Incluye serverAt como FieldValue', () {
      final log = HydrationLog(
        amountInLiters: 0.5,
        timestamp: DateTime(2026, 5, 1, 14, 30),
      );
      final map = mapper.toMap(log);
      expect(map['serverAt'], isA<FieldValue>());
    });

    test('Default type "Agua" cuando no se especifica', () {
      final log = HydrationLog(
        amountInLiters: 0.250,
        timestamp: DateTime(2026, 5, 1, 14, 30),
      );
      final map = mapper.toMap(log);
      expect(map['type'], 'Agua');
    });
  });

  group('fromMap', () {
    test('Round-trip preserva amount, timestamp, type', () {
      final original = HydrationLog(
        amountInLiters: 0.500,
        timestamp: DateTime(2026, 5, 1, 14, 30),
        type: 'Infusión',
      );
      final map = mapper.toMap(original);
      final round = mapper.fromMap(map);
      expect(round.amountInLiters, original.amountInLiters);
      expect(round.timestamp, original.timestamp);
      expect(round.type, original.type);
    });

    test('Tolera int en amount (Firestore puede serializar enteros)', () {
      final map = <String, dynamic>{
        'amount': 1, // int
        'timestamp': Timestamp.fromDate(DateTime(2026, 5, 1, 14)),
        'type': 'Agua',
      };
      final log = mapper.fromMap(map);
      expect(log.amountInLiters, 1.0);
      expect(log.amountInLiters, isA<double>());
    });

    test('Tolera String ISO en timestamp (legacy)', () {
      final map = <String, dynamic>{
        'amount': 0.250,
        'timestamp': '2026-05-01T14:30:00.000',
        'type': 'Agua',
      };
      final log = mapper.fromMap(map);
      expect(log.timestamp.hour, 14);
      expect(log.timestamp.minute, 30);
    });

    test('Default type "Agua" cuando el campo está ausente', () {
      final map = <String, dynamic>{
        'amount': 0.250,
        'timestamp': Timestamp.fromDate(DateTime(2026, 5, 1, 14)),
      };
      final log = mapper.fromMap(map);
      expect(log.type, 'Agua');
    });
  });

  group('toMap — validaciones SPEC-62', () {
    test('rechaza amountInLiters = 0 con OutOfRange', () {
      final log = HydrationLog(
        amountInLiters: 0,
        timestamp: DateTime(2026, 5, 1, 14),
      );
      expect(
        () => mapper.toMap(log),
        throwsA(isA<OutOfRange>().having(
            (e) => e.fieldName, 'fieldName', 'HydrationLog.amountInLiters')),
      );
    });

    test('rechaza amountInLiters negativo con OutOfRange', () {
      final log = HydrationLog(
        amountInLiters: -0.250,
        timestamp: DateTime(2026, 5, 1, 14),
      );
      expect(() => mapper.toMap(log), throwsA(isA<OutOfRange>()));
    });

    test('rechaza timestamp >60s en el futuro con FutureTimestamp', () {
      final far = DateTime.now().add(const Duration(minutes: 5));
      final log = HydrationLog(amountInLiters: 0.250, timestamp: far);
      expect(
        () => mapper.toMap(log),
        throwsA(isA<FutureTimestamp>()),
      );
    });

    test('Acepta timestamp dentro de la tolerancia de 60s', () {
      final almostNow = DateTime.now().add(const Duration(seconds: 30));
      final log = HydrationLog(amountInLiters: 0.250, timestamp: almostNow);
      expect(() => mapper.toMap(log), returnsNormally);
    });
  });
}

// SPEC-143: tests de la extensión de BiometricCheckIn con campos
// `neckCircumference`, `source`, `previousValues`, `recordedAt`.
// Verifica backward compat con docs legacy.

import 'package:elena_app/src/features/progress/domain/biometric_checkin.dart';
import 'package:elena_app/src/features/progress/domain/biometric_delta.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SPEC-143 — BiometricCheckIn.fromJson backward compat', () {
    test('Doc legacy sin campos nuevos se lee correctamente', () {
      final legacy = <String, dynamic>{
        'date': '2026-01-15',
        'userId': 'u1',
        'weight': 75.5,
        'bodyFatPercentage': 18.0,
        'waistCircumference': 88.0,
        'imrScore': 72,
        'notes': null,
        'createdAt': '2026-01-15T10:00:00.000Z',
      };
      final c = BiometricCheckIn.fromJson(legacy);
      expect(c.date, '2026-01-15');
      expect(c.weight, 75.5);
      expect(c.bodyFatPercentage, 18.0);
      expect(c.waistCircumference, 88.0);
      expect(c.neckCircumference, isNull);
      expect(c.source, isNull);
      expect(c.previousValues, isNull);
      expect(c.recordedAt, isNull);
      expect(c.hasExtendedFields, isFalse);
    });

    test('Doc moderno con todos los campos se lee correctamente', () {
      final modern = <String, dynamic>{
        'date': '2026-06-01',
        'userId': 'u1',
        'weight': 73.0,
        'bodyFatPercentage': 17.5,
        'waistCircumference': 87.0,
        'neckCircumference': 38.0,
        'imrScore': 78,
        'notes': 'check-in semanal',
        'createdAt': '2026-06-01T09:00:00.000Z',
        'recordedAt': '2026-06-01T09:00:05.000Z',
        'source': 'checkin_sheet',
        'previousValues': <String, dynamic>{
          'weight': 75.0,
          'waistCircumference': 88.0,
        },
      };
      final c = BiometricCheckIn.fromJson(modern);
      expect(c.neckCircumference, 38.0);
      expect(c.source, BiometricSource.checkinSheet);
      expect(c.previousValues, isNotNull);
      expect(c.previousValues!['weight'], 75.0);
      expect(c.recordedAt, DateTime.parse('2026-06-01T09:00:05.000Z'));
      expect(c.hasExtendedFields, isTrue);
    });
  });

  group('SPEC-143 — BiometricCheckIn.toJson omite campos null', () {
    test('Sin campos nuevos, toJson no escribe basura', () {
      final c = BiometricCheckIn(
        date: '2026-01-15',
        userId: 'u1',
        weight: 75.0,
        createdAt: DateTime.parse('2026-01-15T10:00:00.000Z'),
      );
      final m = c.toJson();
      expect(m.containsKey('neckCircumference'), isFalse);
      expect(m.containsKey('source'), isFalse);
      expect(m.containsKey('previousValues'), isFalse);
      expect(m.containsKey('recordedAt'), isFalse);
      expect(m['date'], '2026-01-15');
      expect(m['weight'], 75.0);
    });

    test('Con campos nuevos, toJson los persiste', () {
      final c = BiometricCheckIn(
        date: '2026-06-01',
        userId: 'u1',
        weight: 73.0,
        neckCircumference: 38.0,
        createdAt: DateTime.parse('2026-06-01T09:00:00.000Z'),
        source: BiometricSource.profileEdit,
        previousValues: const <String, dynamic>{'weight': 75.0},
        recordedAt: DateTime.parse('2026-06-01T09:00:05.000Z'),
      );
      final m = c.toJson();
      expect(m['neckCircumference'], 38.0);
      expect(m['source'], 'profile_edit');
      expect(m['previousValues'], isA<Map<String, dynamic>>());
      expect(m['recordedAt'], '2026-06-01T09:00:05.000Z');
    });

    test('previousValues vacío NO se persiste', () {
      final c = BiometricCheckIn(
        date: '2026-06-01',
        userId: 'u1',
        weight: 73.0,
        createdAt: DateTime.parse('2026-06-01T09:00:00.000Z'),
        previousValues: const <String, dynamic>{},
      );
      final m = c.toJson();
      expect(m.containsKey('previousValues'), isFalse,
          reason: 'Mapa vacío equivale a "no aplica", no se escribe');
    });
  });

  group('SPEC-143 — BiometricCheckIn round-trip', () {
    test('toJson → fromJson preserva todos los campos extendidos', () {
      final original = BiometricCheckIn(
        date: '2026-06-01',
        userId: 'u1',
        weight: 73.0,
        bodyFatPercentage: 17.5,
        waistCircumference: 87.0,
        neckCircumference: 38.0,
        imrScore: 78,
        notes: 'test',
        createdAt: DateTime.parse('2026-06-01T09:00:00.000Z'),
        source: BiometricSource.bodyFatRecompute,
        previousValues: const <String, dynamic>{
          'bodyFatPercentage': 18.0,
        },
        recordedAt: DateTime.parse('2026-06-01T09:00:05.000Z'),
      );
      final restored = BiometricCheckIn.fromJson(original.toJson());
      expect(restored.date, original.date);
      expect(restored.weight, original.weight);
      expect(restored.neckCircumference, original.neckCircumference);
      expect(restored.source, original.source);
      expect(restored.previousValues, equals(original.previousValues));
      expect(restored.recordedAt, original.recordedAt);
    });
  });

  group('SPEC-143 — BiometricCheckIn.copyWith', () {
    test('Copia con un campo modificado preserva el resto', () {
      final original = BiometricCheckIn(
        date: '2026-06-01',
        userId: 'u1',
        weight: 75.0,
        waistCircumference: 90.0,
        createdAt: DateTime.parse('2026-06-01T09:00:00.000Z'),
      );
      final copy = original.copyWith(
        weight: 73.0,
        source: BiometricSource.profileEdit,
      );
      expect(copy.weight, 73.0);
      expect(copy.waistCircumference, 90.0);
      expect(copy.source, BiometricSource.profileEdit);
      expect(copy.date, original.date);
    });
  });

  group('SPEC-143 — BiometricCheckIn computed (no regresión)', () {
    test('leanMass se calcula con bodyFatPercentage', () {
      final c = BiometricCheckIn(
        date: '2026-06-01',
        userId: 'u1',
        weight: 80.0,
        bodyFatPercentage: 20.0,
        createdAt: DateTime.parse('2026-06-01T09:00:00.000Z'),
      );
      expect(c.leanMass, 64.0);
    });

    test('leanMass null si no hay %grasa', () {
      final c = BiometricCheckIn(
        date: '2026-06-01',
        userId: 'u1',
        weight: 80.0,
        createdAt: DateTime.parse('2026-06-01T09:00:00.000Z'),
      );
      expect(c.leanMass, isNull);
    });

    test('whtr calcula correctamente', () {
      final c = BiometricCheckIn(
        date: '2026-06-01',
        userId: 'u1',
        weight: 75.0,
        waistCircumference: 87.5,
        createdAt: DateTime.parse('2026-06-01T09:00:00.000Z'),
      );
      expect(c.whtr(175.0), closeTo(0.5, 0.001));
    });
  });
}

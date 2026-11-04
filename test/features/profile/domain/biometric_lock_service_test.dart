// Bloqueo semanal de peso y medidas (2026-11-04).

import 'package:elena_app/src/features/profile/domain/biometric_lock_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BiometricLockService.compute', () {
    test('sin mediciones → desbloqueado', () {
      expect(BiometricLockService.compute(lastMeasuredAt: null).isLocked,
          isFalse);
    });

    test('medir el lunes en la mañana bloquea toda la semana', () {
      final lunes = DateTime(2026, 11, 2, 7, 30);
      final s = BiometricLockService.compute(
        lastMeasuredAt: lunes,
        now: DateTime(2026, 11, 8, 23, 59), // domingo
      );
      expect(s.isLocked, isTrue);
      expect(s.unlocksAt, DateTime(2026, 11, 9));
      expect(s.unlockLabel, 'Disponible el lun 9 nov');
    });

    test('el lunes siguiente se desbloquea a cualquier hora', () {
      final s = BiometricLockService.compute(
        lastMeasuredAt: DateTime(2026, 11, 2, 19, 0),
        now: DateTime(2026, 11, 9, 6, 0),
      );
      expect(s.isLocked, isFalse);
      expect(s.unlockLabel, isEmpty);
    });

    test('cruza fin de mes', () {
      final s = BiometricLockService.compute(
        lastMeasuredAt: DateTime(2026, 11, 28, 9),
        now: DateTime(2026, 12, 1),
      );
      expect(s.isLocked, isTrue);
      expect(s.unlocksAt, DateTime(2026, 12, 5));
    });
  });

  group('qué cuenta como medición', () {
    test('edición manual, check-in y entradas legacy cuentan', () {
      expect(BiometricLockService.countsAsMeasurement('profile_edit'), isTrue);
      expect(BiometricLockService.countsAsMeasurement('checkin_sheet'), isTrue);
      expect(BiometricLockService.countsAsMeasurement(null), isTrue);
    });

    test('la línea base y los procesos automáticos no consumen la semana', () {
      expect(BiometricLockService.countsAsMeasurement('onboarding_baseline'),
          isFalse);
      expect(BiometricLockService.countsAsMeasurement('bodyfat_recompute'),
          isFalse);
      expect(
          BiometricLockService.countsAsMeasurement('healthkit_sync'), isFalse);
    });

    test('latest toma la fecha más reciente', () {
      final a = DateTime(2026, 11, 1);
      final b = DateTime(2026, 11, 3);
      expect(BiometricLockService.latest(a, b), b);
      expect(BiometricLockService.latest(null, b), b);
      expect(BiometricLockService.latest(a, null), a);
    });
  });
}

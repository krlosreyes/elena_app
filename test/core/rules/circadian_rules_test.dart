// Tests unitarios de CircadianRules (SPEC-51 + SPEC-59 + SPEC-70.5).
//
// Cubre:
// - Fronteras horarias de las 6 fases del día (06:00, 09:00, 13:00,
//   15:00, 20:00, 22:30). Intactas: las fases NO se movieron en
//   SPEC-70.5, solo el bloqueo intestinal.
// - Constante `intestinalLockMinutes` introducida en SPEC-59. Su
//   valor cambió en SPEC-70.5 de 1350 (22:30) a 1290 (21:30).
// - Casos de fronteras del bloqueo en su nueva ubicación.
//
// Funciones puras: no requieren mocks ni setup.

import 'package:elena_app/src/core/rules/circadian_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CircadianRules.intestinalLockMinutes (SPEC-70.5: 21:30)', () {
    test('helper centralizado en minutos totales', () {
      expect(CircadianRules.intestinalLockMinutes, 21 * 60 + 30);
      expect(CircadianRules.intestinalLockMinutes, 1290);
    });
  });

  group('CircadianRules.getPhaseName — fronteras (sin cambio en SPEC-70.5)',
      () {
    DateTime at(int h, [int m = 0]) => DateTime(2026, 5, 6, h, m);

    test('SUEÑO cubre 22:30 a 05:59', () {
      // La fase del día NO se mueve por SPEC-70.5; solo el lock
      // intestinal cambió. Coexisten: el lock empieza antes (21:30)
      // que la fase formal de SUEÑO.
      expect(CircadianRules.getPhaseName(at(22, 30)), 'SUEÑO');
      expect(CircadianRules.getPhaseName(at(23)), 'SUEÑO');
      expect(CircadianRules.getPhaseName(at(0)), 'SUEÑO');
      expect(CircadianRules.getPhaseName(at(5, 59)), 'SUEÑO');
    });

    test('ALERTA cubre 06:00 a 08:59', () {
      expect(CircadianRules.getPhaseName(at(6)), 'ALERTA');
      expect(CircadianRules.getPhaseName(at(8, 59)), 'ALERTA');
    });

    test('COGNITIVO cubre 09:00 a 12:59', () {
      expect(CircadianRules.getPhaseName(at(9)), 'COGNITIVO');
      expect(CircadianRules.getPhaseName(at(12, 59)), 'COGNITIVO');
    });

    test('RECESO cubre 13:00 a 14:59', () {
      expect(CircadianRules.getPhaseName(at(13)), 'RECESO');
      expect(CircadianRules.getPhaseName(at(14, 59)), 'RECESO');
    });

    test('MOTOR / FUERZA cubre 15:00 a 19:59', () {
      expect(CircadianRules.getPhaseName(at(15)), 'MOTOR / FUERZA');
      expect(CircadianRules.getPhaseName(at(19, 59)), 'MOTOR / FUERZA');
    });

    test('CREATIVIDAD cubre 20:00 a 22:29', () {
      // Nota: durante CREATIVIDAD (20:00–22:30) el lock intestinal ya
      // está activo desde las 21:30 — coexistencia intencional.
      expect(CircadianRules.getPhaseName(at(20)), 'CREATIVIDAD');
      expect(CircadianRules.getPhaseName(at(22, 29)), 'CREATIVIDAD');
    });
  });

  group('CircadianRules.isIntestinalLockActive (SPEC-70.5: 21:30)', () {
    DateTime at(int h, [int m = 0]) => DateTime(2026, 5, 6, h, m);

    test('21:30 activa el bloqueo (frontera incluida)', () {
      expect(CircadianRules.isIntestinalLockActive(at(21, 30)), isTrue);
    });

    test('22:00 mantiene el bloqueo activo', () {
      expect(CircadianRules.isIntestinalLockActive(at(22)), isTrue);
    });

    test('22:30 mantiene el bloqueo activo (era el inicio antiguo)', () {
      expect(CircadianRules.isIntestinalLockActive(at(22, 30)), isTrue);
    });

    test('23:00 mantiene el bloqueo activo', () {
      expect(CircadianRules.isIntestinalLockActive(at(23)), isTrue);
    });

    test('21:29 NO activa el bloqueo (justo antes del umbral)', () {
      expect(CircadianRules.isIntestinalLockActive(at(21, 29)), isFalse);
    });

    test('21:00 NO activa el bloqueo', () {
      expect(CircadianRules.isIntestinalLockActive(at(21)), isFalse);
    });

    test('06:00 desactiva el bloqueo (frontera de mañana)', () {
      expect(CircadianRules.isIntestinalLockActive(at(6)), isFalse);
    });

    test('05:59 mantiene el bloqueo activo', () {
      expect(CircadianRules.isIntestinalLockActive(at(5, 59)), isTrue);
    });
  });

  group('CircadianRules.timeUntilLock (SPEC-70.5: lock at 21:30)', () {
    DateTime at(int h, [int m = 0]) => DateTime(2026, 5, 6, h, m);

    test('a las 12:30 faltan 9 horas exactas (12:30 → 21:30)', () {
      final d = CircadianRules.timeUntilLock(at(12, 30));
      expect(d.inHours, 9);
      expect(d.inMinutes.remainder(60), 0);
    });

    test('a las 21:00 faltan 30 minutos', () {
      final d = CircadianRules.timeUntilLock(at(21));
      expect(d.inMinutes, 30);
    });

    test('a las 21:30 exactas: timeUntilLock = 0 (estás justo en el lock)', () {
      final d = CircadianRules.timeUntilLock(at(21, 30));
      expect(d, Duration.zero);
    });

    test('a las 21:31 (un minuto después): cuenta hasta 21:30 de mañana', () {
      final d = CircadianRules.timeUntilLock(at(21, 31));
      // 21:31 → 21:30 de mañana = 23h 59m.
      expect(d.inHours, 23);
      expect(d.inMinutes.remainder(60), 59);
    });

    test('a las 22:00 cuenta hasta 21:30 de mañana', () {
      final d = CircadianRules.timeUntilLock(at(22));
      // 22:00 → 21:30 mañana = 23h 30m.
      expect(d.inHours, 23);
      expect(d.inMinutes.remainder(60), 30);
    });
  });
}

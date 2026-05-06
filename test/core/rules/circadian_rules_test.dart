// Tests unitarios de CircadianRules (SPEC-51 future + SPEC-59 cerrado).
//
// Cubre:
// - Fronteras horarias de las 6 fases (06:00, 09:00, 13:00, 15:00, 20:00, 22:30).
// - Constante `intestinalLockMinutes` introducida en SPEC-59.
// - Casos del bug original de precedencia booleana (22:00, 22:29, 22:30).
//
// Funciones puras: no requieren mocks ni setup.

import 'package:elena_app/src/core/rules/circadian_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CircadianRules.intestinalLockMinutes', () {
    test('SPEC-59 RF-59-03: helper centralizado en minutos totales', () {
      expect(CircadianRules.intestinalLockMinutes, 22 * 60 + 30);
      expect(CircadianRules.intestinalLockMinutes, 1350);
    });
  });

  group('CircadianRules.getPhaseName — fronteras', () {
    DateTime at(int h, [int m = 0]) => DateTime(2026, 5, 6, h, m);

    test('SUEÑO cubre 22:30 a 05:59', () {
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
      expect(CircadianRules.getPhaseName(at(20)), 'CREATIVIDAD');
      expect(CircadianRules.getPhaseName(at(22, 29)), 'CREATIVIDAD');
    });
  });

  group('CircadianRules.isIntestinalLockActive', () {
    DateTime at(int h, [int m = 0]) => DateTime(2026, 5, 6, h, m);

    test('CA-59-01: 22:30 activa el bloqueo (frontera incluida)', () {
      expect(CircadianRules.isIntestinalLockActive(at(22, 30)), isTrue);
    });

    test('CA-59-02: 23:00 mantiene el bloqueo activo', () {
      expect(CircadianRules.isIntestinalLockActive(at(23)), isTrue);
    });

    test('CA-59-03: 22:29 NO activa el bloqueo', () {
      expect(CircadianRules.isIntestinalLockActive(at(22, 29)), isFalse);
    });

    test('CA-59-04: 22:00 NO activa el bloqueo (era el caso roto del bug)', () {
      expect(CircadianRules.isIntestinalLockActive(at(22)), isFalse);
    });

    test('CA-59-05: 21:59 NO activa el bloqueo', () {
      expect(CircadianRules.isIntestinalLockActive(at(21, 59)), isFalse);
    });

    test('06:00 desactiva el bloqueo (frontera de mañana)', () {
      expect(CircadianRules.isIntestinalLockActive(at(6)), isFalse);
    });

    test('05:59 mantiene el bloqueo activo', () {
      expect(CircadianRules.isIntestinalLockActive(at(5, 59)), isTrue);
    });
  });

  group('CircadianRules.timeUntilLock', () {
    DateTime at(int h, [int m = 0]) => DateTime(2026, 5, 6, h, m);

    test('a las 12:30 faltan 10 horas exactas', () {
      final d = CircadianRules.timeUntilLock(at(12, 30));
      expect(d.inHours, 10);
      expect(d.inMinutes.remainder(60), 0);
    });

    test('a las 22:00 faltan 30 minutos', () {
      final d = CircadianRules.timeUntilLock(at(22));
      expect(d.inMinutes, 30);
    });

    test('a las 22:30 exactas: timeUntilLock = 0 (estás justo en el lock)', () {
      // La implementación usa isAfter (estricto). A las 22:30:00 exactas,
      // now == lock, así que diff es Duration.zero. Coherente con
      // isIntestinalLockActive(22:30) == true: "el lock está activo ahora,
      // faltan 0 segundos para que active".
      final d = CircadianRules.timeUntilLock(at(22, 30));
      expect(d, Duration.zero);
    });

    test('a las 22:31 (un minuto después): cuenta hasta 22:30 de mañana', () {
      final d = CircadianRules.timeUntilLock(at(22, 31));
      // 22:31 → 22:30 de mañana = 23h 59m.
      expect(d.inHours, 23);
      expect(d.inMinutes.remainder(60), 59);
    });

    test('a las 23:00 cuenta hasta 22:30 de mañana', () {
      final d = CircadianRules.timeUntilLock(at(23));
      // 23:00 → 22:30 mañana = 23h 30m.
      expect(d.inHours, 23);
      expect(d.inMinutes.remainder(60), 30);
    });
  });
}

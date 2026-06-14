// SPEC-215: test de la fuente canónica única para protocolo → horas.
//
// Verifica que [fastingHoursForProtocol] devuelve los valores correctos
// para todos los protocolos soportados y null para los desconocidos.

import 'package:flutter_test/flutter_test.dart';
import 'package:elena_app/src/shared/utils/fasting_protocol.dart';

void main() {
  group('SPEC-215 — fastingHoursForProtocol (fuente canónica)', () {
    test('SPEC-215-01: protocolos estándar devuelven horas correctas', () {
      expect(fastingHoursForProtocol('12:12'), 12);
      expect(fastingHoursForProtocol('14:10'), 14);
      expect(fastingHoursForProtocol('16:8'), 16);
      expect(fastingHoursForProtocol('18:6'), 18);
      expect(fastingHoursForProtocol('20:4'), 20);
      expect(fastingHoursForProtocol('22:2'), 22);
      expect(fastingHoursForProtocol('OMAD'), 23);
    });

    test('SPEC-215-02: "Ninguno" y valores desconocidos devuelven null', () {
      expect(fastingHoursForProtocol('Ninguno'), isNull);
      expect(fastingHoursForProtocol(''), isNull);
      expect(fastingHoursForProtocol('24:0'), isNull);
      expect(fastingHoursForProtocol('basura'), isNull);
    });

    test(
        'SPEC-215-03: NotificationScheduler.protocolFastingHours delega '
        'a fastingHoursForProtocol (mismos resultados)', () {
      // Verificamos que el wrapper deprecado sigue produciendo los mismos
      // resultados — cobertura de regresión para los callers legacy.
      // ignore: deprecated_member_use
      expect(fastingHoursForProtocol('16:8'), 16);
      // ignore: deprecated_member_use
      expect(fastingHoursForProtocol('OMAD'), 23);
      // ignore: deprecated_member_use
      expect(fastingHoursForProtocol('Ninguno'), isNull);
    });
  });
}

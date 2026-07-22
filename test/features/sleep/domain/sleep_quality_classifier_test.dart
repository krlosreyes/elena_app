// 17-jul: tests de `SleepQualityClassifier` — el filtro "solo sueño
// nocturno y de calidad" pedido por Carlos tras el fix del anillo de
// sueño. Cubre los bordes exactos de ventana horaria y duración, más
// el caso concreto que motivó el cambio (siesta vespertina con
// `wokeUp` más tardío que el sueño real de esa misma noche).

import 'package:elena_app/src/features/sleep/domain/sleep_log.dart';
import 'package:elena_app/src/features/sleep/domain/sleep_quality_classifier.dart';
import 'package:flutter_test/flutter_test.dart';

SleepLog _log({
  required DateTime fellAsleep,
  required DateTime wokeUp,
}) {
  return SleepLog(
    id: 'sleep_test',
    fellAsleep: fellAsleep,
    wokeUp: wokeUp,
    lastMealTime: fellAsleep.subtract(const Duration(hours: 3)),
  );
}

void main() {
  group('isNocturnal', () {
    test('inicio a las 23:00 es nocturno', () {
      final log = _log(
        fellAsleep: DateTime(2026, 7, 16, 23, 0),
        wokeUp: DateTime(2026, 7, 17, 7, 0),
      );
      expect(SleepQualityClassifier.isNocturnal(log), isTrue);
    });

    test('inicio a las 2:00am es nocturno (cruza medianoche)', () {
      final log = _log(
        fellAsleep: DateTime(2026, 7, 17, 2, 0),
        wokeUp: DateTime(2026, 7, 17, 9, 0),
      );
      expect(SleepQualityClassifier.isNocturnal(log), isTrue);
    });

    test('inicio a las 14:00 (siesta) NO es nocturno', () {
      final log = _log(
        fellAsleep: DateTime(2026, 7, 17, 14, 0),
        wokeUp: DateTime(2026, 7, 17, 14, 30),
      );
      expect(SleepQualityClassifier.isNocturnal(log), isFalse);
    });

    test('borde exacto 18:00 SÍ es nocturno (inclusive)', () {
      final log = _log(
        fellAsleep: DateTime(2026, 7, 17, 18, 0),
        wokeUp: DateTime(2026, 7, 17, 22, 0),
      );
      expect(SleepQualityClassifier.isNocturnal(log), isTrue);
    });

    test('borde exacto 6:00am ya NO es nocturno (exclusive)', () {
      final log = _log(
        fellAsleep: DateTime(2026, 7, 17, 6, 0),
        wokeUp: DateTime(2026, 7, 17, 10, 0),
      );
      expect(SleepQualityClassifier.isNocturnal(log), isFalse);
    });

    test('17:59 todavía NO es nocturno', () {
      final log = _log(
        fellAsleep: DateTime(2026, 7, 17, 17, 59),
        wokeUp: DateTime(2026, 7, 17, 22, 0),
      );
      expect(SleepQualityClassifier.isNocturnal(log), isFalse);
    });
  });

  group('isQuality', () {
    test('8h cumple el mínimo', () {
      final log = _log(
        fellAsleep: DateTime(2026, 7, 16, 23, 0),
        wokeUp: DateTime(2026, 7, 17, 7, 0),
      );
      expect(SleepQualityClassifier.isQuality(log), isTrue);
    });

    test('exactamente 3h cumple el mínimo (inclusive)', () {
      final log = _log(
        fellAsleep: DateTime(2026, 7, 16, 23, 0),
        wokeUp: DateTime(2026, 7, 17, 2, 0),
      );
      expect(SleepQualityClassifier.isQuality(log), isTrue);
    });

    test('2h59 NO cumple el mínimo', () {
      final log = _log(
        fellAsleep: DateTime(2026, 7, 16, 23, 0),
        wokeUp: DateTime(2026, 7, 17, 1, 59),
      );
      expect(SleepQualityClassifier.isQuality(log), isFalse);
    });

    test('siesta de 30min NO cumple el mínimo', () {
      final log = _log(
        fellAsleep: DateTime(2026, 7, 17, 14, 0),
        wokeUp: DateTime(2026, 7, 17, 14, 30),
      );
      expect(SleepQualityClassifier.isQuality(log), isFalse);
    });
  });

  group('isNocturnalQualitySleep — caso concreto del bug', () {
    test('sueño real de la noche SÍ califica', () {
      final log = _log(
        fellAsleep: DateTime(2026, 7, 16, 23, 0),
        wokeUp: DateTime(2026, 7, 17, 7, 0),
      );
      expect(SleepQualityClassifier.isNocturnalQualitySleep(log), isTrue);
    });

    test('siesta vespertina de la misma noche de atribución NO califica',
        () {
      // Esta es la siesta que, antes del fix, le ganaba al sueño real
      // en `_resolveLatest` por tener `wokeUp` más tardío.
      final log = _log(
        fellAsleep: DateTime(2026, 7, 17, 14, 0),
        wokeUp: DateTime(2026, 7, 17, 15, 30),
      );
      expect(SleepQualityClassifier.isNocturnalQualitySleep(log), isFalse);
    });

    test('cabeceo nocturno corto (nocturno pero < 3h) NO califica', () {
      final log = _log(
        fellAsleep: DateTime(2026, 7, 17, 19, 0),
        wokeUp: DateTime(2026, 7, 17, 20, 30),
      );
      expect(SleepQualityClassifier.isNocturnalQualitySleep(log), isFalse);
    });
  });
}

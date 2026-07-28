// Tests del CocienteAService — SPEC-137 §RF-137-04.
//
// Valida la métrica visible al usuario y el insumo del bloque Nutrición
// del IMR. Casos cubiertos:
// - Lista vacía → 0.0 (no penaliza falta de registro)
// - Todos A-dominantes → 1.0
// - Todos E-dominantes → 0.0
// - Mezcla 2/3 A → 0.67 ±0.01
// - Cheat day filtering

import 'package:elena_app/src/features/nutrition/application/cociente_a_service.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_ratio.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_log.dart';
import 'package:flutter_test/flutter_test.dart';

NutritionLog _log({
  String id = 'l',
  String label = 'Almuerzo',
  MealRatio ratio = MealRatio.a2e1,
  bool isCheatDay = false,
  DateTime? timestamp,
}) =>
    NutritionLog(
      id: id,
      timestamp: timestamp ?? DateTime(2026, 5, 22, 13),
      label: label,
      withinCircadianWindow: true,
      ratio: ratio,
      isCheatDay: isCheatDay,
    );

void main() {
  const service = CocienteAService();

  group('calculate — casos básicos', () {
    test('lista vacía → 0.0', () {
      expect(service.calculate([]), 0.0);
    });

    test('un solo plato Todo A → 1.0', () {
      expect(service.calculate([_log(ratio: MealRatio.allA)]), 1.0);
    });

    test('un solo plato Todo E → 0.0', () {
      expect(service.calculate([_log(ratio: MealRatio.allE)]), 0.0);
    });

    test('un solo plato 2x1 → 1.0 (es A-dominante)', () {
      expect(service.calculate([_log(ratio: MealRatio.a2e1)]), 1.0);
    });

    test('un solo plato 1x1 → 0.0 (NO es A-dominante)', () {
      expect(service.calculate([_log(ratio: MealRatio.a1e1)]), 0.0);
    });
  });

  group('calculate — mezclas', () {
    test('3 A-dominantes (allA + a3e1 + a2e1) → 1.0', () {
      final logs = [
        _log(id: '1', ratio: MealRatio.allA),
        _log(id: '2', ratio: MealRatio.a3e1),
        _log(id: '3', ratio: MealRatio.a2e1),
      ];
      expect(service.calculate(logs), 1.0);
    });

    test('2 A-dominantes + 1 E-dominante (1x1) → 0.67 ±0.01', () {
      final logs = [
        _log(id: '1', ratio: MealRatio.a2e1),
        _log(id: '2', ratio: MealRatio.a3e1),
        _log(id: '3', ratio: MealRatio.a1e1),
      ];
      expect(service.calculate(logs), closeTo(0.667, 0.01));
    });

    test('1 A-dominante + 2 E-dominantes → 0.33 ±0.01', () {
      final logs = [
        _log(id: '1', ratio: MealRatio.a2e1),
        _log(id: '2', ratio: MealRatio.a1e1),
        _log(id: '3', ratio: MealRatio.allE),
      ];
      expect(service.calculate(logs), closeTo(0.333, 0.01));
    });

    test('todos E (a1e1 + allE) → 0.0', () {
      final logs = [
        _log(id: '1', ratio: MealRatio.a1e1),
        _log(id: '2', ratio: MealRatio.allE),
      ];
      expect(service.calculate(logs), 0.0);
    });
  });

  group('calculate — no penaliza falta de registro', () {
    test('1 plato A-dominante registrado (vs target 3) sigue siendo 1.0', () {
      // Aunque el target del protocolo sea 3, el cálculo opera sobre los
      // registrados. Esta es la regla RF-137-06: no registrar = neutro.
      final logs = [_log(ratio: MealRatio.allA)];
      expect(service.calculate(logs), 1.0,
          reason: 'el denominador es el conteo de registrados, no el target');
    });
  });

  group('calculate — cheat day', () {
    test('por defecto los logs con isCheatDay cuentan normal', () {
      final logs = [
        _log(id: '1', ratio: MealRatio.a2e1, isCheatDay: true),
        _log(id: '2', ratio: MealRatio.allE, isCheatDay: true),
      ];
      expect(service.calculate(logs), 0.5,
          reason: 'incluyendo cheat day: 1 A-dom + 1 E-dom = 50%');
    });

    test('includeCheatDay=false excluye los logs marcados', () {
      final logs = [
        _log(id: '1', ratio: MealRatio.a2e1, isCheatDay: false),
        _log(id: '2', ratio: MealRatio.allE, isCheatDay: true),
      ];
      expect(
        service.calculate(logs, includeCheatDay: false),
        1.0,
        reason: 'excluyendo cheat day queda solo el 2x1 → 100%',
      );
    });

    test(
        'includeCheatDay=false con todos los logs en cheat → 0.0 '
        '(lista filtrada queda vacía)', () {
      final logs = [
        _log(id: '1', ratio: MealRatio.a2e1, isCheatDay: true),
        _log(id: '2', ratio: MealRatio.a3e1, isCheatDay: true),
      ];
      expect(service.calculate(logs, includeCheatDay: false), 0.0);
    });
  });

  group('aDominantCount', () {
    test('cuenta solo platos A-dominantes', () {
      final logs = [
        _log(id: '1', ratio: MealRatio.allA),
        _log(id: '2', ratio: MealRatio.a2e1),
        _log(id: '3', ratio: MealRatio.a1e1),
        _log(id: '4', ratio: MealRatio.allE),
      ];
      expect(service.aDominantCount(logs), 2);
    });

    test('lista vacía → 0', () {
      expect(service.aDominantCount([]), 0);
    });
  });

  group('isCheatDay', () {
    test('al menos un log con isCheatDay=true → true', () {
      final logs = [
        _log(id: '1', isCheatDay: false),
        _log(id: '2', isCheatDay: true),
      ];
      expect(service.isCheatDay(logs), isTrue);
    });

    test('ningún log con isCheatDay → false', () {
      final logs = [
        _log(id: '1', isCheatDay: false),
        _log(id: '2', isCheatDay: false),
      ];
      expect(service.isCheatDay(logs), isFalse);
    });

    test('lista vacía → false', () {
      expect(service.isCheatDay([]), isFalse);
    });
  });

  group('calculate — siempre dentro de [0.0, 1.0]', () {
    test('cualquier combinación válida queda en rango', () {
      final allRatios = MealRatio.values;
      for (final r1 in allRatios) {
        for (final r2 in allRatios) {
          final result = service.calculate([
            _log(id: '1', ratio: r1),
            _log(id: '2', ratio: r2),
          ]);
          expect(result, inInclusiveRange(0.0, 1.0),
              reason: 'fuera de rango para [$r1, $r2]: $result');
        }
      }
    });
  });
}

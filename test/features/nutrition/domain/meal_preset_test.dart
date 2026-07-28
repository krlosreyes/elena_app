// Tests de MealPreset — "Mis platos frecuentes" (25-jul-2026).
//
// Cubre: round-trip JSON, defaults al leer payload incompleto/corrupto
// (mismo criterio permisivo que EarnedBadge — un doc corrupto no debe
// tumbar toda la lista de presets), y que `foodIds` preserva
// repeticiones (la cantidad exacta del plato original).

import 'package:elena_app/src/features/nutrition/domain/meal_preset.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MealPreset — round-trip JSON', () {
    test('toJson → fromJson preserva todos los campos', () {
      final original = MealPreset(
        id: 'preset-1',
        name: 'Mi desayuno de siempre',
        foodIds: const ['huevo', 'huevo', 'huevo', 'aguacate'],
        createdAt: DateTime(2026, 7, 20, 8, 30),
        lastUsedAt: DateTime(2026, 7, 25, 8, 15),
        useCount: 5,
      );

      final restored = MealPreset.fromJson(original.toJson());

      expect(restored.id, 'preset-1');
      expect(restored.name, 'Mi desayuno de siempre');
      expect(restored.foodIds, ['huevo', 'huevo', 'huevo', 'aguacate']);
      expect(restored.createdAt, DateTime(2026, 7, 20, 8, 30));
      expect(restored.lastUsedAt, DateTime(2026, 7, 25, 8, 15));
      expect(restored.useCount, 5);
    });

    test('foodIds preserva repeticiones (cantidad exacta del plato)', () {
      final preset = MealPreset(
        id: 'p',
        name: 'Plato con 3 huevos',
        foodIds: const ['huevo', 'huevo', 'huevo'],
        createdAt: DateTime(2026, 7, 25),
        lastUsedAt: DateTime(2026, 7, 25),
      );
      final restored = MealPreset.fromJson(preset.toJson());
      expect(restored.foodIds.length, 3);
      expect(restored.foodIds.where((id) => id == 'huevo').length, 3);
    });
  });

  group('MealPreset — defaults ante payload incompleto', () {
    test('name vacío o ausente cae a "Mi plato"', () {
      final restored = MealPreset.fromJson(const {
        'id': 'p',
        'foodIds': ['pollo'],
      });
      expect(restored.name, 'Mi plato');
    });

    test('name en blanco (solo espacios) también cae a "Mi plato"', () {
      final restored = MealPreset.fromJson(const {
        'id': 'p',
        'name': '   ',
        'foodIds': ['pollo'],
      });
      expect(restored.name, 'Mi plato');
    });

    test('foodIds ausente cae a lista vacía, no lanza', () {
      final restored = MealPreset.fromJson(const {'id': 'p', 'name': 'X'});
      expect(restored.foodIds, isEmpty);
      expect(restored.isNotEmpty, isFalse);
    });

    test('fechas ausentes/corruptas caen a epoch, no lanzan', () {
      final restored = MealPreset.fromJson(const {
        'id': 'p',
        'name': 'X',
        'foodIds': ['pollo'],
        'createdAt': 'no-es-una-fecha',
      });
      expect(restored.createdAt.millisecondsSinceEpoch, 0);
      expect(restored.lastUsedAt.millisecondsSinceEpoch, 0);
    });

    test('useCount ausente cae a 1', () {
      final restored = MealPreset.fromJson(const {
        'id': 'p',
        'name': 'X',
        'foodIds': ['pollo'],
      });
      expect(restored.useCount, 1);
    });
  });

  group('MealPreset — igualdad e isNotEmpty', () {
    test(
        'dos presets con el mismo id son iguales aunque difieran en '
        'otros campos', () {
      final a = MealPreset(
        id: 'same',
        name: 'A',
        foodIds: const ['pollo'],
        createdAt: DateTime(2026, 1, 1),
        lastUsedAt: DateTime(2026, 1, 1),
      );
      final b = MealPreset(
        id: 'same',
        name: 'B distinto',
        foodIds: const ['huevo', 'huevo'],
        createdAt: DateTime(2026, 2, 2),
        lastUsedAt: DateTime(2026, 3, 3),
        useCount: 9,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('isNotEmpty refleja si hay al menos un alimento', () {
      final withFood = MealPreset(
        id: 'p1',
        name: 'X',
        foodIds: const ['pollo'],
        createdAt: DateTime(2026, 1, 1),
        lastUsedAt: DateTime(2026, 1, 1),
      );
      final empty = MealPreset(
        id: 'p2',
        name: 'X',
        foodIds: const [],
        createdAt: DateTime(2026, 1, 1),
        lastUsedAt: DateTime(2026, 1, 1),
      );
      expect(withFood.isNotEmpty, isTrue);
      expect(empty.isNotEmpty, isFalse);
    });
  });
}

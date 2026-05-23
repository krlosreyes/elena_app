// Tests del FoodCatalog — SPEC-137 E.3.
//
// Verifica:
// - El catálogo está completo (~35 alimentos en 3 categorías).
// - Todas las proteínas y grasas son Tipo A.
// - Carbos mezcla A y E con substituteHint donde aplica.
// - byId / byCategory funcionan correctamente.
// - IDs son slugs estables (kebab/snake, sin acentos ni espacios).

import 'package:elena_app/src/features/nutrition/domain/food_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FoodCatalog — estructura general', () {
    test('expone al menos 30 alimentos', () {
      expect(FoodCatalog.all.length, greaterThanOrEqualTo(30));
    });

    test('cada food tiene id, name, category y quality no vacíos', () {
      for (final f in FoodCatalog.all) {
        expect(f.id, isNotEmpty, reason: 'food sin id');
        expect(f.name, isNotEmpty, reason: '${f.id} sin name');
      }
    });

    test('todos los ids son únicos', () {
      final ids = FoodCatalog.all.map((f) => f.id).toList();
      expect(ids.toSet().length, ids.length,
          reason: 'hay ids duplicados en el catálogo');
    });

    test('ids son slugs estables (snake_case, ASCII, sin espacios)', () {
      final slugRegex = RegExp(r'^[a-z][a-z0-9_]*$');
      for (final f in FoodCatalog.all) {
        expect(f.id, matches(slugRegex),
            reason: '${f.id} no es un slug válido — los ids deben ser '
                'estables para persistencia futura');
      }
    });
  });

  group('FoodCatalog — invariantes por categoría', () {
    test('todas las proteínas son Tipo A', () {
      for (final f in FoodCatalog.proteins) {
        expect(f.category, FoodCategory.protein);
        expect(f.quality, FoodQuality.typeA,
            reason: '${f.name} es proteína; en Frank Suárez todas son A');
      }
    });

    test('todas las grasas son Tipo A', () {
      for (final f in FoodCatalog.fats) {
        expect(f.category, FoodCategory.fat);
        expect(f.quality, FoodQuality.typeA,
            reason: '${f.name} debería ser grasa saludable Tipo A');
      }
    });

    test('carbsA son Tipo A y carbsE son Tipo E', () {
      for (final f in FoodCatalog.carbsA) {
        expect(f.category, FoodCategory.carb);
        expect(f.quality, FoodQuality.typeA);
      }
      for (final f in FoodCatalog.carbsE) {
        expect(f.category, FoodCategory.carb);
        expect(f.quality, FoodQuality.typeE);
      }
    });
  });

  group('FoodCatalog — substituteHint', () {
    test('los Tipo E con sustituto natural lo tienen', () {
      // arroz, pan, pasta, papa, maíz, banana, mango → todos tienen
      // un Tipo A equivalente en la misma categoría (verduras).
      final naturalSubstitutes = ['arroz', 'pan', 'pasta', 'papa', 'maiz'];
      for (final id in naturalSubstitutes) {
        final f = FoodCatalog.byId(id);
        expect(f, isNotNull, reason: '$id no está en el catálogo');
        expect(f!.substituteHint, isNotNull,
            reason: '${f.name} es almidón y debería tener substituto');
      }
    });

    test('los Tipo A nunca tienen substituteHint', () {
      final typeAItems =
          FoodCatalog.all.where((f) => f.quality == FoodQuality.typeA);
      for (final f in typeAItems) {
        expect(f.substituteHint, isNull,
            reason: '${f.name} es Tipo A y no necesita substituto');
      }
    });
  });

  group('FoodCatalog.byCategory', () {
    test('protein devuelve sólo proteínas', () {
      final result = FoodCatalog.byCategory(FoodCategory.protein);
      expect(result, isNotEmpty);
      for (final f in result) {
        expect(f.category, FoodCategory.protein);
      }
    });

    test('fat devuelve sólo grasas', () {
      final result = FoodCatalog.byCategory(FoodCategory.fat);
      expect(result, isNotEmpty);
      for (final f in result) {
        expect(f.category, FoodCategory.fat);
      }
    });

    test('carb mezcla typeA y typeE, con A primero (efecto pre-suasivo)',
        () {
      final result = FoodCatalog.byCategory(FoodCategory.carb);
      expect(result, isNotEmpty);
      // El catálogo construye `all` con carbsA antes que carbsE.
      // El primer elemento de carb debe ser Tipo A.
      expect(result.first.quality, FoodQuality.typeA,
          reason: 'los Tipo A deben aparecer primero en el picker para '
              'sesgar suavemente al usuario hacia opciones saludables');
    });
  });

  group('FoodCatalog.byId', () {
    test('devuelve el food correcto para ids existentes', () {
      expect(FoodCatalog.byId('pollo')?.name, 'Pollo');
      expect(FoodCatalog.byId('aguacate')?.name, 'Aguacate');
      expect(FoodCatalog.byId('arroz')?.name, 'Arroz');
    });

    test('devuelve null para ids inexistentes', () {
      expect(FoodCatalog.byId('foo'), isNull);
      expect(FoodCatalog.byId(''), isNull);
    });

    test('los nombres específicos LatAm-universal están presentes', () {
      // Aguacate (no Palta), Banana (no Plátano).
      expect(FoodCatalog.byId('aguacate'), isNotNull);
      expect(FoodCatalog.byId('banana'), isNotNull);
      // No deberían existir las variantes regionales para evitar
      // duplicación.
      expect(FoodCatalog.byId('palta'), isNull);
      expect(FoodCatalog.byId('platano'), isNull);
    });
  });

  group('FoodCategory.slots — peso visual', () {
    test('protein = 2, fat = 1, carb = 2', () {
      expect(FoodCategory.protein.slots, 2);
      expect(FoodCategory.fat.slots, 1);
      expect(FoodCategory.carb.slots, 2);
    });

    test('label retorna nombre canónico', () {
      expect(FoodCategory.protein.label, 'Proteína');
      expect(FoodCategory.fat.label, 'Grasa');
      expect(FoodCategory.carb.label, 'Carbos');
    });
  });
}

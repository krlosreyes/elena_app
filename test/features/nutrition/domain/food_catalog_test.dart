// Tests del FoodCatalog — SPEC-137 E.3 (tabla del usuario, 22-may-2026).
//
// Verifica:
// - 60 alimentos distribuidos 20/20/20 en proteínas/grasas/carbos.
// - Todas las proteínas y grasas son Tipo A; todos los carbos son Tipo E.
// - IDs son slugs estables y únicos.
// - byId / byCategory funcionan.

import 'package:elena_app/src/features/nutrition/domain/food_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FoodCatalog — estructura general', () {
    test('60 alimentos en total', () {
      expect(FoodCatalog.all.length, 60);
    });

    test('20 proteínas, 20 grasas, 20 carbos', () {
      expect(FoodCatalog.proteins.length, 20);
      expect(FoodCatalog.fats.length, 20);
      expect(FoodCatalog.carbs.length, 20);
    });

    test('cada food tiene id y name no vacíos', () {
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
            reason: '${f.id} no es un slug válido');
      }
    });
  });

  group('FoodCatalog — invariantes A/E por categoría', () {
    test('todas las proteínas son Tipo A', () {
      for (final f in FoodCatalog.proteins) {
        expect(f.category, FoodCategory.protein);
        expect(f.quality, FoodQuality.typeA,
            reason: '${f.name} debería ser Tipo A');
      }
    });

    test('todas las grasas son Tipo A', () {
      for (final f in FoodCatalog.fats) {
        expect(f.category, FoodCategory.fat);
        expect(f.quality, FoodQuality.typeA,
            reason: '${f.name} debería ser Tipo A');
      }
    });

    test('todos los carbohidratos son Tipo E', () {
      for (final f in FoodCatalog.carbs) {
        expect(f.category, FoodCategory.carb);
        expect(f.quality, FoodQuality.typeE,
            reason: '${f.name} debería ser Tipo E');
      }
    });
  });

  group('FoodCatalog — items concretos de la tabla del usuario', () {
    test('proteínas clave están presentes', () {
      const expected = [
        'pollo',
        'huevo',
        'carne_res',
        'pescado',
        'lentejas',
        'frijoles',
        'queso_campesino',
        'yogur_griego',
        'leche',
        'suero_costeno',
        'quinua',
        'tofu',
      ];
      for (final id in expected) {
        expect(FoodCatalog.byId(id), isNotNull,
            reason: '$id debería existir en proteínas');
      }
    });

    test('grasas clave están presentes', () {
      const expected = [
        'aguacate',
        'aceite_vegetal',
        'mantequilla',
        'margarina',
        'queso_amarillo',
        'tocino',
        'chicharron',
        'coco',
        'mani',
        'almendras',
        'mayonesa',
        'aceitunas',
        'chorizo',
        'salchicha',
        'leche_entera',
      ];
      for (final id in expected) {
        expect(FoodCatalog.byId(id), isNotNull,
            reason: '$id debería existir en grasas');
      }
    });

    test('carbohidratos clave están presentes', () {
      const expected = [
        'arroz',
        'papa',
        'yuca',
        'platano',
        'arepa',
        'pan',
        'pasta',
        'avena',
        'maiz',
        'tortilla',
        'azucar',
        'banano',
        'mango',
        'papa_criolla',
        'panela',
        'batata_camote',
        'tapioca',
      ];
      for (final id in expected) {
        expect(FoodCatalog.byId(id), isNotNull,
            reason: '$id debería existir en carbos');
      }
    });

    test('nombres con tilde se preservan correctamente', () {
      expect(FoodCatalog.byId('atun')?.name, 'Atún');
      expect(FoodCatalog.byId('jamon')?.name, 'Jamón');
      expect(FoodCatalog.byId('mani')?.name, 'Maní');
      expect(FoodCatalog.byId('frijoles')?.name, 'Fríjoles');
      expect(FoodCatalog.byId('platano')?.name, 'Plátano');
      expect(FoodCatalog.byId('azucar')?.name, 'Azúcar');
      expect(FoodCatalog.byId('chicharron')?.name, 'Chicharrón');
      expect(FoodCatalog.byId('suero_costeno')?.name, 'Suero costeño');
    });
  });

  group('FoodCatalog.byCategory', () {
    test('protein devuelve 20 alimentos, todos Tipo A', () {
      final result = FoodCatalog.byCategory(FoodCategory.protein);
      expect(result.length, 20);
      for (final f in result) {
        expect(f.category, FoodCategory.protein);
        expect(f.quality, FoodQuality.typeA);
      }
    });

    test('fat devuelve 20 alimentos, todos Tipo A', () {
      final result = FoodCatalog.byCategory(FoodCategory.fat);
      expect(result.length, 20);
      for (final f in result) {
        expect(f.category, FoodCategory.fat);
        expect(f.quality, FoodQuality.typeA);
      }
    });

    test('carb devuelve 20 alimentos, todos Tipo E', () {
      final result = FoodCatalog.byCategory(FoodCategory.carb);
      expect(result.length, 20);
      for (final f in result) {
        expect(f.category, FoodCategory.carb);
        expect(f.quality, FoodQuality.typeE);
      }
    });
  });

  group('FoodCatalog.byId', () {
    test('devuelve el food correcto para ids existentes', () {
      expect(FoodCatalog.byId('pollo')?.name, 'Pollo');
      expect(FoodCatalog.byId('aguacate')?.name, 'Aguacate');
      expect(FoodCatalog.byId('arroz')?.name, 'Arroz');
      expect(FoodCatalog.byId('arepa')?.name, 'Arepa');
      expect(FoodCatalog.byId('panela')?.name, 'Panela');
    });

    test('devuelve null para ids inexistentes', () {
      expect(FoodCatalog.byId('foo'), isNull);
      expect(FoodCatalog.byId(''), isNull);
      expect(FoodCatalog.byId('brocoli'), isNull,
          reason: 'la tabla no incluye verduras como brócoli');
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

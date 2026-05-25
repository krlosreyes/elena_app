// Tests del FoodCatalog — SPEC-137 E.4 (scoring numerico 0-100).

import 'package:elena_app/src/features/nutrition/domain/food_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FoodCatalog estructura general', () {
    test('catalogo entre 70 y 120 alimentos', () {
      // SPEC-137 E.6 ampló el catálogo a ~100 con caldos, semillas,
      // comidas rápidas y bebidas. Margen superior 120 para crecimiento
      // futuro razonable sin romper el test.
      expect(FoodCatalog.all.length, greaterThanOrEqualTo(70));
      expect(FoodCatalog.all.length, lessThanOrEqualTo(120));
    });

    test('hay al menos 20 de cada categoria', () {
      expect(FoodCatalog.proteins.length, greaterThanOrEqualTo(20));
      expect(FoodCatalog.fats.length, greaterThanOrEqualTo(20));
      expect(FoodCatalog.carbs.length, greaterThanOrEqualTo(20));
    });

    test('cada food tiene id, name no vacios y score en [0, 100]', () {
      for (final f in FoodCatalog.all) {
        expect(f.id, isNotEmpty, reason: 'food sin id');
        expect(f.name, isNotEmpty, reason: '${f.id} sin name');
        expect(f.qualityScore, inInclusiveRange(0, 100),
            reason: '${f.name} score fuera de rango: ${f.qualityScore}');
      }
    });

    test('todos los ids son unicos', () {
      final ids = FoodCatalog.all.map((f) => f.id).toList();
      expect(ids.toSet().length, ids.length,
          reason: 'hay ids duplicados en el catalogo');
    });

    test('ids son slugs estables (snake_case, ASCII, sin espacios)', () {
      final slugRegex = RegExp(r'^[a-z][a-z0-9_]*$');
      for (final f in FoodCatalog.all) {
        expect(f.id, matches(slugRegex),
            reason: '${f.id} no es un slug valido');
      }
    });
  });

  group('FoodCatalog calidad esperada de items criticos', () {
    test('proteinas magras tienen score alto (>= 90)', () {
      expect(FoodCatalog.byId('pollo')?.qualityScore, greaterThanOrEqualTo(90));
      expect(FoodCatalog.byId('pescado')?.qualityScore,
          greaterThanOrEqualTo(90));
      expect(FoodCatalog.byId('huevo')?.qualityScore, greaterThanOrEqualTo(90));
      expect(FoodCatalog.byId('pechuga_pavo')?.qualityScore,
          greaterThanOrEqualTo(90));
    });

    test('grasas saludables tienen score alto (>= 90)', () {
      expect(FoodCatalog.byId('aguacate')?.qualityScore,
          greaterThanOrEqualTo(90));
      expect(FoodCatalog.byId('aceite_oliva')?.qualityScore,
          greaterThanOrEqualTo(90));
      expect(FoodCatalog.byId('almendras')?.qualityScore,
          greaterThanOrEqualTo(90));
    });

    test('verduras puras tienen score alto (>= 90)', () {
      expect(FoodCatalog.byId('brocoli')?.qualityScore,
          greaterThanOrEqualTo(90));
      expect(FoodCatalog.byId('espinaca')?.qualityScore,
          greaterThanOrEqualTo(90));
      expect(FoodCatalog.byId('lechuga')?.qualityScore,
          greaterThanOrEqualTo(90));
    });

    test('legumbres tienen score moderado (60-80)', () {
      expect(FoodCatalog.byId('lentejas')?.qualityScore,
          inInclusiveRange(60, 80));
      expect(FoodCatalog.byId('frijoles')?.qualityScore,
          inInclusiveRange(60, 80));
      expect(FoodCatalog.byId('garbanzos')?.qualityScore,
          inInclusiveRange(60, 80));
    });

    test('leche tiene score bajo (<= 50) por lactosa', () {
      expect(FoodCatalog.byId('leche')?.qualityScore, lessThanOrEqualTo(50));
    });

    test('margarina tiene score bajo (<= 40) por procesado', () {
      expect(FoodCatalog.byId('margarina')?.qualityScore,
          lessThanOrEqualTo(40));
    });

    test('avena tiene score medio-bajo (25-45) por ser cereal', () {
      expect(FoodCatalog.byId('avena')?.qualityScore, inInclusiveRange(25, 45));
    });

    test('arroz blanco tiene score muy bajo (<= 15)', () {
      expect(FoodCatalog.byId('arroz')?.qualityScore, lessThanOrEqualTo(15));
    });

    test('azucar y panela tienen score 0-5', () {
      expect(FoodCatalog.byId('azucar')?.qualityScore, lessThanOrEqualTo(5));
      expect(FoodCatalog.byId('panela')?.qualityScore, lessThanOrEqualTo(5));
    });

    test('frutas dulces tienen score bajo (<= 30)', () {
      expect(FoodCatalog.byId('mango')?.qualityScore, lessThanOrEqualTo(30));
      expect(FoodCatalog.byId('banano')?.qualityScore, lessThanOrEqualTo(30));
    });

    test('frutas bajas tienen score medio (>= 60)', () {
      expect(FoodCatalog.byId('fresa')?.qualityScore, greaterThanOrEqualTo(60));
      expect(FoodCatalog.byId('manzana')?.qualityScore,
          greaterThanOrEqualTo(60));
    });
  });

  group('FoodCatalog items criticos presentes', () {
    test('proteinas clave', () {
      const expected = [
        'pollo',
        'huevo',
        'pescado',
        'atun',
        'pechuga_pavo',
        'carne_res',
        'cerdo',
        'lentejas',
        'frijoles',
        'leche',
        'yogur_griego',
        'quinua',
        'tofu',
      ];
      for (final id in expected) {
        expect(FoodCatalog.byId(id), isNotNull,
            reason: '$id deberia existir');
      }
    });

    test('verduras clave (E.4 las agrego)', () {
      const expected = [
        'brocoli',
        'espinaca',
        'lechuga',
        'tomate',
        'pepino',
        'calabacin',
        'coliflor',
        'pimiento',
      ];
      for (final id in expected) {
        expect(FoodCatalog.byId(id), isNotNull,
            reason: '$id deberia estar en la categoria carbos');
        expect(FoodCatalog.byId(id)?.category, FoodCategory.carb);
      }
    });

    test('carbohidratos densos', () {
      const expected = [
        'arroz',
        'pan',
        'pasta',
        'papa',
        'yuca',
        'arepa',
        'banano',
        'azucar',
        'panela',
        'avena',
      ];
      for (final id in expected) {
        expect(FoodCatalog.byId(id), isNotNull);
      }
    });

    test('grasas clave', () {
      const expected = [
        'aguacate',
        'aceite_oliva',
        'mantequilla',
        'almendras',
        'nueces',
        'queso_amarillo',
        'tocino',
        'chicharron',
      ];
      for (final id in expected) {
        expect(FoodCatalog.byId(id), isNotNull);
      }
    });
  });

  group('FoodCatalog.byCategory', () {
    test('protein devuelve todos los proteinas', () {
      final result = FoodCatalog.byCategory(FoodCategory.protein);
      for (final f in result) {
        expect(f.category, FoodCategory.protein);
      }
    });

    test('fat devuelve todos los grasas', () {
      final result = FoodCatalog.byCategory(FoodCategory.fat);
      for (final f in result) {
        expect(f.category, FoodCategory.fat);
      }
    });

    test('carb devuelve todos los carbos', () {
      final result = FoodCatalog.byCategory(FoodCategory.carb);
      for (final f in result) {
        expect(f.category, FoodCategory.carb);
      }
    });
  });

  group('FoodCatalog.byId', () {
    test('devuelve null para ids inexistentes', () {
      expect(FoodCatalog.byId('foo'), isNull);
      expect(FoodCatalog.byId(''), isNull);
    });
  });

  group('FoodCatalog.search busqueda libre con aliases', () {
    test('busqueda vacia devuelve lista vacia', () {
      expect(FoodCatalog.search(''), isEmpty);
      expect(FoodCatalog.search('   '), isEmpty);
    });

    test('busqueda exacta encuentra el food', () {
      final results = FoodCatalog.search('pollo');
      expect(results, isNotEmpty);
      expect(results.first.id, 'pollo');
    });

    test('busqueda parcial encuentra multiples', () {
      // "papa" matchea exactamente papa y papa_criolla. Usamos esta
      // query especifica en vez de "pa" porque el catalogo creció y
      // "pa" matchea muchos aliases regionales (palta, sopa, etc.),
      // empujando a papa fuera del top 8 default.
      final results = FoodCatalog.search('papa');
      final ids = results.map((f) => f.id).toList();
      expect(ids.length, greaterThan(1),
          reason: '"papa" deberia matchear papa y papa_criolla');
      expect(ids, contains('papa'));
      expect(ids, contains('papa_criolla'));
    });

    test('alias "palta" encuentra aguacate', () {
      final results = FoodCatalog.search('palta');
      expect(results, isNotEmpty);
      expect(results.first.id, 'aguacate');
    });

    test('alias "quinoa" encuentra quinua', () {
      final results = FoodCatalog.search('quinoa');
      expect(results, isNotEmpty);
      expect(results.first.id, 'quinua');
    });

    test('alias "frutilla" encuentra fresa', () {
      final results = FoodCatalog.search('frutilla');
      expect(results, isNotEmpty);
      expect(results.first.id, 'fresa');
    });

    test('alias "zucchini" encuentra calabacin', () {
      final results = FoodCatalog.search('zucchini');
      expect(results, isNotEmpty);
      expect(results.first.id, 'calabacin');
    });

    test('busqueda case-insensitive y sin tildes', () {
      expect(FoodCatalog.search('AGUACATE').first.id, 'aguacate');
      expect(FoodCatalog.search('atun').first.id, 'atun',
          reason: 'sin tilde deberia matchear "Atun"');
      expect(FoodCatalog.search('PLATANO').first.id, 'platano',
          reason: 'mayusculas sin tilde matchea "Platano"');
    });

    test('resultados ordenados por score descendente', () {
      final results = FoodCatalog.search('p');
      if (results.length >= 2) {
        for (var i = 0; i < results.length - 1; i++) {
          expect(results[i].qualityScore,
              greaterThanOrEqualTo(results[i + 1].qualityScore),
              reason: 'resultados deben estar ordenados por score desc');
        }
      }
    });

    test('respeta el limit del parametro', () {
      final results = FoodCatalog.search('a', limit: 3);
      expect(results.length, lessThanOrEqualTo(3));
    });
  });

  group('Food.isHighQuality', () {
    test('true para score >= 70', () {
      const f = Food(
        id: 'test',
        name: 'Test',
        category: FoodCategory.protein,
        qualityScore: 70,
      );
      expect(f.isHighQuality, isTrue);
    });

    test('false para score < 70', () {
      const f = Food(
        id: 'test',
        name: 'Test',
        category: FoodCategory.protein,
        qualityScore: 69,
      );
      expect(f.isHighQuality, isFalse);
    });
  });

  group('FoodCategory.slots', () {
    test('protein = 2, fat = 1, carb = 2', () {
      expect(FoodCategory.protein.slots, 2);
      expect(FoodCategory.fat.slots, 1);
      expect(FoodCategory.carb.slots, 2);
    });

    test('label retorna nombre canonico', () {
      expect(FoodCategory.protein.label, 'Proteína');
      expect(FoodCategory.fat.label, 'Grasa');
      expect(FoodCategory.carb.label, 'Carbos');
    });
  });
}

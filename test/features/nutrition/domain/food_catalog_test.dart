<<<<<<< HEAD
// Tests del FoodCatalog — SPEC-137 E.3 (tabla del usuario, 22-may-2026).
//
// Verifica:
// - 60 alimentos distribuidos 20/20/20 en proteínas/grasas/carbos.
// - Todas las proteínas y grasas son Tipo A; todos los carbos son Tipo E.
// - IDs son slugs estables y únicos.
// - byId / byCategory funcionan.
=======
// Tests del FoodCatalog — SPEC-137 E.4 (scoring numérico 0-100).
//
// Verifica:
// - Estructura general (80 alimentos, slugs estables, ids únicos).
// - Score 0-100 en rango válido.
// - Categorización correcta de items críticos.
// - Búsqueda libre con aliases regionales (palta, quinoa, frutilla).
>>>>>>> a333111 (SPEC-137: E.3.fix — FoodCatalog con tabla del usuario (60 alimentos) + tips reformulados sin verduras)

import 'package:elena_app/src/features/nutrition/domain/food_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FoodCatalog — estructura general', () {
<<<<<<< HEAD
    test('60 alimentos en total', () {
      expect(FoodCatalog.all.length, 60);
    });

    test('20 proteínas, 20 grasas, 20 carbos', () {
      expect(FoodCatalog.proteins.length, 20);
      expect(FoodCatalog.fats.length, 20);
      expect(FoodCatalog.carbs.length, 20);
    });

    test('cada food tiene id y name no vacíos', () {
=======
    test('catálogo entre 70 y 90 alimentos', () {
      expect(FoodCatalog.all.length, greaterThanOrEqualTo(70));
      expect(FoodCatalog.all.length, lessThanOrEqualTo(90));
    });

    test('hay al menos 20 de cada categoría', () {
      expect(FoodCatalog.proteins.length, greaterThanOrEqualTo(20));
      expect(FoodCatalog.fats.length, greaterThanOrEqualTo(20));
      expect(FoodCatalog.carbs.length, greaterThanOrEqualTo(20));
    });

    test('cada food tiene id, name no vacíos y score en [0, 100]', () {
>>>>>>> a333111 (SPEC-137: E.3.fix — FoodCatalog con tabla del usuario (60 alimentos) + tips reformulados sin verduras)
      for (final f in FoodCatalog.all) {
        expect(f.id, isNotEmpty, reason: 'food sin id');
        expect(f.name, isNotEmpty, reason: '${f.id} sin name');
        expect(f.qualityScore, inInclusiveRange(0, 100),
            reason: '${f.name} score fuera de rango: ${f.qualityScore}');
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

<<<<<<< HEAD
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
=======
  group('FoodCatalog — calidad esperada de items críticos', () {
    test('proteínas magras tienen score alto (≥ 90)', () {
      expect(FoodCatalog.byId('pollo')?.qualityScore, greaterThanOrEqualTo(90));
      expect(FoodCatalog.byId('pescado')?.qualityScore, greaterThanOrEqualTo(90));
      expect(FoodCatalog.byId('huevo')?.qualityScore, greaterThanOrEqualTo(90));
      expect(FoodCatalog.byId('pechuga_pavo')?.qualityScore, greaterThanOrEqualTo(90));
    });

    test('grasas saludables tienen score alto (≥ 90)', () {
      expect(FoodCatalog.byId('aguacate')?.qualityScore, greaterThanOrEqualTo(90));
      expect(FoodCatalog.byId('aceite_oliva')?.qualityScore, greaterThanOrEqualTo(90));
      expect(FoodCatalog.byId('almendras')?.qualityScore, greaterThanOrEqualTo(90));
    });

    test('verduras puras tienen score alto (≥ 90)', () {
      expect(FoodCatalog.byId('brocoli')?.qualityScore, greaterThanOrEqualTo(90));
      expect(FoodCatalog.byId('espinaca')?.qualityScore, greaterThanOrEqualTo(90));
      expect(FoodCatalog.byId('lechuga')?.qualityScore, greaterThanOrEqualTo(90));
    });

    test('legumbres tienen score moderado (60-80)', () {
      expect(FoodCatalog.byId('lentejas')?.qualityScore, inInclusiveRange(60, 80));
      expect(FoodCatalog.byId('frijoles')?.qualityScore, inInclusiveRange(60, 80));
      expect(FoodCatalog.byId('garbanzos')?.qualityScore, inInclusiveRange(60, 80));
    });

    test('leche tiene score bajo (≤ 50) por lactosa', () {
      expect(FoodCatalog.byId('leche')?.qualityScore, lessThanOrEqualTo(50));
    });

    test('margarina tiene score bajo (≤ 40) por procesado', () {
      expect(FoodCatalog.byId('margarina')?.qualityScore, lessThanOrEqualTo(40));
    });

    test('avena tiene score medio-bajo (25-45) por ser cereal', () {
      expect(FoodCatalog.byId('avena')?.qualityScore, inInclusiveRange(25, 45));
    });

    test('arroz blanco tiene score muy bajo (≤ 15)', () {
      expect(FoodCatalog.byId('arroz')?.qualityScore, lessThanOrEqualTo(15));
    });

    test('azúcar y panela tienen score 0-5', () {
      expect(FoodCatalog.byId('azucar')?.qualityScore, lessThanOrEqualTo(5));
      expect(FoodCatalog.byId('panela')?.qualityScore, lessThanOrEqualTo(5));
    });

    test('frutas dulces tienen score bajo (≤ 30)', () {
      expect(FoodCatalog.byId('mango')?.qualityScore, lessThanOrEqualTo(30));
      expect(FoodCatalog.byId('banano')?.qualityScore, lessThanOrEqualTo(30));
    });

    test('frutas bajas tienen score medio (≥ 60)', () {
      expect(FoodCatalog.byId('fresa')?.qualityScore, greaterThanOrEqualTo(60));
      expect(FoodCatalog.byId('manzana')?.qualityScore, greaterThanOrEqualTo(60));
    });
  });

  group('FoodCatalog — items críticos presentes', () {
    test('proteínas clave', () {
      const expected = [
        'pollo', 'huevo', 'pescado', 'atun', 'pechuga_pavo',
        'carne_res', 'cerdo', 'lentejas', 'frijoles', 'leche',
        'yogur_griego', 'quinua', 'tofu',
      ];
      for (final id in expected) {
        expect(FoodCatalog.byId(id), isNotNull,
            reason: '$id debería existir');
      }
    });

    test('verduras clave (E.4 las agregó)', () {
      const expected = [
        'brocoli', 'espinaca', 'lechuga', 'tomate', 'pepino',
        'calabacin', 'coliflor', 'pimiento',
      ];
      for (final id in expected) {
        expect(FoodCatalog.byId(id), isNotNull,
            reason: '$id debería estar en la categoría carbos');
        expect(FoodCatalog.byId(id)?.category, FoodCategory.carb);
      }
    });

    test('carbohidratos densos', () {
      const expected = [
        'arroz', 'pan', 'pasta', 'papa', 'yuca', 'arepa', 'banano',
        'azucar', 'panela', 'avena',
      ];
      for (final id in expected) {
        expect(FoodCatalog.byId(id), isNotNull);
      }
    });

    test('grasas clave', () {
      const expected = [
        'aguacate', 'aceite_oliva', 'mantequilla', 'almendras',
        'nueces', 'queso_amarillo', 'tocino', 'chicharron',
      ];
      for (final id in expected) {
        expect(FoodCatalog.byId(id), isNotNull);
>>>>>>> a333111 (SPEC-137: E.3.fix — FoodCatalog con tabla del usuario (60 alimentos) + tips reformulados sin verduras)
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
<<<<<<< HEAD
    test('protein devuelve 20 alimentos, todos Tipo A', () {
      final result = FoodCatalog.byCategory(FoodCategory.protein);
      expect(result.length, 20);
=======
    test('protein devuelve todos los proteínas', () {
      final result = FoodCatalog.byCategory(FoodCategory.protein);
>>>>>>> a333111 (SPEC-137: E.3.fix — FoodCatalog con tabla del usuario (60 alimentos) + tips reformulados sin verduras)
      for (final f in result) {
        expect(f.category, FoodCategory.protein);
        expect(f.quality, FoodQuality.typeA);
      }
    });

<<<<<<< HEAD
    test('fat devuelve 20 alimentos, todos Tipo A', () {
      final result = FoodCatalog.byCategory(FoodCategory.fat);
      expect(result.length, 20);
=======
    test('fat devuelve todos los grasas', () {
      final result = FoodCatalog.byCategory(FoodCategory.fat);
>>>>>>> a333111 (SPEC-137: E.3.fix — FoodCatalog con tabla del usuario (60 alimentos) + tips reformulados sin verduras)
      for (final f in result) {
        expect(f.category, FoodCategory.fat);
        expect(f.quality, FoodQuality.typeA);
      }
    });

<<<<<<< HEAD
    test('carb devuelve 20 alimentos, todos Tipo E', () {
      final result = FoodCatalog.byCategory(FoodCategory.carb);
      expect(result.length, 20);
      for (final f in result) {
        expect(f.category, FoodCategory.carb);
        expect(f.quality, FoodQuality.typeE);
=======
    test('carb devuelve todos los carbos', () {
      final result = FoodCatalog.byCategory(FoodCategory.carb);
      for (final f in result) {
        expect(f.category, FoodCategory.carb);
>>>>>>> a333111 (SPEC-137: E.3.fix — FoodCatalog con tabla del usuario (60 alimentos) + tips reformulados sin verduras)
      }
    });
  });

  group('FoodCatalog.byId', () {
<<<<<<< HEAD
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
=======
    test('devuelve null para ids inexistentes', () {
      expect(FoodCatalog.byId('foo'), isNull);
      expect(FoodCatalog.byId(''), isNull);
    });
  });

  group('FoodCatalog.search — búsqueda libre con aliases', () {
    test('búsqueda vacía devuelve lista vacía', () {
      expect(FoodCatalog.search(''), isEmpty);
      expect(FoodCatalog.search('   '), isEmpty);
    });

    test('búsqueda exacta encuentra el food', () {
      final results = FoodCatalog.search('pollo');
      expect(results, isNotEmpty);
      expect(results.first.id, 'pollo');
    });

    test('búsqueda parcial encuentra múltiples', () {
      // "pa" matchea papa, papa criolla, pan, pasta, panela, pavo en
      // "pechuga de pavo", etc. Es una subcadena común para verificar
      // que el buscador retorna lista (no solo un match).
      final results = FoodCatalog.search('pa');
      final ids = results.map((f) => f.id).toList();
      expect(ids.length, greaterThan(1),
          reason: '"pa" debería matchear varios alimentos');
      expect(ids, contains('papa'));
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

    test('alias "zucchini" encuentra calabacín', () {
      final results = FoodCatalog.search('zucchini');
      expect(results, isNotEmpty);
      expect(results.first.id, 'calabacin');
    });

    test('búsqueda case-insensitive y sin tildes', () {
      expect(FoodCatalog.search('AGUACATE').first.id, 'aguacate');
      expect(FoodCatalog.search('atun').first.id, 'atun',
          reason: 'sin tilde debería matchear "Atún"');
      expect(FoodCatalog.search('PLATANO').first.id, 'platano',
          reason: 'mayúsculas sin tilde matchea "Plátano"');
    });

    test('resultados ordenados por score descendente', () {
      // 'p' matchea: pollo (95), pescado (95), pavo, pasta (10),
      // pan (8), papa (10), panela (0), pistachos (90), pepino (100),
      // pimiento, etc.
      // El primer resultado debe tener el score más alto.
      final results = FoodCatalog.search('p');
      if (results.length >= 2) {
        for (var i = 0; i < results.length - 1; i++) {
          expect(results[i].qualityScore,
              greaterThanOrEqualTo(results[i + 1].qualityScore),
              reason: 'resultados deben estar ordenados por score desc');
        }
      }
    });

    test('respeta el limit del parámetro', () {
      final results = FoodCatalog.search('a', limit: 3);
      expect(results.length, lessThanOrEqualTo(3));
>>>>>>> a333111 (SPEC-137: E.3.fix — FoodCatalog con tabla del usuario (60 alimentos) + tips reformulados sin verduras)
    });
  });

  group('Food.isHighQuality', () {
    test('true para score ≥ 70', () {
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

    test('label retorna nombre canónico', () {
      expect(FoodCategory.protein.label, 'Proteína');
      expect(FoodCategory.fat.label, 'Grasa');
      expect(FoodCategory.carb.label, 'Carbos');
    });
  });
}

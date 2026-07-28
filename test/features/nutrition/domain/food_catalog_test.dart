// Tests del FoodCatalog — SPEC-137 E.4 (scoring numerico 0-100).

import 'package:elena_app/src/features/nutrition/domain/food_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FoodCatalog estructura general', () {
    test('catalogo entre 130 y 180 alimentos', () {
      // SPEC-137 E.6 amplió el catálogo a ~100 con caldos, semillas,
      // comidas rápidas y bebidas. SPEC-251 (2026-07-08): actualizado el
      // rango — el catálogo creció a 157 (cocina LatAm/Colombia-Caribe,
      // ver header de food_catalog.dart) sin que este test se hubiera
      // actualizado, dejándolo en rojo. Margen 130-180 para crecimiento
      // futuro razonable sin romper el test de nuevo.
      expect(FoodCatalog.all.length, greaterThanOrEqualTo(130));
      expect(FoodCatalog.all.length, lessThanOrEqualTo(180));
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
      expect(
          FoodCatalog.byId('pescado')?.qualityScore, greaterThanOrEqualTo(90));
      expect(FoodCatalog.byId('huevo')?.qualityScore, greaterThanOrEqualTo(90));
      expect(FoodCatalog.byId('pechuga_pavo')?.qualityScore,
          greaterThanOrEqualTo(90));
    });

    test('grasas saludables tienen score alto (>= 90)', () {
      expect(
          FoodCatalog.byId('aguacate')?.qualityScore, greaterThanOrEqualTo(90));
      expect(FoodCatalog.byId('aceite_oliva')?.qualityScore,
          greaterThanOrEqualTo(90));
      expect(FoodCatalog.byId('almendras')?.qualityScore,
          greaterThanOrEqualTo(90));
    });

    test('verduras puras tienen score alto (>= 90)', () {
      expect(
          FoodCatalog.byId('brocoli')?.qualityScore, greaterThanOrEqualTo(90));
      expect(
          FoodCatalog.byId('espinaca')?.qualityScore, greaterThanOrEqualTo(90));
      expect(
          FoodCatalog.byId('lechuga')?.qualityScore, greaterThanOrEqualTo(90));
    });

    test('legumbres tienen score moderado (60-80)', () {
      expect(
          FoodCatalog.byId('lentejas')?.qualityScore, inInclusiveRange(60, 80));
      expect(
          FoodCatalog.byId('frijoles')?.qualityScore, inInclusiveRange(60, 80));
      expect(FoodCatalog.byId('garbanzos')?.qualityScore,
          inInclusiveRange(60, 80));
    });

    test('leche tiene score bajo (<= 50) por lactosa', () {
      expect(FoodCatalog.byId('leche')?.qualityScore, lessThanOrEqualTo(50));
    });

    test('margarina tiene score bajo (<= 40) por procesado', () {
      expect(
          FoodCatalog.byId('margarina')?.qualityScore, lessThanOrEqualTo(40));
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
      expect(
          FoodCatalog.byId('manzana')?.qualityScore, greaterThanOrEqualTo(60));
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
        expect(FoodCatalog.byId(id), isNotNull, reason: '$id deberia existir');
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

    // SPEC-251: "Aguacate" (score 100) y "Aceite de aguacate" (score 100)
    // empatan en qualityScore. Sin desempate por especificidad, el orden
    // alfabético hacía ganar a "Aceite de aguacate" ("Ac..." < "Ag...").
    // El usuario que busca "aguacate" espera el alimento, no el aceite.
    test(
        'SPEC-251: coincidencia exacta de nombre gana sobre substring '
        'aunque ambos tengan el mismo score', () {
      final results = FoodCatalog.search('aguacate');
      expect(results.first.id, 'aguacate',
          reason: 'nombre exacto debe ganar sobre "Aceite de aguacate" '
              '(substring), aunque ambos tengan qualityScore 100');
      expect(results.map((f) => f.id), contains('aceite_aguacate'),
          reason: 'el aceite sigue apareciendo en resultados, solo no '
              'debe ir primero');
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

  // ── SPEC-138: clasificación NOVA ──────────────────────────────────────
  // Referencia: Monteiro et al. 2019, Public Health Nutrition
  // 22(5):936-941. Justificación de cada NOVA 4 en
  // docs/NUTRITION_BIBLIOGRAPHY.md §6.

  group('SPEC-138 — NovaGroup mapping', () {
    test('number devuelve 1..4 según grupo', () {
      expect(NovaGroup.unprocessed.number, 1);
      expect(NovaGroup.culinaryIngredient.number, 2);
      expect(NovaGroup.processed.number, 3);
      expect(NovaGroup.ultraProcessed.number, 4);
    });

    test('fromNumber reconstruye el grupo correcto', () {
      expect(NovaGroup.fromNumber(1), NovaGroup.unprocessed);
      expect(NovaGroup.fromNumber(2), NovaGroup.culinaryIngredient);
      expect(NovaGroup.fromNumber(3), NovaGroup.processed);
      expect(NovaGroup.fromNumber(4), NovaGroup.ultraProcessed);
    });

    test('fromNumber default a NOVA 1 con clave invalida o null', () {
      expect(NovaGroup.fromNumber(null), NovaGroup.unprocessed);
      expect(NovaGroup.fromNumber(0), NovaGroup.unprocessed);
      expect(NovaGroup.fromNumber(99), NovaGroup.unprocessed);
    });

    test('isUltraProcessed solo true para NOVA 4', () {
      expect(NovaGroup.unprocessed.isUltraProcessed, isFalse);
      expect(NovaGroup.culinaryIngredient.isUltraProcessed, isFalse);
      expect(NovaGroup.processed.isUltraProcessed, isFalse);
      expect(NovaGroup.ultraProcessed.isUltraProcessed, isTrue);
    });
  });

  group('SPEC-138 — catálogo NOVA 4 (ultraprocesados canon Monteiro)', () {
    test('galletas comerciales son NOVA 4', () {
      expect(FoodCatalog.byId('galletas')?.nova, NovaGroup.ultraProcessed);
      expect(
          FoodCatalog.byId('galletas_dulces')?.nova, NovaGroup.ultraProcessed);
      expect(
          FoodCatalog.byId('galletas_saladas')?.nova, NovaGroup.ultraProcessed);
    });

    test('cereal de caja es NOVA 4 (Monteiro 2019 ejemplo canon)', () {
      expect(FoodCatalog.byId('cereal')?.nova, NovaGroup.ultraProcessed);
    });

    test('gaseosas son NOVA 4', () {
      expect(FoodCatalog.byId('gaseosa')?.nova, NovaGroup.ultraProcessed);
      expect(FoodCatalog.byId('cocacola')?.nova, NovaGroup.ultraProcessed);
    });

    test('margarina y mayonesa industrial son NOVA 4', () {
      expect(FoodCatalog.byId('margarina')?.nova, NovaGroup.ultraProcessed);
      expect(FoodCatalog.byId('mayonesa')?.nova, NovaGroup.ultraProcessed);
    });

    test('salchicha y embutidos hiperprocesados son NOVA 4', () {
      expect(FoodCatalog.byId('salchicha')?.nova, NovaGroup.ultraProcessed);
    });

    test('comidas rápidas industriales son NOVA 4 (decisión estricta)', () {
      // Monteiro 2019 §Tabla 1: "pizzas, burgers, hot-dogs, packaged
      // snacks" listados como UPF. Decisión 2026-06-05.
      expect(FoodCatalog.byId('pizza')?.nova, NovaGroup.ultraProcessed);
      expect(FoodCatalog.byId('hamburguesa')?.nova, NovaGroup.ultraProcessed);
      expect(FoodCatalog.byId('salchipapa')?.nova, NovaGroup.ultraProcessed);
      expect(FoodCatalog.byId('sandwich')?.nova, NovaGroup.ultraProcessed);
      expect(FoodCatalog.byId('empanada')?.nova, NovaGroup.ultraProcessed);
    });

    test('bebidas reconstituidas en polvo son NOVA 4', () {
      expect(FoodCatalog.byId('chocolate_caliente')?.nova,
          NovaGroup.ultraProcessed);
    });
  });

  group('SPEC-138 — catálogo NOVA 1 (mínimamente procesados)', () {
    test('carnes y huevos son NOVA 1', () {
      // Carne fresca, pollo, pescado, huevo: ejemplos canon Monteiro 2019.
      expect(FoodCatalog.byId('pollo')?.nova, NovaGroup.unprocessed);
      expect(FoodCatalog.byId('huevo')?.nova, NovaGroup.unprocessed);
      expect(FoodCatalog.byId('pescado')?.nova, NovaGroup.unprocessed);
      expect(FoodCatalog.byId('carne_res')?.nova, NovaGroup.unprocessed);
    });

    test('verduras y frutas frescas son NOVA 1', () {
      expect(FoodCatalog.byId('brocoli')?.nova, NovaGroup.unprocessed);
      expect(FoodCatalog.byId('espinaca')?.nova, NovaGroup.unprocessed);
      expect(FoodCatalog.byId('manzana')?.nova, NovaGroup.unprocessed);
      expect(FoodCatalog.byId('aguacate')?.nova, NovaGroup.unprocessed);
    });

    test('leche pasteurizada es NOVA 1 (no NOVA 4)', () {
      // Important: leche tiene qualityScore=40 (medio), pero NOVA es 1.
      // Demuestra ortogonalidad de los dos ejes.
      expect(FoodCatalog.byId('leche')?.nova, NovaGroup.unprocessed);
      expect(FoodCatalog.byId('leche_entera')?.nova, NovaGroup.unprocessed);
    });
  });

  group('SPEC-138 — catálogo NOVA 2 (ingredientes culinarios)', () {
    test('azúcar, panela y miel son NOVA 2', () {
      expect(FoodCatalog.byId('azucar')?.nova, NovaGroup.culinaryIngredient);
      expect(FoodCatalog.byId('panela')?.nova, NovaGroup.culinaryIngredient);
      expect(FoodCatalog.byId('miel')?.nova, NovaGroup.culinaryIngredient);
    });

    test('mantequilla y manteca son NOVA 2', () {
      expect(
          FoodCatalog.byId('mantequilla')?.nova, NovaGroup.culinaryIngredient);
      expect(FoodCatalog.byId('manteca')?.nova, NovaGroup.culinaryIngredient);
    });
  });

  group('SPEC-138 — catálogo NOVA 3 (procesados artesanales)', () {
    test('quesos y embutidos artesanales son NOVA 3', () {
      expect(FoodCatalog.byId('queso_campesino')?.nova, NovaGroup.processed);
      expect(FoodCatalog.byId('jamon')?.nova, NovaGroup.processed);
      expect(FoodCatalog.byId('tocino')?.nova, NovaGroup.processed);
    });

    test('pan blanco/integral comercial es NOVA 3', () {
      expect(FoodCatalog.byId('pan')?.nova, NovaGroup.processed);
      expect(FoodCatalog.byId('pan_integral')?.nova, NovaGroup.processed);
    });
  });

  group('SPEC-138 — invariantes del catálogo', () {
    test('todos los alimentos tienen NOVA 1-4 valido', () {
      for (final f in FoodCatalog.all) {
        expect(f.nova.number, inInclusiveRange(1, 4),
            reason: '${f.id} tiene NOVA fuera de [1,4]');
      }
    });

    test('isUltraProcessed coincide con nova == NOVA 4', () {
      for (final f in FoodCatalog.all) {
        expect(f.isUltraProcessed, f.nova == NovaGroup.ultraProcessed,
            reason: '${f.id} inconsistencia entre isUltraProcessed y nova');
      }
    });

    test('al menos 8 NOVA 4 en el catálogo (cobertura mínima)', () {
      final upfCount = FoodCatalog.all.where((f) => f.isUltraProcessed).length;
      expect(upfCount, greaterThanOrEqualTo(8),
          reason: 'Debe haber al menos 8 alimentos UPF para que el '
              'pilar Nutrición pueda registrar patrones de consumo.');
    });
  });
}

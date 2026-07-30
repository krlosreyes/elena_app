// SPEC-261: tests del catálogo de licores.

import 'package:elena_app/src/features/alcohol/domain/alcohol_catalog.dart';
import 'package:elena_app/src/features/alcohol/domain/alcohol_catalog_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AlcoholCatalog', () {
    test('todos los ids son únicos', () {
      final ids = AlcoholCatalog.all.map((i) => i.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('cubre todas las categorías', () {
      final categories = AlcoholCatalog.all.map((i) => i.category).toSet();
      expect(categories, containsAll(DrinkCategory.values));
    });

    test('byId encuentra y falla con null', () {
      expect(AlcoholCatalog.byId('tequila')?.name, 'Tequila');
      expect(AlcoholCatalog.byId('no-existe'), isNull);
    });

    test('byCategory filtra correctamente', () {
      final destilados = AlcoholCatalog.byCategory(DrinkCategory.destilado);
      expect(destilados, isNotEmpty);
      expect(
        destilados.every((i) => i.category == DrinkCategory.destilado),
        isTrue,
      );
    });

    test('los cócteles usan gramsOverride', () {
      final margarita = AlcoholCatalog.byId('margarita')!;
      expect(margarita.isCocktail, isTrue);
      expect(margarita.gramsFor(), 18);
    });

    test('las bebidas por fórmula calculan gramos por volumen×ABV', () {
      final cerveza = AlcoholCatalog.byId('cerveza-lager')!;
      expect(cerveza.gramsFor(), closeTo(14.0, 0.05));
      expect(cerveza.standardUnitsFor(), closeTo(1.4, 0.01));
    });

    test('servida personalizada escala los gramos', () {
      final vino = AlcoholCatalog.byId('vino-tinto')!;
      final small = vino.gramsFor(servingMl: 100);
      final big = vino.gramsFor(servingMl: 200);
      expect(big, greaterThan(small));
    });

    test('las opciones sin alcohol tienen carga mínima', () {
      final cero = AlcoholCatalog.byId('cerveza-cero')!;
      expect(cero.standardUnitsFor(), lessThan(0.2));
    });
  });
}

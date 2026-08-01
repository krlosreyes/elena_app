// SPEC-261.4: tests de la lista de tipos de trago del picker.

import 'package:elena_app/src/features/alcohol/domain/drink_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ids únicos', () {
    final ids = DrinkTypes.all.map((t) => t.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('byId encuentra y falla con null/desconocido', () {
    expect(DrinkTypes.byId('vino')?.label, 'Vino');
    expect(DrinkTypes.byId(null), isNull);
    expect(DrinkTypes.byId('no-existe'), isNull);
  });

  test('todos traen etiqueta, hint, servida y gramos válidos', () {
    for (final t in DrinkTypes.all) {
      expect(t.label.trim(), isNotEmpty);
      expect(t.hint.trim(), isNotEmpty);
      expect(t.servingLabel.trim(), isNotEmpty);
      expect(t.gramsPerServing, greaterThan(0));
    }
  });

  test('tragos populares reconocibles, sin "destilado claro/oscuro"', () {
    final labels = DrinkTypes.all.map((t) => t.label.toLowerCase());
    expect(labels.any((l) => l.contains('destilado')), isFalse);
    expect(DrinkTypes.byId('cuba-libre'), isNotNull);
    expect(DrinkTypes.byId('mojito'), isNotNull);
    expect(DrinkTypes.byId('pina-colada'), isNotNull);
    expect(DrinkTypes.byId('crema-whisky'), isNotNull);
  });

  test('congéneres: whisky sí, tequila no', () {
    expect(DrinkTypes.byId('whisky')!.highCongeners, isTrue);
    expect(DrinkTypes.byId('tequila')!.highCongeners, isFalse);
  });
}

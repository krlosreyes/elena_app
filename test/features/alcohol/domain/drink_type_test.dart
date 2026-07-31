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

  test('todos traen etiqueta y hint no vacíos', () {
    for (final t in DrinkTypes.all) {
      expect(t.label.trim(), isNotEmpty);
      expect(t.hint.trim(), isNotEmpty);
    }
  });

  test('hay al menos un claro y un oscuro con congéneres', () {
    expect(DrinkTypes.byId('destilado-oscuro')!.highCongeners, isTrue);
    expect(DrinkTypes.byId('destilado-claro')!.highCongeners, isFalse);
  });
}
